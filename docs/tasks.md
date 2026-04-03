# Task Backlog: dwarvesf/dotfiles

Updated: 2026-04-02

## Completed (v0.1.0)

- [x] F-01: Idempotent install.sh (--check, --force, exit codes, post-verify)
- [x] F-02: CI smoke test (shellcheck + chezmoi dry-run on macOS, weekly schedule)
- [x] F-05: Fish dotfiles CLI (13 subcommands)
- [x] F-06: Fish completions for custom functions (8 completion files)
- [x] F-07: Drift detection (dotfiles-drift function + daily startup check)
- [x] F-08: SSH config hardening (1Password agent, IdentitiesOnly, config.d/)
- [x] F-09: Age encryption (dotfiles encrypt-setup guided command)
- [x] F-10: Ghostty image rendering (render-img with chafa + kitty protocol)
- [x] F-11: Decision records (5 ADRs in docs/decisions/)
- [x] R-03: Slim secrets.fish.tmpl from 43 to 26 lines
- [x] R-05: Fish naming consistency (op_env -> op-env, etc.)
- [x] R-06: VS Code extension sync (skip already-installed)
- [x] R-08: tmux config (C-a prefix, vim nav, fzf picker, project launcher)
- [x] R-09: Consolidate toolchain scripts into install-toolchains.sh
- [x] T-02: Bootstrap-without-git one-liner in README
- [x] T-03: Clean up stale docs (session_state.md, tasks.md)
- [x] T-04: Starship prompt (Brewfile + starship.toml + Fish init + doctor check)
- [x] T-05: Brewfile split (base/dev/apps layers via chezmoi template + headless prompt)
- [x] T-07: `dotfiles update` subcommand (git pull --ff-only + chezmoi apply)
- [x] T-08: `dotfiles bench` subcommand (10-run startup benchmark with rating)
- [x] T-10: `dotfiles backup` subcommand (1Password upload + local fallback)
- [x] R-11: Error message system (gum-styled output, template guards, apply summary)

## Next up

### R-12: Ghostty config sync

Ghostty config is a plain file (`home/dot_config/ghostty/config`) — no template. This means settings like font, theme, and shell path are hardcoded. Plan:

- [ ] Convert to `.tmpl` if any values need to vary per machine (e.g. font size, theme)
- [ ] Review settings against latest Ghostty docs — config keys may have changed since initial setup
- [ ] Consider whether `command = /opt/homebrew/bin/fish --login` should use a template variable (breaks on Intel Macs where brew is at `/usr/local/bin`)
- [ ] Add Ghostty to `dotfiles doctor` checks (verify binary exists, config is valid)

### R-13: Starship config polish

Starship config (`home/dot_config/starship.toml`) is functional but could be tuned:

- [ ] Review module list — add any missing languages/tools used daily (e.g. `ruby`, `java`, `aws`)
- [ ] Check if `detect_folders`/`detect_env_vars` are optimal for k8s module
- [ ] Consider adding `time` module (useful for long-running sessions)
- [ ] Consider adding `git_metrics` (insertions/deletions) — disabled by default in starship
- [ ] Verify Nerd Font symbols render correctly in Ghostty

### R-14: Brewfile cleanup

Audit `home/dot_Brewfile.tmpl` for stale/redundant entries:

- [ ] Verify `font-sauce-code-pro-nerd-font` vs `font-source-code-pro` — possible duplicate or misname
- [ ] Check commented-out entries (AI tools, Web3 tools) — remove or uncomment
- [ ] Verify all casks still exist in Homebrew (`brew info <name>`)
- [ ] Check for packages installed by both brew and another manager (e.g. `mise` vs brew for language runtimes)
- [ ] Remove any packages no longer used day-to-day
- [ ] Run `brew bundle cleanup --file=~/.Brewfile` to find installed-but-unlisted packages worth adding

## Backlog (no immediate plans)

- [ ] Aerospace tiling window manager (lightweight i3-like WM for macOS)
- [ ] Multi-machine profiles (chezmoi tags for work vs personal vs server)
- [ ] Per-project Nix flakes (complementary to mise for pinned environments)
