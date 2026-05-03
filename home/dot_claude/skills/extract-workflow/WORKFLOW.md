# Extract-workflow: 6-step process

## Step 1: Confirm the candidate is real

Before doing anything, verify recurrence. **Three runs is the floor.**

- Ask the user: how many times have you done this manually? Across how many sessions?
- If the user can name 3+ prior runs (with rough dates or commit refs), proceed.
- If only 1-2, push back: "Wait until pattern is real. Mark it as a watch item, not a skill candidate."
- If the user can name many but spread across many repos, that's the strongest signal — definitely a skill, not a CLAUDE.md note.

If recurrence isn't confirmable, surface the rejection in plain language. Don't dress it up.

## Step 2: Triage shape

Read `references/triage-rules.md` and `references/shape-decision.md`.

Decide between:

| Shape | Use when |
|---|---|
| **Skill package** (`~/.claude/skills/<name>/`) | Workflow has a clear *trigger intent* the user expresses naturally. Should auto-fire when the language matches. Has bootstrap needs (sets up files in a fresh repo). Has nuance worth multiple files (references, templates). |
| **Slash command only** (`~/.claude/commands/<name>.md`) | Workflow needs explicit invocation. No bootstrap. Single-file body is enough. False-positive auto-trigger would be annoying. |
| **Both — skill + slash command pair** | Workflow benefits from both surfaces. Skill auto-fires on natural language; slash command lets the user explicitly invoke even when the language doesn't quite match. |
| **Reject** | One-off, project-specific, automatable via hook/validation, or already covered by an existing skill. |

Surface the decision + rationale to the user. Get explicit confirmation before proceeding to Step 3.

## Step 3: Reverse-engineer the rules

Read `references/reverse-engineering.md` for techniques. Quick recap:

- For workflows tied to a repo's git history: `git log -p -- <relevant-files>` over the last 5-10 manual runs.
- For workflows that produce structured output: read the actual outputs from prior runs and infer the structural rules.
- For workflows the user describes verbally: ask them to walk through one example end-to-end, then ask "what did you decide differently than last time, and why?"

Build a rules table:

```markdown
| Rule | Source (commit / file / verbal) | Notes |
|---|---|---|
| Keep D-NNN refs intact | 72e0b83 (HANDOFF compaction) | Han preserves all decision-ledger links |
| Squash play-by-play, keep lessons | 72e0b83 + 9516019 | Story drops, lesson stays |
| ...
```

## Step 4: Surface rules for sign-off

**This is non-skippable.** Inference != correctness. Before coding the skill body, present the rules table to the user with the question: "Did I get this right? Any rules missing or wrong?"

Common ways the user corrects:
- "That's not a rule, that's just what I happened to do once."
- "You missed [X], it's actually the most important constraint."
- "Reframe rule N — the criterion is [Y], not [Z]."

Iterate until the rules table is signed off. Then proceed.

## Step 5: Hand off to superpowers:writing-skills

**REQUIRED SUB-SKILL: superpowers:writing-skills**.

That skill defines:
- SKILL.md frontmatter (`name`, `description`)
- The CSO rule: description = WHEN to use, never the workflow itself
- Skill folder structure
- TDD-with-subagents methodology (RED-GREEN-REFACTOR for skills)

Use the templates from `templates/` as a starting point, then apply writing-skills' rigor.

For discipline-enforcing skills (rules user must follow): full TDD-with-subagent rigor is recommended.

For technique skills (how-to guides): lighter testing — apply the technique to a known scenario and verify output matches. Defer subagent pressure tests as a future hardening pass.

## Step 6: Smoke test against the prior manual run

Pick a specific prior manual run (commit, output, conversation). Feed the same input to the formalized workflow. Diff the output.

- **Match**: ship.
- **Drift**: classify the drift. Is the new output *better* (the manual run had a bug) or *worse* (the skill missed a rule)? Refine accordingly. If drift is intentional, document the delta in the skill body.

After smoke test passes, proceed to deployment:

1. If skill package: verify `~/.claude/skills/<name>/SKILL.md` is loaded by checking the available-skills list at session start, or via ToolSearch.
2. If slash command: verify `/<name>` appears in available skills/commands.
3. If per-repo adapter: verify the adapter file exists at `<repo>/.claude/<name>-config.md` and the skill body reads from it correctly.
4. Update the calling repo's CLAUDE.md or pointer doc if the new skill is worth surfacing.

## Common failure modes

| Symptom | Fix |
|---|---|
| Skill auto-fires when user didn't intend | Description was too broad. Tighten triggers. Re-test. |
| Skill body reads as "what the workflow does" | Description summary leaked into the body, OR description summarizes the workflow. Per CSO rule, strip both. |
| Per-repo adapter not honored | Skill body has hardcoded paths instead of reading from adapter. Refactor. |
| Smoke test diverges from prior manual run | Either rules table missed something (most common), OR prior run had a bug (rare but happens). Reverse-engineer one more cycle. |
