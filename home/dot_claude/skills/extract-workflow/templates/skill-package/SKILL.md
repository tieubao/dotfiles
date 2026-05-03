---
name: SKILL-NAME-HERE
description: Use when [TRIGGER CONDITIONS — specific symptoms, situations, contexts]. Symptoms include "[verbatim trigger phrase]", "[another phrase]", "[another]". [Optional one-line cross-reference to required sub-skill: "Uses superpowers:writing-skills for X."]
---

# SKILL TITLE HERE

[One-paragraph overview. State the workflow's purpose and when it matters. Don't summarize the workflow steps — that's WORKFLOW.md's job. Per CSO rule: description is WHEN, body is WHAT.]

## When to activate

**Trigger phrases (any of):**
- "[user phrasing 1]"
- "[user phrasing 2]"
- "[user phrasing 3]"

**Reject criteria** (don't fire, redirect):
- [non-trigger 1]
- [non-trigger 2]

## How to use this skill

1. **Read `WORKFLOW.md`** for the per-run process.
2. **Bootstrap a fresh repo (if applicable)**: read `BOOTSTRAP.md`.
3. **Reference material**: `references/<topic>.md` for [topic1], [topic2].
4. **Templates**: `templates/<artifact>.md`.
5. **REQUIRED SUB-SKILL** (if applicable): `<plugin>:<skill-name>`.

## Per-repo configuration

[Only if the skill needs project-specific config.]

The skill reads `.claude/<skill-name>-config.md` at the target repo root. If missing, `BOOTSTRAP.md` creates it. Config declares:

- `<key1>` — [purpose, default]
- `<key2>` — [purpose, default]

## Principles

1. [Principle 1: short, declarative.]
2. [Principle 2.]
3. [Principle 3.]

## What NOT to do

- [Anti-pattern 1.]
- [Anti-pattern 2.]
- [Anti-pattern 3.]

## Output expectations

After running this skill, the user should see:
- [Output 1]
- [Output 2]
- [Output 3]

## Anti-rationalizations

| Excuse | Reality |
|---|---|
| "[expected rationalization 1]" | [counter] |
| "[expected rationalization 2]" | [counter] |
