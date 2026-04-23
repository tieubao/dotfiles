---
id: S-41
title: Surface SSH key backup status in dotfiles doctor
type: feature
status: done
date: 2026-04-23
depends_on: S-38
---

# S-41: Surface SSH key backup status in `dotfiles doctor`

## Problem

S-38 added `dotfiles ssh audit` as a dedicated subcommand for inspecting SSH key inventory and 1Password backup coverage. It does its job, but it's behind a separate command most users won't think to run unless they already suspect a problem.

`dotfiles doctor` is the opposite: it's the command the user runs as a reflex health check. It already covers chezmoi source linkage, shell defaults, Homebrew, 1Password CLI, SSH agent socket, git identity, toolchain binaries, age key presence, drift count, and `.local` pattern integrity. The SSH-key posture is conspicuously missing from that list even though:

- S-38 made "disk keys without 1P backup" a measurable, automatable check.
- The user runs `doctor` frequently; the dedicated audit rarely.
- A missing 1P backup for a disk key is exactly the kind of slow-moving regression that a health check is supposed to catch.

Right now there's nothing in doctor that would flag "you added a new SSH key to `~/.ssh` last week and forgot to adopt it" until the user happens to run a sync or think about SSH keys explicitly.

## Non-goals

- **Replacing `dotfiles ssh audit`.** Audit is the detailed, multi-section view. Doctor gets a one-line summary. Running audit remains the correct action when the summary flags something.
- **Triggering adoption from doctor.** Adoption is interactive and requires a 1P session plus a desktop GUI. Doctor stays non-interactive and read-only, matching every other check in its body.
- **Auditing keys held only in the SSH agent.** Agent-resident keys without on-disk or 1P counterparts are fine by design (1P-only keys sit in the agent). Doctor cares about the disk-no-1P gap specifically.
- **New output format or styling for doctor.** Reuse the existing `[ok]` / `[!!]` / `[--]` convention.
- **Caching audit output across invocations.** Doctor should produce fresh results each run. If the audit call costs a few 1P API requests, so be it; users run doctor infrequently relative to the freshness benefit.

## Solution

Insert one inline block in `home/dot_config/fish/functions/dotfiles.fish` inside `case doctor`, placed after the existing 1P SSH agent socket check and before the config-files existence loop. The block calls `dotfiles ssh audit` once, captures its output, parses the summary line, and emits exactly one doctor-style status line.

### Behavior matrix

| Environment state | `[ok]` / `[!!]` / `[--]` | Message |
|---|---|---|
| `op` not installed | `[--]` | `SSH key backup status: op CLI not available (optional)` |
| `op` installed, not signed in | `[--]` | `SSH key backup status: op not signed in (run: op signin)` |
| No disk keys at all | `[ok]` | `SSH keys: none on disk (any in-use keys served by 1P agent)` |
| All N disk keys have 1P counterparts | `[ok]` | `SSH keys: N on disk, all backed up to 1P` |
| M of N disk keys lack 1P backup | `[!!]` | `SSH keys: M of N disk key(s) lack 1P backup (run: dotfiles ssh adopt)` |

Only the last row increments `$issues`. Everything else is informational.

### Parsing contract

`dotfiles ssh audit` emits one of two summary lines in its fourth section:

```
  ✓ all N disk key(s) have a 1P counterpart
  ⚠ M of N disk key(s) have no 1P backup
```

or, when there are no disk keys:

```
  (no disk keys to back up)
```

Doctor greps for each of these three patterns. If no match at all (e.g. `op` unreachable), it emits the `op` state message.

### Implementation shape (reference, not the canonical source)

