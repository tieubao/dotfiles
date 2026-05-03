## Incident reports (binding)

When investigating a real defect, **file a report** in `{{INCIDENTS_PATH}}`. The report captures the diagnostic trail (commands, hypotheses, evidence) that ADRs and SPECs do not. Future-me re-debugging the same class of issue should be able to reconstruct what we observed and ruled out, not just what we ultimately decided.

Workflow + canonical template: `~/.claude/skills/incident-workflow/` (skill: `incident-workflow`).

### Trigger rule

File an incident report when **any** of:

1. A monitoring CRIT alert fires that is **not** a known artifact (deploy debris, expected one-off).
2. A diagnostic session runs **>5 commands** chasing a real defect.
3. A user-visible service degradation occurs.
4. A near-miss: a guardrail caught a defect AND the underlying cause is still in the code.

Do **not** file for: operational toil, pre-merge test failures, owner-side blockers waiting on credentials, routine deploys (the prior incident report owns the fix).

### Cross-reference rules (hard)

- HANDOFF.md "Last session" entry **must** link the incident report when one was filed that session.
- SPECs / ADRs created out of an incident **must** have a `## References` line back to it.
- New `H-NN` items **must** reference the incident in their description (e.g. `H-46 (filed via INC-001) ...`).
- The incident's own `## References` section closes the loop.

(Repos that don't use HANDOFF / SPECs / ADRs skip the inapplicable rules.)

### Privacy

This repo is **private**. Full forensic detail is allowed: command outputs with HMAC hashes, account IDs, broker error codes, internal IPs. **Still forbidden** per the project's secrets rule: raw API keys, raw HMAC values (their hash is fine), 1Password URIs containing credentials, seed phrases. Sanitized post-mortems with reusable lessons can publish to public TIL repos under their privacy gate; default is private only.

### Why this exists

ADRs capture *what we decided*. SPECs capture *what we built*. Neither captures *what we observed and ruled out*. That diagnostic trail is the highest-leverage knowledge generated during incidents and currently evaporates when chat transcripts compress. Full reasoning + format definition: `{{INCIDENTS_PATH}}README.md` and the `incident-workflow` skill.
