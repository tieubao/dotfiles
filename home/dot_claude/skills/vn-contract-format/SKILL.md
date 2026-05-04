---
name: vn-contract-format
description: Use when the user wants to draft a print-ready Vietnamese legal document (biên bản thanh lý hợp đồng, biên bản bàn giao, giấy uỷ quyền, hợp đồng thuê nhà, biên nhận, hợp đồng đặt cọc) that someone will print on A4 and sign by hand. Symptoms include "soạn biên bản X", "in ra ký", "biên bản thanh lý / bàn giao / nghiệm thu", "giấy uỷ quyền cho X đại diện ký", "format hợp đồng print-ready", "make this a Word doc". Workflow is markdown-source-of-truth + python-docx generator producing a clean A4 .docx with TNR 13pt, fixed-width tables, and proper Vietnamese legal structure (quốc hiệu, tiêu ngữ, các Điều, chữ ký 2 cột). NOT for English contracts (style differs), NOT for casual letters, NOT for slide decks.
---

# Format a Vietnamese legal document into a print-ready Word file

The default failure mode here: try to render markdown directly to .docx via pandoc and end up with mismatched columns, wrapped underscore lines, and table layouts Word silently mangles. This skill encodes a tested two-file workflow (markdown + python-docx generator) that produces clean A4 output Vietnamese signers will accept.

## When to fire this skill

User wants a **legal-style** Vietnamese document that someone will:
1. Print on A4
2. Fill in blanks by hand (CCCD, signatures, dates)
3. Sign with wet ink

Examples:
- Biên bản thanh lý hợp đồng thuê nhà (lease termination)
- Biên bản bàn giao nhà / tài sản (property handover)
- Giấy uỷ quyền (power of attorney)
- Hợp đồng đặt cọc / thuê nhà (lease / deposit contract)
- Biên nhận tiền cọc (deposit receipt)

Do NOT use for:
- English-language contracts (use `frontend-design` or generic markdown)
- Casual letters / messages
- Internal checklists meant to stay digital
- Slide decks or marketing material

## The two-file workflow

```
listings/<slug>/contracts/<event-folder>/
├── 03-bien-ban-thanh-ly.md      ← human-editable markdown source (git-versioned)
└── 03-bien-ban-thanh-ly.docx    ← print-ready Word file (generated, may be git-ignored)
```

The .md is the source of truth. The .docx is regenerated from a python script kept alongside (or in `/tmp/` if one-off). Never edit the .docx directly - changes will be lost on next regen.

## Folder convention (Vietnamese real-estate / family-office repos)

For a `properties` repo with `listings/<slug>/`:

| Goes in `contracts/` | Goes in `documents/` |
|---|---|
| Tenant lease lifecycle (signed leases, deposit receipts, handover forms, termination notices, POAs related to a lease) | Permanent property records (red book / sổ đỏ, original purchase contract, tax records, construction permits, utility contracts gắn với nhà) |

If unsure: contracts/ for anything tied to a specific tenant or transaction, documents/ for anything tied to the property itself.

## Steps

1. **Confirm scope with user**:
   - What document type? (biên bản thanh lý, giấy uỷ quyền, hợp đồng thuê, biên nhận, etc.)
   - Who are the parties? Get **full legal names in ALL CAPS** (e.g. NGUYỄN THỊ MINH TRANG, not "Trang"). Family/casual names belong outside the contract.
   - Address of the asset / event location? Use real Vietnamese format: số nhà, đường, phường, thành phố, tỉnh.
   - Effective date? Must match the day of signing, not drafting date.
   - Where will it live? (per the folder convention above)

2. **Write the markdown source first** (`<NN>-<slug>.md`). Structure:

   ```
   <quốc hiệu + tiêu ngữ + o0o>

   # <TITLE IN ALL CAPS>
   (Optional subtitle: V/v: ...)

   - Căn cứ ...;
   - Căn cứ ...

   Hôm nay, ngày DD tháng MM năm YYYY, tại <địa chỉ>, chúng tôi gồm:

   ### BÊN A (...)
   <table: Họ tên, CCCD, địa chỉ, SĐT - one row each>

   ### BÊN B (...)
   <same>

   <Body intro: "Hai bên cùng thống nhất ... với các nội dung sau:">

   ### ĐIỀU 1. <TITLE>
   ...
   ### ĐIỀU 2. <TITLE>
   ...
   ### ĐIỀU N. HIỆU LỰC
   "Văn bản này có hiệu lực kể từ ngày ký và được lập thành 02 (hai) bản
    có giá trị pháp lý như nhau, mỗi bên giữ 01 (một) bản."

   <Optional: Ghi chú section with blank lines>

   <Signature 2-column block: Bên A | Bên B>

   ### Tài liệu đính kèm
   - [ ] ...
   ```

