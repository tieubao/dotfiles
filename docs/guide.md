# User guide

Everything you need to use and customize this dotfiles setup. The
[README](../README.md) covers quick start and what's included; this guide
covers how it all works and how to make it yours.

---

## 1. How this works

### The two layers

chezmoi keeps two copies of every config file:

| Layer | Location | Contains |
|-------|----------|----------|
| **Source** (repo) | `~/.local/share/chezmoi/home/` | Templates, `op://` refs, chezmoi prefixes |
| **Target** (machine) | `$HOME` | Rendered files with real values |

You edit the source. chezmoi renders templates and copies the result to
your home directory. This is a one-way flow: source to target.

<p align="center">
  <img src="dotfiles_chezmoi_model.svg" alt="chezmoi model: source to target" width="680">
</p>

**Why two layers?** The source can live in a public git repo because it
never contains real secrets — only `op://` references. The target has
your actual API keys, but it's never committed.

Here's the full bootstrap flow when you first install:

<p align="center">
  <img src="dotfiles_bootstrap_flow.svg" alt="Bootstrap flow" width="680">
</p>

### Where things live

```
~/dotfiles/                          ← the repo (git clone location)
├── home/                            ← chezmoi source state
│   ├── dot_gitconfig.tmpl           ← becomes ~/.gitconfig
│   ├── dot_config/
│   │   ├── fish/
│   │   │   ├── config.fish.tmpl     ← shell config
│   │   │   ├── functions/           ← one file per function
│   │   │   ├── completions/         ← tab completions
│   │   │   └── conf.d/              ← auto-sourced snippets
│   │   ├── ghostty/config           ← terminal config
│   │   ├── starship.toml            ← prompt config
│   │   ├── tmux/tmux.conf           ← multiplexer config
│   │   ├── code/                    ← VS Code settings
│   │   └── zed/                     ← Zed settings
│   ├── dot_Brewfile.tmpl            ← Homebrew packages
│   ├── .chezmoidata/secrets.toml    ← secret registry (op:// refs)
│   └── .chezmoiscripts/             ← automation scripts
├── docs/                            ← this guide, specs, ADRs
└── install.sh                       ← bootstrap script
```

Naming: `dot_` becomes `.`, `.tmpl` means "render this template",
`private_` sets mode 0600.

---

## 2. Your first 30 minutes

You just ran `install.sh`. Here's what's on your machine now.

### Shell: Fish

