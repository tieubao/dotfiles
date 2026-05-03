---
name: extract-workflow
description: Use when the user notices a multi-step manual process they have repeated across sessions and asks to formalize it as a Claude Code skill or slash command. Symptoms include "I keep doing this manually", "let's pack this as a skill", "save this workflow", "make this repeatable", "skill-ify it", "this should be a skill", "extract this into a skill", "I noticed a pattern across sessions". Drives triage and packaging; uses superpowers:writing-skills for the actual writing rigor.
---

# Extract workflow

Recurring manual workflows are a tax on memory and consistency. This skill turns them into either a packaged skill (auto-fire on intent) or a global slash command (explicit trigger), with a per-repo adapter when the workflow depends on project-specific paths or vocabulary.

## When to activate

**Trigger phrases (any of):**
- "I keep doing this manually"
- "let's pack this as a skill"
- "save this workflow"
- "make this repeatable"
- "skill-ify it"
- "this should be a skill"
- "extract this into a skill"
- "I noticed a pattern"

**Reject criteria** (don't formalize, redirect):
- One-off solution that won't recur (3+ prior runs is the floor)
- Project-specific convention (put in `CLAUDE.md`, not a skill)
- Mechanical constraint enforceable by hook/regex/validation (automate it instead, see `update-config` skill)

## How to use this skill

1. **Read `WORKFLOW.md`** for the 6-step extraction process.
2. **Triage rules**: `references/triage-rules.md` — when to formalize, when to redirect.
3. **Shape decision**: `references/shape-decision.md` — skill package vs slash command vs both.
4. **Reverse-engineer rules**: `references/reverse-engineering.md` — how to recover the workflow's actual rules from `git log -p`, prior commits, and user past output.
5. **REQUIRED SUB-SKILL: `superpowers:writing-skills`** for the actual SKILL.md drafting + (optional but recommended) TDD-with-subagents pressure testing.
6. **Templates**: `templates/skill-package/`, `templates/slash-command/`, `templates/adapter-config/`.

## Principles

1. **Don't formalize what doesn't repeat.** Three+ manual runs across sessions = candidate. Once-and-done = skip.
2. **Triage shape before writing.** Skill packages auto-fire; slash commands need explicit invocation. Wrong shape = friction. Both is a valid shape (skill for auto-fire + slash command for explicit "do this now").
3. **Project-coupled bits go to the adapter.** Skill body is portable across repos; per-repo config goes to `<repo>/.claude/<skill>-config.md`. Hardcoded paths in the skill body are the #1 portability bug.
4. **Reverse-engineer rules from prior runs.** If the user has compressed HANDOFF five times, those five compactions ARE the rule set. Surface inferred rules for sign-off before writing.
5. **Delegate writing rigor.** Don't reinvent superpowers:writing-skills. After triage and shape decisions, hand off the SKILL.md drafting + testing.
6. **Smoke test against prior manual run.** If the formalized workflow on the same input doesn't reproduce the prior manual output → diff it, refine.

## What NOT to do

- Never formalize a workflow run only once. Patterns from a single instance are speculation.
- Never put project-specific paths in the skill body. They go to the adapter config.
- Never skip surfacing inferred rules to the user before coding the skill body. Inference != correctness.
- Never write a skill description that summarizes the skill's workflow (per superpowers:writing-skills CSO rule).
- Never treat this as a replacement for superpowers:writing-skills. They stack: this triages and packages; that one writes and tests.
- Never leave a per-repo adapter file with the skill name baked in if the skill has been renamed since.

## Output expectations

After running this skill on a candidate workflow, the user should see:
- A triage decision (skill / command / both / reject) with rationale
- A reverse-engineered rules table from prior manual runs (where applicable), surfaced for sign-off
- The new skill package or slash command at the correct path (`~/.claude/skills/<name>/` or `~/.claude/commands/<name>.md`)
- An optional per-repo adapter at `<repo>/.claude/<skill>-config.md`
- A smoke test confirming the formalized workflow reproduces the prior manual output (or a diff explaining the delta)

## Anti-rationalizations

| Excuse | Reality |
|---|---|
| "It's only run twice but I'm sure I'll need it again" | Wait. Three runs is the floor for a reason: pattern needs evidence, not optimism. |
| "The skill body can have hardcoded paths, it's only used in one repo today" | Today. The adapter pattern costs 5 minutes; the rewrite when you adopt this in repo #2 costs an hour. |
| "Skipping the smoke test, the skill is obviously correct" | Obvious-to-author ≠ correct. The smoke test against the prior manual run is the contract. |
| "I'll skip superpowers:writing-skills, I know how to write skills" | Maybe. But the description-vs-workflow rule is non-obvious (description must NOT summarize workflow). Read the skill anyway. |
| "Three workflows in one skill is fine" | No. One skill, one trigger surface. Bundling kills auto-fire precision. |
