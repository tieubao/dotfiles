# Reverse-engineering rules from prior runs

The hardest part of skill extraction isn't writing the skill — it's recovering the rules the user has been applying without articulating them.

## The principle

If the user has done a workflow N times, those N runs ARE the rule set. Read them.

Don't ask the user "what are the rules?" until you've inferred a candidate set from their actual past behavior. People are bad at articulating their own implicit rules; people are good at reacting to a wrong rule and saying "no, it's actually [X]."

## Techniques by workflow type

### Git-history-tied workflows

For workflows that touch tracked files (HANDOFF compaction, decisions ledger update, INGEST_LOG appending, etc.):

```bash
# Find the relevant prior runs
git log --oneline --all -- <relevant-files>

# Read the diffs (NOT just the commit messages)
git log -p --no-merges -- <relevant-files> | head -300

# Look at specific commits
git show <commit-hash> -- <relevant-files>
```

What to look for:
- **Patterns in what gets added vs removed**: deleted lines tell you the compaction rules.
- **Patterns in commit message phrasing**: "compress today's X", "trim Y", "consolidate Z" reveal the user's mental categories.
- **Cross-file dependencies**: did HANDOFF compaction always touch the decisions ledger too? That's a rule.

### Output-tied workflows

For workflows that produce a structured artifact (a docx, a Discord post, an invoice):

- Read 3-5 prior outputs side by side.
- Look for invariants (always present), variants (differ but follow a pattern), and accidents (only there once, probably noise).
- Cross-check against the templates if any exist.

### Verbal / conversational workflows

For workflows the user describes verbally (no artifact trail):

- Ask the user to walk through one specific past run end-to-end.
- After they finish: "What did you decide differently than the last time you did this, and why?"
- After that: "What's the part that always trips you up or that you nearly forgot just now?"

The "nearly forgot" answer is gold — it's the implicit rule the user knows but doesn't articulate.

## Building the rules table

Format consistently:

```markdown
| Rule | Source | Confidence | Notes |
|---|---|---|---|
| Preserve all D-NNN refs | 72e0b83, 2014bb6 | High | Appears in every compaction commit |
| Squash play-by-play, keep lessons | 72e0b83 | Medium | Single commit; verify with user |
| Compaction always touches decisions.md | 72e0b83 | Low | Sample of 1; might be incidental |
```

**Confidence levels**:
- **High**: pattern appears across 3+ runs.
- **Medium**: pattern appears in 1-2 runs but is structurally important.
- **Low**: single instance, may be incidental.

**Always surface low-confidence rules to the user** with explicit framing: "I see this once, is it actually a rule?"

## The non-skippable sign-off

Before writing the skill body, present the rules table to the user with this question:

> "Here's what I inferred from your prior runs. Did I get this right? Any rules missing or wrong?"

Common corrections:
- "That's not a rule, I was just sloppy that day."
- "You missed [X]. It's the most important constraint."
- "Reframe: the criterion is [Y], not [Z]."
- "Combine N and M, they're the same rule."

Iterate until the rules table is signed off. **Then** write the skill body using the validated rules.

## Common failure modes

| Symptom | Diagnosis | Fix |
|---|---|---|
| Skill output diverges from prior manual runs | Missed a rule during reverse-engineering | Re-grep `git log -p`; check if there's a rule that only fires under specific conditions |
| Skill output is "right" but user says "no, that's not how I do it" | Inferred rule is wrong even though output happens to match | Ask the user to articulate what rule they apply; encode that, not the surface-level pattern |
| Multiple competing patterns across runs | User changed their approach over time | Only encode the most recent pattern (last 3 runs). Older runs are historical, not the current rule. |
| User can't articulate the rule even when prompted | Workflow is muscle-memory; rules exist but are tacit | Write a draft skill anyway, run it, ask the user to react. Reaction surfaces the tacit rule fast. |
