# Bootstrap Mode

Scaffolds the ingest workflow in a new repo. Idempotent: detects existing files and skips them.

## Pre-flight check

Before writing anything, check:

1. Is this a git repo? (`git rev-parse --is-inside-work-tree`). If no, ask the user whether to proceed anyway (some repos are not git-tracked).
2. Does `_inbox/` exist?
3. Does `_templates/` exist?
4. Does `ingest/` exist?
5. Does `INGEST_LOG.md` at root exist?
6. Does `docs/ingest/README.md` exist?
7. Does `.claude/ingest-config.md` exist?

If ALL exist, announce "repo already bootstrapped" and skip to a dry-run report (what the skill would do, versus what is already there).

If any are missing, proceed to create only the missing pieces.

## Ask the user

Before creating files, collect per-repo config via one batched question:

> Setting up the ingest workflow for this repo. A few config questions:
>
> 1. **Private location** for PII/sensitive material. Default: `private/` (gitignored). Some repos use `.private/`, `local/`, or a symlink to a cloud drive. What do you want here?
> 2. **Index/freshness file** at root. Default: `STALENESS.md`. Options: keep default, rename, or skip (small repos don't always need one).
> 3. **Domain folders** - which top-level folders in this repo can receive promoted content? (e.g. `people/`, `sales/`, `finance/`, `content/`, `strategy/`). If unsure, I'll infer from what's already here and propose a list.
> 4. **Privacy rule** - one sentence describing what goes to `private_location`. Default: "names real people, real clients, real money, or real contracts → private; everything else stays tracked." Override if your repo has different sensitivity (e.g. trading repos treat positions and strategies as private).

If the user says "use defaults", proceed with defaults and infer `domain_folders` from existing directory structure (any top-level folder that is not `_inbox/`, `_templates/`, `ingest/`, `scripts/`, `docs/`, `.claude/`, `.git`, `archive/`, `scratch/`, or hidden dotfiles).

## Files to create

Create each of these if missing. Use the templates bundled with the skill where applicable.

### 1. `_inbox/README.md`

```markdown
# `_inbox/` - Raw ingest landing zone

Drop any material you want processed here: `.md`, `.docx`, `.pdf`, `.xlsx`, raw text dumps, exports, screenshots.

## How it works

1. You drop files here.
2. You say `ingest inbox` (or similar).
3. The workflow triages each file (promote / summarize / duplicate / skip).
4. Binary files get converted to markdown if promoted.
5. Output lands in the right domain folder (or configured private location).
6. The session is recorded in `INGEST_LOG.md` at repo root.
7. Originals stay here until you confirm they can be cleared.

## Gitignore behaviour

Only this README is tracked. Raw drops are gitignored because pre-triage material may contain sensitive information that has not been classified yet.

## Related

- `docs/ingest/README.md` - full workflow
- `INGEST_LOG.md` - chronological record
```

### 2. `_templates/` - four templates

Copy from the skill's `templates/` directory:
- `ingested-doc.md` - mirror of an external doc
- `sop.md` - standard operating procedure
- `memo.md` - strategic/analytical one-off
- `spec.md` - feature or automation spec

Also create `_templates/README.md` explaining when to use each.

### 3. (optional) `<ingest_path>/.gitkeep`

Only if the user opts into per-session sidecar files (config `ingest_path` set). Subdirectories created on first ingest (e.g. `<ingest_path>/gdrive/<slug>/`). Most repos skip this; `INGEST_LOG.md` alone is enough.

### 4. `INGEST_LOG.md` at root

```markdown
# Ingest Log

Chronological record of ingest sessions. Newest first. One block per session.

For the workflow spec, see `docs/ingest/README.md`.
For per-doc freshness, see `{{index_file}}`.

---

## [{{YYYY-MM-DD}}] bootstrap | Ingest workflow initialised

Scaffolded via the `ingest-to-wiki` skill. Created `_inbox/`, `_templates/`, `docs/ingest/README.md`, and this log.

**Compilation work:**
- `.gitignore` updated to exclude `_inbox/*` (except README).
- `.claude/ingest-config.md` written with per-repo config.

---
```

### 5. `docs/ingest/README.md`

Copy `references/workflow-template.md` from the skill and substitute the per-repo parameters (private location, index file, domain folders).

### 6. `.claude/ingest-config.md`

Write the config collected from the user:

```markdown
# Ingest config

Consumed by the `ingest-to-wiki` skill. Edit freely; the skill re-reads this file on every ingest.

- **private_location**: `{{value}}`
- **index_file**: `{{value}}`
- **log_file**: `INGEST_LOG.md`
- **privacy_rule**: {{value}}
- **domain_folders**: {{comma-separated list}}

## Notes

Any repo-specific conventions that diverge from the skill defaults go here.
```

### 7. `.gitignore` entries

Add if missing:

```
# Inbox is the raw-drop landing zone; contents stay out of git until triaged.
_inbox/*
!_inbox/README.md
```

### 8. CLAUDE.md (or AGENTS.md / GEMINI.md) update

If a `CLAUDE.md` exists at repo root, offer to add (ask first):

```markdown
## Ingest workflow
Canonical spec: `docs/ingest/README.md`. Landing zone: `_inbox/`. Chronological record: `INGEST_LOG.md`. Per-session detail: `ingest/<source>/<slug>/`. Trigger phrases: `ingest inbox`, `ingest <file>`, `ingest this drive folder <URL>`, `re-ingest <slug>`, `compile recent`.
```

If no CLAUDE.md, skip this step.

## Post-bootstrap

After scaffolding, write a one-time `INGEST_LOG.md` entry documenting the bootstrap (already shown above as the first block). Save a short project memory noting where the config lives:

```markdown
---
name: Ingest workflow bootstrapped
description: This repo has the ingest-to-wiki skill scaffolded
type: project
---

Config at `.claude/ingest-config.md`. Workflow at `docs/ingest/README.md`. Bootstrapped on {{date}}.
```

## Dry-run report (when repo is already bootstrapped)

If all expected files exist, compare against the skill defaults and report drift:

- Missing templates? → "You have 3 of 4 expected templates; missing `spec.md`. Want me to add it?"
- Config file drift? → "Config says `private_location: foo` but the repo has `bar/`. Reconcile?"
- Old `scratch/inbox/` convention still referenced anywhere? → Flag as legacy.

Don't auto-fix drift. Report it and ask.