Your default shell is now [Fish](https://fishshell.com/). It differs
from bash/zsh in a few ways:

- **Autosuggestions** — type a few characters, Fish suggests from history
  in gray. Press `→` to accept.
- **Tab completion** — press `Tab` for rich completions with descriptions.
- **No `.bashrc`** — config lives at `~/.config/fish/config.fish`.
- **Abbreviations, not aliases** — type `gs` then space, it expands to
  `git status`. Your abbreviations:

| Category | Abbreviations |
|----------|--------------|
| Git | `g` `gs` `gd` `gl` `gp` `gc` `gco` `gpr` |
| Navigation | `ls` `l` `ll` `la` `lt` `..` `...` |
| Modern replacements | `cat`→bat `top`→btop `du`→dust `df`→duf `ps`→procs |
| Tmux | `tx` `tml` `tma` `tmk` |
| Kubernetes/Docker | `k` `k9` `d` `dc` |

Fish plugins (installed without a plugin manager, via direct download):

| Plugin | What it does |
|--------|-------------|
| **autopair** | Auto-closes brackets, quotes, parentheses |
| **done** | Desktop notification when a long command finishes |
| **sponge** | Removes failed commands from history |
| **async-prompt** | Keeps the prompt responsive while git info loads |

### Terminal: Ghostty

[Ghostty](https://ghostty.org/) is your terminal. Key settings:

- **Font**: SauceCodePro Nerd Font, size 12
- **Theme**: base16-eighties-dark (switch with `ghostty-theme N`)
- **Quick toggle**: `Cmd+`` brings up the terminal from anywhere
- **Splits**: `Cmd+Shift+Enter` (right), `Cmd+Shift+-` (down)
- **Navigate splits**: `Cmd+Alt+Arrows`

### Prompt: Starship

[Starship](https://starship.rs/) shows: directory, git branch/status,
language versions (Go, Python, Node, Rust), cloud context (AWS, k8s),
and command duration (if >3s). Green arrow = last command OK, red = error.

### Editors

Your editor was set during install (`chezmoi init`). VS Code and Zed
both have managed settings and extensions. MCP servers in Zed are
pre-configured with 1Password-injected API keys.

### Verify everything works

```fish
dotfiles doctor
```

This checks: chezmoi installed, fish is default shell, Homebrew, 1Password,
key config files exist, git identity set, CLI tools present, no drift.

---

## 3. Daily workflows

### Primary workflow: Claude-assisted sync

The easiest way to keep your dotfiles in sync is to ask Claude. Run
`/dotfiles-sync` in Claude Code (or just say "catch up with my dotfiles").
Claude scans your machine for drift across brew packages, casks, config
files, VS Code extensions, fish functions, and secrets. It reports what
changed in plain language and waits for your instructions before syncing.

This is the recommended workflow for batch changes. The manual commands
below are for quick edits or when you're not in a Claude session.

### Editing any config

Use `dotfiles edit` (dotfile edit) for all config changes. It edits the source,
applies, and auto-commits in one step:

```fish
dotfiles edit ~/.config/fish/config.fish
```

<p align="center">
  <img src="dotfiles_dfe_workflow.svg" alt="dfe workflow" width="680">
</p>

Pass `--no-commit` to skip the auto-commit.

### Adding a Homebrew package

Don't run `brew install` directly — that installs locally but doesn't
update the Brewfile, so your next machine won't have it.

```fish
dotfiles edit ~/.Brewfile    # add the line, save, brew bundle runs automatically
```

<p align="center">
  <img src="dotfiles_workflow_brew.svg" alt="Homebrew workflow" width="680">
</p>

### Handling drift

If you (or an app) edited a deployed file directly, `dotfiles drift` detects and
fixes it:

```fish
dotfiles drift    # shows drifted files, prompts, re-absorbs into source, commits
```

<p align="center">
  <img src="dotfiles_dfs_workflow.svg" alt="dfs workflow" width="680">
</p>

### Changing a config: two paths

<p align="center">
  <img src="dotfiles_workflow_config.svg" alt="Config change: dfe vs direct edit" width="680">
</p>

### The `dotfiles` CLI

For everything beyond editing, use the `dotfiles` wrapper:

| Command | Alias | Abbr | What it does |
|---------|-------|------|-------------|
| `dotfiles edit <path>` | `e` | `de` | Edit + apply + auto-commit |
| `dotfiles drift` | | `dd` | Detect and re-absorb drifted files |
| `dotfiles secret <cmd>` | | | Manage 1Password secrets (add/rm/list) |
| `dotfiles diff` | `d` | | Show pending changes |
| `dotfiles sync` | `s` | `ds` | Apply all changes |
| `dotfiles update` | `u` | `du` | Pull latest + apply |
| `dotfiles status` | `st` | | Managed file count + pending diffs |
| `dotfiles cd` | | | Go to chezmoi source directory |
| `dotfiles refresh` | `r` | | Re-download fish plugins |
| `dotfiles add <path>` | `a` | | Add a new file to chezmoi |
| `dotfiles doctor` | | | Health check |
| `dotfiles bench` | | | Benchmark shell startup time |
| `dotfiles backup` | | | Back up config + age key to 1Password |
| `dotfiles encrypt-setup` | | | Set up age encryption |

All subcommands have tab completions. Abbreviations expand on space (e.g. type `de` then space, it becomes `dotfiles edit`).

---

## 4. Customization cookbook

### Quick-change table

| Change | File to edit | Command |
|--------|-------------|---------|
| Homebrew packages | `dot_Brewfile.tmpl` | `dotfiles edit ~/.Brewfile` |
| Fish abbreviations/env | `config.fish.tmpl` | `dotfiles edit ~/.config/fish/config.fish` |
| Fish function | `functions/NAME.fish` | `dotfiles edit ~/.config/fish/functions/NAME.fish` |
| Starship prompt | `starship.toml` | `dotfiles edit ~/.config/starship.toml` |
| Ghostty terminal | `ghostty/config` | `dotfiles edit ~/.config/ghostty/config` |
| Ghostty theme | any time | `ghostty-theme N` |
| tmux | `tmux/tmux.conf` | `dotfiles edit ~/.config/tmux/tmux.conf` |
| VS Code settings | `code/settings.json` | `dotfiles edit ~/.config/code/settings.json` |
| VS Code extensions | `code/extensions.txt` | edit + `chezmoi apply` |
| Zed settings + MCP | `zed/settings.json.tmpl` | `dotfiles edit ~/.config/zed/settings.json` |
| Git config | `dot_gitconfig.tmpl` | `dotfiles edit ~/.gitconfig` |
| SSH hosts | `dot_ssh/config.d/*` | drop file + `chezmoi apply` |
| macOS defaults | `run_once_after_macos-defaults.sh.tmpl` | edit + `chezmoi apply` |
| Fish plugins | `.chezmoiexternal.toml` | edit + `chezmoi apply --refresh-externals` |
| Setup answers | `~/.config/chezmoi/chezmoi.toml` | `chezmoi init` |
| 1Password secrets | `.chezmoidata/secrets.toml` | `dotfiles secret add VAR op://...` |

### Walkthrough: add a new fish function

**Goal:** create a `weather` function that shows the forecast.
**File:** `home/dot_config/fish/functions/weather.fish` (new file)

```fish
dotfiles edit ~/.config/fish/functions/weather.fish
```

In the editor, write:
```fish
function weather --description "Show weather forecast"
    curl -s "wttr.in/?format=3"
end
```

Save and close. `dotfiles edit` applies (function is immediately available) and
auto-commits. Test it:

```fish
weather
```

**Expected result:** prints something like `Da Nang: ☀️ +31°C`.
The function is available in every new shell. The change is committed.

### Walkthrough: change your Starship prompt

**Goal:** shorten the directory display from 3 levels to 2.
**File:** `home/dot_config/starship.toml`

```fish
dotfiles edit ~/.config/starship.toml
```

Edit the `[directory]` section:
```toml
[directory]
truncation_length = 2
```

Save and close.

**Expected result:** your prompt immediately shows shorter paths
(e.g. `~/w/dotfiles` instead of `~/workspace/tieubao/dotfiles`).
The change is auto-committed.

### Walkthrough: add a VS Code extension

**Goal:** install the GitHub Copilot extension and persist it.
**File:** `home/dot_config/code/extensions.txt`

```fish
dotfiles edit ~/.config/code/extensions.txt
```

Add one extension ID per line (e.g. `github.copilot`). Save. Then:

```fish
chezmoi apply   # triggers the VS Code extension sync script
```

**Expected result:** VS Code installs the extension. The extensions
list is committed, so your next machine gets it too.

### Walkthrough: switch Ghostty theme

**Goal:** preview and switch terminal themes.
No file editing needed — use the built-in helper:

```fish
ghostty-theme        # lists available themes with numbers
ghostty-theme 5      # switch to theme #5
```

**Expected result:** the terminal theme changes immediately (live
reload, no restart). The config file is updated in place.

### Walkthrough: add an SSH host

**Goal:** add a `staging` SSH host for quick access.
**File:** `home/dot_ssh/config.d/work-servers`

```fish
dotfiles edit ~/.ssh/config.d/work-servers
```

Write:
```
Host staging
    HostName 10.0.1.50
    User deploy
    IdentityFile ~/.ssh/id_ed25519
```

Save and close.

**Expected result:** `ssh staging` connects to 10.0.1.50. The main
`~/.ssh/config` includes everything in `config.d/` via `Include config.d/*`.
The change is auto-committed.

---

## 5. Secrets management

### The three tiers

| Tier | When to use | Command |
|------|------------|---------|
| **Auto-loaded** | Env var in every shell session | `dotfiles secret add VAR "op://..."` |
| **Runtime** | Occasional CLI use, don't pollute every env | `op-env VAR "op://..."` |
| **One-off** | Quick inline use | `set -x VAR (op read "op://...")` |

### Adding a new secret

```fish
dotfiles secret add OPENAI_API_KEY "op://Private/OpenAI/credential"
```

<p align="center">
  <img src="dotfiles_workflow_secrets.svg" alt="Secrets workflow" width="680">
</p>

This command:
1. Creates the 1Password item if it doesn't exist (prompts for the value)
2. Registers the `op://` binding in `secrets.toml`
3. Runs `chezmoi apply` to render `secrets.fish` with the real value
4. Auto-commits the change (only the `op://` ref, never the value)

Open a new shell (or `exec fish`) to pick up the variable.

### Rotating a token

Update the value in 1Password (app or CLI). Then:

```fish
chezmoi apply ~/.config/fish/conf.d/secrets.fish
exec fish
```

No repo change needed — the `op://` reference hasn't changed.

### Removing a secret

```fish
dotfiles secret rm OPENAI_API_KEY    # unregisters from secrets.toml, auto-commits
```

### Listing current secrets

```fish
dotfiles secret list    # shows all registered VAR → op:// bindings
```

### How it works under the hood

<p align="center">
  <img src="dotfiles_secrets_flow.svg" alt="Secrets flow: template to machine" width="680">
</p>

`secrets.toml` is a chezmoi data file loaded as `.secrets` in templates.
`secrets.fish.tmpl` iterates the registry and emits one `set -gx` per
entry, resolving each `op://` ref via `onepasswordRead`. The rendered
file at `~/.config/fish/conf.d/secrets.fish` contains real tokens but
never leaves your machine.

---

## 6. Multi-machine setup

### Deploying to a second Mac

On the new machine:

```bash
git clone https://github.com/dwarvesf/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The setup wizard prompts for the same config (name, email, editor,
1Password). If you use 1Password, sign in first (`eval $(op signin)`),
and all secrets are pulled automatically.

### Headless/server mode

During `chezmoi init`, answer `headless = true`. This skips:
- GUI apps (Ghostty, VS Code, Zed)
- Mac App Store apps
- Dev casks (Docker, Figma, etc.)
- macOS defaults

You get: Fish shell, CLI tools, git config, SSH config, tmux.

### Keeping machines in sync

On any machine:

```fish
dotfiles update    # git pull + chezmoi apply
```

Or manually:

```fish
cd ~/dotfiles && git pull
chezmoi apply
```

### Machine-specific overrides

chezmoi templates handle per-machine differences. The `.chezmoi` variable
provides hostname, OS, and arch. Example in a `.tmpl` file:

```
{{ if eq .chezmoi.hostname "work-mbp" }}
# work-specific config here
{{ end }}
```

The `headless` flag is the most common override — it gates entire
sections of the Brewfile and script execution.

---

## 7. Troubleshooting

Start with `dotfiles doctor` — it catches most issues.

### "I edited the wrong file"

You edited `~/.config/fish/config.fish` directly instead of the source.
Your change works now but will be lost on the next `chezmoi apply`.

**Fix:** run `dotfiles drift` to detect the drift and re-absorb it into the source.

### "chezmoi apply wants to overwrite my change"

Same root cause: the deployed file differs from the source. Options:

1. `dotfiles drift` — pull the deployed version back into source
2. `chezmoi merge <path>` — three-way merge
3. `chezmoi apply --force` — overwrite deployed with source (destructive)

### "1Password errors"

- **"not signed in"**: run `eval (op signin)` or `eval $(op signin)` in bash
- **"item not found"**: check vault name and item title match the `op://` path
- **"connect timeout"**: 1Password CLI needs internet for the first auth

### "Template rendering failed"

A `.tmpl` file is missing a variable. Usually means `chezmoi init` needs
to be re-run:

```fish
chezmoi init
chezmoi apply
```

### "Brewfile didn't re-run"

The brew script only fires when the Brewfile content changes (chezmoi
tracks a hash). Force it:

```fish
brew bundle --file=~/.Brewfile
```

### "Fish function not found"

The function file must be named exactly `FUNCTIONNAME.fish` in
`~/.config/fish/functions/`. Check:

```fish
functions --names | grep yourfunction
ls ~/.config/fish/functions/yourfunction.fish
```

### "Shell startup is slow"

Benchmark it:

```fish
dotfiles bench
```

Common causes: 1Password CLI calls on every shell (move to auto-loaded
secrets), too many PATH additions, slow network for async prompt.

### Nuclear options

If something is deeply broken:

```fish
# Re-run setup wizard (re-prompts for all config)
chezmoi init

# Force apply everything (overwrites all deployed files)
chezmoi apply --force

# Full reinstall (teardown + rebuild)
cd ~/dotfiles && ./install.sh --force
```

---

## 8. Architecture reference

<p align="center">
  <img src="dotfiles_architecture.svg" alt="Architecture overview" width="680">
</p>

### Script execution order

During `chezmoi apply`, scripts run in this order:

1. `run_before_aa-init.sh` — resets the apply log
2. `run_before_ab-1password-check.sh` — validates 1Password CLI
3. `run_onchange_before_brew-bundle.sh` — `brew bundle` (triggers on Brewfile change)
4. **File deployment** — templates rendered, files copied
5. `run_once_after_*` — one-time setup (Fish shell, macOS defaults, MAS apps, toolchains)
6. `run_onchange_after_*` — VS Code extensions, Zed config (triggers on content change)
7. `run_after_zz-summary.sh` — styled apply summary with OK/warning/error counts

`run_once_` scripts won't re-run unless their content changes.
`run_onchange_` scripts re-run when the template output changes.

### How templates work

Any file ending in `.tmpl` is rendered through Go's `text/template`
engine at apply time. chezmoi provides variables from:

- `chezmoi init` answers (`.name`, `.email`, `.editor`, `.headless`, `.use_1password`)
- `.chezmoidata/*.toml` files (`.secrets` from `secrets.toml`)
- Built-in `.chezmoi.*` (hostname, OS, arch, username)

Every `.tmpl` file validates required variables at the top with
`hasKey`/`fail` guards. Missing variables produce actionable error
messages instead of cryptic Go template errors.

### External downloads

Fish plugins and completions are defined in `.chezmoiexternal.toml` as
GitHub URLs. chezmoi downloads and caches them with a 30-day refresh.
Force re-download with `dotfiles refresh` or `chezmoi apply --refresh-externals`.

### Design decisions

Architectural choices are documented as ADRs in `docs/decisions/`:

- [001: chezmoi over GNU Stow](decisions/001-chezmoi-over-stow.md)
- [002: Fish over Zsh](decisions/002-fish-over-zsh.md)
- [003: Ghostty over Kitty](decisions/003-ghostty-over-kitty.md)
- [004: 1Password for secrets](decisions/004-1password-for-secrets.md)
- [005: No plugin manager for Fish](decisions/005-no-plugin-manager-for-fish.md)
- [006: Auto-commit workflow](decisions/006-auto-commit-workflow.md)

---

## Appendix: cheat sheet

### Commands at a glance

| I want to... | Command | Abbreviation |
|--------------|---------|-------------|
| **Batch sync everything** | **`/dotfiles-sync` (in Claude Code)** | |
| Edit any config | `dotfiles edit <path>` | `de` |
| Detect and fix drift | `dotfiles drift` | `dd` |
| Apply all changes | `dotfiles sync` | `ds` |
| Pull latest + apply | `dotfiles update` | `du` |
| See what would change | `dotfiles diff` | |
| Check health | `dotfiles doctor` | |
| Add a Homebrew package | `dotfiles edit ~/.Brewfile` | |
| Add a secret | `dotfiles secret add VAR "op://..."` | |
| List secrets | `dotfiles secret list` | |
| Remove a secret | `dotfiles secret rm VAR` | |
| Rotate a secret | Update in 1Password, then `chezmoi apply` | |
| Add a fish function | `dotfiles edit ~/.config/fish/functions/NAME.fish` | |
| Switch Ghostty theme | `ghostty-theme N` | |
| Benchmark startup | `dotfiles bench` | |
| Backup config | `dotfiles backup` | |
| Re-run setup wizard | `chezmoi init` | |

### Key file locations

| What | Source (repo) | Target (machine) |
|------|--------------|-------------------|
| Fish config | `home/dot_config/fish/config.fish.tmpl` | `~/.config/fish/config.fish` |
| Fish functions | `home/dot_config/fish/functions/` | `~/.config/fish/functions/` |
| Ghostty | `home/dot_config/ghostty/config` | `~/.config/ghostty/config` |
| Starship | `home/dot_config/starship.toml` | `~/.config/starship.toml` |
| tmux | `home/dot_config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| Git | `home/dot_gitconfig.tmpl` | `~/.gitconfig` |
| Brewfile | `home/dot_Brewfile.tmpl` | `~/.Brewfile` |
| Secrets registry | `home/.chezmoidata/secrets.toml` | (data file, not deployed) |
| Rendered secrets | `home/dot_config/fish/conf.d/secrets.fish.tmpl` | `~/.config/fish/conf.d/secrets.fish` |
