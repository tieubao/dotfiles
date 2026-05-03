---
name: ingest-to-wiki
description: Use when the user drops external material (docx, pdf, md, Drive links, raw notes) into a repo and wants it triaged, converted, logged, and compiled into the repo's knowledge structure. Also use when setting up a new repo that will accumulate knowledge over time (bootstrap mode creates _inbox/, _templates/, INGEST_LOG.md, docs/ingest/README.md).
---

# Ingest to Wiki

Portable ingest workflow based on the LLM-wiki pattern (inbox + templates + chronological log + compilation step). Converts raw drops into durable repo knowledge without losing provenance.

## When to activate

**Bootstrap mode** (runs once per repo):
- User says `bootstrap ingest workflow`, `set up ingest`, `initialize wiki`
- Or: current repo has no `_inbox/` and no `INGEST_LOG.md`, and the user is about to drop material

**Ingest mode** (runs every drop):
- `ingest inbox` - process everything in `_inbox/`
- `ingest <file>` - process a single file
- `ingest this drive folder <URL>` - fetch from Drive (fall back to user-dumping locally if MCP cannot list)
- `ingest this notion page <URL>` - same pattern
- `re-ingest <slug>` - re-run a prior session after source changed
- `compile recent` - walk recent commits, backfill missing `INGEST_LOG.md` entries

**Session-start check** (runs automatically at the start of a session where the skill has been bootstrapped):
1. List `_inbox/` contents. Flag files newer than the latest `INGEST_LOG.md` entry.
2. Scan last 3 entries in `INGEST_LOG.md` for `status: in-progress` or `status: blocked`.
3. If either signal fires, surface: "N new inbox files [and/or] an incomplete ingest session from YYYY-MM-DD. Want me to continue?"

## How to use this skill

1. **First time in a repo**: read `BOOTSTRAP.md` and run the scaffold.
2. **Every ingest**: read `WORKFLOW.md` and run the 7 steps.
3. **Tool questions**: read `references/conversion-tools.md` (pandoc, pdftotext, xlsx fallbacks).
4. **Privacy questions**: read `references/privacy-gate-patterns.md`.

## Per-repo configuration

The skill reads `.claude/ingest-config.md` at the target repo root. If that file is missing, `BOOTSTRAP.md` creates it. Config declares:

- `private_location` - where sensitive material goes (default `private/`)
- `index_file` - per-doc freshness tracker (default `STALENESS.md`; omit if repo doesn't use one)
- `log_file` - chronological log location (default `INGEST_LOG.md` at root)
- `inbox_path` - where raw drops land (default `_inbox/`)
- `ingest_path` - **optional** per-session sidecar directory. Omit for the default (single `INGEST_LOG.md`, no sidecars - recommended for most repos). Set it (e.g. `ingest/`) only if the repo wants per-session `INDEX.md` + `ingest_log.md` detail files on top of the root log.
- `privacy_rule` - one-sentence rule for public vs private split
- `domain_folders` - list of top-level domain folders that can receive promoted content

## Principles

1. **Every ingest is logged.** No silent writes.
2. **Binary is not knowledge.** Convert `.docx`/`.pdf` to markdown; leave binaries in their source system.
3. **Tracked by default.** Sensitive material goes to the configured `private_location`; everything else stays in git.
4. **The inbox is transient.** Raw drops in `_inbox/` are gitignored. Triage moves material to the right domain.
5. **Compilation is mandatory.** Filing is not enough; update related links, freshness tracker, and log in one pass.

## What NOT to do

- Never ingest a file without logging it in `INGEST_LOG.md`.
- Never commit `_inbox/` contents. Move to the right domain first.
- Never convert a binary just-in-case; only convert if the file is classified `Promote` or `Summarize`.
- Never silently resolve a contradiction. Flag both sides with a `> [!warning] Contradiction` callout.
- Never reshuffle pre-existing content classification (public vs private) without explicit user direction.

## Output expectations

After any ingest, the user should see:
- A summary table (file → classification → destination)
- One new entry in `INGEST_LOG.md` at repo root
- Updated `STALENESS.md` (or configured `index_file`) rows for promoted docs
- Any memory writes surfaced (what was saved, why)
- Per-session sidecar files at `<ingest_path>/<source>/<slug>/` **only if** the repo has `ingest_path` set in its config
