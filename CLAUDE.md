# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A chezmoi-managed dotfiles repo for macOS (Apple Silicon). The `home/` directory is the chezmoi source state  - it maps to `$HOME` on the target machine. The `install.sh` script bootstraps a fresh Mac from zero.

User-facing customization flows (how to change Brewfile, secrets, editors, etc.) live in [`docs/guide.md`](docs/guide.md). When a user asks "how do I change X", point them there rather than reinventing.

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

**1Password** (primary)  - via chezmoi Go templates at apply time:
```
{{ onepasswordRead (printf "op://%s/ItemName/credential" .op_vault) }}
```
Used directly in: `dot_gitconfig.tmpl`, `dot_config/zed/settings.json.tmpl`.

For auto-loaded shell env vars, prefer the data-driven workflow: register
entries in `.chezmoidata/secrets.toml` via `dotfiles secret add VAR op://...`
and let `secrets.fish.tmpl` iterate. Do not hand-edit the template to add
new env vars  - use `dotfiles secret add` / `dotfiles secret rm` / `dotfiles secret list`.

**macOS Keychain**  - via `keyring` template function or runtime fish functions:
```
{{ keyring "service-name" .chezmoi.username }}
```

Template variables are prompted once during `chezmoi init` and cached:
- `.name`, `.email`  - git identity
- `.editor`  - chosen editor (`code --wait`, `zed --wait`, `nvim`, `vim`)
- `.headless`  - boolean, skips GUI apps and dev tools on servers
- `.use_1password`  - boolean, gates all 1Password sections
- `.op_account`, `.op_vault`  - only prompted if `use_1password` is true

### Script execution order

Scripts in `.chezmoiscripts/` run during `chezmoi apply`:

1. `run_before_aa-init.sh`  - resets apply log file (`~/.cache/dotfiles-apply.log`)
2. `run_before_ab-1password-check.sh`  - validates 1Password CLI setup (if enabled)
3. `run_onchange_before_brew-bundle.sh`  - triggers when `dot_Brewfile` content changes (sha256 hash in comment)
4. Files are deployed (including `~/.config/dotfiles/lib.sh`)
5. `run_once_after_*`  - one-time setup (fish shell, macOS defaults, mas apps, toolchains)
6. `run_onchange_after_*`  - triggers when VS Code settings/extensions or Zed config changes
7. `run_after_zz-summary.sh`  - prints styled apply summary with warnings/errors/next steps

`run_once_` scripts track execution in chezmoi's state DB and won't re-run unless the script content changes. `run_onchange_` scripts re-run when the hash comment inside them changes (chezmoi evaluates the template, hashes the output).

### External downloads: `.chezmoiexternal.toml`

Fish plugins and completions are pulled from GitHub URLs (no plugin manager). Cached with 30-day refresh. These files don't exist in `home/`  - they're defined as URLs and downloaded at apply time.

### OS-conditional: `.chezmoiignore`

The ignore file is itself a Go template. macOS-only configs (Ghostty, Zed, Brewfile) are skipped on Linux. GUI configs are skipped in GitHub Codespaces.

## Important conventions

- **Never commit secrets.** API keys go in 1Password with `op://` references in `.tmpl` files. The rendered output (with real secrets) only exists on the target machine, never in git.
- **Zed settings** (`settings.json.tmpl`) contains 5 MCP server configs with 1Password-injected API keys. When adding MCP servers, use the same `onepasswordRead` pattern.
- **VS Code settings** live in `dot_config/code/` (not the Library path). The `run_onchange_after_vscode.sh` script copies them to `~/Library/Application Support/Code/User/` at apply time.
- **Brewfile changes auto-apply**  - editing `dot_Brewfile` and running `chezmoi apply` triggers `brew bundle` automatically.
- **Fish functions** in `home/dot_config/fish/functions/` are auto-loaded by fish (one function per file, filename = function name).
- **Error message library** (`~/.config/dotfiles/lib.sh`) is sourced by all `run_*_after_*` scripts. Uses `gum log`/`gum style` for styled output with ANSI fallback. Functions: `info`, `warn "what" "why" "fix"`, `err`, `die`, `require_cmd`, `section`, `script_ok`. All warnings/errors log to `~/.cache/dotfiles-apply.log`.
- **Template guards**  - every `.tmpl` file validates required variables with `hasKey`/`fail` at the top. Missing variables produce `Fix: chezmoi init` instead of cryptic Go template errors.
- **Apply summary**  - `run_after_zz-summary.sh` prints a gum-styled status box at the end of every apply with OK/warning/failure counts, details, and actionable next steps.

## Claude Code project config

- **`.claude/settings.json`**  - project-level permissions (allow lint/verify, deny destructive) + PostToolUse hook that auto-runs shellcheck on `.sh` and `fish -n` on `.fish` after every edit.
- **`.claude/agents/verify-dotfiles.md`**  - QA subagent. Runs 5 checks: shellcheck, fish syntax, chezmoi dry-run, file existence, managed file count. Use proactively after implementing any feature.
- **`.claude/commands/implement-feature.md`**  - Slash command: `/implement-feature S-24` reads the spec, implements, verifies via subagent, fixes, commits.
- **`home/dot_claude/`**  - chezmoi-managed Claude Code user config (settings.json, keybindings.json, statusline script). Deployed to `~/.claude/` on apply. Skipped on headless/Codespaces.

## Verification rules

After implementing any feature from `docs/specs/S-*.md`:

### Mandatory self-check (do NOT skip)
1. Run the relevant verification commands (see table below)
2. If ANY check fails, fix the issue and re-run
3. Repeat until all checks pass or you've made 5 fix attempts
4. Do NOT ask the user to verify. Run verification yourself.
5. Only report back when all checks are green, or when you've hit the 5-attempt limit and need human help
6. When reporting, include the actual test output, not a summary of what you think happened

### Verification commands by file type

| File pattern | Command | What it checks |
|-------------|---------|---------------|
| `*.sh` | `shellcheck --severity=warning FILE` | Shell script lint |
| `*.fish` | `fish -n FILE` | Fish syntax check |
| `*.tmpl` | `chezmoi execute-template < FILE > /dev/null` | Template rendering |
| `home/dot_Brewfile*` | `chezmoi apply --dry-run 2>&1 \| head -50` | Brewfile validity |
| Any chezmoi file | `chezmoi apply --dry-run --verbose 2>&1 \| tail -20` | Full dry run |
| `install.sh` | `bash -n install.sh && shellcheck install.sh` | Syntax + lint |

### After every feature implementation
```bash
# 1. Lint all shell scripts
find . -name "*.sh" -not -path "./.git/*" | xargs shellcheck --severity=warning

# 2. Syntax check all fish files
find home -name "*.fish" | while read f; do fish -n "$f" || echo "FAIL: $f"; done

# 3. Dry run chezmoi
chezmoi apply --dry-run 2>&1 | tail -20

# 4. Check managed file list is not empty
test $(chezmoi managed | wc -l) -gt 10 || echo "FAIL: too few managed files"
```

### Git workflow
- Commit each feature separately with conventional commit format
- Commit message: `feat(S-XX): short description`
- Do NOT batch multiple features into one commit
- Run verification BEFORE committing, not after
