# Feature Specs: tieubao/dotfiles

Generated: 2026-04-02
For: Claude Code handoff
Repo: https://github.com/tieubao/dotfiles

---

## F-01: Idempotent install.sh

### Problem
Running `install.sh` twice currently nukes the chezmoi symlink (`rm -rf ~/.local/share/chezmoi`) and re-runs `chezmoi init --apply`, which re-prompts for name, email, editor, 1Password vault. This is annoying on an already-configured machine.

### Spec
Modify `install.sh` to detect existing state and skip accordingly:

```bash
# Pseudocode
if chezmoi is installed AND ~/.local/share/chezmoi exists AND .chezmoi.toml exists:
    echo "Already initialized. Running chezmoi apply..."
    chezmoi apply
elif chezmoi is installed:
    # chezmoi exists but not initialized for this repo
    link source dir + chezmoi init --apply
else:
    # fresh machine
    install homebrew + chezmoi + link + init --apply
fi
```

Rules:
- Never re-prompt if `.chezmoi.toml.tmpl` has already been rendered to `~/.config/chezmoi/chezmoi.toml`
- The `rm -rf` of the symlink should only happen if the existing link points somewhere OTHER than `$DOTFILES/home`
- Add a `--force` flag that does the full teardown+reinit for edge cases
- Print what it is doing at each step (keep existing `echo "==>"` style)
- Exit codes: 0 = success, 1 = homebrew install failed, 2 = chezmoi init failed

### Files to modify
- `install.sh`

### Test
1. Run `install.sh` on configured machine. Should NOT prompt for name/email. Should just run `chezmoi apply`.
2. Run `install.sh --force` on configured machine. Should teardown and re-prompt.
3. Run on fresh machine (or fresh user account). Should do full bootstrap.

---

## F-02: CI smoke test

### Problem
No automated testing. Config changes might break `chezmoi apply` on a fresh machine and you won't know until you actually set up a new Mac.

### Spec
Create `.github/workflows/test.yml`:

```yaml
name: dotfiles-test
on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 9 * * 1'  # weekly Monday 9am UTC

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install chezmoi
        run: brew install chezmoi
      - name: Link source
        run: |
          mkdir -p ~/.local/share
          ln -sf $GITHUB_WORKSPACE/home ~/.local/share/chezmoi
      - name: Dry run (no 1Password)
        run: |
          chezmoi init --data=false --no-tty <<EOF
          {
            "name": "CI Test",
            "email": "ci@test.com",
            "editor": "vim",
            "use_1password": false
          }
          EOF
          chezmoi apply --dry-run --verbose
      - name: Validate managed files
        run: chezmoi managed | head -50
      - name: Check templates render
        run: chezmoi execute-template '{{ .chezmoi.os }}' | grep darwin
```

Rules:
- Must work WITHOUT 1Password (set `use_1password: false` in test data)
- Must NOT actually apply (dry-run only) since we can't install all casks in CI
- Template rendering errors should fail the build
- Weekly schedule catches upstream breakage (e.g., chezmoi version bumps)

### Files to create
- `.github/workflows/test.yml`

### Test
Push to a branch, verify the Action runs green.

---

## F-03: Bootstrap without git

### Problem
The README requires `git clone` as the first step. On a truly fresh Mac, git requires Xcode CLT which takes 10+ minutes to install. chezmoi can bootstrap directly from a GitHub repo.

### Spec
Add an alternative one-liner to README:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply tieubao
```

Also add a second method using Homebrew (no git needed, brew installs via curl):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
chezmoi init --apply tieubao
```

Rules:
- Keep the `git clone` method as primary (better for development workflow)
- Add "without git" as a clearly labeled alternative section
- The `chezmoi init tieubao` approach means chezmoi clones to `~/.local/share/chezmoi/` itself (no symlink trick). Document this difference.
- Both methods should produce the same end state

### Files to modify
- `README.md` (add "Alternative: bootstrap without git" section)

---

## F-04: Brewfile split

