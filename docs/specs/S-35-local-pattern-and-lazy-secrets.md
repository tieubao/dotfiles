---
id: S-35
title: Multi-machine core/local pattern + lazy 1Password resolution
type: feature
status: done
date: 2026-04-16
---

# S-35: Multi-machine core/local pattern + lazy 1Password resolution

## Problem

The repo is meant to be shared across multiple Macs, but two design gaps made cross-machine sync painful:

1. **Single-template Brewfile.** `dot_Brewfile.tmpl` was the only place packages could live. Hardware-specific items (`chrysalis`, `lunar`, `monitorcontrol`), deprecated apps (`skype`), and niche tools (`sentencepiece`) ended up in the shared template, forcing every machine to install them. The sync workflow's "do it all" path classified everything as core, exacerbating the pollution. The same issue applied to VS Code extensions, fish functions, and other per-config drift.

2. **1Password popups on every apply.** `secrets.fish.tmpl` used `{{ onepasswordRead "op://..." }}` which resolves at `chezmoi apply` time. Each registered secret triggered a 1Password auth popup -- biometric or password -- every time `chezmoi apply` ran. This coupled infrastructure ops to a human interaction loop.

## Non-goals

- Per-machine overrides for configs without native include support (starship, ghostty, zed). Can be added later as chezmoi template variables if needed.
- Syncing local-file state across machines (by design; `.local` is machine-local).
- Replacing the `onepasswordRead` template function for files where apply-time resolution is required (e.g., `dot_gitconfig.tmpl`, `dot_config/zed/settings.json.tmpl`).

## Solution

Three coordinated changes:

### A. `.local` override files for every config with native include support

| Config | Local file | Include mechanism |
|--------|-----------|-------------------|
| Brew/cask | `~/.Brewfile.local` | Ruby `eval()` at end of `.Brewfile` |
| VS Code | `~/.config/code/extensions.local.txt` | Apply script reads both files |
| Fish | `~/.config/fish/config.local.fish` | `source` at end of `config.fish` |
| Tmux | `~/.config/tmux/tmux.local.conf` | `source-file -q` at end of `tmux.conf` |
| Git | `~/.gitconfig.local` | `[include] path = ...` (pre-existing) |
| SSH | `~/.ssh/config.d/*` | `Include config.d/*` (pre-existing) |

All `.local` paths are in `.chezmoiignore` -- chezmoi will never track them. They are never committed to git.

### B. `dotfiles local` CLI for promote/demote

New subcommand in the `dotfiles` fish function:

```
dotfiles local list                       # show cache status of all .local files
dotfiles local promote <brew|cask|ext> <name>    # local → core, apply, auto-commit
dotfiles local demote  <brew|cask|ext> <name>    # core → local, apply, auto-commit
dotfiles local edit                       # $EDITOR ~/.Brewfile.local
```

Promote uses an anchor-based `awk` insert into `dot_Brewfile.tmpl` (before the `# ── Local overrides` comment). Demote strips the line from the template and appends it to the local file. Dynamic tab completion suggests the exact packages movable in each direction.

### C. Lazy 1Password resolution with Keychain cache

New helper `~/.local/bin/secret-cache-read`:

```
Input:  VAR_NAME, OP_REF
Flow:
  1. Keychain lookup          → hit: echo and exit (silent)
  2. op read OP_REF            → only on miss; triggers 1P popup
  3. security add-generic-password → cache for next time
  4. Echo value
```

Template change in `secrets.fish.tmpl`:

```diff
-set -gx TOKEN "{{ onepasswordRead "op://..." }}"
+set -gx TOKEN ($HOME/.local/bin/secret-cache-read "TOKEN" "op://...")
```

Resolution moved from apply time to shell startup. `chezmoi apply` no longer calls `op`. The first interactive shell on a new machine triggers one popup per registered secret; every shell after is silent.

### D. Verification hooks

- **Hostname-tagged sync log.** Entries now use `## [date] sync @ <hostname>` to make it obvious which machine made which classification decision.
- **`dotfiles doctor` checks.** Three new checks:
  1. `.local` files not tracked by chezmoi
  2. `~/.Brewfile.local` parses as valid Ruby (if present)
  3. No `.local` files ever appeared in git history (`git log --all`)

