# Bootstrap Mode

Scaffolds the incident-workflow in a new repo. **Idempotent**: detects existing files and skips them.

## Pre-flight check

Before writing anything:

1. Is this a git repo? (`git rev-parse --is-inside-work-tree`). If no, ask the user whether to proceed (some repos aren't git-tracked).
2. Does `<incidents_path>/` exist? (default check: `docs/incidents/`)
3. Does `<incidents_path>/README.md` exist?
4. Does `<incidents_path>/_TEMPLATE.md` exist OR a `template_path` pointing at the skill's canonical template?
5. Does `.claude/incident-config.md` exist?
6. Does the repo's `CLAUDE.md` (or `AGENTS.md` / `GEMINI.md`) have an "Incident reports (binding)" section?
7. Does the repo have an `INDEX.md` (or equivalent agent-priming file)? If yes, does it have a row for incidents?
8. Does the repo have a `HANDOFF.md`? If yes, does it acknowledge the incident workflow exists?

If ALL exist, announce "repo already bootstrapped" and skip to a dry-run report (what the skill would change vs what's already there). Useful for migration audits.

If any are missing, proceed to create only the missing pieces.

## Ask the user (one batched question)

Before creating files:

> Setting up the incident workflow for this repo. A few config questions:
>
> 1. **Visibility**: is this repo `private` (full forensic detail OK) or `public` (must sanitize internal IPs, account IDs, error stack traces)? Default: `private`.
> 2. **Layout**: where should incidents live? Default: `docs/incidents/`. Other common picks: `documentation/incidents/`, flat `incidents/`. Some repos with no `docs/` folder use `notes/incidents/`.
> 3. **CLAUDE.md exists?**: confirm whether to append the binding section to existing `CLAUDE.md`, create a new one, or skip (some repos use `AGENTS.md` or no agent-instructions file at all).
> 4. **Existing INDEX.md or equivalent?**: should I add a row, or is this repo's structure flat?
> 5. **HANDOFF.md exists?**: skill writes a one-line note to its session-protocol section if found.
>
> If you say "use defaults", I'll assume: private, `docs/incidents/`, append to existing `CLAUDE.md` if present, add row to `INDEX.md` if present, note to `HANDOFF.md` if present.

If user opts for non-defaults, capture in `.claude/incident-config.md`.

## Files to create

### 1. `<incidents_path>/README.md` - the index + workflow surface

Copy from `templates/README-index.md`. Substitute placeholders:

- `{{REPO_NAME}}` - inferred from `git remote get-url origin` or repo dir name
- `{{INCIDENTS_PATH}}` - the chosen layout path
- `{{VISIBILITY}}` - `private` / `public`
- `{{TEMPLATE_PATH}}` - either local `_TEMPLATE.md` or `skill:incident-workflow/templates/_TEMPLATE-{{VISIBILITY}}.md`
- `{{CROSS_REF_TARGETS}}` - the list of files this repo expects to cross-reference (HANDOFF.md, INDEX.md, etc.)

### 2. `<incidents_path>/_TEMPLATE.md` - the per-incident template

Two variants:
- **Private**: `templates/_TEMPLATE-private.md` (full detail, hashes/IPs OK)
- **Public**: `templates/_TEMPLATE-public.md` (sanitization-first; explicit "do NOT include..." callouts)

Copy the matching variant. Or skip the local copy and point `template_path` at the skill's canonical version (preferred for repos that want to inherit upstream changes).

### 3. `.claude/incident-config.md` - per-repo config

```markdown
---
skill: incident-workflow
skill_version: 0.1.0
bootstrapped: YYYY-MM-DD
---

# Incident workflow config (per-repo)

- **repo_visibility**: {{VISIBILITY}}
- **incidents_path**: {{INCIDENTS_PATH}}
- **template_path**: {{TEMPLATE_PATH}}
- **severity_ladder**: default (P0..P3)
- **cross_ref_targets**: {{CROSS_REF_TARGETS}}

## Bootstrap notes

- Scaffolded by the `incident-workflow` skill on YYYY-MM-DD.
- Bump `skill_version` + re-read `~/.claude/skills/incident-workflow/SKILL.md` after upstream changes.
```

### 4. CLAUDE.md (or AGENTS.md / GEMINI.md) binding section

Copy from one of:
- `templates/claude-md-section-private.md`
- `templates/claude-md-section-public.md`

Append at a sensible point in the file (after any existing "Tool evaluation" / similar workflow section, before "Secrets" rules if present).

If no agent-instructions file exists in the repo, ask the user whether to create one.

### 5. INDEX.md row (if INDEX.md exists)

Append:

```markdown
| Incident reports | `{{INCIDENTS_PATH}}` | Forensic post-mortems for real defects. Trigger rule + workflow defined in `CLAUDE.md` §"Incident reports (binding)". Index at `{{INCIDENTS_PATH}}README.md`. |
```

Plus FAQ rows in the "Where to find things" section if one exists:

```markdown
| "What incidents have we investigated before?" | `{{INCIDENTS_PATH}}README.md` index table |
| "How do I file an incident report?" | `CLAUDE.md` §"Incident reports (binding)" |
```

### 6. HANDOFF.md note (if HANDOFF.md exists)

Append a one-liner to the "Last session" or update protocol section:

```markdown
- Incident workflow installed via `incident-workflow` skill on YYYY-MM-DD. See `.claude/incident-config.md`.
```

Don't rewrite existing HANDOFF content. Just ensure the workflow is acknowledged.

## After bootstrap

Print a summary:

```
Bootstrapped incident-workflow in <repo>:
  ✓ Created <incidents_path>/README.md
  ✓ Created <incidents_path>/_TEMPLATE.md  (variant: private)
  ✓ Created .claude/incident-config.md
  ✓ Appended "Incident reports (binding)" section to CLAUDE.md
  ✓ Added incidents row to INDEX.md
  ✓ Noted skill install in HANDOFF.md
  ⏭  Skipped: <anything that already existed>

Next: when a defect investigation crosses the trigger rule, run the skill in
file mode (or just invoke as a subagent during the investigation).
```

## Idempotency rules

- **Never overwrite** an existing file without asking. Always check `[ -f ]` first.
- **Append-only** for shared files (CLAUDE.md, INDEX.md, HANDOFF.md). Detect "already has the section" by grepping for the section header; if present, skip.
- **Dry-run mode**: `bootstrap --dry-run` shows the diff without writing. Use this when re-running on a partially-bootstrapped repo to see what would change.
- **Migration mode**: `bootstrap --migrate` updates per-repo files to a newer skill version. Bumps `skill_version` in `.claude/incident-config.md`. Asks before overwriting.

## Failure modes

- **Repo has a non-standard layout** (e.g. monorepo with sub-repos): the skill scaffolds at the cwd, not the git root. User can re-run in a sub-folder.
- **Repo uses a different agent-instructions file** (`AGENTS.md`, `GEMINI.md`): bootstrap detects which exists and offers to inject there instead.
- **Repo is public but private-template was chosen**: bootstrap warns. Public repos should default to `-public.md` template variant.
- **CLAUDE.md is huge / structured**: bootstrap appends the section near the end with a clear `## Incident reports (binding)` heading. Owner can move it later.
