# dotfiles

![macOS](https://img.shields.io/badge/macOS-Apple%20Silicon-000?logo=apple&logoColor=white)
![Fish](https://img.shields.io/badge/Fish-Shell-4AAE46?logo=gnubash&logoColor=white)
![Starship](https://img.shields.io/badge/Starship-Prompt-DD0B78?logo=starship&logoColor=white)
![Ghostty](https://img.shields.io/badge/Ghostty-Terminal-1a1a2e)
![chezmoi](https://img.shields.io/badge/chezmoi-Managed-blue)
![1Password](https://img.shields.io/badge/1Password-Secrets-0572EC?logo=1password&logoColor=white)
![CI](https://img.shields.io/github/actions/workflow/status/dwarvesf/dotfiles/test.yml?label=CI&logo=github)

A modern developer tooling stack for macOS, deployed in one command. Every tool is chosen for speed, ergonomics, and native macOS integration; no legacy defaults, no bloat.

**The stack:** [Fish](https://fishshell.com/) replaces Zsh (faster startup, better defaults). [Starship](https://starship.rs/) replaces Oh My Zsh themes (cross-shell, instant). [Ghostty](https://ghostty.org/) replaces iTerm2 (GPU-rendered, native). [delta](https://github.com/dandavison/delta) replaces diff (syntax-highlighted). [eza](https://eza.rocks/), [bat](https://github.com/sharkdp/bat), [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep), [zoxide](https://github.com/ajeetdsouza/zoxide), [fzf](https://github.com/junegunn/fzf) replace ls, cat, find, grep, cd, Ctrl+R. [1Password](https://1password.com/) handles secrets via `op://` templates; nothing is ever stored in git. All managed by [chezmoi](https://www.chezmoi.io/) with a [gum](https://github.com/charmbracelet/gum)-powered setup wizard.

<!-- TODO: Add terminal screenshot at docs/assets/terminal.png -->
<!-- ![Terminal](docs/assets/terminal.png) -->

**Requirements:** macOS 12+, Apple Silicon (Intel works too). First run takes ~30 minutes (Homebrew downloads).

## Quick start

```bash
git clone https://github.com/dwarvesf/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

A styled setup wizard ([gum](https://github.com/charmbracelet/gum)) will prompt for your name, email, editor, headless mode, and whether you use 1Password. Everything adapts accordingly. On a headless/server machine, GUI apps, dev toolchains, and casks are skipped automatically.

**Flags:**
- `./install.sh --check` -- dry-run, validates without applying
- `./install.sh --force` -- teardown and reinit from scratch
- `./install.sh --config-only` -- deploy config files only, skip brew/mas/defaults

<details>
<summary><b>Adopt on an existing Mac</b></summary>

Already have brew, fish, and your tools installed? Use `--config-only` to deploy just the config files without re-running brew bundle, mas installs, or macOS defaults:

```bash
git clone https://github.com/dwarvesf/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh --config-only
```

This will:
1. Link chezmoi source to `~/dotfiles/home`
2. Prompt for your name, email, editor, headless mode, 1Password
3. Deploy all config files to `$HOME`
4. **Skip** brew bundle, Mac App Store apps, macOS defaults, toolchain installs

Then switch your shell and reload:
```bash
# Set fish as default (if not already)
grep -q /opt/homebrew/bin/fish /etc/shells || echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

# Open a new terminal to pick up the configs
```

</details>

<details>
<summary><b>Alternative: bootstrap without git</b></summary>

On a truly fresh Mac, git requires Xcode CLT (10+ minutes to install). These methods skip that:

**Via chezmoi directly (no git, no Homebrew):**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply dwarvesf
```

**Via Homebrew + chezmoi (no git):**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
chezmoi init --apply dwarvesf
```

> **Note:** These methods clone into `~/.local/share/chezmoi/` (chezmoi's default) instead of `~/dotfiles`. The git clone method is better for active development since you control the repo location.

</details>

<details>
<summary><b>Fork and customize</b></summary>

```bash
# 1. Fork this repo on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles

# 3. Edit what you want (see "Customization" below)
# 4. Run
./install.sh
```

</details>

## What happens on install

<p align="center">
  <img src="docs/dotfiles_bootstrap_flow.svg" alt="Bootstrap flow" width="680">
</p>

1. Installs Homebrew (if missing)
2. Installs chezmoi
3. Runs setup wizard (styled prompts for name, email, editor, headless mode, 1Password)
4. Deploys all config files to `$HOME`
5. Runs automation scripts:
   - `brew bundle` -- installs ~80 packages + casks
   - Mac App Store apps via `mas`
   - macOS defaults (Dock, Finder, keyboard, trackpad, screenshots)
   - Sets Fish as default shell
   - Installs Foundry (cast), Rust, npm/uv tools
   - VS Code extensions
6. Verifies key files were deployed

## What's included

| Layer | Tools |
|-------|-------|
| **Shell** | Fish + Starship prompt + plugins (autopair, done, sponge, async-prompt) |
| **Terminal** | Ghostty (catppuccin-mocha, JetBrains Mono) |
| **Multiplexer** | tmux (C-a prefix, vim nav, fzf session picker, project launcher) |
| **Editors** | VS Code + Zed (settings, extensions, MCP servers) |
| **Git** | .gitconfig (delta diffs, aliases) + .gitignore + commit template |
| **SSH** | 1Password SSH Agent (optional), modular config.d/ |
| **Secrets** | 1Password (`op://`) + data-driven registry (`secrets.toml`) -- never in git |
| **Packages** | Layered Brewfile (base/dev/apps) + Mac App Store (`mas`) |
| **Languages** | mise (Node, Python, Go, Ruby) via `.tool-versions` |
| **Containers** | OrbStack / Docker config |
| **macOS** | 30+ `defaults write` (Dock left, fast key repeat, Finder, screenshots) |
| **Web3/DeFi** | Foundry (`cast`), fish aliases + helper functions |
| **Claude Code** | Settings, hooks, statusline, verify-dotfiles subagent, `/implement-feature` command |

## Why this setup

- **Layered Brewfile** -- base tools always install; dev toolchains and GUI apps are conditional. Set `headless=true` for servers.
- **Zero plaintext secrets** -- 1Password `op://` references in templates, macOS Keychain for the rest. The rendered secrets only exist on your machine, never in git.
- **Claude-assisted sync** -- run `/dotfiles-sync` in Claude Code to detect all drift (brew, casks, configs, extensions, secrets), review in plain language, and sync with one approval. Manual commands (`dotfiles edit`, `dotfiles drift`) work offline.
- **15-command CLI** -- `dotfiles edit`, `dotfiles drift`, `dotfiles secret`, `dotfiles sync`, `dotfiles doctor`, `dotfiles bench`... no need to remember raw chezmoi commands ([ADR-006](docs/decisions/006-auto-commit-workflow.md)).
- **CI-tested weekly** -- shellcheck + chezmoi dry-run on macOS. Catches regressions before your next fresh install.
- **Graceful degradation** -- works with or without 1Password. Skip web3, skip Mac App Store, pick your editor. Everything is opt-in.

## Daily usage

**Core principle:** every setting change should be both applied to your machine and committed to the repo in one step. The helpers below enforce this by default.

<p align="center">
  <img src="docs/dotfiles_chezmoi_model.svg" alt="chezmoi model: source to target" width="680">
</p>

### Editing configs

```fish
dotfiles edit ~/.config/fish/config.fish   # edit source → apply → auto-commit
dotfiles edit ~/.Brewfile                  # edit Brewfile → apply (runs brew bundle) → commit
dotfiles edit ~/.config/ghostty/config     # edit → apply (live reload) → commit
```

`dotfiles edit` opens the chezmoi source file in your editor, applies on save, and commits the change. Pass `--no-commit` to skip the commit.

<p align="center">
  <img src="docs/dotfiles_dfe_workflow.svg" alt="dfe workflow: edit, apply, commit" width="680">
</p>

### Syncing drift

If you edited a deployed file directly (or an app rewrote its config), `dotfiles drift` detects the drift and pulls it back into the source:

```fish
dotfiles drift                              # detect drift → prompt → re-add → commit
dotfiles drift --no-commit                  # re-absorb without committing
```

<p align="center">
  <img src="docs/dotfiles_dfs_workflow.svg" alt="dotfiles drift workflow: detect drift and sync" width="680">
</p>

### The `dotfiles` wrapper

For everything else, the `dotfiles` CLI provides ergonomic subcommands:

```fish
dotfiles diff                              # preview changes
dotfiles sync                              # apply everything
dotfiles update                            # pull latest + apply
dotfiles status                            # managed file count + pending diffs
dotfiles doctor                            # health check (tools, config, drift)
dotfiles bench                             # benchmark shell startup time
dotfiles backup                            # back up config + age key to 1Password
dotfiles encrypt-setup                     # guided age encryption setup
```

<details>
<summary>Raw chezmoi commands</summary>

```bash
chezmoi edit ~/.config/fish/config.fish
chezmoi diff
chezmoi apply
chezmoi apply --refresh-externals
```

</details>

## Customization

Use `dotfiles edit` to edit any config (edit → apply → commit in one step):

```fish
dotfiles edit ~/.Brewfile                  # add Homebrew packages
dotfiles edit ~/.config/fish/config.fish   # shell config
dotfiles edit ~/.config/ghostty/config     # terminal settings
```

Add secrets via 1Password:

```fish
dotfiles secret add OPENAI_API_KEY "op://Private/OpenAI/credential"
```

The full user guide covers walkthroughs, the secrets workflow, multi-machine
setup, troubleshooting, and architecture: **[docs/guide.md](docs/guide.md)**.

<details>
<summary><b>Encrypted files (age)</b></summary>

For files too complex for template injection (kubeconfig, VPN configs, certificates):

```fish
# Guided setup (generates key, prints next steps)
dotfiles encrypt-setup

# Then add encrypted files
chezmoi add --encrypt ~/.kube/config
# Creates home/encrypted_dot_kube/config.age in the repo
```

Manual setup if you prefer:
```bash
brew install age
age-keygen -o ~/.config/chezmoi/key.txt
# Copy the public key (age1...) from output
chezmoi edit-config   # uncomment age section, paste public key
# Backup key.txt to 1Password as a Secure Note
```

</details>

<details>
<summary><b>Removing what you don't need</b></summary>

- **No web3?** Delete web3 aliases from `config.fish.tmpl`, remove `cast_*` functions, remove Foundry from install script
- **No 1Password?** Answer "no" during `chezmoi init` -- all 1Password sections are skipped
- **No Mac App Store?** Delete `run_once_after_mas-apps.sh.tmpl`
- **Different editor?** `chezmoi init` prompts for your choice (VS Code, Zed, Neovim, Vim)

</details>

## Troubleshooting

Run `dotfiles doctor` to diagnose issues:

```
$ dotfiles doctor
Dotfiles health check
=====================

[ok] chezmoi installed
[ok] chezmoi source linked
[ok] fish is default shell
[ok] homebrew installed
[ok] 1Password CLI: signed in
[ok] 1Password SSH agent: socket exists
[ok] ~/.gitconfig exists
[ok] ~/.config/fish/config.fish exists
[ok] ~/.ssh/config exists
[ok] git identity: Your Name <you@email.com>
[ok] fzf
[ok] bat
...
[ok] no drift detected

All checks passed.
```

<details>
<summary><b>How secrets flow</b></summary>

<p align="center">
  <img src="docs/dotfiles_secrets_flow.svg" alt="Secrets flow" width="680">
</p>

On a new Mac: clone -> `./install.sh` -> `op signin` -> `chezmoi apply` -> done.

</details>

<details>
<summary><b>Architecture</b></summary>

<p align="center">
  <img src="docs/dotfiles_architecture.svg" alt="Architecture" width="680">
</p>

</details>

## Credits

Built with [chezmoi](https://www.chezmoi.io/). Inspired by [halostatue/dotfiles](https://github.com/halostatue/dotfiles) and [narze/dotfiles](https://github.com/narze/dotfiles).

## License

MIT
