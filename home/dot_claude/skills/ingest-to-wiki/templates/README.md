# `_templates/`

Ops-shaped note templates. Claude copies one of these when promoting inbox material to a tracked location, then fills in the blanks.

| Template | When to use |
|----------|-------------|
| `ingested-doc.md` | Mirror of an external doc (Google Drive, Notion, email thread). Preserves source link, date, and provenance. |
| `sop.md` | Standard operating procedure for a recurring ops task. Steps, owner, triggers. |
| `memo.md` | Strategic / analytical one-off. Positioning, gap analysis, decision memos. |
| `spec.md` | Feature or automation spec for `docs/specs/`. Intended to drive Claude Code or Hermes Agent implementation. |

No em dashes. Keep headings in sentence case. Date format `YYYY-MM-DD`.
