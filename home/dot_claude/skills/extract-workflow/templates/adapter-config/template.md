# <skill-name> config (per-repo)

Per-repo adapter for the global `<skill-name>` skill. Lives at `<repo>/.claude/<skill-name>-config.md`. Read by the skill's `WORKFLOW.md` to adapt the global behavior to this repo's conventions.

## Config

```yaml
# Required keys
<key1>: <value>           # what this controls
<key2>: <value>           # what this controls

# Optional keys (omit for skill default)
<key3>: <value>           # default: <skill-default>
```

## Repo-specific rules

[List rules that override or extend the skill's defaults. Examples:
- "Preserve all D-NNN references during compaction (dfoundation convention)."
- "Always include SPEC-NNN cross-refs in commit message (trading convention)."
- "Dollar figures and signed contracts go to `private/`, not the repo root."
]

## File locations

[If the skill expects files at non-default paths, declare them here.]

| File | Path | Purpose |
|---|---|---|
| [file 1] | `<path>` | [purpose] |
| [file 2] | `<path>` | [purpose] |

## Notes

[Anything else the skill needs to know about this repo. Edge cases, sibling skills it should coordinate with, etc.]
