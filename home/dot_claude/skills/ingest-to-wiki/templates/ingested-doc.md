---
title: "{{title}}"
date: {{YYYY-MM-DD}}
source_type: gdrive | notion | email | pdf | url | other
source_id: ""
source_url: ""
ingested_on: {{YYYY-MM-DD}}
converted_from: "{{original-filename.ext}}"
status: mirror
domain: people | sales | finance | hiring | content | brand | legal | projects | strategy | other
sensitivity: public-in-repo | private
tags: []
---

> **Source**: [{{source label}}]({{source_url}})
> **Ingested**: {{YYYY-MM-DD}} from `_inbox/{{original-filename.ext}}`
> **Format**: converted from {{.docx|.pdf|.md}} via {{pandoc|read_file_content|manual}}

## Summary

Two-to-four sentences. What is this document and why does it matter to Dwarves operations.

## Content

{{paste converted content here, lightly cleaned: strip page headers/footers, fix heading levels, remove navigation artefacts}}

## Notes on conversion

Anything lost in conversion (images, tables, embedded diagrams). Flag if the binary original should be re-read manually.

## Related

- Source of truth: {{Drive file / Notion page}}
- Related repo docs: `path/to/related.md`
