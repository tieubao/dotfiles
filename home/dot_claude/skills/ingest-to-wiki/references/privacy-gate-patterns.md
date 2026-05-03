# Privacy gate patterns

How different repos configure the tracked-vs-private split. Read this when setting up `privacy_rule` in `.claude/ingest-config.md` or when classifying an ambiguous file.

## Default pattern (recommended for most repos)

**Rule**: Names real people, real clients, real money, or real contracts → `{{private_location}}/`. Everything else stays tracked.

Applies when: repo is a private GitHub repo (so tracked ≠ public internet). Organization-level sensitivity applies but not individual-level privacy.

## Stricter patterns

### Trading / finance repos

**Rule**: Anything that reveals position sizes, entry/exit prices, API keys, specific strategies, or bankroll → private. Generic patterns, public-data analyses, tool evaluations → tracked.

Applies when: adversaries could copy a strategy or reverse-engineer positions from the repo history.

### Multi-tenant repos

**Rule**: Anything client-specific (code, data, strategy) → private sub-directory per client. Only cross-client patterns and infrastructure stay tracked.

Applies when: one repo serves multiple clients and you must not accidentally mix their data.

### Legal / HR repos

**Rule**: Anything with real employee names, salaries, signed contracts, performance reviews, health data → private. Templates, blank forms, generic policies → tracked.

Applies when: the repo handles employment or personal data subject to jurisdictional rules (GDPR, CCPA, VN labor law, etc.).

## Looser patterns

### Public open-source project

**Rule**: Nothing private by default. If content is sensitive, it doesn't belong in the repo at all.

Applies when: every commit lands on public GitHub. There is no "private" tier in git; only "in the repo" vs "not in the repo".

### Personal knowledge base

**Rule**: Very little is private. Personal notes, research, analysis are all tracked. Private stays reserved for credentials, medical, banking, and identity-document scans.

Applies when: the repo is the user's personal wiki (like the `til/` repo pattern).

## Grey zone decision heuristic

When unsure whether a file goes to tracked or private:

1. **Would a competitor gain advantage from reading this?** If yes → private.
2. **Could an individual sue the user for having this in a repo?** If yes → private.
3. **Would the user's clients be upset to see this in a backup archive?** If yes → private.
4. **Is it just strategic thinking with no specific identifiers?** Tracked.
5. **Is it a pattern or framework abstracted from real work?** Tracked.

If still unclear, default to **tracked** and flag it in the session log with a "classification note" so the user can review.

## How to handle pre-existing mis-classifications

If during an ingest you notice that existing files may be mis-classified:

- Do NOT silently move them.
- Log the observation in the session log under a "Classification review" heading.
- Surface to the user at session end with a specific recommendation: "File X at path P looks like it could be reclassified to Q. Want me to move it?"

Rationale: pre-existing content has established links and references from other files. Moving it silently breaks those references.

## Config examples

### dfoundation (ops workspace for a consulting firm)

```markdown
- private_location: private/     # iCloud symlink, gitignored
- privacy_rule: Names real people, real clients, real money, or real contracts → private. Strategic analysis without specifics → tracked.
- domain_folders: people, sales, finance, hiring, content, brand, legal, projects, strategy
```

### Trading repo

```markdown
- private_location: .private/
- privacy_rule: Positions, strategies, API keys, bankroll → private. Generic patterns, tool evaluations, public-data analyses → tracked.
- domain_folders: strategies, tools, research, operations
```

### Personal wiki (til-style)

```markdown
- private_location: (none)
- privacy_rule: Everything is tracked. Credentials, medical, banking do not enter this repo at all.
- domain_folders: (all top-level topic folders)
```