3. **Generate the python-docx script** using the helpers below. Output A4, Times New Roman 13pt, margins 2cm/2.2cm. Save the script either:
   - Inline in the project at `<contract-folder>/build_<slug>.py` (if you want it versioned)
   - Or in `/tmp/build_<slug>.py` (if one-off; copy contents into your reply for the user)

4. **Run the script** to produce the .docx. Verify visually by opening in Word/Pages. Common things to check:
   - All fill-in lines visible (no "missing" lines from Word's paragraph border merge bug)
   - No text wrapping inside cells (column widths sufficient)
   - Signature block aligned (Bên A name lines up with Bên B last row)
   - Header (quốc hiệu + tiêu ngữ) centered
   - Title centered, bold, in caps

5. **Cross-link from related docs**:
   - From the project README / handover instructions, reference the contract by filename
   - From `tenant-history.md` (or equivalent), log the event with a pointer to the contract folder

## Required python-docx helpers (battle-tested)

These solve specific Word/python-docx pitfalls. Copy them verbatim. Full reference implementations in `references/`.

### `set_fixed_table_layout(table, col_widths_cm)` (lock column widths)

**Why**: python-docx alone does NOT enforce column widths. Word silently auto-fits to 50/50 unless you set `tblLayout="fixed"` + `tblGrid` + `tcW` on every cell.

```python
def set_fixed_table_layout(table, col_widths_cm):
    tblPr = table._tbl.find(qn('w:tblPr'))
    if tblPr is None:
        tblPr = OxmlElement('w:tblPr')
        table._tbl.insert(0, tblPr)
    for el in tblPr.findall(qn('w:tblLayout')):
        tblPr.remove(el)
    tblLayout = OxmlElement('w:tblLayout')
    tblLayout.set(qn('w:type'), 'fixed')
    tblPr.append(tblLayout)

    tblGrid = table._tbl.find(qn('w:tblGrid'))
    if tblGrid is not None:
        table._tbl.remove(tblGrid)
    tblGrid = OxmlElement('w:tblGrid')
    for w_cm in col_widths_cm:
        gridCol = OxmlElement('w:gridCol')
        gridCol.set(qn('w:w'), str(int(w_cm * 567)))
        tblGrid.append(gridCol)
    tblPr.addnext(tblGrid)

    for row in table.rows:
        for i, cell in enumerate(row.cells):
            tcPr = cell._tc.get_or_add_tcPr()
            tcW = tcPr.find(qn('w:tcW'))
            if tcW is None:
                tcW = OxmlElement('w:tcW')
                tcPr.append(tcW)
            tcW.set(qn('w:w'), str(int(col_widths_cm[i] * 567)))
            tcW.set(qn('w:type'), 'dxa')
```

### `info_table(rows, label_w_cm, value_w_cm)` (label-value rows with fill lines)

**Why**: The standard "Họ tên: ___, CCCD: ___" block. Auto-detects fill-in cells (value starts with `____` or is empty) and uses **cell bottom border** for the line. Avoids the underscore-string-wraps problem entirely.

Default widths: label 4.5cm, value 12.2cm (sums to 16.7cm = A4 minus 2cm/2.2cm margins).

```python
def info_table(rows, label_w_cm=4.5, value_w_cm=12.2, *, parent=None,
               font_size=13, row_height_cm=None):
    if parent is None:
        parent = doc
    t = parent.add_table(rows=len(rows), cols=2)
    t.autofit = False
    set_fixed_table_layout(t, [label_w_cm, value_w_cm])
    fillin_mask = []
    for i, (label, value) in enumerate(rows):
        if row_height_cm:
            t.rows[i].height = Cm(row_height_cm)
            t.rows[i].height_rule = WD_ROW_HEIGHT_RULE.AT_LEAST
        c0, c1 = t.rows[i].cells
        c0.paragraphs[0].text = ""
        c0.paragraphs[0].add_run(label).font.size = Pt(font_size)
        c1.paragraphs[0].text = ""
        is_fillin = value.startswith("____") or value == ""
        if not is_fillin:
            run = c1.paragraphs[0].add_run(value)
            run.font.size = Pt(font_size)
            # Bold names that look like full Vietnamese names (caps)
            if value.isupper() or "Bà " in value or "Ông " in value:
                run.bold = True
        fillin_mask.append([False, is_fillin])
    apply_borders(t, fillin_mask)
    return t
```

### `apply_borders(table, fillin_mask)` (cell-level borders, NOT paragraph-level)

**Why**: Paragraph borders (`w:pBdr/bottom`) get **merged by Word** when consecutive paragraphs share the same border style - only the last paragraph's border draws. Even setting `w:between` produces messy double-lines. **Always use cell borders for fill lines.**

```python
def apply_borders(table, fillin_mask):
    for i, row in enumerate(table.rows):
        for j, cell in enumerate(row.cells):
            tcPr = cell._tc.get_or_add_tcPr()
            for el in tcPr.findall(qn('w:tcBorders')):
                tcPr.remove(el)
            tcBorders = OxmlElement('w:tcBorders')
            for edge in ('top', 'left', 'right'):
                b = OxmlElement(f'w:{edge}')
                b.set(qn('w:val'), 'nil')
                tcBorders.append(b)
            bottom = OxmlElement('w:bottom')
            if fillin_mask[i][j]:
                bottom.set(qn('w:val'), 'single')
                bottom.set(qn('w:sz'), '6')
                bottom.set(qn('w:color'), '000000')
            else:
                bottom.set(qn('w:val'), 'nil')
            tcBorders.append(bottom)
            tcPr.append(tcBorders)
```

### `add_label_with_leader_line(cell, label, tab_at_cm)` (inline fill in narrow cell)

**Why**: When a cell needs a "Label: ____________" pattern but is too narrow for an info_table approach (e.g. inside a signature block cell), use Word's tab leader feature. `WD_TAB_LEADER.LINES` draws an underscore from end-of-label to the tab stop position. Auto-fits cell width, never wraps.

```python
def add_label_with_leader_line(cell, label, *, tab_at_cm=7.5, font_size=12,
                                alignment=WD_ALIGN_PARAGRAPH.LEFT, space_after=Pt(2)):
    cell.paragraphs[0].text = ""
    p = cell.paragraphs[0]
    p.alignment = alignment
    p.paragraph_format.space_after = space_after
    p.paragraph_format.tab_stops.add_tab_stop(
        Cm(tab_at_cm), WD_TAB_ALIGNMENT.LEFT, WD_TAB_LEADER.LINES
    )
    if label:
        p.add_run(label).font.size = Pt(font_size)
    p.add_run("\t").font.size = Pt(font_size)
    return p
```

### `fill_lines_table(n_rows, width_cm)` (full-width blank lines for "Ghi chú")

**Why**: For Ghi chú or other free-form fill areas, use a 1-column N-row table with cell bottom borders. Reliable, no wrapping, no Word merge bug.

```python
def fill_lines_table(n_rows, *, width_cm=16.7, row_height_cm=0.7, parent=None):
    if parent is None:
        parent = doc
    t = parent.add_table(rows=n_rows, cols=1)
    t.autofit = False
    set_fixed_table_layout(t, [width_cm])
    for i in range(n_rows):
        row = t.rows[i]
        row.height = Cm(row_height_cm)
        row.height_rule = WD_ROW_HEIGHT_RULE.AT_LEAST
        row.cells[0].paragraphs[0].text = ""
    for row in t.rows:
        cell = row.cells[0]
        tcPr = cell._tc.get_or_add_tcPr()
        for el in tcPr.findall(qn('w:tcBorders')):
            tcPr.remove(el)
        tcBorders = OxmlElement('w:tcBorders')
        for edge in ('top', 'left', 'right'):
            b = OxmlElement(f'w:{edge}'); b.set(qn('w:val'), 'nil')
            tcBorders.append(b)
        bottom = OxmlElement('w:bottom')
        bottom.set(qn('w:val'), 'single')
        bottom.set(qn('w:sz'), '6')
        bottom.set(qn('w:color'), '000000')
        tcBorders.append(bottom)
        tcPr.append(tcBorders)
    return t
```

## Pitfalls and how to avoid them

| Pitfall | Symptom | Fix |
|---|---|---|
| Em-dash `—` anywhere | User's hard rule violated | Use `,`, `.`, `;`, `(...)`, or split sentence. Greppable rule: `grep -nE "—"` should always return zero in your generated content. |
| Underscore string in narrow cell | Wraps to next line, orphan `_` | Use cell bottom border (info_table fillin) or tab leader (add_label_with_leader_line) |
| Paragraph bottom border, multiple in a row | Only last line draws (Word merges) | Use a table; never use `pBdr/bottom` for fill lines |
| Paragraph border + `w:between=single` | Draws too many lines (above AND below) | Same: use a table |
| Cell content vertically misaligned with neighbor | Sig name floats to top of row | Set `cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.BOTTOM` (or use balanced row counts) |
| Long value wraps in info_table | "Bà X (đại diện ký by Y)" breaks the column | Split into TWO rows: one for name, one for "Người đại diện ký:" |
| Date in document mismatches signing day | Legal weakness, can be challenged | Always use the **day-of-signing** date, not draft date. If unsure, leave blank with `____/____/______` |
| Casual name in formal contract | Looks unprofessional, may be invalid | Always use **full legal name in ALL CAPS** (e.g. NGUYỄN THỊ MINH TRANG). Casual "Trang" is fine outside the contract. |
| Generic A4 margins 2.54cm | Looks too padded for VN forms | Use 2cm top/bottom, 2.2cm left, 2cm right (matches VN office norms) |
| Chỉ ký theo uỷ quyền nhưng không có Giấy uỷ quyền đính kèm | Bên thuê có thể từ chối ký | Always pair: nếu Bên A signed by proxy, must include Giấy uỷ quyền in the same handover folder |

## Page setup (always)

```python
for section in doc.sections:
    section.page_height = Mm(297)
    section.page_width = Mm(210)
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)
    section.left_margin = Cm(2.2)
    section.right_margin = Cm(2)

# Default font
style = doc.styles['Normal']
style.font.name = 'Times New Roman'
style.font.size = Pt(13)
rPr = style.element.get_or_add_rPr()
rFonts = rPr.find(qn('w:rFonts'))
if rFonts is None:
    rFonts = OxmlElement('w:rFonts')
    rPr.append(rFonts)
rFonts.set(qn('w:ascii'), 'Times New Roman')
rFonts.set(qn('w:hAnsi'), 'Times New Roman')
rFonts.set(qn('w:cs'), 'Times New Roman')
```

## Standard imports

```python
from docx import Document
from docx.shared import Pt, Cm, Mm
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_ROW_HEIGHT_RULE
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
```

## Reference implementations

Two complete, tested generator scripts in `references/`:

- `references/build_bien_ban_thanh_ly.py` - Biên bản thanh lý hợp đồng thuê nhà (lease termination, signed by proxy)
- `references/build_giay_uy_quyen.py` - Giấy uỷ quyền (power of attorney for handover)

Adapt either as a starting point for new document types. Keep the helpers (`set_fixed_table_layout`, `info_table`, `apply_borders`, `add_label_with_leader_line`, `fill_lines_table`) verbatim - they encode hard-won fixes.

## Verification before delivering

Before telling the user "done":

1. Run the generator. It should print `OK: <path>` and exit 0.
2. Open the .docx in Word/Pages (`open <path>`).
3. Visually check:
   - [ ] Quốc hiệu + tiêu ngữ centered at top
   - [ ] Title bold, all caps, centered
   - [ ] All Bên A / Bên B fields visible, no wrapping
   - [ ] Each fill-in line has exactly one underline, full-width of its column
   - [ ] Signature block: Bên A name aligned with Bên B's last row
   - [ ] Date matches signing day (not drafting day)
   - [ ] Full names in ALL CAPS, bold
   - [ ] Page count is reasonable (1-3 pages typically)
   - [ ] No em-dashes anywhere (`grep -E "—" your_script.py` returns nothing)
4. If user has the file open in Word, regenerating won't auto-reload. Tell them to close and reopen, or close it for them via `osascript`.
