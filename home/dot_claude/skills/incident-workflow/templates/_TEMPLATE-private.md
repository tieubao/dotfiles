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
---

# INC-NNN - <short title, lowercase except proper nouns>

## TL;DR

One paragraph. What broke, what caused it, what fixed it. A reader who skims only this should grasp the incident in 30 seconds.

## ELI5 (required for P0/P1, optional below)

Plain-language narrative with analogies, for a reader cold on this subsystem. TL;DR is for skimmers who already know the stack; ELI5 is for future-you returning after a year, or a non-engineer reading the post-mortem. Target 150-300 words. Lead with an analogy, name the mechanism in everyday terms, state the consequence (not the error code), end with the fix in one sentence. Write while the analogies are fresh (near root cause), not weeks later. Skip for P2/P3 unless the incident touches something owner-facing.

## Timeline

All timestamps in `epoch | UTC | local-tz` for grep + cross-reference. (Adjust the local-tz column header to your tz; ICT, PT, UTC-only, etc.)

| Epoch | UTC | Local | Event |
|---|---|---|---|
| <epoch> | YYYY-MM-DDTHH:MM | YYYY-MM-DDTHH:MM | First symptom observed |
| ... | ... | ... | ... |

## Symptoms (what triggered the look)

Concrete observable signals: alert text, dashboard numbers, error messages, screenshots only when they carry irreplaceable detail. Don't paste full log dumps; link to file or commit.

## Diagnostic steps

Reverse-chronological narrative. Each step shows the command run, the relevant slice of output, and the inference drawn.

> **Privacy** (private repo): full forensic detail OK. HMAC hashes, account IDs, internal IPs, file paths, error codes all fine. **Still forbidden**: raw API keys (their hash is fine), 1Password URIs containing credentials, seed phrases, recovery codes.

### Hypothesis 1 (later falsified) - <name>

- Why suspected: <reasoning>
- How tested: <command + output>
- Outcome: ruled out because <evidence>

### Hypothesis 2 (confirmed) - <name>

- Why suspected: <reasoning>
- How tested: <command + output>
- Outcome: confirmed via <evidence>

### Smoking-gun evidence

The single piece of data that locked the diagnosis. Pin it explicitly so future-you (or the next on-call) can replicate the check.

## Root cause

One paragraph. The mechanism, not the trigger.

(Trigger: yesterday's deploy. Mechanism: agent buffer-flush ↔ rate-limit interaction.)

## Fix(es) applied

| Layer | Change | Where | PR / commit |
|---|---|---|---|
| code | <one line> | `path/to/file:LINE` | `#NN` / `<sha>` |
| ops | <one line> | manual ssh + cmd | (no commit) |
| spec | new SPEC-NNN | `docs/specs/...` | `#NN` |
| adr | D-NNN..D-NNN | `docs/decisions.md` | `#NN` |

## Follow-ups filed

- [ ] **H-NN** <description, with link to incident> - <owner | agent>
- [ ] ...

## Lessons

What changes about how we work going forward? Concrete process or code shifts; not "be more careful".

- <e.g. add a smoke test that pins the cron-tick budget>
- <e.g. file an incident report any time the buffer ever fills>

## References

- `docs/specs/SPEC-NNN-...md` - the design that owns the fix
- `docs/decisions.md#D-NNN` - the rationale entries
- HANDOFF "Last session" entry: <date>
- PR <#NN>
