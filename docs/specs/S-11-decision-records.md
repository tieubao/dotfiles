---
id: S-11
title: Decision records
type: feature
status: done
old_id: F-11
---

# Decision records

### Problem
No documentation of WHY certain tools were chosen. Future-you (or contributors) will wonder why Fish instead of Zsh, why Ghostty instead of Kitty, why chezmoi instead of GNU Stow.

### Spec
Create `docs/decisions/` with one file per decision:

```
docs/decisions/
  001-chezmoi-over-stow.md
  002-fish-over-zsh.md
  003-ghostty-over-kitty.md
  004-1password-for-secrets.md
  005-no-plugin-manager-for-fish.md
```

Each follows ADR format:
```markdown
# ADR-001: chezmoi over GNU Stow

## Status: accepted

## Context
Needed a dotfiles manager that supports: 1Password integration, Go templates
for machine-specific config, multi-machine support, and XDG-compliant storage.

## Decision
Use chezmoi as the dotfiles manager.

## Alternatives considered
- GNU Stow: Simple symlinks only, no templates, no secrets, no multi-machine.
  Good for single machine but doesn't scale.
- yadm: Git wrapper with Jinja2 templates, but template engine depends on
  unmaintained external tools (envtpl, j2cli). chezmoi uses Go's text/template
  standard library.
- Nix Home Manager: Overkill. Requires learning Nix language. We just need
  dotfiles, not a full system package manager.

## Consequences
- All configs live in `home/` with chezmoi naming conventions (dot_, .tmpl, etc.)
- Secrets use `onepasswordRead` template function
- New team members need to learn chezmoi basics (apply, edit, diff)
- Repo is safe to make public since no plaintext secrets exist
```

### Rules
- Write based on the actual decisions from our conversation + your own reasoning
- Be opinionated. State what won and why.
- Include real tradeoffs, not just marketing points
- Keep each ADR to ~150-250 words

### Files to create
- `docs/decisions/001-chezmoi-over-stow.md`
- `docs/decisions/002-fish-over-zsh.md`
- `docs/decisions/003-ghostty-over-kitty.md`
- `docs/decisions/004-1password-for-secrets.md`
- `docs/decisions/005-no-plugin-manager-for-fish.md`

Content for each is derived from the Claude.ai chat session where these tools were evaluated.
