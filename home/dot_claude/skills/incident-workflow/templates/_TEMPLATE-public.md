---
id: INC-NNN
date: YYYY-MM-DD
duration_min: <wall-clock from first symptom to root cause named>
severity: P0 | P1 | P2 | P3
components: [<system>, <subsystem>]
related_specs: [SPEC-NNN, ...]
related_adrs: [D-NNN, ...]
related_h_items: [H-NN, ...]
pr_links: []
status: open | closed
visibility: public
---

# INC-NNN - <short title, lowercase except proper nouns>

> **Public-repo notice**: this incident report is committed to a public repository. **Sanitize aggressively** before save. The `references/privacy-gate.md` checklist is mandatory for every diagnostic step.

## TL;DR

One paragraph. What broke (mechanism, not specific data), what caused it, what fixed it. Should be readable as a generic engineering post-mortem.

## ELI5 (required for P0/P1, optional below)

Plain-language narrative with analogies, for a reader cold on this subsystem. Target 150-300 words; lead with an analogy, end with the fix in one sentence. Analogies are inherently privacy-safe (a "robot + notebook" doesn't leak an account ID), so this section is usually easier to ship publicly than the forensic Diagnostic steps. Still - scrub specific numbers, vendor names, and owner-shape tells per `references/privacy-gate.md`. Write near root cause while analogies are fresh; skip for P2/P3 unless the incident touches something owner-facing.

## Timeline

`epoch | UTC` only. Public repos drop the local-tz column to avoid leaking owner geography.

| Epoch | UTC | Event |
|---|---|---|
| <epoch> | YYYY-MM-DDTHH:MM | First symptom observed |
| ... | ... | ... |

## Symptoms (what triggered the look)

Generic descriptions of observable signals. **Do not** include:
- Internal IPs, hostnames, account IDs, exchange/broker UIDs
- Exact error stack traces with internal file paths
- Screenshots of internal dashboards (crop or recreate as a generic example)
- Owner-specific phrases ("for my $X account", "on my M4")

Do include:
- Class of signal (alert text shape, dashboard metric type, error category)
- Numbers if they're a generic order-of-magnitude (10× spike, 60% error rate)

## Diagnostic steps

> **Privacy gate** (public repo): every command output gets sanitized. Run the checklist in `~/.claude/skills/incident-workflow/references/privacy-gate.md` before saving.

### Hypothesis 1 (later falsified) - <name>

- Why suspected: <reasoning>
- How tested: <command, sanitized — replace internal URLs with `<internal-host>`, account IDs with `<account-id>`>
- Outcome: ruled out because <evidence, sanitized>

### Hypothesis 2 (confirmed) - <name>

- Why suspected: <reasoning>
- How tested: <command, sanitized>
- Outcome: confirmed via <evidence, sanitized>

### Smoking-gun evidence

The mechanism, expressed generically. Future readers from outside the org should be able to recognize this pattern in their own systems.

## Root cause

One paragraph. Mechanism, not specifics.

## Fix(es) applied

| Layer | Change | Where | PR / commit |
|---|---|---|---|
| code | <one line, generic; OK to link public PRs> | `path/to/file:LINE` | `#NN` |
| spec | new SPEC-NNN | `docs/specs/...` | `#NN` |

## Follow-ups

Generic. List action types, not internal task IDs.

- <e.g. "add CI smoke test for cron-tick budget vs server rate limit">

## Lessons (for the public reader)

The whole reason a public incident report exists. Generic process or design lessons that another team could apply.

- <e.g. "any client-side queue draining a server with rate limits must use status-aware retry, not bool>
- <e.g. "paired constants on client + server must cross-link in code comments"

## References

- Related specs / ADRs / public PRs only.
- Internal tracking IDs (H-NN, OD-NNN) **omitted** — they leak nothing useful to the public reader and reveal internal nomenclature.
