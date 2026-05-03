# Ingest Workflow

Canonical spec for how Claude processes material dropped into this repo.

Last reviewed: {{YYYY-MM-DD}}.

## Principles

1. **Every ingest is logged.** Root `{{log_file}}` records the session. Per-session detail lands in `ingest/<source>/<slug>/`.
2. **Binary is not knowledge.** Binaries stay in their source system (Drive, Notion, email, etc.). Markdown mirrors live in the repo.
3. **Tracked by default.** Most material stays in git. Only content matching the privacy rule goes to `{{private_location}}/`.
4. **The inbox is transient.** Raw drops in `_inbox/` are gitignored. Triage moves material to the right domain.
5. **Compilation is mandatory.** Filing is not enough; update related links, {{index_file}} row, and `{{log_file}}` entry in one pass.

## Privacy rule

{{privacy_rule}}

## Directory map

| Path | Role | Tracked? |
|------|------|----------|
| `_inbox/` | Raw drops. Pre-triage. | README only |
| `_templates/` | Note templates. | Yes |
| `ingest/<source>/<slug>/` | Per-session detail: `INDEX.md`, `ingest_log.md`. | Yes |
| `{{log_file}}` (root) | Chronological record. | Yes |
| `{{index_file}}` (root) | Per-doc freshness tracker. | Yes |
| `docs/ingest/README.md` | This file. | Yes |
| `<domain>/` | Promoted generic knowledge. | Yes |
| `{{private_location}}/<domain>/` | Promoted knowledge matching the privacy rule. | No |

Domain folders in this repo: {{domain_folders}}.

## The workflow (7 steps)

See the `ingest-to-wiki` skill's `WORKFLOW.md` for the full step-by-step. Short form:

1. **Triage** - classify each file: promote / summarize / duplicate / skip. Checksum first.
2. **Convert** - binary to markdown via pandoc (or MCP tools for Drive/Notion native).
3. **Frontmatter** - fill `_templates/ingested-doc.md` minimum.
4. **Placement** - apply the privacy rule; land in domain folder or `{{private_location}}/`.
5. **Compile** - overlap check, contradiction flag, {{index_file}} row, related links.
6. **Log** - write per-session detail and a root `{{log_file}}` entry.
7. **Memory** - save cross-session facts to `~/.claude/projects/<slug>/memory/`.

## Trigger phrases

| Phrase | Scope |
|--------|-------|
| `ingest inbox` | All files in `_inbox/` |
| `ingest <file>` | Single file |
| `ingest this drive folder <URL>` | Remote Drive folder |
| `re-ingest <slug>` | Re-run prior session |
| `compile recent` | Backfill missing log entries from recent commits |

## What NOT to do

- Never ingest without logging.
- Never commit `_inbox/` contents.
- Never convert a binary just-in-case.
- Never silently resolve a contradiction.
- Never reshuffle pre-existing classification without user direction.
