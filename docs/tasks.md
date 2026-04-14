# Task Backlog: dwarvesf/dotfiles

Updated: 2026-04-14

<!-- Old ID → New ID mapping: F-XX/R-XX/T-XX → S-XX. See docs/specs/S-*.md -->

## Completed (v0.1.0)

- [x] S-01: Idempotent install.sh (--check, --force, exit codes, post-verify)
- [x] S-02: CI smoke test (shellcheck + chezmoi dry-run on macOS, weekly schedule)
- [x] S-03: Bootstrap without git (one-liner in README)
- [x] S-04: Brewfile split (base/dev/apps layers via chezmoi template + headless prompt)
- [x] S-05: Fish dotfiles CLI (13 subcommands)
- [x] S-06: Fish completions for custom functions (8 completion files)
- [x] S-07: Drift detection (dotfiles-drift function + daily startup check)
- [x] S-08: SSH config hardening (1Password agent, IdentitiesOnly, config.d/)
- [x] S-09: Age encryption (dotfiles encrypt-setup guided command)
- [x] S-10: Ghostty image rendering (render-img with chafa + kitty protocol)
- [x] S-11: Decision records (5 ADRs in docs/decisions/)
- [x] S-12: Tag v0.1.0 release
- [x] S-13: Install idempotency refinement
- [x] S-14: CI integration test refinement
- [x] S-15: Secrets fish cleanup (slim secrets.fish.tmpl from 43 to 26 lines)
- [x] S-16: Age encryption guided setup
- [x] S-17: Fish naming consistency (op_env -> op-env, etc.)
- [x] S-18: VS Code extension sync (skip already-installed)
- [x] S-19: Dotfiles doctor
- [x] S-20: Tmux config (C-a prefix, vim nav, fzf picker, project launcher)
- [x] S-21: Consolidate toolchain scripts into install-toolchains.sh
- [x] S-22: Gum TUI onboarding
- [x] S-23: Error message system (gum-styled output, template guards, apply summary)
- [x] Data-driven secret registry (secrets.toml, add-secret, rm-secret, list-secrets)
- [x] Auto-commit workflow (dfe auto-commits, dfs reverse drift sync, ADR-006)

## Next up

- [ ] S-24: Ghostty config sync  - convert to template, review settings, add doctor check
- [x] S-25: Starship config polish  - review modules, check Nerd Font rendering
- [ ] S-26: Brewfile cleanup  - audit stale entries, verify casks, deduplicate
- [ ] S-27: Gum UI helper library (lib/ui.sh)  - styled boxes, step progress, validation
- [x] S-28: README tool showcase icons  - skillicons.dev + shields.io badges
- [ ] S-29: VHS terminal demo  - animated GIF of install wizard
- [x] S-30: Verification loop  - CLAUDE.md rules, subagent, hooks, slash command
- [x] S-31: User guide  - comprehensive manual replacing customization.md
- [ ] S-32: Claude-assisted dotfiles sync  - LLM scans drift, reports, syncs on approval

## Backlog (no immediate plans)

- [ ] Aerospace tiling window manager (lightweight i3-like WM for macOS)
- [ ] Multi-machine profiles (chezmoi tags for work vs personal vs server)
- [ ] Per-project Nix flakes (complementary to mise for pinned environments)