```fish
# inserted after the "1Password SSH agent socket" check
if not command -q op
    echo "[--] SSH key backup status: op CLI not available (optional)"
else if not op account list &>/dev/null
    echo "[--] SSH key backup status: op not signed in (run: op signin)"
else
    set -l audit_out (dotfiles ssh audit 2>/dev/null)
    set -l none_line (echo $audit_out | grep -oE 'no disk keys to back up' | head -1)
    set -l all_ok_line (echo $audit_out | grep -oE 'all [0-9]+ disk key\(s\) have a 1P counterpart' | head -1)
    set -l gap_line (echo $audit_out | grep -oE '[0-9]+ of [0-9]+ disk key\(s\) have no 1P backup' | head -1)
    if test -n "$none_line"
        echo "[ok] SSH keys: none on disk (any in-use keys served by 1P agent)"
    else if test -n "$all_ok_line"
        set -l n (echo $all_ok_line | awk '{print $2}')
        echo "[ok] SSH keys: $n on disk, all backed up to 1P"
    else if test -n "$gap_line"
        set -l m (echo $gap_line | awk '{print $1}')
        set -l n (echo $gap_line | awk '{print $3}')
        echo "[!!] SSH keys: $m of $n disk key(s) lack 1P backup (run: dotfiles ssh adopt)"
        set issues (math $issues + 1)
    else
        # audit produced no recognisable summary; don't block doctor
        echo "[--] SSH key backup status: audit produced no summary"
    end
end
```

The block is self-contained; no new helper functions, no changes to `dotfiles ssh audit` itself.

## Rules

- **Doctor stays read-only.** No clipboard writes, no 1P item creation, no filesystem changes. Exactly the same guarantees the other checks provide.
- **Silent degradation when `op` is not usable.** `[--]` is the signal for "optional, skipped." Never let an offline 1P environment break doctor's exit code.
- **Gap-only gets counted as an issue.** Having no disk keys is fine. Plaintext disk keys already backed up are fine. Only the "disk key with no 1P counterpart" case is a real problem.
- **Parsing keys off the `dotfiles ssh audit` summary, not reimplementing the logic.** If the audit summary format changes later, doctor is updated in the same PR. Don't duplicate the fingerprint-match logic inside doctor.
- **No change to audit's output.** S-41 is purely consumer-side.

## Files to create or modify

| File | Change |
|---|---|
| `docs/specs/S-41-ssh-status-in-doctor.md` | This spec (new) |
| `home/dot_config/fish/functions/dotfiles.fish` | Insert the inline SSH check inside `case doctor` after the SSH agent socket check |

## Test

1. **Happy path, all adopted.** Run `dotfiles doctor` on this machine with the current state (2 disk keys, both in 1P). Expect one new line: `[ok] SSH keys: 2 on disk, all backed up to 1P`. Doctor's total `$issues` count unchanged.
2. **Gap case (synthetic).** Temporarily create `~/.ssh/id_ed25519_test` (no 1P counterpart). Re-run doctor. Expect `[!!] SSH keys: 1 of 3 disk key(s) lack 1P backup (run: dotfiles ssh adopt)`. `$issues` incremented by 1. Remove the test key after. (This test is manual and optional; the parsing is the same path as `/dotfiles-sync` already uses.)
3. **No-op path.** `op signout`; run doctor. Expect `[--] SSH key backup status: op not signed in (run: op signin)`. `$issues` unchanged. `op signin` to restore.
4. **Zero-disk-keys path.** Not reproducible on this machine without moving keys aside; covered by the `none_line` branch. Verify the grep pattern by inspection against the audit function's emitted string.
5. **Standard verification.**
   - `fish -n home/dot_config/fish/functions/dotfiles.fish` passes
   - `chezmoi apply --dry-run` reports only pre-existing warnings
   - `verify-dotfiles` subagent green (5/5)

## Out of this spec

- Any change to `dotfiles ssh audit` or the shared `__dotfiles_op_vault` helper.
- Flagging plaintext-on-disk keys in doctor. That's a rotation decision the user makes consciously (e.g. `id_rsa` is plaintext on purpose during the observation window); doctor shouldn't nag about it.
- Integrating the same check into any non-doctor surface. `/dotfiles-sync` already surfaces the same information; no other sync point needs it.
- Timing or caching optimizations. The audit call takes one op API roundtrip per SSH Key item. That's acceptable for a health check invoked by hand.
