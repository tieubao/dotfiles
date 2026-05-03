# Conversion tools reference

Binary-to-markdown conversion for the ingest workflow. Check tool availability before recommending.

## Pandoc (primary)

```bash
which pandoc && pandoc --version | head -1
```

Install: `brew install pandoc` (macOS) or `apt install pandoc` (Debian).

| Input | Command |
|-------|---------|
| `.docx` | `pandoc -f docx -t gfm --extract-media=assets/ input.docx -o output.md` |
| `.pptx` | `pandoc -f pptx -t gfm input.pptx -o output.md` |
| `.odt` | `pandoc -f odt -t gfm input.odt -o output.md` |
| `.epub` | `pandoc -f epub -t gfm input.epub -o output.md` |
| `.html` | `pandoc -f html -t gfm input.html -o output.md` |
| `.pdf` (text, pandoc 3+) | `pandoc -f pdf -t gfm input.pdf -o output.md` (may fail on complex layouts) |

Flags:
- `-t gfm` - GitHub Flavored Markdown (widest compatibility)
- `--extract-media=assets/` - extracts images to `assets/` so the markdown references them
- `--wrap=none` - disable line wrapping if you want git-friendly diffs later
- `--reference-doc=<file>` - only for `.docx` output, not input

## pdftotext (fallback for PDFs)

```bash
which pdftotext
```

Install: `brew install poppler`.

```bash
pdftotext -layout input.pdf output.txt   # preserves layout
pdftotext input.pdf output.txt            # flat text
```

Then manually reformat `.txt` → `.md` (headings, lists). Pandoc's PDF support is better than pdftotext for structured documents; use pdftotext only when pandoc fails.

## xlsx / spreadsheets

Pandoc does not handle `.xlsx`. Options:

1. **Ask user to export CSV** - simplest; paste CSV into a markdown table or attach as `.csv` in the domain folder.
2. **Python openpyxl helper** - for repeated use, add a script:
   ```python
   from openpyxl import load_workbook
   wb = load_workbook("input.xlsx")
   for sheet in wb.sheetnames:
       ws = wb[sheet]
       # iterate ws.rows, emit markdown table
   ```
3. **LibreOffice headless** - `soffice --headless --convert-to csv input.xlsx`

## Google Drive native (docs, sheets, slides)

Do NOT download-and-convert. Use the Drive MCP's `read_file_content` which returns a natural-language representation:

```
mcp__claude_ai_Google_Drive__read_file_content(fileId: "...")
```

Works for: `application/vnd.google-apps.document`, `presentation`, `spreadsheet`. The returned text is intended for LLM consumption; not a pixel-perfect mirror.

For binary Drive files (uploaded `.docx`/`.pdf`), `download_file_content` returns bytes that you then run through pandoc locally.

## Notion pages

```
mcp__claude_ai_Notion__notion-fetch(id: "...")
```

Returns markdown-adjacent text. Database rows need `notion-query-database-view` with the collection ID.

## Images / screenshots

Don't convert. If the image is knowledge (diagram, whiteboard photo), describe it in markdown and reference the image path. If the image is a scanned document, flag to user: OCR requires external tooling (`tesseract`, Claude's vision if the image is pasted directly).

## Decision tree

```
Is it text already?
├── Yes → use as-is
└── No
    ├── Is it a Google Drive native file? → read_file_content (MCP)
    ├── Is it a Notion page?              → notion-fetch (MCP)
    ├── Is pandoc available?              → try pandoc first
    │   ├── Success                       → commit markdown
    │   └── Failure                       → fall back to pdftotext / openpyxl / ask user
    └── Is it a scanned image?            → ask user for OCR or a text copy
```

## What NOT to do

- Don't commit the binary to the repo just because you can't convert it. Leave it in its source system; flag in the ingest log.
- Don't hand-transcribe large documents. If pandoc fails, say so and ask the user.
- Don't trust OCR output without showing it to the user for review.
