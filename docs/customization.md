# Customization guide

How to change anything in this dotfiles repo without going back and
forth between the source directory and your machine.

## Core requirement

> Every change to a setting must be **applied to the machine** AND
> **backed up in the dotfiles repo** in one step. The user should never
> have to remember to re-run `chezmoi apply` or `git commit` separately.

All helpers in this guide (`dfe`, `dfs`, `add-secret`, `rm-secret`) are
designed to satisfy this rule by default. Opt out with `--no-commit` if
you need to stage a change but not commit it.

Pushing is still manual. Run `git -C (dirname (chezmoi source-path)) push`
when you're ready to share the commits with other machines.

## The one rule

```
edit source  →  chezmoi apply  →  effect on your machine
```

Every customization follows this shape. The source lives in the repo at
`home/` and gets linked to `~/.local/share/chezmoi`. When you run
`chezmoi apply`, chezmoi renders any `.tmpl` files, then deploys the
result to `$HOME`.

```mermaid
flowchart LR
    A[you edit source file<br/>in ~/.local/share/chezmoi/...] -->|chezmoi apply| B[chezmoi renders<br/>.tmpl files]
    B --> C[deploys to $HOME<br/>~/.config/fish/config.fish etc.]
    C --> D[new shell /<br/>reload app]
```

### The shortcut

The `dfe` fish helper edits the **source**, applies on save, and
commits the change in one shot:

```fish
dfe ~/.config/fish/config.fish           # edit + apply + commit
dfe ~/.config/fish/config.fish --no-commit  # edit + apply only
```

Pushing is still on you. When there are commits to share:

```fish
git -C (dirname (chezmoi source-path)) push
```

### Reverse drift — `dfs`

If you edited a deployed file directly (bypassing `dfe`) and want the
change captured back into the source:

```fish
dfs                # diff, prompt, chezmoi re-add, commit
dfs --no-commit    # re-absorb without committing
```

`dfs` runs `chezmoi diff` so you see the drift before agreeing, then
uses `chezmoi re-add` to pull the live file contents back into the
source tree and commits the result.

Other useful shortcuts you can alias yourself or type directly:

| What | Command |
|---|---|
| Apply pending changes | `chezmoi apply` |
| See what would change | `chezmoi diff` |
| Edit without applying | `chezmoi edit <path>` |
| Jump to the source dir | `chezmoi cd` |
| List everything managed | `chezmoi managed` |

## Quick reference — common customizations

| Change | File | Command |
|---|---|---|
| Homebrew packages | `home/dot_Brewfile.tmpl` | `dfe ~/.Brewfile` (auto-runs `brew bundle`) |
| Fish abbrs / env | `home/dot_config/fish/config.fish.tmpl` | `dfe ~/.config/fish/config.fish` |
| Fish function | `home/dot_config/fish/functions/NAME.fish` | `dfe ~/.config/fish/functions/NAME.fish` |
| Starship prompt | `home/dot_config/starship.toml` | `dfe ~/.config/starship.toml` |
| Ghostty config | `home/dot_config/ghostty/config` | `dfe ~/.config/ghostty/config` (live reload) |
| Ghostty theme | any time | `ghostty-theme N` — live switch |
| VS Code settings | `home/dot_config/code/settings.json` | `dfe ~/.config/code/settings.json` |
| VS Code extensions | `home/dot_config/code/extensions.txt` | edit + `chezmoi apply` |
| Zed settings + MCP | `home/dot_config/zed/settings.json.tmpl` | `dfe ~/.config/zed/settings.json` |
| Git config | `home/dot_gitconfig.tmpl` | `dfe ~/.gitconfig` |
| SSH hosts | `home/dot_ssh/config.d/*` | drop file + `chezmoi apply` |
| macOS defaults | `home/.chezmoiscripts/run_once_after_macos-defaults.sh.tmpl` | edit + `chezmoi apply` (re-runs on content change) |
| Claude Code config | `home/dot_claude/` | `dfe ~/.claude/settings.json` |
| 1Password secrets | `home/.chezmoidata/secrets.toml` | `add-secret VAR op://...` — see below |
| Fish plugins | `home/.chezmoiexternal.toml` | edit + `chezmoi apply --refresh-externals` |
| Setup wizard answers | `~/.config/chezmoi/chezmoi.toml` | `chezmoi init` to re-prompt |

## Secrets workflow

Secrets are handled differently because the value lives in 1Password,
not in the repo. Three tiers, pick per secret:

| Tier | When | Command |
|---|---|---|
| **Auto-loaded** | env var you want in every shell | `add-secret VAR "op://..."` |
| **Runtime** | occasional CLI use, don't want in every env | `op-env VAR "op://..."` |
| **One-off** | inline trial | `set -x VAR (op read "op://...")` |

### The `add-secret` flow

```mermaid
flowchart TD
    A[add-secret VAR op://Vault/Item/field --commit] --> B{op read<br/>succeeds?}
    B -- no --> C[prompt for value<br/>hidden input] --> D[op item create<br/>in 1Password]
    D --> E
    B -- yes --> E[append VAR=ref to<br/>.chezmoidata/secrets.toml]
    E --> F[chezmoi apply<br/>renders secrets.fish]
    F --> G[git commit --commit flag]
    G --> H[user opens new shell<br/>$VAR is set]
```

Example:
```fish
add-secret OPENAI_API_KEY "op://Private/OpenAI/credential"
exec fish   # or open a new terminal — now $OPENAI_API_KEY is set
```

The commit is automatic. Pass `--no-commit` if you want to stage the
registry change without committing.

Companions:
```fish
list-secrets                    # show current bindings
rm-secret OPENAI_API_KEY        # unregister (auto-commits)
```

### How it works under the hood

`home/.chezmoidata/secrets.toml` is a registry chezmoi loads automatically
as the `.secrets` template variable. `home/dot_config/fish/conf.d/secrets.fish.tmpl`
iterates `.secrets` at apply time and emits one `set -gx` per entry,
resolving each `op://` ref via `onepasswordRead`. The rendered
`~/.config/fish/conf.d/secrets.fish` contains real tokens — it never
leaves your machine.

### Rotating a token

Just update the value in 1Password. The next `chezmoi apply` re-renders
the fish file with the new value. To force immediately:

```fish
chezmoi apply ~/.config/fish/conf.d/secrets.fish
exec fish
```

## Troubleshooting

- **"I changed the source but nothing happened"** — you probably edited
  `~/.config/...` directly. Edit the source at
  `~/.local/share/chezmoi/...` (or use `dfe`). `chezmoi diff` will show
  if your change drifted.
- **"chezmoi apply wants to prompt me"** — you modified a deployed file
  outside chezmoi. Either accept the overwrite, or `chezmoi merge PATH`
  to bring the change back into the source.
- **"op read failed"** — run `eval (op signin)` once per shell session.
- **"Template error at apply"** — a `.tmpl` file is missing a variable.
  Run `chezmoi init` to refresh the answer cache.
- **"Brewfile didn't re-run"** — `run_onchange_before_brew-bundle.sh.tmpl`
  only fires when the file content changes. Force it with
  `rm ~/.config/chezmoi/state/chezmoistate.boltdb` (nuclear) or just
  `brew bundle --file=~/.Brewfile`.

## Key design choices

- **No hand-edits to `secrets.fish.tmpl`** for new env vars — use the
  registry so the template stays small and readers see one source of
  truth.
- **`dfe` over `chezmoi edit` + `chezmoi apply`** — less to remember,
  fewer forgotten applies.
- **1Password references, not values, are in git** — rotation doesn't
  touch the repo.
