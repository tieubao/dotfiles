# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A chezmoi-managed dotfiles repo for macOS (Apple Silicon). The `home/` directory is the chezmoi source state — it maps to `$HOME` on the target machine. The `install.sh` script bootstraps a fresh Mac from zero.

## Key commands

```bash
chezmoi apply                    # Deploy all configs + run scripts
chezmoi apply --dry-run          # Preview what would change
chezmoi diff                     # Show pending diffs
chezmoi apply --refresh-externals  # Force re-download fish plugins
chezmoi managed                  # List all managed files
chezmoi edit ~/.config/fish/config.fish  # Edit a managed file
```

## Architecture

### chezmoi source directory: `home/`

chezmoi uses filename prefixes to encode target attributes:
- `dot_` → hidden file (e.g., `dot_gitconfig` → `~/.gitconfig`)
- `.tmpl` suffix → Go template, rendered at apply time
- `private_` → mode 0600
- `encrypted_` → encrypted in repo, decrypted on apply

### Secret injection (two backends)

**1Password** (primary) — via chezmoi Go templates at apply time:
```
{{ onepasswordRead (printf "op://%s/ItemName/credential" .op_vault) }}
```
Used in: `secrets.fish.tmpl`, `dot_gitconfig.tmpl`, `dot_config/zed/settings.json.tmpl`

**macOS Keychain** — via `keyring` template function or runtime fish functions:
```
{{ keyring "service-name" .chezmoi.username }}
```

Template variables are prompted once during `chezmoi init` and cached:
- `.name`, `.email` — git identity
- `.editor` — chosen editor (`code --wait`, `zed --wait`, `nvim`, `vim`)
- `.headless` — boolean, skips GUI apps and dev tools on servers
- `.use_1password` — boolean, gates all 1Password sections
- `.op_account`, `.op_vault` — only prompted if `use_1password` is true

### Script execution order

Scripts in `.chezmoiscripts/` run during `chezmoi apply`:

1. `run_before_aa-init.sh` — resets apply log file (`~/.cache/dotfiles-apply.log`)
2. `run_before_ab-1password-check.sh` — validates 1Password CLI setup (if enabled)
3. `run_onchange_before_brew-bundle.sh` — triggers when `dot_Brewfile` content changes (sha256 hash in comment)
4. Files are deployed (including `~/.config/dotfiles/lib.sh`)
5. `run_once_after_*` — one-time setup (fish shell, macOS defaults, mas apps, toolchains)
6. `run_onchange_after_*` — triggers when VS Code settings/extensions or Zed config changes
7. `run_after_zz-summary.sh` — prints styled apply summary with warnings/errors/next steps

`run_once_` scripts track execution in chezmoi's state DB and won't re-run unless the script content changes. `run_onchange_` scripts re-run when the hash comment inside them changes (chezmoi evaluates the template, hashes the output).

### External downloads: `.chezmoiexternal.toml`

Fish plugins and completions are pulled from GitHub URLs (no plugin manager). Cached with 30-day refresh. These files don't exist in `home/` — they're defined as URLs and downloaded at apply time.

### OS-conditional: `.chezmoiignore`

The ignore file is itself a Go template. macOS-only configs (Ghostty, Zed, Brewfile) are skipped on Linux. GUI configs are skipped in GitHub Codespaces.

## Important conventions

- **Never commit secrets.** API keys go in 1Password with `op://` references in `.tmpl` files. The rendered output (with real secrets) only exists on the target machine, never in git.
- **Zed settings** (`settings.json.tmpl`) contains 5 MCP server configs with 1Password-injected API keys. When adding MCP servers, use the same `onepasswordRead` pattern.
- **VS Code settings** live in `dot_config/code/` (not the Library path). The `run_onchange_after_vscode.sh` script copies them to `~/Library/Application Support/Code/User/` at apply time.
- **Brewfile changes auto-apply** — editing `dot_Brewfile` and running `chezmoi apply` triggers `brew bundle` automatically.
- **Fish functions** in `home/dot_config/fish/functions/` are auto-loaded by fish (one function per file, filename = function name).
- **Error message library** (`~/.config/dotfiles/lib.sh`) is sourced by all `run_*_after_*` scripts. Uses `gum log`/`gum style` for styled output with ANSI fallback. Functions: `info`, `warn "what" "why" "fix"`, `err`, `die`, `require_cmd`, `section`, `script_ok`. All warnings/errors log to `~/.cache/dotfiles-apply.log`.
- **Template guards** — every `.tmpl` file validates required variables with `hasKey`/`fail` at the top. Missing variables produce `Fix: chezmoi init` instead of cryptic Go template errors.
- **Apply summary** — `run_after_zz-summary.sh` prints a gum-styled status box at the end of every apply with OK/warning/failure counts, details, and actionable next steps.
