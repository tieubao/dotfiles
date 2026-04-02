# Task Backlog: tieubao/dotfiles

Updated: 2026-04-02

## Completed (v0.1.0)

- [x] F-01: Idempotent install.sh (--check, --force, exit codes, post-verify)
- [x] F-02: CI smoke test (shellcheck + chezmoi dry-run on macOS, weekly schedule)
- [x] F-05: Fish dotfiles CLI (9 subcommands: edit, diff, sync, status, cd, refresh, add, doctor, encrypt-setup)
- [x] F-06: Fish completions for custom functions (8 completion files)
- [x] F-07: Drift detection (dotfiles-drift function)
- [x] F-08: SSH config hardening (1Password agent, IdentitiesOnly, config.d/)
- [x] F-09: Age encryption (dotfiles encrypt-setup guided command)
- [x] F-10: Ghostty image rendering (render-img with chafa + kitty protocol)
- [x] F-11: Decision records (5 ADRs in docs/decisions/)
- [x] R-03: Slim secrets.fish.tmpl from 43 to 26 lines
- [x] R-05: Fish naming consistency (op_env -> op-env, etc.)
- [x] R-06: VS Code extension sync (skip already-installed)
- [x] R-08: tmux config (C-a prefix, vim nav, fzf picker, project launcher)
- [x] R-09: Consolidate toolchain scripts into install-toolchains.sh

## Completed (v0.2.0)

- [x] T-02: Bootstrap-without-git one-liner in README (already existed)
- [x] T-03: Clean up stale docs (session_state.md, tasks.md updated)
- [x] T-04: Starship prompt (Brewfile + starship.toml + Fish init + doctor check)
- [x] T-05: Brewfile split (base/dev/apps layers via chezmoi template + headless prompt)
- [x] T-07: `dotfiles update` subcommand (git pull --ff-only + chezmoi apply)
- [x] T-08: `dotfiles bench` subcommand (10-run startup benchmark with rating)
- [x] T-09: Drift check wired into config.fish (once-per-day, already existed)

## Remaining

- [ ] T-01: Tag v0.1.0 release with GitHub Release and changelog
- [ ] T-06: Aerospace tiling window manager (lightweight i3-like WM for macOS)
- [ ] T-10: `dotfiles backup` subcommand (export chezmoi data to 1Password)
- [ ] T-11: Multi-machine profiles (chezmoi tags for work vs personal vs server)
- [ ] T-12: Per-project Nix flakes (complementary to mise for pinned environments)
