## Incident reports (binding)

When investigating a real defect, **file a report** in `{{INCIDENTS_PATH}}`. Captures the diagnostic trail (commands, hypotheses, evidence) that ADRs and SPECs do not.

Workflow + canonical template: `~/.claude/skills/incident-workflow/` (skill: `incident-workflow`).

### Trigger rule

File when **any** of:
1. CRIT alert that is not a known artifact.
2. Diagnostic session running >5 commands chasing a real defect.
3. User-visible service degradation.
4. Near-miss caught by a guardrail with cause still in code.

Do **not** file for: operational toil, pre-merge test failures, owner-side blockers, routine deploys.

### Cross-references (hard)

- HANDOFF / "Last session" links incidents filed that session.
- New SPECs / ADRs out of incidents `## References` them.
- New tracking items reference the incident in their description.

### Privacy (public repo)

This repo is **public**. Sanitize aggressively before save:

- **Never include**: internal IPs, hostnames, account/exchange/broker IDs, API keys (any form), 1Password URIs, internal file paths, owner-specific phrases ("for my $X account"), screenshots of internal dashboards.
- **OK to include**: generic mechanism descriptions, public PR links, public commit SHAs, generic order-of-magnitude numbers (10× spike, 60% error rate).
- **Run** `~/.claude/skills/incident-workflow/references/privacy-gate.md` checklist before every save. Any FAIL halts the commit.

The public-repo template variant in `_TEMPLATE.md` enforces these rules in its section structure (no local-tz column in Timeline, "do NOT include" callouts, generic Lessons section targeting external readers).

### Why this exists

ADRs capture *what we decided*. SPECs capture *what we built*. Neither captures *what we observed and ruled out*. Public incident reports also serve as a teaching artifact for engineers in similar situations.
