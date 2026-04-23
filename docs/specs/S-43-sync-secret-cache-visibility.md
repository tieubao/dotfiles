---
id: S-43
title: Surface registered-but-uncached secrets in /dotfiles-sync and doctor
type: feature
status: done
date: 2026-04-23
---

# S-43: Surface registered-but-uncached secrets in /dotfiles-sync and doctor

## Problem

S-35 introduced the Keychain cache for secrets; S-42 added a service account
token on top of that same machinery. Both rely on the user's first interactive
fish login to trigger `secret-cache-read`, biometric-prompt once per secret,
and populate the Keychain. Until that happens, the env var is empty and any
agent subprocess that needs it fails silently.

The bookkeeping tooling does not surface this transitional state:

1. `/dotfiles-sync` scans brew, casks, extensions, fish functions, SSH
   configs, hardcoded secrets in fish config, guardrails pin, and SSH key
   backup status. It does **not** scan cached-vs-uncached status of the
   registered secrets themselves.
2. `dotfiles doctor` checks whether `op` is installed and signed in. It does
   **not** iterate `secrets.toml` to confirm each registration has a Keychain
   entry or a reachable 1P item.

On a fresh machine that pulls the repo, runs `chezmoi apply`, and opens a
non-interactive shell (ssh, tmux resume, direct VS Code terminal), the user
can go indefinitely without ever triggering the first-shell biometric. They
only find out secrets aren't loaded when an agent call returns 401 or the
`op read` itself hits an empty env var. The failure path teaches nothing and
the tooling that was supposed to surface state lies by omission.

## Non-goals

- Auto-refreshing or auto-warming the cache. Biometric is the human-in-loop
  gate and must remain. The LLM does bookkeeping, the user approves.
- Validating 1P item reachability (`op read` against every registered ref).
  Doing so on every `doctor` run would be slow and would trigger popups on
  Keychain miss, which defeats the purpose.
- Detecting stale / revoked tokens. Revocation shows up as `op read` 401s;
  that is a runtime problem, not a doctor-time problem.
- Adding a new chezmoi script that runs on apply. Apply stays popup-free per
  S-35; this spec adds zero new apply-time code.

## Solution

Two additive, notify-only probes. Zero new state, zero new commands, zero new
interactive flows. Both reuse the existing Keychain lookup that
`dotfiles secret list` already performs.

### A. `/dotfiles-sync` step 2: secret cache probe

New block in the detection phase of `.claude/commands/dotfiles-sync.md`
(and the identical deployed copy `home/dot_claude/commands/dotfiles-sync.md`).
Runs only when `op` is installed **and** signed in, to avoid noise on
headless machines. Silent when all registered secrets are cached.

```bash
### Secret cache status (notify-only)
if command -v op >/dev/null 2>&1 && op account list &>/dev/null; then
  EMPTY=$(fish -l -c 'dotfiles secret list' 2>/dev/null \
            | awk '/^  \[ empty\]/ {print $3}')
  if [ -n "$EMPTY" ]; then
    echo "secrets: registered but not cached:" $EMPTY
    echo "  (first interactive shell will biometric-prompt; run 'exec fish' to trigger now)"
  fi
fi
```

Report category added under the existing "Secrets:" line in the step-3
report format.

### B. `dotfiles doctor`: registered-but-not-cached check

New block in the doctor subcommand of
`home/dot_config/fish/functions/dotfiles.fish`, added after the existing
"SSH key backup status" group. Iterates `secrets.toml`, performs the same
Keychain lookup as `dotfiles secret list`, counts misses:

```fish
set -l data (chezmoi source-path)/.chezmoidata/secrets.toml
if test -f $data
    set -l empty_vars
    for line in (grep -E '^[A-Z_][A-Z0-9_]* = ' $data)
        set -l var (echo $line | awk '{print $1}')
        if not security find-generic-password -a "$USER" -s "$var" -w >/dev/null 2>&1
            set -a empty_vars $var
        end
    end
    if test (count $empty_vars) -eq 0
        echo "[ok] all registered secrets cached in Keychain"
    else
        echo "[--] registered but not cached: "(string join ", " $empty_vars)
        echo "     (first interactive shell triggers 1P popup; or run 'exec fish')"
    end
end
```

