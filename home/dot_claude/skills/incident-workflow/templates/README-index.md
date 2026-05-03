---
doc: incidents-index
last_updated: YYYY-MM-DD
purpose: Forensic record of investigations into real defects in {{REPO_NAME}}. Captures the diagnostic trail (commands, hypotheses, evidence) that ADRs and SPECs do not.
visibility: {{VISIBILITY}}
---

# Incident reports

Per-incident forensic memos. One file per incident; the body is the diagnostic trail. SPECs own designs, ADRs own decisions, this folder owns **what was observed and ruled out** during a real failure.

## Why this folder exists

ADRs capture *what we decided*. SPECs capture *what we built*. Neither captures *what we observed and ruled out* during investigation. That diagnostic trail is the highest-leverage knowledge generated during incidents and currently evaporates when chat transcripts compress. This folder fixes that.

Workflow: `incident-workflow` skill (canonical at `~/.claude/skills/incident-workflow/`).

## When to file (trigger rule)

File an incident report if **any** of:

1. A monitoring CRIT alert fires that is **not** a known artifact (deploy debris, expected one-off).
2. A diagnostic session runs **>5 commands** chasing a real defect.
3. A user-visible service degradation occurs.
4. A near-miss: a guardrail caught a defect AND the underlying cause is still in the code.

Do **not** file for: operational toil, pre-merge test failures, owner-side blockers, routine deploys (the prior incident's report owns the fix).

When in doubt, file. A noisy folder is far less expensive than a missing diagnosis.

## Severity ladder

| Level | Definition |
|---|---|
| P0 | Funds at risk OR live operation blocked OR data loss |
| P1 | Monitoring blind OR alerts unreliable |
| P2 | Degraded surface, no funds risk |
| P3 | Cosmetic / informational |

Set at filing based on observed impact. If severity rises during investigation, update both frontmatter AND timeline row noting the re-grade.

## File layout

```
{{INCIDENTS_PATH}}
├── README.md                                  (this file)
├── _TEMPLATE.md  OR  pointer to skill         (use this when filing)
└── YYYY-MM-DD-<short-slug>.md                 (one per incident)
```

Slug rules: kebab-case, 2-5 words, describes mechanism if known else symptom. ID `INC-NNN` lives in frontmatter only (filename stays human-readable).

## Lifecycle

| Phase | Status | Owner action |
|---|---|---|
| Investigation in progress | `status: open` | Fill TL;DR + Timeline + Symptoms + Diagnostic steps as you go. Mark Fix sections `[in progress]`. |
| Fix landed | `status: open` (still) | Fill Fixes applied table + Lessons. Open follow-ups can be H-NN items. |
| All follow-ups closed | `status: closed` | Bump `last_updated`, mark closed. Add a row to the index below. |

An open incident is a debt. Closed incidents are reference. Don't delete.

## Cross-reference rules (hard)

- HANDOFF.md `## Last session` entry **must** link the incident report when one was filed that session.
- SPECs / ADRs created out of an incident **must** have a `## References` line back to it.
- New `H-NN` items **must** reference the incident in description (e.g. `H-46 (filed via INC-001) ...`).
- The incident's own `## References` section closes the loop.

Repos that don't use HANDOFF / INDEX / SPECs / ADRs skip the inapplicable rules.

## Privacy

Visibility: **{{VISIBILITY}}**.

{{PRIVACY_NOTE}}

## Index

| ID | Date | Slug | Severity | Status | Components | Related |
|---|---|---|---|---|---|---|
| _none yet_ | | | | | | |

## See also

- `_TEMPLATE.md` (or `template_path` in `.claude/incident-config.md`) - copy when filing
- `~/.claude/skills/incident-workflow/WORKFLOW.md` - canonical filing procedure
- `~/.claude/skills/incident-workflow/references/privacy-gate.md` - sanitization checklist
