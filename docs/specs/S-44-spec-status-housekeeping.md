---
id: S-44
title: Spec status frontmatter discipline + tasks.md as rolling index
type: chore
status: done
date: 2026-04-23
---

# S-44: Spec status frontmatter discipline + tasks.md as rolling index

## Problem

The `docs/specs/S-*.md` files each declare a `status` field in their
frontmatter (`proposed`, `planned`, `done`). On audit of the current
repo, five specs that have clearly shipped (verifiable via `git log`
and feature presence in the codebase) still carry `status: proposed`:

- S-36 (guardrails-as-managed-installer), shipped in PR #40
- S-37 (guardrails-upstream-release-notify), shipped in PR #41
- S-38 (ssh-key-backup), shipped in PR #44
- S-39 (dotfiles-backup-fixes), shipped in PR #46
- S-41 (ssh-status-in-doctor), shipped in PR #47

Separately, `docs/tasks.md` carries a "Updated: 2026-04-14" header and
does not list S-35 through S-43 at all. It silently misleads any
reader or LLM trying to understand "what's done and what's next."

The root cause is procedural: the SDD flow (spec -> impl -> verify ->
commit -> PR -> merge) had no step for "flip status to done and update
the index." So the frontmatter and tasks.md drifted from reality
every time a spec shipped.

S-32 (claude-assisted-sync) is a sixth case of the same drift, just
with `status: planned` instead of `status: proposed`. The fix treats
both values identically when the spec has shipped.

## Non-goals

- Retroactively auditing commit messages for older specs whose status
  was authored correctly. Only flip statuses where the evidence is
  unambiguous (merged PR referencing the spec ID).
- Auto-generating tasks.md from spec frontmatter. A script could do this
  but is out of scope; a small manual refresh is fine for now.
- Backfilling a missing S-40. The number is a gap with no history; it
  stays a gap, documented as intentionally unused.

## Solution

Two parts. The first is a one-time fix; the second is a standing rule.

### A. One-time fix (this PR)

1. Flip `status: proposed` -> `status: done` on the five shipped specs
   listed above. Flip S-32's `status: planned` -> `status: done` on
   the same basis. Nothing else in those files changes.
2. Refresh `docs/tasks.md`:
   - Update the header date.
   - Move S-24 through S-34 entries from "Next up" to "Completed" where
     they have shipped (S-25, S-28, S-30, S-31, S-32 per spec status).
   - Add entries for S-35 through S-44 in the appropriate section.
   - Add a one-liner under S-40: intentionally unused, no spec exists.
3. Add an entry to `docs/sync-log.md` documenting this cleanup on
   Hans Air M4.

### B. Standing rule (going forward)

When shipping a spec, the "done" state includes:

1. The spec's frontmatter `status` field is set to `done`.
2. `docs/tasks.md` is updated to reflect the shipped state (tick the
   checkbox, move to Completed section if needed).
3. `docs/sync-log.md` has a hostname-tagged entry with the spec ID.

This is already the de-facto pattern for (3) but was skipped for (1)
and (2) on S-35 through S-43. Going forward, treat all three as part
of a single ship, not optional post-work.

## Architecture decisions recorded

1. **Status frontmatter is the source of truth, tasks.md is the index.**
   A reader who wants authoritative status checks the spec file. A
   reader who wants a map checks tasks.md. Keeping them in sync is a
   ship obligation, not an audit obligation.
2. **Do not write a spec generator yet.** The five-spec drift is small
   enough to fix by hand. Automating index generation is worth doing
   only if the drift recurs; then it becomes its own spec (S-45+).
3. **Skipped spec numbers stay as gaps.** S-40 is documented as
   intentionally unused rather than reassigned. Renumbering breaks
   external references (PRs, commits, sync-log entries, chat history).
4. **No status-check lint in CI.** Adding a GitHub Action that fails
   the build when a merged spec still reads `proposed` is plausible but
   overkill for a personal dotfiles repo. Rely on the standing rule in
   this spec plus the sync log as the audit trail.

## Files changed

**New:**
- `docs/specs/S-44-spec-status-housekeeping.md`: this spec

**Modified (status frontmatter only):**
- `docs/specs/S-32-claude-assisted-sync.md` (`planned` -> `done`)
- `docs/specs/S-36-guardrails-as-managed-installer.md` (`proposed` -> `done`)
- `docs/specs/S-37-guardrails-upstream-release-notify.md` (`proposed` -> `done`)
- `docs/specs/S-38-ssh-key-backup.md` (`proposed` -> `done`)
- `docs/specs/S-39-dotfiles-backup-fixes.md` (`proposed` -> `done`)
- `docs/specs/S-41-ssh-status-in-doctor.md` (`proposed` -> `done`)

**Modified (content refresh):**
- `docs/tasks.md`: header date + S-24..S-44 reconciliation + S-40 gap note
- `docs/sync-log.md`: hostname-tagged entry

**Not changed:**
- Any source code, templates, scripts, or chezmoi state
- Any runtime behavior

## Rollout notes

- Zero runtime change. No `chezmoi apply` needed on any machine.
- Any tooling or LLM that reads spec frontmatter for authoritative
  status now gets truthful values.
- Future spec PRs should include the frontmatter flip and tasks.md tick
  as part of the implementation, not as a follow-up.

## Testing

```bash
# 1. Verify no stale "proposed" status remain on shipped specs.
rg '^status: proposed' docs/specs/
# Expected: only specs that genuinely have not been implemented

# 2. Spec files still parse as valid frontmatter.
for f in docs/specs/S-*.md; do
  head -1 "$f" | grep -q '^---$' || echo "BAD: $f"
done

# 3. tasks.md has no references to dropped specs.
grep -E 'S-[0-9]+' docs/tasks.md | grep -E 'S-4[0-4]'
```

## What's explicitly NOT supported

- Automatic sync between spec frontmatter and tasks.md. Both are hand-edited.
- Historical revisionism. Specs that were genuinely in `proposed` state
  at some point keep that history; we only flip the current value when
  the spec has shipped.
- A migration check that fires on every `chezmoi apply`. Status hygiene
  is a repo-maintainer concern, not a per-machine concern.
