# R-11: Error message system

## Problem

When `chezmoi apply` fails, users get cryptic, unactionable errors:

```
chezmoi: .Brewfile: template: dot_Brewfile.tmpl:54:10: executing "dot_Brewfile.tmpl" at <.headless>: map has no entry for key "headless"
```

Users have no idea this means "run `chezmoi init`". Other failures are worse — brew bundle truncates output to 20 lines, `mas install` and `code --install-extension` fail silently with `|| true`, and there's no summary of what happened after apply finishes.

### Error handling audit

| Script / Template | Current handling | Impact |
|---|---|---|
| `.tmpl` files (7 files) | None — Go template crash | Blocks entire apply |
| `brew-bundle.sh` | Output truncated to 20 lines | Hides root cause |
| `macos-defaults.sh` | `|| true` on killall | Acceptable |
| `mas-apps.sh` | No error handling | 20+ silent failures |
| `vscode.sh` | `|| true` on extensions | Silent failures |
| `install-toolchains.sh` | `set -e`, `|| true` on npm/uv | Partial |
| `setup-fish-shell.sh` | `|| echo "Run manually"` | Good fallback |
| `install.sh` | `set -e`, exit codes, verification | Good (reference) |

## Design

### Tooling: gum-first, ANSI fallback

We use [gum](https://github.com/charmbracelet/gum) by Charm as the primary rendering engine. It's already a dependency (in Brewfile, used by `install.sh`). Raw ANSI printf is the fallback when gum isn't available (e.g. first run before brew, CI).

**Why gum over raw ANSI:**
- `gum log` gives leveled messages with colored badges, timestamps, and structured fields out of the box
- `gum style` gives a CSS-like box model (border, padding, margin, alignment) for summary rendering
- `gum join` composes blocks horizontally/vertically — no manual column math
- `gum format -t emoji` renders emoji shortcodes for cross-terminal consistency
- Declarative and readable vs opaque escape sequences

### Color palette

Uses Charm's default level colors (from `charmbracelet/log`) for consistency with the broader Charm ecosystem:

| Level | Color | ANSI 256 | Badge |
|-------|-------|----------|-------|
| OK/Info | cyan | `86` | `INFO` |
| Success | green | `78` | `PASS` |
| Warning | yellow | `192` | `WARN` |
| Error | red | `204` | `ERRO` |
| Fatal | magenta | `134` | `FATA` |
| Accent | blue | `75` | — (section headers) |
| Dim | gray | `245` | — (helper text) |

### Message anatomy

Every message follows a **what → why → fix** pattern using `gum log` for the primary line and `gum style --faint` for supporting detail:

```
WARN  brew: monitor-control not found
        Cask removed from Homebrew.
        Fix: remove from ~/.Brewfile

ERRO  Homebrew not found
        Cannot install packages without brew.
        Fix: /bin/bash -c "$(curl -fsSL ...)"

INFO  Fish shell set as default
```

**Rendered with gum:**

```bash
# info — one-liner
gum log --level info "Fish shell set as default"

# warn — with structured context and indented detail
gum log --level warn "brew: monitor-control not found"
gum style --faint --foreground 245 --padding "0 0 0 8" \
  "Cask removed from Homebrew." \
  "Fix: remove from ~/.Brewfile"

# error — same structure
gum log --level error "Homebrew not found"
gum style --faint --foreground 245 --padding "0 0 0 8" \
  "Cannot install packages without brew." \
  "Fix: /bin/bash -c \"\$(curl -fsSL ...)\""

# structured fields for debugging context
gum log --level error --structured "brew bundle failed" exit_code 1 log "/tmp/brew-xxx.log"
```

**Section headers** — bold accent, matching `install.sh` `==>` pattern:

```bash
gum style --bold --foreground 75 "==> Brewfile changed, running brew bundle..."
```

### Apply summary

Rendered with `gum style --border` + `gum join` for a polished box at the end of every apply.

**Success (all OK):**

```
╭────────────────────────────────────────────╮
│                                            │
│   ✓ dotfiles apply complete — all OK       │
│                                            │
╰────────────────────────────────────────────╯
```

```bash
gum style --border rounded --border-foreground 78 --padding "1 2" --margin "1 0" \
  "$(gum style --foreground 78 --bold '✓ dotfiles apply complete — all OK')"
```

**With warnings:**

```
╭────────────────────────────────────────────╮
│                                            │
│   dotfiles apply complete                  │
│                                            │
│   ✓  5 scripts OK                         │
│   ⚠  2 warnings                           │
│                                            │
│   Warnings                                 │
│     brew    monitor-control not found      │
│     vscode  1 extension failed             │
│                                            │
│   Next steps                               │
│     1. Remove monitor-control              │
│        from ~/.Brewfile                    │
│     2. Retry extensions:                   │
│        code --install-extension <name>     │
│                                            │
╰────────────────────────────────────────────╯
```

```bash
# Build each section
TITLE=$(gum style --bold "dotfiles apply complete")
COUNTS=$(gum join --vertical \
  "$(gum style --foreground 78  '  ✓  5 scripts OK')" \
  "$(gum style --foreground 192 '  ⚠  2 warnings')")
WARNS=$(gum join --vertical \
  "$(gum style --bold --foreground 117 '  Warnings')" \
  "$(gum style --faint '    brew    monitor-control not found')" \
  "$(gum style --faint '    vscode  1 extension failed')")
NEXT=$(gum join --vertical \
  "$(gum style --bold --foreground 117 '  Next steps')" \
  "$(gum style --faint '    1. Remove monitor-control from ~/.Brewfile')" \
  "$(gum style --faint '    2. Retry: ')$(gum style --foreground 75 'code --install-extension <name>')")

# Compose and box
BODY=$(gum join --vertical "$TITLE" "" "$COUNTS" "" "$WARNS" "" "$NEXT")
gum style --border rounded --border-foreground 192 --padding "1 2" --margin "1 0" "$BODY"
```

**With failures:**

Same layout but border color `204` (red), adds failure section, "Next steps" prioritizes fixes.

**Fallback (no gum):**

```
==> Apply complete
  ✓ 5 scripts OK
  ⚠ 2 warnings

  Warnings:
    brew    monitor-control not found
    vscode  1 extension failed

  Next steps:
    1. Remove monitor-control from ~/.Brewfile
    2. Retry: code --install-extension <name>
```

### Log file

All warnings and errors append to `~/.cache/dotfiles-apply.log` during apply:

```
2026-04-03T10:15:00 OK: brew-bundle
2026-04-03T10:15:05 WARN: brew: monitor-control not found | Fix: remove from Brewfile
2026-04-03T10:15:30 OK: macos-defaults
2026-04-03T10:15:32 FAIL: mas: Fantastical (975937182) | Fix: sign into App Store, rerun chezmoi apply
2026-04-03T10:16:00 OK: vscode
```

Summary script reads this file. Log is reset at the start of each apply.

## Architecture

### Component 1: Shared bash library

**File:** `home/dot_config/dotfiles/lib.sh` → deploys to `~/.config/dotfiles/lib.sh`

Provides: `info`, `warn`, `err`, `die`, `require_cmd`, `section`, `script_ok`

```bash
# ~/.config/dotfiles/lib.sh — sourced by chezmoi after-scripts
# gum-first output with ANSI fallback

DOTFILES_LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-apply.log"
_HAS_GUM=$(command -v gum &>/dev/null && echo 1 || echo 0)

# ── Logging helpers ──

# section "title"
section() {
    if [ "$_HAS_GUM" = 1 ]; then
        gum style --bold --foreground 75 "==> $*"
    else
        printf '\n\033[1;38;5;75m==> %s\033[0m\n' "$*"
    fi
}

# info "message"
info() {
    if [ "$_HAS_GUM" = 1 ]; then
        gum log --level info "$*"
    else
        printf '\033[38;5;86m  ✓\033[0m %s\n' "$*"
    fi
}

# warn "what" "why" "fix command"
warn() {
    if [ "$_HAS_GUM" = 1 ]; then
        gum log --level warn "$1"
        [ -n "${2:-}" ] && gum style --faint --foreground 245 --padding "0 0 0 8" "$2"
        [ -n "${3:-}" ] && gum style --faint --foreground 245 --padding "0 0 0 8" \
            "$(gum format -t template 'Fix: {{ Color "78" "" "'"$3"'" }}')"
    else
        printf '\033[38;5;192m  ⚠\033[0m \033[1m%s\033[0m\n' "$1"
        [ -n "${2:-}" ] && printf '\033[38;5;245m    %s\033[0m\n' "$2"
        [ -n "${3:-}" ] && printf '\033[38;5;245m    Fix: \033[38;5;78m%s\033[0m\n' "$3"
    fi
    echo "$(date +%Y-%m-%dT%H:%M:%S) WARN: $1${3:+ | Fix: $3}" >> "$DOTFILES_LOG"
}

# err "what" "why" "fix command"
err() {
    if [ "$_HAS_GUM" = 1 ]; then
        gum log --level error "$1"
        [ -n "${2:-}" ] && gum style --faint --foreground 245 --padding "0 0 0 8" "$2"
        [ -n "${3:-}" ] && gum style --faint --foreground 245 --padding "0 0 0 8" \
            "$(gum format -t template 'Fix: {{ Color "78" "" "'"$3"'" }}')"
    else
        printf '\033[38;5;204m  ✗\033[0m \033[1m%s\033[0m\n' "$1" >&2
        [ -n "${2:-}" ] && printf '\033[38;5;245m    %s\033[0m\n' "$2" >&2
        [ -n "${3:-}" ] && printf '\033[38;5;245m    Fix: \033[38;5;78m%s\033[0m\n' "$3" >&2
    fi
    echo "$(date +%Y-%m-%dT%H:%M:%S) FAIL: $1${3:+ | Fix: $3}" >> "$DOTFILES_LOG"
}

# die "what" "why" "fix command" — prints error then exits
die() { err "$@"; exit 1; }

# require_cmd "cmd" "why needed" "install command"
require_cmd() {
    command -v "$1" &>/dev/null || die \
        "$1 not found" \
        "${2:-Required for this step.}" \
        "${3:-brew install $1}"
}

# script_ok "name" — call at end of each script
script_ok() {
    local name="${1:-$(basename "$0" | sed 's/^run_[a-z_]*_//' | sed 's/\.sh.*//')}"
    info "$name complete"
    echo "$(date +%Y-%m-%dT%H:%M:%S) OK: $name" >> "$DOTFILES_LOG"
}
```

**Note:** `before` scripts run prior to file deployment — they can't source the library. They detect gum inline:

```bash
_has_gum() { command -v gum &>/dev/null; }
```

### Component 2: Template guards

Every `.tmpl` file gets `hasKey` + `fail` guards for the variables it uses:

```
{{- if not (hasKey . "headless") -}}
{{-   fail "\n\n  ✗ Missing config variable: headless\n    Your chezmoi config is out of date or was never created.\n    Fix: chezmoi init\n" -}}
{{- end -}}
```

chezmoi's `fail` runs at template render time (before any bash), so gum isn't available here. The `\n`-formatted message with `✗` makes it stand out in chezmoi's own error output.

**Guard mapping:**

| File | Guards |
|------|--------|
| `dot_Brewfile.tmpl` | `headless`, `use_1password` |
| `dot_gitconfig.tmpl` | `name`, `email`, `editor` |
| `config.fish.tmpl` | `editor` |
| `secrets.fish.tmpl` | `use_1password` |
| `dot_ssh/config.tmpl` | `use_1password` |
| `zed/settings.json.tmpl` | `use_1password`, `editor` |

### Component 3: Script hardening

All scripts get `set -eo pipefail` and use the library for structured messages.

**Per-script message catalog:**

#### brew-bundle (before script — inline gum)

```bash
# success
gum log --level info "brew bundle complete"

# failure
gum log --level error --structured "brew bundle failed" exit_code "$rc" log "$BREW_LOG"
gum style --faint --foreground 245 --padding "0 0 0 8" \
  "Some packages could not be installed." \
  "$(gum format -t template 'Fix: {{ Color "78" "" "brew bundle --file=~/.Brewfile --verbose" }}')"
```

#### 1password-check (before script — inline gum)

```bash
# op not installed
gum log --level warn "1Password CLI (op) not found"
gum style --faint --foreground 245 --padding "0 0 0 8" \
  "Config has use_1password=true but op is not installed." \
  "$(gum format -t template 'Fix: {{ Color "78" "" "brew install 1password-cli && eval $(op signin)" }}')"

# op not signed in
gum log --level warn "1Password CLI not signed in"
gum style --faint --foreground 245 --padding "0 0 0 8" \
  "Secret injection via onepasswordRead will fail." \
  "$(gum format -t template 'Fix: {{ Color "78" "" "eval $(op signin)" }}')"
```

#### setup-fish-shell

```bash
die "fish not found at /opt/homebrew/bin/fish" \
    "Homebrew fish must be installed first." \
    "brew install fish"
```

#### macos-defaults

```bash
warn "defaults write $domain $key failed" \
     "May require a newer macOS version." \
     "defaults write $domain $key $value"
```

#### mas-apps

```bash
# pre-check
warn "Not signed into Mac App Store" \
     "Cannot install apps without an active account." \
     "open -a 'App Store' and sign in, then rerun: chezmoi apply"

# per-app failure
warn "Mac App Store: failed to install $name ($id)" \
     "App may have been removed or requires purchase." \
     "open 'macappstore://apps.apple.com/app/id$id'"
```

#### vscode

```bash
warn "VS Code: $failed extension(s) failed to install" \
     "Extensions may have been renamed or removed." \
     "code --install-extension <name> to retry"
```

#### install-toolchains

```bash
warn "npm: failed to install $pkg" \
     "Package may be unavailable or network error." \
     "npm i -g $pkg"
```

### Component 4: Apply lifecycle scripts

**`run_onchange_before_aa-init.sh.tmpl`** — resets log at start of apply:

```bash
#!/bin/bash
# Trigger on every apply: {{ now | date "2006-01-02" }}
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
: > "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-apply.log"
```

**`run_after_zz-summary.sh`** — reads log, renders summary box:

1. Count OK / WARN / FAIL lines in log
2. Pick border color: `78` (green) if all OK, `192` (yellow) if warnings, `204` (red) if failures
3. If gum available: compose with `gum style --border rounded` + `gum join --vertical`
4. If no gum: plain ANSI fallback with `==>` header
5. If warnings/failures: show detail lines with category labels
6. If warnings/failures: show "Next steps" with fix commands extracted from `| Fix: ...` suffix in log
7. Always print log path at the bottom in dim text

### Component 5: 1Password pre-check

**`run_onchange_before_ab-1password-check.sh.tmpl`** — runs early, warns if 1Password setup incomplete. Non-fatal — brew-bundle installs `op` if it's in the Brewfile. Uses inline gum (before-script, no library yet).

### Component 6: Brewfile cleanup

While we're here:
- Remove `monitor-control` (removed from Homebrew)
- Fix `zen-browser` → `zen` (renamed)

## Files to create

| File | Purpose |
|------|---------|
| `home/dot_config/dotfiles/lib.sh` | Shared bash library (gum-first, ANSI fallback) |
| `home/.chezmoiscripts/run_onchange_before_aa-init.sh.tmpl` | Reset log at start of apply |
| `home/.chezmoiscripts/run_onchange_before_ab-1password-check.sh.tmpl` | 1Password pre-check |
| `home/.chezmoiscripts/run_after_zz-summary.sh` | End-of-apply summary box |

## Files to modify

| File | Change |
|------|--------|
| `home/dot_Brewfile.tmpl` | Guards + remove monitor-control + zen-browser→zen |
| `home/dot_gitconfig.tmpl` | Guards |
| `home/dot_config/fish/config.fish.tmpl` | Guard |
| `home/dot_config/fish/conf.d/secrets.fish.tmpl` | Guard |
| `home/dot_ssh/config.tmpl` | Guard |
| `home/dot_config/zed/settings.json.tmpl` | Guards |
| `home/.chezmoiscripts/run_onchange_before_brew-bundle.sh.tmpl` | Full output capture, gum styled errors |
| `home/.chezmoiscripts/run_once_after_setup-fish-shell.sh` | Source lib, pre-check fish |
| `home/.chezmoiscripts/run_once_after_macos-defaults.sh.tmpl` | Source lib, safe_defaults |
| `home/.chezmoiscripts/run_once_after_mas-apps.sh.tmpl` | Source lib, mas_install wrapper |
| `home/.chezmoiscripts/run_onchange_after_vscode.sh.tmpl` | Source lib, count failures |
| `home/.chezmoiscripts/run_once_after_install-toolchains.sh` | Source lib, warn on failures |

## Testing

### Manual verification (local)

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 1 | Template guard — missing var | Remove `headless` from `~/.config/chezmoi/chezmoi.toml`, run `chezmoi apply` | `✗ Missing config variable: headless` ... `Fix: chezmoi init` |
| 2 | Template guard — all vars present | Normal `chezmoi apply` | No guard errors, templates render clean |
| 3 | gum log rendering | Run any after-script | `gum log` styled messages with colored level badges (INFO cyan, WARN yellow, ERROR red) |
| 4 | Summary — all OK | Normal apply with no issues | Green-bordered gum box: `✓ dotfiles apply complete — all OK` |
| 5 | Summary — with warnings | Force a warning (e.g. remove a brew formula) | Yellow-bordered box with warnings section + "Next steps" with fix commands |
| 6 | Summary — with failures | Force an error (e.g. break a script) | Red-bordered box with failures section + "Next steps" |
| 7 | ANSI fallback | Hide gum: `PATH=/usr/bin:/bin chezmoi apply` | Clean plain-text output, no broken escape codes, no `gum: command not found` |
| 8 | Log file | After any apply | `~/.cache/dotfiles-apply.log` has timestamped OK/WARN/FAIL entries |
| 9 | Log reset | Run apply twice | Log only contains entries from the latest run |
| 10 | 1Password pre-check | Set `use_1password=true`, uninstall `op` | Yellow warning with `Fix: brew install 1password-cli` |
| 11 | Lib sourcing | Check after-scripts all load lib | No `dotfiles lib not found` errors |
| 12 | Brewfile cleanup | `chezmoi apply` | No errors for `monitor-control` or `zen-browser` |

### CI verification (`.github/workflows/test.yml`)

The existing CI already runs `chezmoi apply --dry-run` and `chezmoi apply --exclude=scripts` with a test config that has all variables set. Changes needed:

| # | CI change | Why |
|---|-----------|-----|
| 1 | Add `shellcheck` for `lib.sh` | New bash file needs linting |
| 2 | Add `shellcheck` for `run_after_zz-summary.sh` | New non-template script |
| 3 | Template guard regression test | Run `chezmoi execute-template` with a deliberately missing variable, verify the error message contains "Fix: chezmoi init" |
| 4 | Verify lib.sh deployed | After `chezmoi apply --exclude=scripts`, check `~/.config/dotfiles/lib.sh` exists |

```yaml
# Addition to test-macos job:
- name: Verify lib.sh deployed
  run: |
    [ -f ~/.config/dotfiles/lib.sh ] || { echo "FAIL: lib.sh not deployed"; exit 1; }
    echo "OK: lib.sh"

- name: Test template guard message
  run: |
    # Create config missing 'headless'
    cat > /tmp/test-chezmoi.toml <<'EOF'
    [data]
      name = "Test"
      email = "test@test.com"
      editor = "vim"
      use_1password = false
      op_account = ""
      op_vault = ""
    EOF
    if chezmoi execute-template --config /tmp/test-chezmoi.toml \
      '{{ if not (hasKey . "headless") }}GUARD_TRIGGERED{{ end }}' 2>&1 | grep -q "GUARD_TRIGGERED"; then
      echo "OK: template guard catches missing variable"
    else
      echo "FAIL: template guard did not trigger"
      exit 1
    fi
```

```yaml
# Addition to shellcheck job:
- name: Lint lib.sh
  run: shellcheck home/dot_config/dotfiles/lib.sh

- name: Lint summary script
  run: shellcheck home/.chezmoiscripts/run_after_zz-summary.sh
```

## Documentation updates

| File | Change |
|------|--------|
| `CLAUDE.md` | Add section on error message system: lib.sh location, how scripts source it, template guard pattern, log file path |
| `CLAUDE.md` | Update "Script execution order" to include `aa-init`, `ab-1password-check`, and `zz-summary` |
| `CLAUDE.md` | Add `.headless` to template variables list (currently missing) |
| `README.md` | No changes needed — error system is internal, not user-facing setup docs |
| `docs/tasks.md` | Add `R-11: Error message system` to completed list after implementation |
| `.github/workflows/test.yml` | Add shellcheck for new files + template guard regression test (see CI section above) |

### CLAUDE.md additions

Add under "Important conventions":

```markdown
- **Error message library** (`~/.config/dotfiles/lib.sh`) is sourced by all `run_*_after_*` scripts.
  Uses `gum log`/`gum style` for styled output with ANSI fallback. Functions: `info`, `warn "what" "why" "fix"`,
  `err`, `die`, `require_cmd`, `section`, `script_ok`. All warnings/errors log to `~/.cache/dotfiles-apply.log`.
- **Template guards** — every `.tmpl` file validates required variables with `hasKey`/`fail` at the top.
  Missing variables produce `Fix: chezmoi init` instead of cryptic Go template errors.
- **Apply summary** — `run_after_zz-summary.sh` prints a gum-styled status box at the end of every apply.
```

Update "Script execution order":

```markdown
1. `run_onchange_before_aa-init.sh` — resets apply log file
2. `run_onchange_before_ab-1password-check.sh` — validates 1Password setup (if enabled)
3. `run_onchange_before_brew-bundle.sh` — triggers when `dot_Brewfile` content changes
4. Files are deployed (including `~/.config/dotfiles/lib.sh`)
5. `run_once_after_*` — one-time setup (fish shell, macOS defaults, mas apps, toolchains)
6. `run_onchange_after_*` — triggers when VS Code/Zed config changes
7. `run_after_zz-summary.sh` — prints apply summary with warnings/errors/next steps
```

## Implementation order

1. Create `lib.sh` (foundation — everything depends on this)
2. Add template guards to all 6 `.tmpl` files (independent, can be done in parallel)
3. Create lifecycle scripts: `aa-init`, `ab-1password-check`, `zz-summary`
4. Update existing scripts to source lib and use structured messages
5. Brewfile cleanup (monitor-control, zen-browser)
6. Update CI workflow
7. Update CLAUDE.md
8. Update docs/tasks.md