### Problem
One `dot_Brewfile` with ~80 packages is hard to scan, and on a minimal machine (e.g., CI, server, borrowed laptop) you might want just the essentials without 30 GUI casks.

### Spec
Split into three files:

```
home/
  dot_Brewfile.tmpl              # main entry point, includes the others
  dot_config/brew/
    Brewfile.base                # essentials: git, fish, chezmoi, coreutils, starship, etc.
    Brewfile.dev                 # dev tools: mise, go, node, docker, kubectl, etc.
    Brewfile.apps                # GUI casks: Ghostty, VS Code, 1Password, Arc, etc.
    Brewfile.mas                 # Mac App Store apps (mas IDs)
```

The main `dot_Brewfile.tmpl` uses chezmoi templating:

```ruby
# Base (always)
{{ include "dot_config/brew/Brewfile.base" }}

# Dev tools
{{ if .dev_computer }}
{{ include "dot_config/brew/Brewfile.dev" }}
{{ end }}

# GUI apps (skip in CI/headless)
{{ if not .headless }}
{{ include "dot_config/brew/Brewfile.apps" }}
{{ end }}

# Mac App Store
{{ if and (not .headless) (eq .chezmoi.os "darwin") }}
{{ include "dot_config/brew/Brewfile.mas" }}
{{ end }}
```

New chezmoi init prompt:

```
Is this a headless/server environment? (true/false) → .headless
Is this a development machine? (true/false) → .dev_computer
```

Rules:
- `Brewfile.base` should be < 20 items. Only things you need on EVERY machine.
- `Brewfile.dev` is language toolchains, databases, cloud CLIs
- `Brewfile.apps` is GUI casks only
- `Brewfile.mas` is Mac App Store apps (using `mas` IDs)
- The `run_onchange_before_brew-bundle.sh` script must still trigger on ANY sub-file change. Use chezmoi's hash tracking on the rendered output.
- Add `chafa`, `librsvg`, `imagemagick` to `Brewfile.dev` (for F-10)

### Files to create/modify
- Split `home/dot_Brewfile` into 4 files under `home/dot_config/brew/`
- Create `home/dot_Brewfile.tmpl` as the aggregator
- Modify `home/.chezmoi.toml.tmpl` to add `headless` and `dev_computer` prompts
- Verify `run_onchange_before_brew-bundle.sh` still triggers correctly

---

## F-05: Fish helper commands (dotfiles CLI)

### Problem
Daily dotfiles operations require remembering `chezmoi edit`, `chezmoi diff`, `chezmoi apply` commands. A wrapper function makes it more ergonomic.

### Spec
Create `home/dot_config/fish/functions/dotfiles.fish`:

```fish
function dotfiles -d "Manage dotfiles via chezmoi"
    switch $argv[1]
        case edit e
            chezmoi edit $argv[2..]
        case diff d
            chezmoi diff --no-pager
        case sync s
            chezmoi apply
            and echo "Applied."
        case status st
            echo "Managed files:"
            chezmoi managed | wc -l
            echo ""
            echo "Pending changes:"
            chezmoi diff --no-pager | head -30
        case cd
            cd (chezmoi source-path)
        case refresh r
            chezmoi apply --refresh-externals
        case add a
            chezmoi add $argv[2..]
        case ''
            echo "Usage: dotfiles <command>"
            echo ""
            echo "Commands:"
            echo "  edit <file>   Edit a managed file"
            echo "  diff          Show pending changes"
            echo "  sync          Apply all changes"
            echo "  status        Show managed file count + pending diffs"
            echo "  cd            cd to chezmoi source directory"
            echo "  refresh       Re-download external files (fish plugins)"
            echo "  add <file>    Add a new file to chezmoi"
        case '*'
            chezmoi $argv
    end
end
```

Also create `home/dot_config/fish/completions/dotfiles.fish`:

