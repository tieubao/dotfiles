---
id: S-33
title: Bitwarden secrets backend
type: feature
status: planned
---

# Bitwarden secrets backend

### Problem

The repo currently only supports 1Password for secret injection. Users
who use Bitwarden (self-hosted or cloud) cannot adopt the secrets
workflow without switching password managers. This limits adoption.

### Goal

Let users choose their secrets backend during `chezmoi init`:
1Password, Bitwarden, or none. All downstream features (templates,
`dotfiles secret add/rm/list`, `/dotfiles-sync`, `dotfiles doctor`)
adapt to the chosen backend.

### Design

#### Config variable

Add `secrets_backend` to `.chezmoi.toml.tmpl`:

```
{{- $secrets_backend := promptChoiceOnce . "secrets_backend" "Secrets backend" (list "1password" "bitwarden" "none") -}}
```

This replaces the current `use_1password` boolean. Migration: treat
`use_1password = true` as `secrets_backend = "1password"`.

The `op_account` and `op_vault` prompts only appear when
`secrets_backend = "1password"`. For Bitwarden, prompt for:
- `bw_server` (optional, for self-hosted: `https://vault.example.com`)

#### Template changes

`secrets.fish.tmpl` currently uses `onepasswordRead`. It needs to
branch on the backend:

```
{{- if eq .secrets_backend "1password" }}
set -gx {{ $var }} "{{ onepasswordRead $ref }}"
{{- else if eq .secrets_backend "bitwarden" }}
set -gx {{ $var }} "{{ bitwarden "item" $itemId $field }}"
{{- end }}
```

chezmoi's `bitwarden` template function requires item ID + field name
(not a URI like `op://`). The `secrets.toml` registry format needs to
support both:

```toml
# 1Password format
OPENAI_API_KEY = "op://Private/OpenAI/credential"

# Bitwarden format
OPENAI_API_KEY = "bw://OpenAI API/notes"
```

The template parses the prefix (`op://` vs `bw://`) and calls the
right chezmoi function.

#### `dotfiles secret add` changes

The `dotfiles secret add` subcommand currently:
1. Parses `op://Vault/Item/field`
2. Creates 1Password item if missing (`op item create`)
3. Appends to `secrets.toml`
4. Runs `chezmoi apply`

For Bitwarden, it needs to:
1. Parse `bw://ItemName/field`
2. Create Bitwarden item if missing (`bw create item`)
3. Append to `secrets.toml`
4. Runs `chezmoi apply`

The command reads `secrets_backend` from chezmoi data to decide which
path to take.

#### `dotfiles doctor` changes

Add Bitwarden health checks (when `secrets_backend = "bitwarden"`):
- `bw` CLI installed
- `bw status` shows "unlocked"
- Self-hosted server reachable (if configured)

#### `/dotfiles-sync` changes

The hardcoded secrets check in the sync command already looks for
hardcoded keys in fish config. No changes needed for detection. The
sync report should mention which backend is active.

#### Lifecycle

**Install:** wizard prompts for secrets backend choice. Bitwarden
users are told to run `bw login` and `bw unlock` before `chezmoi apply`.

**Update:** `dotfiles secret add/rm/list` works with either backend.
`/dotfiles-sync` detects secrets drift regardless of backend.

**Uninstall:** guide mentions removing `~/.config/Bitwarden CLI/` if
applicable (Bitwarden CLI config dir).

### Files to modify

| File | Change |
|------|--------|
| `home/.chezmoi.toml.tmpl` | Replace `use_1password` with `secrets_backend` choice, add `bw_server` prompt |
| `home/dot_config/fish/conf.d/secrets.fish.tmpl` | Branch on backend for template function |
| `home/dot_config/fish/functions/dotfiles.fish` | `secret add/rm` - support `bw://` format, `bw create item` |
| `home/dot_config/fish/functions/dotfiles.fish` | `doctor` - add Bitwarden health checks |
| `home/.chezmoiscripts/run_before_ab-1password-check.sh` | Rename/generalize to secrets-check, handle both backends |
| `home/dot_Brewfile.tmpl` | Add `bitwarden-cli` when backend is bitwarden |
| `.claude/commands/dotfiles-sync.md` | Mention active backend in report |
| `home/dot_claude/commands/dotfiles-sync.md` | Same (user-level copy) |
| `docs/guide.md` | Update secrets section for both backends |
| `docs/llm-dotfiles.md` | Add Bitwarden to the stack options table |
| `CLAUDE.md` | Update secret injection docs |

### Migration from `use_1password`

Existing users have `use_1password = true/false` in their chezmoi
config. The template needs backwards compatibility:

```
{{- $secrets_backend := "none" -}}
{{- if hasKey . "secrets_backend" -}}
{{-   $secrets_backend = .secrets_backend -}}
{{- else if and (hasKey . "use_1password") .use_1password -}}
{{-   $secrets_backend = "1password" -}}
{{- end -}}
```

On next `chezmoi init`, users are prompted for the new
`secrets_backend` variable. The old `use_1password` is ignored once
`secrets_backend` is set.

### Acceptance criteria

- [ ] `chezmoi init` prompts for secrets backend (1password, bitwarden, none)
- [ ] Choosing "bitwarden" prompts for optional self-hosted server URL
- [ ] `secrets.fish.tmpl` renders correctly for both `op://` and `bw://` refs
- [ ] `dotfiles secret add VAR "bw://Item/field"` creates Bitwarden item if missing
- [ ] `dotfiles secret add VAR "op://Vault/Item/field"` still works for 1Password
- [ ] `dotfiles secret rm` works regardless of backend
- [ ] `dotfiles secret list` shows bindings with correct prefix
- [ ] `dotfiles doctor` checks the configured backend (not both)
- [ ] Brewfile includes `bitwarden-cli` when backend is bitwarden
- [ ] Existing `use_1password = true` users migrate seamlessly
- [ ] Guide documents both backends with examples
- [ ] `/dotfiles-sync` report mentions active backend

### Test plan

```bash
# 1. Fresh init with Bitwarden
chezmoi init --force  # choose "bitwarden"
chezmoi data | grep secrets_backend  # should show "bitwarden"

# 2. Template renders
chezmoi execute-template < home/dot_config/fish/conf.d/secrets.fish.tmpl

# 3. Doctor checks Bitwarden
dotfiles doctor  # should check bw CLI, not op CLI

# 4. Migration
# Set use_1password = true in chezmoi config, remove secrets_backend
chezmoi init  # should prompt for secrets_backend, default to "1password"

# 5. Standard checks
fish -n home/dot_config/fish/functions/dotfiles.fish
shellcheck home/.chezmoiscripts/run_before_ab-*.sh
chezmoi apply --dry-run
```

### Non-goals

- Bitwarden SSH agent (doesn't exist; SSH stays 1Password-only)
- HashiCorp Vault, AWS Secrets Manager, etc. (too niche for a dotfiles repo)
- Migrating secrets between backends (manual process)
