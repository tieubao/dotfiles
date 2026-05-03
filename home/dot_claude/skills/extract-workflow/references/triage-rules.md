# Triage rules: when to formalize, when to redirect

Adapted from `superpowers:writing-skills` with workflow-extraction framing.

## Formalize when

- **Cross-project recurrence**: workflow has been done in 2+ repos, OR user explicitly says "I'd want this in repo X too."
- **Three+ manual runs**: pattern is real, not speculation. Three is the floor; more is better.
- **Non-obvious method**: the technique wasn't intuitively obvious — there are rules, gotchas, or judgment calls a fresh-context Claude would miss.
- **Future-self benefit**: user can articulate "next time I want to do this, I shouldn't have to remember [X]."
- **Composable**: workflow can be invoked or auto-fired without the user re-explaining context every time.

## Redirect to CLAUDE.md when

- **Project-specific conventions**: PPSS framework, Dwarves brand, VN tax rules, dfoundation-only file paths. Convention belongs near the project, not in a global skill.
- **One-line guidance**: "always do X before Y" doesn't need a skill. CLAUDE.md is the right home.
- **Config decisions**: "we use opentofu, not terraform." That's tech-stack guidance, lives in CLAUDE.md.

## Redirect to a hook / settings.json when

- **Mechanical constraint enforceable by validation/regex/script**: e.g. "block git push --force to main." Use `update-config` skill to add a hook. Skills are for judgment; hooks are for enforcement.
- **Behavior triggered by tool calls**: pre/post hooks are the right surface.
- **Permissions allowlist**: `update-config` skill plus `fewer-permission-prompts`.

## Reject (skip the formalization)

- **One-off**: solved a specific bug once, won't recur identically.
- **Already covered**: search existing skills first. `superpowers:writing-skills`, `ingest-to-wiki`, `incident-workflow`, etc. may already cover it. Adding a redundant skill fragments the trigger surface.
- **Workflow IS the project**: e.g. "implement this feature." Implementation isn't a workflow, it's the work itself. Skills are for *how you implement*, not the implementing.

## Quick decision flow

```
Is this workflow run 3+ times?
├── No → wait, mark as watch-item
└── Yes
    │
    Is it project-specific in content (not just paths)?
    ├── Yes → CLAUDE.md
    └── No
        │
        Is it enforceable by automation (hook/regex/script)?
        ├── Yes → update-config (hook)
        └── No
            │
            Already covered by an existing skill?
            ├── Yes → reject, point user at existing skill
            └── No → FORMALIZE (proceed to shape decision)
```

## Examples

| Workflow | Decision | Why |
|---|---|---|
| HANDOFF.md compaction (5+ runs in dfoundation) | Formalize as skill | Cross-project pattern (HANDOFF lives in any repo with `_meta/`); judgment-heavy (what to keep vs drop); writing-skills-style rules |
| SDD six-phase ritual (used in dfoundation + trading) | Formalize as skill+command | Already cross-project (literally duplicated); auto-fire on "implement SPEC-NNN" + explicit `/sdd` |
| `npm install` reminder | Reject → CLAUDE.md | One-line guidance, not a workflow |
| Block force-push to main | Reject → update-config (hook) | Mechanical enforcement |
| PPSS weekly consolidation | Reject → keep repo-local | Project-specific framework (dfoundation only) |
| VN contractor invoice generation | Reject → keep repo-local | Tax-jurisdiction-specific |
