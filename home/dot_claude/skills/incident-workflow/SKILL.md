---
name: incident-workflow
description: Use when investigating real defects (alerts, error spikes, service degradation, near-misses caught by guardrails) AND the current repo would benefit from a forensic post-mortem. Also use to bootstrap the incidents/ structure in a new repo. Captures the diagnostic trail (commands run, hypotheses ruled out, smoking-gun evidence) that ADRs and SPECs do not. NOT for inbox material (use ingest-to-wiki) or for designing new features (use SDD / brainstorming).
---

# Incident Workflow

Portable forensic post-mortem workflow. Owns the third doc container alongside SPECs (designed work) and ADRs (decisions): **what we observed and ruled out** during a real failure.

## When to activate

**Bootstrap mode** (runs once per repo):
- User says `bootstrap incident workflow`, `set up incidents`, `init incidents`, `add incident reports here`
- Or: agent is about to file an incident in a repo that has no `docs/incidents/` (or configured equivalent) - prompt to bootstrap first

**File mode** (runs every incident):
- User says `file an incident for X`, `log this incident`, `start an incident report`, `this looks like an incident`
- Or: trigger rule fires (see below) and no incident is currently being filed in the session

**Session-start check** (runs automatically when the skill has been bootstrapped in the current repo):
1. List `docs/incidents/` (or configured `incidents_path`).
2. Find any file with frontmatter `status: open`.
3. If any open incident exists, surface: "N open incident report(s) — want me to roll forward / continue?"

## Trigger rule (when to file)

File an incident report when **any** of:

1. A monitoring CRIT alert fires that is **not** a known artifact (deploy debris, expected one-off).
2. A diagnostic session runs **>5 commands** chasing a real defect (covers deep dives that don't trip an alert, e.g. dashboard anomalies the user spots manually).
3. A user-visible service degradation occurs (live trade refused, alerts go silent, plugin throws, broker API surprise).
4. A near-miss: a guardrail (kill-switch, rate-limit, risk gate) caught a defect AND the underlying cause is still in the code.

Do **NOT** file for:
- Operational toil (forgot a flag, mistyped command, network flap that recovered in <60s).
- Pre-merge test failures during normal development.
- Owner-side blockers waiting on credentials or data.
- Routine deploys, even when they ship fixes for prior incidents (the prior incident report owns the fix).

When in doubt, file. A noisy folder is far less expensive than a missing diagnosis.

## How to use this skill

1. **First time in a repo**: read `BOOTSTRAP.md` and run the scaffold.
2. **Every incident**: read `WORKFLOW.md` and follow the lifecycle.
3. **Privacy questions**: read `references/privacy-gate.md`.
4. **Severity calibration**: read `references/severity-ladder.md` for P0..P3 examples by repo type.

## Per-repo configuration

Skill reads `.claude/incident-config.md` at the target repo root. If missing, `BOOTSTRAP.md` creates it. Config declares:

- `repo_visibility` - `private` or `public`. Determines which CLAUDE.md section variant + template variant to install.
- `incidents_path` - where reports live (default `docs/incidents/`). Some repos prefer `documentation/incidents/` or flat `incidents/`.
- `template_path` - where the per-incident template lives (default `<incidents_path>/_TEMPLATE.md`). Can be a path to the skill's canonical template instead of a local copy: `skill:incident-workflow/templates/_TEMPLATE-private.md`.
- `severity_ladder` - keep default P0..P3 OR override (e.g. some repos have only P1/P2).
- `cross_ref_targets` - which other repo files must link incidents (default: `HANDOFF.md`, `INDEX.md`, related `docs/specs/`, `docs/decisions.md`). Repos without these files just skip the cross-ref.

## Principles

1. **The diagnostic trail is the asset.** ADRs capture *what we decided*, SPECs capture *what we built*, incident reports capture *what we observed and ruled out*. Each container has a different decay profile and audience.
2. **Trigger rule must bite.** Without explicit triggers, the folder either bloats (every dev session) or dead-letters (nobody writes them). The trigger rule is binding for agents.
3. **One file per incident.** Append-only mindset: incidents close, they don't get rewritten. New investigation of the same defect = new incident with a `## References` link to the prior one.
4. **Cross-references are mandatory in both directions.** SPECs/ADRs out of incidents must link back. HANDOFF "Last session" must link incidents filed that session. Closing the loop is what makes future-self find them.
5. **Private by default.** Sanitized public versions (for TIL / public engineering blog) are a separate explicit step gated by a privacy checklist.

## Cross-skill notes

| Use this skill when... | Use a different skill when... |
|---|---|
| Investigating a real defect | Dropping raw material into `_inbox/` → `ingest-to-wiki` |
| Documenting what failed and how | Designing a new feature → SDD / `superpowers:brainstorming` |
| Capturing diagnostic commands + hypotheses | Recording a tool evaluation → repo's tool-evaluation workflow |
| Filing follow-up `H-NN` items | Tracking a single conversation's tasks → `TaskCreate` |

## Versioning

Skill version: `0.1.0` (initial release 2026-04-24).

## Relationship to the origin repo

**Origin**: extracted from the `tieubao/trading` repo's first incident workflow (PR #32 + INC-001 in PR #33).

**Trading and this skill are siblings, not parent/child.** Trading is the canonical reference for *trading-specific* incident reports (with vps-mon examples, ICT timestamps, broker-API failure modes). This skill is the canonical reference for *new-repo bootstrap*: a generic, substitution-friendly version that fits any repo via the bootstrap script.

The two will drift over time and that's correct. Edits to this skill don't need to backport to trading; edits to trading's `docs/incidents/` don't need to forward to this skill. New repos consuming the skill (`family-office`, `properties`, future projects) get the generic version + customize from there.

When iterating on this skill: bump version + log changes inline at the bottom of this file. Do **not** treat trading's local files as needing to "stay in sync" - they won't, and shouldn't.

## Changelog

- `0.1.0` (2026-04-24): initial extraction from trading repo. Two template variants (private + public), bootstrap script, per-repo config file pattern.
