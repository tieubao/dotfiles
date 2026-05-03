# Ingest Workflow - 7 Steps

Read `.claude/ingest-config.md` before starting to get per-repo rules. If no config exists, run `BOOTSTRAP.md` first.

## Step 1. Triage

For each file in scope (from `_inbox/`, explicit filename, or downloaded from Drive/Notion), classify:

| Classification | Meaning | Action |
|----------------|---------|--------|
| **Promote** | Worth persisting as durable knowledge | Convert to markdown, fill template, land in domain folder |
| **Summarize** | Long / peripheral; only conclusions matter | Write a short memo referencing the source; skip verbatim mirror |
| **Duplicate** | Byte-identical or superseded version already in repo | Note in session log; no new file |
| **Skip** | One-off, low signal, not repo-relevant | Log decision with reason |

**Checksum before anything else**: `shasum -a 256 <file>` and compare against existing files in the repo. Detect duplicates fast before you waste tokens reading them.

## Step 2. Convert

If the file is binary and classified `Promote` or `Summarize`, convert to markdown. See `references/conversion-tools.md` for the tool matrix.

Quick reference:

| Format | Tool | Command |
|--------|------|---------|
| `.docx` / `.pptx` / `.odt` | pandoc | `pandoc -f docx -t gfm --extract-media=assets/ <file> -o <output.md>` |
| `.pdf` (text) | pandoc 3+ | `pandoc -f pdf -t gfm <file> -o <output.md>` |
| `.pdf` (scanned) | OCR needed | Ask user; no auto-fallback |
| `.xlsx` | no pandoc path | Use Python openpyxl helper or ask user for CSV export |
| `.md` | none | Use as-is |
| Google Drive native | `mcp__claude_ai_Google_Drive__read_file_content` | Returns natural-language mirror |
| Notion page | `mcp__claude_ai_Notion__notion-fetch` | Returns markdown-ish structure |

Do NOT commit binaries to the repo. Keep them in their source system; commit only the markdown mirror.

## Step 3. Frontmatter

Every promoted file gets frontmatter from `_templates/ingested-doc.md` at minimum:

```yaml
---
title: "..."
date: YYYY-MM-DD
ingested_on: YYYY-MM-DD
source_type: gdrive | notion | email | pdf | url | other
source_id: ""
source_url: ""
converted_from: "original-filename.ext"
status: mirror | refined | evergreen
domain: <one of the configured domain_folders>
sensitivity: public-in-repo | private
tags: []
---
```

If the user rewrites the mirror into a new SOP, memo, or spec, switch the template and update `status`.

## Step 4. Placement (privacy gate)

Read `privacy_rule` from `.claude/ingest-config.md`. Apply it.

Default rule: "Names real people, real clients, real money, or real contracts → `{{private_location}}/`. Everything else stays tracked in the repo."

Grey zone (content names the user or their own company generically, no client/money specifics): default to **tracked**. Flag in the session log for user review.

Landing paths:
- **Tracked**: `<domain>/drafts/<filename>.md` or `<domain>/<filename>.md` depending on whether the domain has a `drafts/` convention
- **Private**: `{{private_location}}/<domain>/<filename>.md`

## Step 5. Compile

After landing the file, do all of:

1. **Overlap check**: search tracked folders for notes covering the same topic. If found, add a `## Related` section to the new file and update the existing file's `## Related` section.

2. **Contradiction flag**: if the new file contradicts existing content, add to both sides:
   ```markdown
   > [!warning] Contradiction
   > This note claims X, but `other-file.md` claims Y. See context for which may be more current.
   ```
   Do not silently resolve contradictions.

3. **Index/freshness update**: if the repo uses an `index_file` (default `STALENESS.md`), add or update the row with today's date and source reference.

4. **Related links**: prefer relative markdown links. Use Obsidian-style `[[wikilinks]]` only if the repo already uses them.

## Step 6. Log the session

**Default (most repos)**: append one block to `INGEST_LOG.md` at repo root. That is the entire record.

```markdown
## [YYYY-MM-DD] ingest | <short topic>

<2-4 sentences of context>

**New / promoted:**
- `path/to/file.md` - one-line summary

**Duplicates / skipped:**
- `filename` - why

**Compilation work:**
- Index file updated: yes/no
- Related links updated in: list
- Contradictions flagged: none | list

**External link:** <URL if binary originals live elsewhere>

---
```

**Optional per-session sidecar files**: only if the target repo's `.claude/ingest-config.md` sets `ingest_path` (e.g. `ingest/`). Then ALSO write `<ingest_path>/<source>/<slug>/INDEX.md` (file-by-file status table) and `<ingest_path>/<source>/<slug>/ingest_log.md` (chronological actions), and reference them from the root block with a `**Detail log:**` line. Most repos skip this.

## Step 7. Memory

Save cross-session facts to the memory directory (Claude Code: `~/.claude/projects/<project-slug>/memory/`):

- Source IDs encountered (Drive folder IDs, Notion page IDs) → `reference_<source>_catalogue.md`
- Canonical location decisions → project memory
- Tool limitations discovered → feedback memory
- Privacy grey-zone decisions → project memory (so the same decision isn't re-litigated)

Do NOT save ephemeral task state or the content itself; the repo is the durable store for that.

## Session-start hook

At the start of any session in a bootstrapped repo:

1. `ls _inbox/` - count files not yet in `INGEST_LOG.md`
2. Read last 3 blocks of `INGEST_LOG.md` - look for `status: in-progress` or `status: blocked`
3. If either signal fires, surface to the user before doing anything else.

## Trigger phrases reference

| Phrase | What to do |
|--------|------------|
| `ingest inbox` | Step 1-7 for every file in `_inbox/` |
| `ingest <file>` | Step 1-7 for one file |
| `ingest this drive folder <URL>` | Try MCP listing first; fall back to asking user to dump files into `_inbox/` |
| `ingest this notion page <URL>` | Fetch via Notion MCP, run 1-7 |
| `re-ingest <slug>` | Re-run step 1-7 on an existing `ingest/<source>/<slug>/` session; diff against prior outcome |
| `compile recent` | Walk `git log --oneline -10`; for any commit adding tracked files to a domain folder, verify `INGEST_LOG.md` has a corresponding entry; backfill if missing |
| `bootstrap ingest workflow` | Run `BOOTSTRAP.md` |
