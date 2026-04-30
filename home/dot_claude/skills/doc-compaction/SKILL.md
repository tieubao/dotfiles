---
name: doc-compaction
description: Compact long-form append-only documentation (handoff files, decisions ledgers, similar artifacts) without losing irreplaceable signal. Use when the user asks to "compact", "trim", "shrink", "audit signal density", "make X concise" on a doc that has grown past ~600 lines, or when a file's `purpose:` claim no longer matches reality (it claims "minimal" but takes >60s to scan). Implements a three-bucket triage (DELETE / COMPRESS / ARCHIVE) with anchor-integrity verification before merge.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# /doc-compaction

A skill for compacting append-only documentation files (HANDOFF, decisions ledgers, work logs) when they accumulate past their declared purpose. The default outcome: the active file shrinks to its claimed shape (e.g. "session-resume artifact"), irreplaceable signal moves to per-file archive artifacts, the rest collapses to one-row index entries.

## When to fire

Match on phrases like "compact this doc", "handoff is too long", "make X concise", "the doc is bloated", "audit signal density", or when an agent priming on the file would spend >60 seconds before being able to answer "what's next, what's blocked, where's the last decision". Also: a quantitative trigger fires when an append-only doc crosses ~600 lines or its declared purpose stops matching reality.

Do NOT fire for:
- Per-file artifact directories (specs, incidents, plans) — they're already paginated.
- Date-partitioned logs (trade logs, daily reports) — immutable per partition.
- Live operational state (config files, lockfiles).

## Core rule: three-bucket triage

For each entry / session / row in the file, classify:

| Bucket | Criterion | Outcome |
|---|---|---|
| **DELETE** | Whole entry reconstructable from `git log --grep=<id>` plus the linked artifact (spec, ticket, PR). Pure ship summary, no narrative gain in keeping a one-liner. | Drop entirely. |
| **COMPRESS** | Routine work with stated outcome but no unique judgment call. | One row in `## <Older entries> (compressed)` table: date, what, anchors, optional archive link. |
| **ARCHIVE** | Contains decision rationale, options-triaged paragraphs, blockers tried-and-rejected, owner-side discovery notes (gotchas, environment quirks, security investigations), or meta-pattern lessons. | Move full body to `<archive-dir>/YYYY-MM-DD-<slug>.md` with frontmatter; leave one-row pointer in compressed table. |

### Survival rule for irreplaceable signal

Any entry containing one or more of these gets **archived**, never compressed or deleted:

- Cross-references to incident reports / post-mortems / RCAs.
- Defended or rejected decision IDs (where rationale matters more than outcome).
- Strings: "decision", "lesson", "blocker", "rejected", "discovered", "root cause", "gotcha", "surprise", "investigation".
- Paragraphs starting with `**Investigation**`, `**Discovery**`, `**Options triaged**`, `**Why this matters**`.

When in doubt, archive. Compression is reversible only via the snapshot escape hatch (below); if you compress something that should have been archived and the chat transcript is gone, the signal is lost.

## Workflow (5 steps)

### Step 1 — Snapshot escape hatch

Before any edits, tag the pre-compaction commit:

```bash
git tag pre-compaction-YYYY-MM-DD <main-HEAD-sha>
git push origin pre-compaction-YYYY-MM-DD
```

This is the only honest recovery path if signal loss is found post-merge. The tag is permanent on origin; cost is one ref pointer.

### Step 2 — Create the archive directory

```bash
mkdir -p <archive-dir>          # e.g. docs/handoff-archive/, docs/decisions-archive/
```

Add a one-paragraph `<archive-dir>/README.md`:

```markdown
---
purpose: Archive of <SOURCE-FILE> entries that contain irreplaceable judgment calls (decisions, blockers tried-and-rejected, discovery notes) but have aged past the cross-link horizon. The compressed-row table inside <SOURCE-FILE> is the canonical index for these files.
---

# <Source> archive

Each file is one entry that was originally inline in `<SOURCE-FILE>` and got moved here during the YYYY-MM-DD compaction (snapshot tag: `pre-compaction-YYYY-MM-DD`).

Filenames mirror the per-file artifact convention used elsewhere in this repo: `YYYY-MM-DD-<short-slug>.md`.
```

