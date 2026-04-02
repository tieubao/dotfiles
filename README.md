# dotfiles

[chezmoi](https://www.chezmoi.io/)-managed dotfiles for macOS. One command to set up a new Mac — shell, terminal, editors, packages, secrets, system preferences, everything.

Fork this repo and make it yours.

## Quick start

**Use as-is:**
```bash
git clone https://github.com/tieubao/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

**Fork and customize:**
```bash
# 1. Fork this repo on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles

# 3. Edit what you want (see "Customization" below)
# 4. Run
./install.sh
```

`chezmoi init` will prompt for your name, email, editor, and whether you use 1Password. Everything adapts accordingly.

## What happens on install

1. Installs Homebrew (if missing)
2. Installs chezmoi
3. Prompts for your info (name, email, editor, 1Password vault)
4. Deploys all config files to `$HOME`
5. Runs automation scripts:
   - `brew bundle` — installs ~80 packages + casks
   - Mac App Store apps via `mas`
   - macOS defaults (Dock, Finder, keyboard, trackpad, screenshots)
   - Sets Fish as default shell
   - Installs Foundry (cast), Rust, npm/uv tools
   - VS Code extensions

## What's included

| Layer | Tools |
|-------|-------|
| **Shell** | Fish + plugins (autopair, done, sponge, async-prompt) |
| **Terminal** | Ghostty (catppuccin-mocha, JetBrains Mono) |
| **Multiplexer** | tmux (C-a prefix, fzf session picker, project launcher) |
| **Editors** | VS Code + Zed (settings, extensions, MCP servers) |
| **Git** | .gitconfig (delta diffs, aliases) + .gitignore + commit template |
| **SSH** | 1Password SSH Agent (optional) |
| **Secrets** | 1Password (`op://`) + macOS Keychain — never in git |
| **Packages** | Homebrew Brewfile + Mac App Store (`mas`) |
| **Languages** | mise (Node, Python, Go, Ruby) via `.tool-versions` |
| **Containers** | OrbStack / Docker config |
| **macOS** | 30+ `defaults write` (Dock left, fast key repeat, Finder, screenshots) |
| **Web3/DeFi** | Foundry (`cast`), fish aliases + helper functions |

## Customization

### Files you'll want to edit

| File | What to change |
|------|---------------|
| `home/dot_Brewfile` | Add/remove Homebrew packages and casks |
| `home/dot_config/fish/config.fish.tmpl` | Shell aliases, paths, tool integrations |
| `home/dot_config/ghostty/config` | Terminal theme, font, keybindings |
| `home/dot_config/tmux/tmux.conf` | tmux prefix, keybindings, status bar |
| `home/dot_config/code/settings.json` | VS Code theme, font, settings |
| `home/dot_config/code/extensions.txt` | VS Code extensions (one per line) |
| `home/dot_config/zed/settings.json.tmpl` | Zed theme, MCP servers |
| `home/dot_tool-versions` | Global language versions |
| `home/.chezmoiscripts/run_once_after_mas-apps.sh.tmpl` | Mac App Store apps |
| `home/.chezmoiscripts/run_once_after_macos-defaults.sh.tmpl` | macOS system preferences |
| `home/.chezmoiexternal.toml` | Fish plugins to auto-download |

### Adding secrets

Secrets are injected at `chezmoi apply` time and never stored in git.

**With 1Password** (recommended):
```bash
# Store the secret
op item create --vault=Developer --category=api_credential --title="OpenAI" password="sk-..."

# Reference it in a template (e.g., secrets.fish.tmpl)
set -gx OPENAI_API_KEY "{{ onepasswordRead "op://Developer/OpenAI/password" }}"
```

**With macOS Keychain:**
```fish
keychain_set MY_TOKEN "secret-value"   # store
keychain_env MY_TOKEN                  # load into current shell
```

**Without any password manager:**
```fish
# Just set env vars in a gitignored local file
# Or use chezmoi's age encryption for files
```

### Removing what you don't need

- **No web3?** Delete web3 aliases from `config.fish.tmpl`, remove `cast_*` functions, remove Foundry from install script
- **No 1Password?** Answer "no" during `chezmoi init` — all 1Password sections are skipped
- **No Mac App Store?** Delete `run_once_after_mas-apps.sh.tmpl`
- **Different editor?** `chezmoi init` prompts for your choice (VS Code, Zed, Neovim, Vim)

## Daily usage

```bash
chezmoi edit ~/.config/fish/config.fish  # edit a config
chezmoi diff                             # preview changes
chezmoi apply                            # apply everything
chezmoi apply --refresh-externals        # force re-download plugins
```

Adding a Homebrew package:
```bash
chezmoi edit ~/.Brewfile     # add the line
chezmoi apply                # auto-runs brew bundle
```

## How secrets work

```
Git repo (safe to publish)          Your machine (after chezmoi apply)
──────────────────────────          ────────────────────────────────────
op://Developer/OpenAI/cred    →     sk-proj-actual-secret-key
{{ keyring "MY_TOKEN" ... }}  →     actual-token-value
SSH IdentityAgent path        →     1Password handles keys via Touch ID
```

On a new Mac: clone → `./install.sh` → `op signin` → `chezmoi apply` → done.

## Structure

```
home/                              # chezmoi source → maps to $HOME
├── .chezmoi.toml.tmpl             # init prompts (name, email, editor, 1Password)
├── .chezmoiexternal.toml          # fish plugins auto-downloaded from GitHub
├── .chezmoiignore                 # OS-conditional file exclusions
├── .chezmoiscripts/               # automation scripts
│   ├── run_onchange_before_*      # Brewfile → auto brew bundle
│   ├── run_once_after_*           # one-time: shell, defaults, apps, tools
│   └── run_onchange_after_*       # VS Code + Zed settings sync
├── dot_Brewfile                   # all Homebrew packages
├── dot_gitconfig.tmpl             # git config (name + email templated)
├── dot_ssh/config.tmpl            # SSH config (1Password agent)
├── dot_tool-versions              # global language versions (mise)
├── dot_docker/config.json         # Docker / OrbStack
└── dot_config/
    ├── fish/
    │   ├── config.fish.tmpl       # main config (paths, aliases, integrations)
    │   ├── conf.d/secrets.fish.tmpl  # secrets via 1Password / Keychain
    │   └── functions/             # cdg, op_env, keychain_env, tx, web3_env
    ├── ghostty/config             # terminal config
    ├── tmux/tmux.conf             # tmux + fzf session picker
    ├── zed/settings.json.tmpl     # Zed editor (MCP servers templated)
    ├── code/                      # VS Code settings + extensions list
    └── git/ignore                 # global git ignore
```

## Credits

Built with [chezmoi](https://www.chezmoi.io/). Inspired by [halostatue/dotfiles](https://github.com/halostatue/dotfiles) and [narze/dotfiles](https://github.com/narze/dotfiles).

## License

MIT