Rendered as informational (`[--]`, not `[!!]`) because an empty cache is a
legitimate transient state on fresh machines. Not an error condition.

## Architecture decisions recorded

1. **Notify-only, no side effects.** Matches the pattern of the existing
   SSH-backup and guardrails-upgrade probes. The sync tooling reports; the
   user decides whether to act. Auto-warming the cache at doctor time would
   violate design principle #1 (LLM does bookkeeping, user makes decisions).
2. **Information state only, not reachability.** Probes ask "is the Keychain
   entry present?" not "does `op read` succeed against the ref?". The latter
   requires a live 1P call, which may popup and may be slow; the former is
   local, silent, O(N) in registered secrets.
3. **Reuse the existing `dotfiles secret list` iterator in `/dotfiles-sync`.**
   Parsing its output via `awk` avoids reimplementing the same Keychain probe
   inline in a bash heredoc. `doctor` reimplements it because it already runs
   in the same fish process, so calling itself would be circular.
4. **Gate on `op account list &>/dev/null` in the sync command** to stay
   silent on machines where 1P isn't configured. The doctor check does not
   need this gate because it probes Keychain directly, which works
   independently of op auth state.
5. **Severity level `[--]` not `[!!]`.** An empty cache on a fresh machine is
   expected; reporting it as a failure would produce false alarms during
   bootstrap. The `[--]` channel is the existing "info, no action required
   unless context suggests otherwise" convention, already used for optional
   components like the 1P SSH agent socket.

## Files changed

**New:**
- `docs/specs/S-43-sync-secret-cache-visibility.md`: this spec

**Modified:**
- `.claude/commands/dotfiles-sync.md`: new "Secret cache status" block in
  step 2; new "Secrets:" / "Secret cache" line in the step-3 report format
- `home/dot_claude/commands/dotfiles-sync.md`: identical to the project copy
- `home/dot_config/fish/functions/dotfiles.fish`: new check in the `doctor`
  case, inserted after the SSH key backup block
- `docs/sync-log.md`: hostname-tagged entry

**Not changed (intentionally):**
- `home/dot_local/bin/executable_secret-cache-read`: the probe side is
  purely observational; the load path stays untouched
- `home/dot_config/fish/conf.d/secrets.fish.tmpl`: no change to the loop
- `home/.chezmoidata/secrets.toml`: no new registrations
- Apply scripts in `home/.chezmoiscripts/`: nothing runs at apply time

## Rollout notes

- First `chezmoi apply` after this spec merges deploys the updated fish
  function; the next `dotfiles doctor` call uses the new check. No state
  migration.
- Existing fresh machines running the old doctor continue to work; they just
  lack the visibility this spec adds. Not a regression.
- `/dotfiles-sync` picks up the new block the next time the user runs the
  slash command (after `chezmoi apply` deploys the refreshed
  `home/dot_claude/commands/` copy).

## Testing

```fish
# 1. All-cached path: doctor reports [ok]
dotfiles doctor | grep -A1 'registered secrets'
# Expected: [ok] all registered secrets cached in Keychain

# 2. Empty path (simulate a fresh machine): delete one cache entry
security delete-generic-password -a "$USER" -s "OP_SERVICE_ACCOUNT_TOKEN" >/dev/null 2>&1
dotfiles doctor | grep -A1 'registered'
# Expected: [--] registered but not cached: OP_SERVICE_ACCOUNT_TOKEN

# 3. Re-populate to clean up
dotfiles secret refresh OP_SERVICE_ACCOUNT_TOKEN

# 4. /dotfiles-sync probe: simulate the heredoc
fish -l -c 'dotfiles secret list' | awk '/^  \[ empty\]/ {print $3}'
# Expected: (empty output when all cached)

# 5. Shell lint
fish -n home/dot_config/fish/functions/dotfiles.fish

# 6. Dry run
chezmoi apply --dry-run --force
```

## What's explicitly NOT supported

- Watching for registered secrets added by other machines via git pull. The
  probe is per-machine state; inter-machine drift of which registrations
  exist is already visible via git diff on `secrets.toml`.
- Distinguishing "never cached" from "cache was deleted recently". Both
  render as `[--]`; the user does not need the distinction.
- Alerting on the service account token specifically. The probe is uniform
  across all registrations; `OP_SERVICE_ACCOUNT_TOKEN` is not special.