### Step 3 — Triage every entry

Walk the file from oldest to newest (or newest to oldest, your call — but consistent). For each entry:

1. Read it carefully. Don't speed-read.
2. Apply the three-bucket rule (§Core rule above).
3. Apply the survival rule (§Survival rule above).
4. Bucket assignment: write it down before executing — a per-entry plan beats committing to wrong calls under triage fatigue.

**This is the slow, judgment-heavy part.** A 24-entry triage takes ~90 minutes if done well. Tooling cannot replace this step.

### Step 4 — Execute moves

For each archived entry:

1. Create `<archive-dir>/YYYY-MM-DD-<slug>.md` with frontmatter:
   ```yaml
   ---
   archived_from: <SOURCE-FILE>
   session_date: YYYY-MM-DD
   slug: <kebab-slug>
   references: [<anchor-1>, <anchor-2>, ...]
   ---

   # YYYY-MM-DD — <original heading>

   <body lifted verbatim from source>
   ```
2. Remove the entry's body from `<SOURCE-FILE>`.
3. Add a one-row entry to `## <Older entries> (compressed)` table inside `<SOURCE-FILE>` linking to the archive file.

For each compressed entry:
- Add a one-row entry to the compressed table. Columns: date | one-line outcome | anchors (cross-reference IDs) | archive link (empty for compressed-only entries).

For each deleted entry:
- Drop. Verify by `git log --grep=<id>` that the content is recoverable elsewhere before final removal.

### Step 5 — Verify before merge

Run all three checks:

#### 5.1 Anchor-count integrity (mechanical, ripgrep)

Identify the cross-reference anchor patterns in your repo (typical examples: `SPEC-NNN`, `D-NNN`, `H-NN`, `INC-NNN`, ticket-style `JIRA-1234`, etc.). Then:

```bash
# Pre-compaction baseline (from snapshot tag)
git show pre-compaction-YYYY-MM-DD:<SOURCE-FILE> \
  | rg -ho "<anchor-pattern-regex>" | sort -u > /tmp/anchors-before.txt

# Post-compaction
rg -ho "<anchor-pattern-regex>" <SOURCE-FILE> <archive-dir>/ | sort -u > /tmp/anchors-after.txt

# Diff: anchors lost from the union (must be empty)
comm -23 /tmp/anchors-before.txt /tmp/anchors-after.txt
```

Empty output is the green light. Any line in the diff means an anchor was dropped — find where it should have moved (archive vs decisions ledger vs spec) before merge.

#### 5.2 Irreplaceable-signal spot-check (manual, ~10 min)

For each compressed-row entry, ask: "if I had only `git log` + the cited specs/decisions, could I reconstruct this paragraph?" If no → it belongs in archive, not compressed. Promote and re-test.

#### 5.3 60-second resume test

Cold-read the file's "read order" entry points (e.g. `INDEX.md` → `<SOURCE-FILE>`). Can you answer the file's three primary questions (whatever they are — typically "what's queued", "what's blocked", "where's the most recent decision") in under 60 seconds? That's the file's `purpose:` claim. After compaction, it should actually hold.

## Output

Commit per logical chunk for revertibility:
- Commit 1: archive directory + per-file artifacts.
- Commit 2: source file restructure (compressed table + active section + frontmatter trim).
- Commit 3: any policy-level edits (e.g. updating cross-references).

Open a PR. Body should call out:
- Pre/post line counts of `<SOURCE-FILE>`.
- Anchor-count delta (must be 0 or positive).
- Snapshot tag for revert clarity.

## Notes

- This skill does NOT compact specs, incident reports, plans, or any per-file artifact directory — those are already paginated by design.
- Don't build automation for the triage step. The judgment-heavy read-and-classify is the actual value; tools that bypass it produce wrong calls.
- For very large files (>2000 lines), consider compacting in two passes: first pass is mechanical (delete clearly-recoverable rows, compress routine ship summaries); second pass is the judgment-heavy archive triage on the remaining content.
- This skill's authoritative repo-specific policy lives at the source repo's `docs/specs/` directory if a corresponding SPEC has been written. The skill is the generic, substitution-friendly version. They diverge over time; the SPEC stays trading-canonical, the skill stays generic.
