# Shape decision: skill package vs slash command vs both

Three valid shapes for a formalized workflow. Pick deliberately — wrong shape causes friction (false positives if too eager, dead artifact if too obscure).

## Skill package (`~/.claude/skills/<name>/`)

Use when:
- Workflow has a clear *intent* the user expresses naturally ("compress today's HANDOFF").
- Workflow benefits from **auto-fire** on description match — user shouldn't have to remember to type `/foo`.
- Workflow has bootstrap needs (creates files / structures in a fresh repo).
- Workflow has multi-file structure: references, templates, scripts.

Structure (mirrors `ingest-to-wiki`, `incident-workflow`):

```
~/.claude/skills/<name>/
├── SKILL.md         # frontmatter + when-to-activate body. Loaded into every session.
├── BOOTSTRAP.md     # one-time setup for a fresh repo (creates expected files)
├── WORKFLOW.md      # per-run process
├── references/      # heavy reference material (rules, decision matrices)
└── templates/       # output skeletons
```

`BOOTSTRAP.md` is optional — include when the workflow expects a structure (`_meta/HANDOFF.md`, `incidents/`, `_inbox/`) that may not exist in a fresh repo.

## Slash command only (`~/.claude/commands/<name>.md`)

Use when:
- Workflow needs **explicit** invocation. User types `/foo`, no auto-fire.
- Auto-fire would have unacceptable false-positive rate (e.g. words too common).
- Single-file body is enough — no references, no templates.
- No bootstrap; workflow runs against existing repo state without setup.

Structure:

```
~/.claude/commands/<name>.md   # frontmatter optional, body is the prompt
```

## Both — skill + slash command pair

Use when:
- Workflow benefits from auto-fire on natural language (skill side) AND from explicit invocation (command side).
- Some users phrase the trigger naturally ("let's do SDD"), others prefer typing `/sdd` directly.
- Risk of skill auto-fire missing nuanced phrasing — slash command is the safety valve.

Structure: both above. The slash command body is typically a one-liner pointing at the skill: "Invoke the `<name>` skill against the current context."

## Decision flow

```
Does the user want auto-fire on natural language?
├── No (explicit only) → slash command
└── Yes
    │
    Is the trigger language unambiguous enough to avoid false positives?
    ├── No (too common, would mis-fire) → slash command
    └── Yes
        │
        Does the workflow need bootstrap, references, or templates?
        ├── Yes → skill package
        └── No
            │
            Would the user also want explicit `/foo` invocation as a fallback?
            ├── Yes → skill + slash command pair
            └── No → skill package only
```

## Examples

| Workflow | Shape | Why |
|---|---|---|
| `ingest-to-wiki` | Skill package | Auto-fires on "ingest this", has bootstrap, references, templates |
| `incident-workflow` | Skill package | Auto-fires on "let's postmortem", has scripts directory |
| `compress-handoff` | Skill + command | Auto-fires on "compress HANDOFF" but `/compress-handoff` is a clean explicit trigger |
| `sdd` | Skill + command | Auto-fires on "implement SPEC-NNN" + explicit `/sdd` for "let's do this the usual way" |
| `edge-up` | Slash command only | Single launcher action, no auto-trigger ambiguity, no bootstrap |
| `diagram-render` | Slash command only | Explicit "convert this SVG", no auto-fire intent |
| `notion-bulk` | Slash command only | Explicit invocation, has review-before-publish gate that needs explicit user request |

## Anti-patterns

- **Skill with too-eager description**: matches phrasings the user didn't intend. Symptom: skill fires when user mentions HANDOFF in any context. Fix: tighten the trigger language to specific verbs (compress, compact, tighten).
- **Slash command for an intent-driven workflow**: user has to remember the slash command name. Symptom: workflow rarely runs because user forgets it exists. Fix: promote to skill or skill+command pair.
- **Skill body in the description field**: causes Claude to follow description summary instead of reading body. Always check: description = WHEN to use, body = WHAT to do.
