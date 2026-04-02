# Session State

Updated: 2026-04-02
Project: dwarvesf/dotfiles
Phase: Stable, expanding

## POSITION

### Phase
Mature. All 12 original features (F-01 through F-12) and 5 cleanup specs (R-03 through R-09) are shipped except F-03 (bootstrap without git), F-04 (Brewfile split), and F-12 (v0.1.0 tag). 24+ commits on main. CI passing weekly.

### What is decided
- chezmoi as dotfiles manager (over GNU Stow, yadm, Nix)
- Fish shell (over Zsh/Oh My Zsh/Prezto) for startup speed and built-in features
- Ghostty terminal (over Kitty, WezTerm, iTerm2) for native macOS feel + performance
- 1Password for secrets (op:// template injection, never plaintext in git)
- XDG Base Directory compliance where possible
- Fish plugins via .chezmoiexternal.toml (no plugin manager, ADR-005)
- mise for language version management (.tool-versions)
- age encryption for complex sensitive files (encrypt-setup command exists)
- Modular SSH config with config.d/ and 1Password agent
- tmux with C-a prefix, vim nav, fzf session picker

### What is still open
- Whether to add Starship prompt (recommended, not yet added)
- Brewfile split into base/dev/apps layers (F-04)
- Window tiling manager (Aerospace or similar)
- Multi-machine profiles (chezmoi tags for work vs personal)

### Codebase status
Production-grade dotfiles system with:
- Idempotent install.sh (--check, --force flags, exit codes)
- CI pipeline (shellcheck + dry-run on macOS, weekly schedule)
- `dotfiles` CLI with 9 subcommands (edit, diff, sync, status, cd, refresh, add, doctor, encrypt-setup)
- Drift detection (dotfiles-drift function)
- 9 custom Fish functions with tab completions
- 5 ADRs documenting key decisions
- 14 external Fish plugins/completions via .chezmoiexternal.toml
- ~80 Homebrew packages + 26 MAS apps

## CONTEXT

### User preferences
- Brutally honest feedback, no yes-man behavior
- Visual learner, likes diagrams and charts
- Light theme for visual elements
- No em dashes in text
- Leadership at Dwarves Foundation, based in Da Nang/Saigon
- Uses Claude Code heavily, has custom skills/MCP infrastructure
- Familiar with chezmoi, not a beginner

### Constraints
- macOS primary (Apple Silicon)
- Must work with 1Password or without (graceful degradation)
- Public repo (no plaintext secrets ever)
- XDG-compliant where tools support it
- Fish as default shell

## INTENT

### Next steps (v0.2.0 roadmap)
See docs/tasks.md for the full backlog.