```fish
complete -c dotfiles -f
complete -c dotfiles -n "__fish_use_subcommand" -a "edit" -d "Edit managed file"
complete -c dotfiles -n "__fish_use_subcommand" -a "diff" -d "Show pending changes"
complete -c dotfiles -n "__fish_use_subcommand" -a "sync" -d "Apply all changes"
complete -c dotfiles -n "__fish_use_subcommand" -a "status" -d "Show status"
complete -c dotfiles -n "__fish_use_subcommand" -a "cd" -d "Go to source dir"
complete -c dotfiles -n "__fish_use_subcommand" -a "refresh" -d "Re-download externals"
complete -c dotfiles -n "__fish_use_subcommand" -a "add" -d "Add file to chezmoi"
```

### Files to create
- `home/dot_config/fish/functions/dotfiles.fish`
- `home/dot_config/fish/completions/dotfiles.fish`

---

## F-06: Fish completions for custom functions

### Problem
Custom Fish functions (cdg, op_env, keychain_env, tx, web3_env) have no tab completions. They feel like second-class citizens compared to system commands.

### Spec
Create completion files for each existing function. Inspect what each function accepts and generate appropriate completions.

Example for `tx` (assuming it is a tmux session helper):

```fish
# home/dot_config/fish/completions/tx.fish
complete -c tx -f
complete -c tx -a "(tmux list-sessions -F '#{session_name}' 2>/dev/null)"
```