## Architecture decisions recorded

1. **Keychain over a dotfile cache.** Silent after initial user approval; encrypted at rest by macOS; machine-local by design.
2. **Cache invalidation is manual.** `dotfiles secret refresh VAR` deletes the Keychain entry and immediately re-fetches. Alternative (TTL / sync) adds complexity not worth the cost.
3. **Apply never touches 1Password.** Even the pre-existing `run_before_ab-1password-check.sh` only does `op account list` (a cheap session check), not a secret read. If `op` is not signed in on apply, the user gets a warning; nothing fails.
4. **`.local` files fail open.** Every include mechanism tolerates a missing file (Ruby's `File.exist?` guard, tmux's `source-file -q`, fish's `if test -f`, git's silent skip, ssh's no-match glob). A fresh machine without any `.local` files applies cleanly.
5. **`.local` files are not part of backup/restore.** Intentional: if a machine dies, its machine-specific packages should not be restored on a different machine. The sync log + 1Password references serve as the audit trail.
6. **`onepasswordRead` still used where apply-time resolution is required.** Git config and Zed settings need secrets materialized before tools read them, so lazy eval isn't feasible. These are low-frequency apply triggers and currently few in count.

## Files changed

**New:**
- `home/dot_local/bin/executable_secret-cache-read` -- Keychain-first secret reader
- `docs/specs/S-35-local-pattern-and-lazy-secrets.md` -- this spec
- `docs/testing.md` -- end-to-end test plan

**Modified:**
- `home/dot_Brewfile.tmpl` -- Ruby `eval` sources `.Brewfile.local`; duplicates/renames fixed (`zen`, `gcloud-cli`, `gifski` as formula, `nordvpn` as cask); 12 modern tools added; deprecated `homebrew/bundle` and `homebrew/services` taps removed
- `home/dot_config/fish/config.fish.tmpl` -- sources `config.local.fish`
- `home/dot_config/fish/conf.d/secrets.fish.tmpl` -- lazy resolution via `secret-cache-read`
- `home/dot_config/fish/functions/dotfiles.fish` -- new `local` subcommand; `secret list` shows cache status; new `secret refresh`; 3 new `doctor` checks
- `home/dot_config/fish/completions/dotfiles.fish` -- completions for `local` and `secret refresh`
- `home/dot_config/tmux/tmux.conf` -- `source-file -q` at end
- `home/.chezmoiignore` -- ignore all `.local` paths
- `home/.chezmoiscripts/run_onchange_after_vscode.sh.tmpl` -- install extensions from both core and local lists
- `.claude/commands/dotfiles-sync.md` + `home/dot_claude/commands/dotfiles-sync.md` -- classify prompt; hostname in log; local file reporting
- `CLAUDE.md`, `docs/guide.md` -- doc updates

## What's explicitly NOT supported

- Starship / Ghostty / Zed per-machine overrides. Their config formats have no include mechanism. If this becomes necessary, add a chezmoi template variable (e.g., `.machine_role`) and gate sections accordingly. Not done now because observed drift is near zero.
- Automated secret rotation detection. `refresh` is a manual command; cache does not notice when the 1P value changes.
- Cross-shell secret cache sharing (bash/zsh). The helper works in any POSIX shell; `conf.d/secrets.fish.tmpl` is fish-specific by design.

## Testing

See [docs/testing.md](../testing.md) for exact commands. Summary:

- **Local smoke** (this machine): zero 1P popups on apply; first shell gets one popup per secret; shell after is silent; `doctor` reports all-green.
- **Cross-machine** (Machine B): clone + `install.sh` does not install Machine A's `.local` packages; `/dotfiles-sync` on B detects B's unique packages as new.
- **Round-trip** (A ↔ B via git): promote on A, pull on B, item installs on B.

## Rollout notes

- Existing machines keep working: the first apply after this change deploys the new `secret-cache-read` helper AND updates `secrets.fish`. The rendered `secrets.fish` no longer contains a baked-in secret value -- next shell startup runs `secret-cache-read`, which finds an empty Keychain, calls `op read` once (popup), and caches. Subsequent shells: silent.
- No migration script needed. The cache self-populates on first use.
- To force-clear old baked-in secrets from memory, `exec fish` in active shells.
