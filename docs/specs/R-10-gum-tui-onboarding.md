# R-10: Gum TUI onboarding wizard

## Problem

The current `chezmoi init` onboarding is plain text prompts with no visual feedback:
```
Full name (for git)?
Email address?
Default editor?
```

No colors, no selection menus, no spinners, no progress indication.

## Entry paths analysis

There are 3 distinct ways a user sets up this repo. The gum wizard only applies to path A.

| Path | Command | Uses install.sh? | Gets gum? |
|------|---------|-------------------|-----------|
| **A: git clone** | `git clone ... && ./install.sh` | Yes | Yes |
| **B: chezmoi direct** | `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply dwarvesf` | No | No (native prompts) |
| **C: brew + chezmoi** | `brew install chezmoi && chezmoi init --apply dwarvesf` | No | No (native prompts) |

Paths B and C bypass install.sh entirely, so `.chezmoi.toml.tmpl` must remain fully functional with native `promptStringOnce` prompts as the fallback.

## Solution

Use [Gum](https://github.com/charmbracelet/gum) by Charm for styled TUI prompts in install.sh.

### Architecture: gum pre-fills, chezmoi validates

To avoid dual-maintenance (wizard AND template defining the same variables), the gum wizard **pre-fills** chezmoi.toml, then we still run `chezmoi init`:

```
gum collects values → write ~/.config/chezmoi/chezmoi.toml → chezmoi init (reads existing values, skips prompts) → chezmoi apply
```

Why this works:
- `promptStringOnce` reads existing values from chezmoi.toml and skips prompting
- `.chezmoi.toml.tmpl` remains the single source of truth for config shape
- If a new variable is added to the template but not the wizard, `chezmoi init` will prompt for just that one missing value
- Paths B and C work exactly as before

### Gum wizard flow

```bash
# Styled header
gum style --border double --padding "1 2" --foreground 212 "dotfiles setup"

# Pre-fill from existing git config
name=$(gum input --placeholder "Full name" --value "$(git config user.name 2>/dev/null)")
email=$(gum input --placeholder "Email" --value "$(git config user.email 2>/dev/null)")
editor=$(gum choose --header "Default editor" "code --wait" "zed --wait" "nvim" "vim")
headless=$(gum confirm "Headless/server?" && echo true || echo false)
use_1password=$(gum confirm "Use 1Password?" && echo true || echo false)

if [ "$use_1password" = "true" ]; then
    op_account=$(gum input --placeholder "Account" --value "my.1password.com")
    op_vault=$(gum input --placeholder "Vault" --value "Developer")
fi

# Write chezmoi.toml
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<EOF
[data]
  name = "$name"
  email = "$email"
  editor = "$editor"
  headless = $headless
  use_1password = $use_1password
  op_account = "${op_account:-}"
  op_vault = "${op_vault:-}"
EOF

# chezmoi init validates template (reads existing values, no re-prompts)
chezmoi init

# Apply with spinners
gum spin --spinner dot --title "Deploying configs..." -- chezmoi apply --exclude=scripts
gum spin --spinner dot --title "Running brew bundle..." -- chezmoi apply
```

### Fallback strategy

```bash
run_wizard() {
    if command -v gum &>/dev/null && [ -t 0 ]; then
        # Interactive TTY + gum available: fancy wizard
        run_gum_wizard
    else
        # No gum or no TTY: fall through to chezmoi init (native prompts)
        chezmoi init
    fi
}
```

| Condition | What happens |
|-----------|-------------|
| Has gum + TTY | Gum wizard |
| Has gum + no TTY (CI, pipe) | Skip wizard, use `chezmoi init` or pre-written toml |
| No gum + TTY | `chezmoi init` native prompts |
| No gum + no TTY | Needs pre-written chezmoi.toml (CI path) |

### Spinners for apply steps

Replace bare `chezmoi apply` / `brew bundle` output with gum spinners:

```bash
if command -v gum &>/dev/null; then
    gum spin --spinner dot --title "Deploying configs..." -- chezmoi apply
else
    chezmoi apply
fi
```

## Edge cases

| Case | Behavior |
|------|----------|
| Ctrl+C during wizard | `set -e` exits, no partial toml written |
| chezmoi.toml already exists | Skip wizard, just apply (existing behavior) |
| Partial chezmoi.toml (missing fields) | `chezmoi init` prompts for missing ones |
| `--force` flag | Deletes toml, re-runs wizard |
| `--force --config-only` | Deletes toml, wizard, apply without scripts |
| New var added to .chezmoi.toml.tmpl but not wizard | `chezmoi init` fills the gap (prompts for that one) |
| gum install fails | Fall back to `chezmoi init` native prompts |
| User runs path B, then later `./install.sh` | toml exists, wizard skips, just applies |

## Files to modify

- `install.sh` -- add gum install, wizard function, spinner wrapping
- `home/dot_Brewfile.tmpl` -- add `brew "gum"` to base section
- `.chezmoi.toml.tmpl` -- no changes (stays as single source of truth)

## Test plan

- [ ] `./install.sh` on fresh machine (path A): installs brew, gum, runs wizard, full apply
- [ ] `./install.sh --config-only` on existing machine: wizard, deploy configs only
- [ ] `./install.sh` when toml exists: skips wizard, just applies
- [ ] `./install.sh --force`: deletes toml, re-runs wizard
- [ ] `chezmoi init --apply dwarvesf` (path B): native prompts work, no gum dependency
- [ ] CI (no TTY, pre-written toml): no prompts, apply works
- [ ] Ctrl+C during wizard: clean exit, no partial state
- [ ] `chezmoi apply` with use_1password=true: no 1Password errors (secrets are examples only)