Example for `cdg` (assuming it cd's to git repos):

```fish
# home/dot_config/fish/completions/cdg.fish
complete -c cdg -f
complete -c cdg -a "(find ~/Projects ~/src -maxdepth 2 -name .git -type d 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {})"
```

Rules:
- Read the actual function implementations in `home/dot_config/fish/functions/` first
- Only create completions where they add value (skip if the function takes no arguments)
- Keep completions fast. No expensive operations on every tab press.
- Use `2>/dev/null` on all commands that might fail

### Files to create
- `home/dot_config/fish/completions/cdg.fish`
- `home/dot_config/fish/completions/op_env.fish`
- `home/dot_config/fish/completions/keychain_env.fish`
- `home/dot_config/fish/completions/tx.fish`
- Others as applicable based on function signatures

---

## F-07: Drift detection

### Problem
You manually edit `~/.config/ghostty/config` directly instead of through `chezmoi edit`. The edit works but is never committed back. Weeks later you wonder why your new machine has different settings.

### Spec
Create `home/dot_config/fish/functions/dotfiles-drift.fish`:

```fish
function dotfiles-drift -d "Check for local config drift from chezmoi source"
    set -l diffs (chezmoi diff --no-pager 2>/dev/null)
    if test -n "$diffs"
        echo "Drift detected in "(chezmoi diff --no-pager | grep '^diff' | wc -l | string trim)" files:"
        echo ""
        chezmoi diff --no-pager | grep '^diff' | sed 's/diff --git a\//  /' | sed 's/ b\/.*//'
        echo ""
        echo "Run 'dotfiles sync' to apply source → local"
        echo "Run 'chezmoi merge <file>' to reconcile"
        echo "Run 'chezmoi re-add <file>' to pull local → source"
        return 1
    else
        echo "No drift. Local files match chezmoi source."
        return 0
    end
end
```

Optional: add a periodic check hook in `config.fish.tmpl` that runs on shell startup (but only once per day):

```fish
# Drift check (once per day, non-blocking)
set -l drift_check_file ~/.cache/dotfiles-drift-check
set -l today (date +%Y-%m-%d)
if not test -f $drift_check_file; or test (cat $drift_check_file) != $today
    echo $today > $drift_check_file
    set -l drift_count (chezmoi diff --no-pager 2>/dev/null | grep '^diff' | wc -l | string trim)
    if test "$drift_count" -gt 0
        echo "dotfiles: $drift_count files have drifted. Run 'dotfiles-drift' to see details."
    end
end
```

Rules:
- Daily check must be non-blocking (fast, no network calls)
- Never auto-apply. Only inform.
- `dotfiles-drift` is the explicit command to see full details
- Cache the check result in `~/.cache/` (XDG-compliant)

### Files to create
- `home/dot_config/fish/functions/dotfiles-drift.fish`
- Modify `home/dot_config/fish/config.fish.tmpl` (add daily drift check block)

---

## F-08: SSH config hardening

### Problem
SSH config with 1Password SSH Agent needs specific settings to be secure and functional. Missing `IdentitiesOnly yes` can leak key identifiers. Missing `Include` pattern makes the config monolithic.

### Spec
Restructure `home/dot_ssh/config.tmpl` to use a modular include pattern:

```ssh-config
# ~/.ssh/config (managed by chezmoi)

# Global defaults
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

{{ if .use_1password }}
# 1Password SSH Agent
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
{{ end }}

# Include modular configs
Include config.d/*
```

Create `home/dot_ssh/config.d/` directory for per-context SSH configs:

```
home/dot_ssh/
  config.tmpl            # main config (above)
  config.d/
    personal.tmpl        # personal servers
    work.tmpl            # Dwarves servers
```

Rules:
- `IdentitiesOnly yes` is mandatory when using 1Password SSH Agent. Without it, SSH tries all keys and the agent might expose key identifiers to hostile servers.
- `Include config.d/*` must come after the global `Host *` blocks
- Each file in `config.d/` should have `private_` prefix in chezmoi (mode 0600)
- The `config.d/` directory must exist even if empty (create with `.gitkeep` or chezmoi `create_` prefix)

### Files to modify/create
- `home/dot_ssh/config.tmpl` (restructure)
- `home/dot_ssh/config.d/` (new directory with sample files)

---

## F-09: Age encryption for sensitive files

### Problem
Some files are too complex for template injection (e.g., kubeconfig with multiple contexts, VPN configs, certificate bundles) but too sensitive for plaintext in git. 1Password `op://` works for single values, not entire files.

### Spec
Set up chezmoi's age encryption:

1. Generate an age key (one-time, manual):
```bash
age-keygen -o ~/.config/chezmoi/key.txt
```

2. Configure chezmoi to use it in `home/.chezmoi.toml.tmpl`:
```toml
encryption = "age"

[age]
identity = "~/.config/chezmoi/key.txt"
recipient = "age1..." # from key.txt public key
```

3. Add encrypted files with:
```bash
chezmoi add --encrypt ~/.kube/config
# creates home/encrypted_dot_kube/config.age
```

Rules:
- `~/.config/chezmoi/key.txt` must NEVER be in git. Add to `.gitignore`.
- Document the backup procedure for the age key (store in 1Password as a Secure Note)
- Add `age` to `Brewfile.base`
- Document in README how to add/decrypt files
- The age key is machine-specific. On a new machine, retrieve from 1Password and place at the expected path before `chezmoi apply`.

### Files to modify
- `home/.chezmoi.toml.tmpl` (add age encryption config)
- `.gitignore` (add `key.txt` pattern)
- `README.md` (add "Encrypted files" section)
- `Brewfile.base` (add `age`)

---

## F-10: Ghostty image rendering

### Problem
Ghostty supports the Kitty graphics protocol for inline image display, but no tools are installed and no helper function exists to render images.

### Spec
Add packages to Brewfile and create a Fish function:

Packages (add to `Brewfile.dev`):
```ruby
brew "chafa"        # terminal image renderer (auto-detects kitty protocol)
brew "librsvg"      # SVG to PNG conversion (rsvg-convert)
brew "imagemagick"  # general image processing
```

Create `home/dot_config/fish/functions/render-img.fish`:

```fish
function render-img -d "Render images inline in Ghostty terminal"
    set -l file $argv[1]
    set -l width (math (tput cols) - 4)

    if test -z "$file"
        echo "Usage: render-img <file> [width]"
        echo "Supports: png, jpg, svg, gif, webp"
        return 1
    end

    if test (count $argv) -ge 2
        set width $argv[2]
    end

    if not test -f "$file"
        echo "File not found: $file"
        return 1
    end

    set -l ext (string lower (string split -r -m1 '.' $file)[2])
    set -l temp /tmp/render-img-preview.png

    switch $ext
        case svg
            if command -q rsvg-convert
                rsvg-convert "$file" -o $temp 2>/dev/null
            else
                echo "Need rsvg-convert: brew install librsvg"
                return 1
            end
        case png jpg jpeg gif webp
            set temp "$file"
        case '*'
            echo "Unsupported format: $ext"
            return 1
    end

    # Use kitty protocol for Ghostty
    chafa --format=kitty --size="$width"x "$temp"
end
```

Create completion:
```fish
# home/dot_config/fish/completions/render-img.fish
complete -c render-img -f
complete -c render-img -a "(__fish_complete_path)" -d "Image file"
```

### Files to create
- `home/dot_config/fish/functions/render-img.fish`
- `home/dot_config/fish/completions/render-img.fish`
- Modify `Brewfile.dev` (add chafa, librsvg, imagemagick)

### Test
```bash
# In Ghostty terminal:
render-img /path/to/screenshot.png
render-img /path/to/diagram.svg
render-img /path/to/photo.jpg 40  # explicit width
```

---

## F-11: Decision records

### Problem
No documentation of WHY certain tools were chosen. Future-you (or contributors) will wonder why Fish instead of Zsh, why Ghostty instead of Kitty, why chezmoi instead of GNU Stow.

### Spec
Create `docs/decisions/` with one file per decision:

```
docs/decisions/
  001-chezmoi-over-stow.md
  002-fish-over-zsh.md
  003-ghostty-over-kitty.md
  004-1password-for-secrets.md
  005-no-plugin-manager-for-fish.md
```

Each follows ADR format:
```markdown
# ADR-001: chezmoi over GNU Stow

## Status: accepted

## Context
Needed a dotfiles manager that supports: 1Password integration, Go templates
for machine-specific config, multi-machine support, and XDG-compliant storage.

## Decision
Use chezmoi as the dotfiles manager.

## Alternatives considered
- GNU Stow: Simple symlinks only, no templates, no secrets, no multi-machine.
  Good for single machine but doesn't scale.
- yadm: Git wrapper with Jinja2 templates, but template engine depends on
  unmaintained external tools (envtpl, j2cli). chezmoi uses Go's text/template
  standard library.
- Nix Home Manager: Overkill. Requires learning Nix language. We just need
  dotfiles, not a full system package manager.

## Consequences
- All configs live in `home/` with chezmoi naming conventions (dot_, .tmpl, etc.)
- Secrets use `onepasswordRead` template function
- New team members need to learn chezmoi basics (apply, edit, diff)
- Repo is safe to make public since no plaintext secrets exist
```

Rules:
- Write based on the actual decisions from our conversation + your own reasoning
- Be opinionated. State what won and why.
- Include real tradeoffs, not just marketing points
- Keep each ADR to ~150-250 words

### Files to create
- `docs/decisions/001-chezmoi-over-stow.md`
- `docs/decisions/002-fish-over-zsh.md`
- `docs/decisions/003-ghostty-over-kitty.md`
- `docs/decisions/004-1password-for-secrets.md`
- `docs/decisions/005-no-plugin-manager-for-fish.md`

Content for each is derived from the Claude.ai chat session where these tools were evaluated.

---

## F-12: Tag v0.1.0 release

### Problem
No versioning. Can't rollback if a change breaks the setup.

### Spec
Once Phase 1 and Phase 2 features are merged and tested:

```bash
git tag -a v0.1.0 -m "Initial stable release: Fish + Ghostty + chezmoi + 1Password"
git push origin v0.1.0
```

Also create a GitHub Release with a changelog summarizing what's included.

Rules:
- Only tag after at least one successful fresh-machine test
- Changelog should list: tools included, what install.sh does, known limitations
- Future changes should be tagged incrementally (v0.2.0 for new features, v0.1.1 for fixes)

### Files to create
- None (git tag operation)
- Optional: `CHANGELOG.md` at repo root
