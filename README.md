# dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/). One command to set up a new Mac.

## Install

```bash
git clone https://github.com/tieubao/dotfiles ~/workspace/tieubao/dotfiles
cd ~/workspace/tieubao/dotfiles && ./install.sh
```

This bootstraps Homebrew, chezmoi, then runs `chezmoi init --apply` which:

1. Prompts for email + 1Password vault name
2. Installs ~80 Homebrew packages + casks
3. Deploys all configs (shell, terminal, editors, git, ssh, docker)
4. Injects secrets from 1Password into templated configs
5. Downloads fish plugins from GitHub
6. Sets fish as default shell
7. Applies macOS system preferences (Dock, Finder, keyboard, trackpad)
8. Installs Mac App Store apps via `mas`
9. Installs Foundry, Rust, npm/uv tools
10. Sets up VS Code extensions

## What's managed

| Config | Tool |
|--------|------|
| Shell | Fish + plugins (autopair, done, sponge, async-prompt) |
| Terminal | Ghostty (catppuccin-mocha, JetBrains Mono) |
| Multiplexer | tmux (C-a prefix, fzf session picker) |
| Editors | VS Code + Zed (settings, extensions, MCP servers) |
| Git | .gitconfig (delta, aliases) + .gitignore + .gitmessage |
| SSH | 1Password SSH Agent |
| Secrets | 1Password (`op://`) + macOS Keychain (`keyring`) |
| Packages | Homebrew Brewfile + Mac App Store (mas) |
| Languages | mise (Node, Python, Go, Ruby) via .tool-versions |
| Containers | OrbStack + Docker config |
| macOS | 30+ `defaults write` (Dock, Finder, keyboard, screenshots) |
| Web3/DeFi | Foundry (cast), fish aliases + helper functions |

## Secrets

Secrets never touch git. Two backends:

**1Password** — resolved at `chezmoi apply` time via Go templates:
```
{{ onepasswordRead "op://Developer/OpenAI/credential" }}
```

**macOS Keychain** — via chezmoi `keyring` or fish functions:
```fish
keychain_set MY_TOKEN "value"    # store
keychain_env MY_TOKEN            # load into env
op_env MY_TOKEN "op://Vault/Item/field"  # load from 1Password on-demand
```

On a new device: `op signin` → `chezmoi apply` → all secrets flow through.

## Daily usage

```bash
chezmoi edit ~/.config/fish/config.fish   # edit a config
chezmoi apply                             # apply changes
chezmoi diff                              # preview before applying
chezmoi apply --refresh-externals         # force re-download fish plugins
```

Adding a Homebrew package:
```bash
chezmoi edit ~/.Brewfile                  # add the package
chezmoi apply                             # auto-runs brew bundle
```

Adding a secret:
```bash
# Store in 1Password
op item create --vault=Developer --category=api_credential --title="MyService" password="secret"
# Reference in template
chezmoi edit ~/.config/fish/conf.d/secrets.fish  # add: set -gx MY_KEY "{{ onepasswordRead "op://Developer/MyService/password" }}"
chezmoi apply
```

## Structure

```
home/                          # chezmoi source → maps to $HOME
├── .chezmoi.toml.tmpl         # init config (prompts for email, 1Password vault)
├── .chezmoiexternal.toml      # fish plugins downloaded from GitHub
├── .chezmoiignore             # OS-conditional file exclusions
├── .chezmoiscripts/           # automation scripts
│   ├── run_onchange_before_*  # Brewfile → auto brew bundle
│   ├── run_once_after_*       # one-time: fish shell, macOS defaults, mas, Foundry, Rust
│   └── run_onchange_after_*   # VS Code + Zed settings sync
├── dot_Brewfile               # Homebrew packages
├── dot_gitconfig.tmpl         # git config (email templated)
├── dot_ssh/config.tmpl        # SSH config (1Password agent)
├── dot_tool-versions          # global language versions (mise)
├── dot_docker/config.json     # Docker/OrbStack
└── dot_config/
    ├── fish/                  # Fish shell
    │   ├── config.fish        # main config (paths, aliases, integrations)
    │   ├── conf.d/secrets.fish.tmpl  # 1Password-injected secrets
    │   └── functions/         # cdg, op_env, keychain_env, tx, web3_env
    ├── ghostty/config         # Ghostty terminal
    ├── tmux/tmux.conf         # tmux + fzf session picker
    ├── zed/settings.json.tmpl # Zed (MCP server keys via 1Password)
    ├── code/                  # VS Code settings + extensions list
    └── git/ignore             # global git ignore
```
