---
name: cashflow-close
description: Use when the user asks to process, ingest, or close a month of family cashflow in tieubao/family-office (e.g. "process April cashflow", "close April", "ingest expenses", "do the April books", "fill in May cashflow"). Triggers on screenshots of expense summaries, bank CSVs, transfer slips, or receipts dropped in _inbox/ OR pasted inline in a session. Produces a populated `tracking/cashflow/YYYY-MM.md` with deduped transactions, per-property and per-staff attribution, an `INGEST_LOG.md` entry, and source archival per the repo privacy rule. Cashflow only; net worth and PnL are out of scope.
---

# Cashflow close

Close a month of family bookkeeping for `tieubao/family-office`. Inputs are messy (screenshots of partner's Google Sheet, bank CSV exports, photo receipts, free-form notes); output is a single deterministic `tracking/cashflow/YYYY-MM.md` plus a logged ingest session.

## When to use

- User says: `process [month] cashflow`, `close [month]`, `ingest expenses`, `do the [month] books`, `fill in [month] cashflow`, `cashflow close`.
- User drops screenshots / CSVs / receipts into `_inbox/` and asks to "sort them" or "ingest them" AND the contents are spending/income data.
- User starts a fresh session and pastes/uploads expense summary images for a specific month.
- Before a quarterly review (`planning/reviews/YYYY-QN.md`) when the relevant months are still TBD.

## When NOT to use

- User wants net worth snapshot → use the (future) `networth-close` skill or fill `tracking/net-worth/YYYY-MM.md` manually.
- User wants annual PnL → that's `tracking/pnl/YYYY.md`, different shape, deferred.
- Inbox material is non-financial (contracts, IDs, manuscripts, generic notes) → use `ingest-to-wiki`.
- User wants to track a single one-off transaction (e.g. log a property tax payment) → just edit the relevant cashflow file directly; this skill is for batches.
- A monthly file already exists with `status: final` → ask before re-running; don't silently overwrite.

## Hard rules

These are non-negotiable. Violating any of them produces a wrong cashflow file.

1. **Single-write principle.** Every transaction recorded once. If a manual entry and a bank-statement entry describe the same spend, only one of them lands in the file.
2. **Bank precedence on conflict.** When a bank CSV/PDF and a manual entry overlap (same amount within ±5% AND same date within ±1 calendar day AND plausible same merchant), the bank entry wins. The manual entry is dropped (not summed).
3. **Cash-only items have no bank counterpart.** Markets (chợ), taxis, household staff cash payments, gifts, tips, small kid expenses → these come from the manual log only. Don't search for them in bank statements.
4. **Card-only items have no manual counterpart.** Subscriptions (iCloud, Gemini/Claude, domain renewals), online purchases, fuel-station card swipes → these come from the bank/card statement only. Don't expect them in the manual log.
5. **Property attribution required.** Every line under "Property maintenance", "Property tax / land lease", or "Construction" MUST reference a property by name (Hado Centrosa P21608, Le Hong Phong, Casamia Calm, Panoma, An Trung, TKH) OR be flagged `TBD` in the breakdown table. Never silently aggregate.
6. **Staff attribution required.** Every line under "Household staff" splits by person (Min nanny day = Chị Hưởng; Min nanny night = Chị Thanh; Cleaning = whoever). Cross-reference `operations/household-staff.md`. Never aggregate "nannies" into one line.
7. **Flag, do not guess.** When you can't confidently classify a transaction, leave the source identifier in the Notes section and ask the user. Wrong attribution is worse than `TBD`.
8. **Currency check.** All amounts in VND unless explicitly USD. If the source has USD, convert at month-end SBV rate AND record both (`USD 1,200 ≈ 30,500,000 VND @ 25,400`).
9. **Final-only status promotion.** A file is `status: partial` until income side is complete. Never write `status: final` unless every income source has a confirmed number (or is explicitly 0).
10. **Privacy rule.** Source originals (bank PDFs/CSVs with account numbers, signed receipts) → `_vault/`. The cashflow `.md` file shows category totals and merchant context, NEVER raw account numbers. See `.claude/ingest-config.md` for the exact rule.

## Canonical category mapping

Use these categories. Don't invent new ones without asking. Anchor: `tracking/cashflow/2026-04.md` (the worked example).

### Income lines

| Source | Notes |
|---|---|
| Salary + sales (Dwarves, Han) | Fluctuates with sales; pull from Dwarves payroll if available |
| Salary (partner) | Ask if not in inputs |
| Rental - <Property> (City) | One row per income-producing property; cross-reference `assets/real-estate.md` |
| Dividends (Dwarves) | Quarterly; not every month |
| Book royalties | 0 until "Raising the Kid" publishes |
| Investment returns | 0 unless tracked |
| Other | Use sparingly; prefer named row |

### Fixed expenses

| Category | Source pattern |
|---|---|
| Rent / mortgage | Currently 0 (debt-free) |
| Insurance premiums | Currently 0 (no active policies, see `assets/insurance.md`) |
| School / childcare (Đan) | Group sub-line items: cô <name>, swimming, etc. |
| Household staff - Nanny night (Min) | Chị Thanh, ca đêm |
| Household staff - Nanny day (Min) | Chị Hưởng, ca ngày |
| Household staff - Cleaning | Dọn nhà, count × rate |
| Subscriptions | iCloud, Gemini/Claude, domain renewals — usually card statements |
| Loan payments | Currently 0 |
| Savings contributions | Auto-transfers to savings accounts |

### Variable expenses

| Category | Source pattern |
|---|---|
| Groceries / food | Chợ + supermarket; mostly cash |
| Dining out | Restaurants, delivery |
| Transportation | Xăng (fuel), grab/be, parking |
| Utilities (electric, water, internet) | Per-household + per-property splits |
| Kids (diapers, clothes, toys) | Newborn-heavy this year |
| Health / medical | Out-of-pocket (no insurance) |
| Property maintenance | Per-property; see breakdown table below |
| Property tax / land lease | Per-property; annual but recorded in payment month |
| Construction (Casamia Calm + Panoma) | Separate line if material |
| Personal | |
| Gifts / social | |
| Other | Use sparingly |

### Property maintenance breakdown

When property maintenance has 2+ items, add a sub-table:

```
### Property maintenance breakdown

| Date | Amount (VND) | Item | Property |
|------|-------------|------|----------|
| DD/MM/YYYY | ... | ... | <Property name> or TBD |
| **Total** | **...** | | |
```

Properties whitelist (must match): Hado Centrosa P21608, Le Hong Phong, Casamia Calm, Panoma, An Trung, TKH. Anything else → ask.

## Workflow (8 steps)

### Step 1. Determine the month

Identify which `YYYY-MM` you're closing. Sources of truth, in order:
1. Explicit user statement ("close April 2026").
2. The latest month in the inputs (filenames, screenshot dates, statement periods).
3. The most recent month with `status: partial` in `tracking/cashflow/`.
4. Last resort: ask.

If the target file already exists with `status: final`, stop and ask before continuing.

### Step 2. Inventory inputs

List every artifact in scope:
- Files in `_inbox/` (or subdirectories).
- Files pasted/uploaded into the current session.
- Files referenced via Drive URL or file path.
- Files in `_vault/` the user explicitly points at.

Classify each by source type:

| Source type | Examples | Treatment |
|---|---|---|
| Manual log screenshot | partner's Google Sheet snapshot, handwritten list | Cash-side authority. Read OCR/multimodal. |
| Bank statement | VCB/Techcombank/ACB CSV or PDF | Card/transfer authority. Parse rows. |
| Card statement | credit card PDF | Subscriptions + online purchases authority. |
| Receipt photo | single transaction proof | Cross-reference; use to attribute uncertain items. |
| Transfer slip | screenshot of one-off transfer | Single transaction; useful for property tax / land lease. |
| Free-form note | "đã trả tiền điện 3M" | Treat as manual log entry. |

Print the inventory as a table to the user before doing extraction.

### Step 3. Extract transactions

For each source, produce a flat list of `{date, amount_vnd, raw_description, source_id, source_type}` rows. Don't categorize yet.

- **Screenshot/photo** → use multimodal read; capture every visible row. Note the image's frame (cutoff at top/bottom is common — flag if so).
- **CSV** → parse with a one-shot Python script if the format is non-trivial; otherwise read the file directly.
- **PDF** → pandoc or pdftotext, then regex/structure extraction. Vietnamese bank PDFs often have non-standard layouts; verify totals match.
- **Vietnamese text** → preserve diacritics in the `raw_description`. Don't strip them.

If a source is mostly unreadable (low-res, foreign format), surface it and ask.

### Step 4. Dedupe (cross-source)

For each pair of sources that COULD overlap (manual log + bank statement covering the same dates), apply the dedup rule:

```
For each manual_entry in manual_log:
    candidates = bank_entries WHERE
        abs(amount - manual_entry.amount) <= 5% of manual_entry.amount
        AND abs(date - manual_entry.date) <= 1 day
    IF candidates is non-empty:
        # Probable dup. Keep bank entry, drop manual entry.
        log: "Dropped manual entry '{desc}' as dup of bank entry '{bank_desc}'"
    ELSE:
        # Cash-only or unique. Keep manual entry.
```

Surface the dedup decisions in the output as a small section at the top of the Notes block. Never silently drop without logging.

If a manual entry and a bank entry are CLOSE but not within thresholds (e.g. amount differs by 10%, dates differ by 3 days), flag both and ask. Don't auto-decide.

### Step 5. Categorize and attribute

Map each surviving transaction to a category from the canonical list above.

- Property maintenance / tax / construction → require property attribution. If unclear, list as `TBD` in the breakdown table.
- Household staff → require person attribution (Chị Thanh / Chị Hưởng / cleaning).
- Subscriptions → group, name the services in Notes.
- "Personal" or "Other" → use sparingly. If you find yourself reaching for these, look harder for a real category first.

Compute subtotals: fixed, variable, income.

### Step 6. Fill the template

1. Copy `tracking/cashflow/_template.md` → `tracking/cashflow/YYYY-MM.md` (only if the file doesn't exist).
2. Add frontmatter:
   ```
   ---
   title: Cashflow - YYYY-MM
   type: tracking
   status: partial    # or final once income is complete
   last_updated: <today YYYY-MM-DD>
   review_cadence: monthly
   ---
   ```
3. Populate Income, Fixed expenses, Variable expenses tables. Use the canonical category labels verbatim.
4. Add the property-maintenance breakdown sub-table if needed.
5. Compute the Summary block. Show partial subtotals when items are TBD; never claim a total is complete when sub-rows are TBD.
6. Notes section structure:
   - First bullet: source list (e.g. "Sources: partner's Google Sheet screenshot 2026-05-01; VCB statement Apr 2026; ACB card statement Apr 2026").
   - Second bullet: dedup decisions (if any).
   - Third bullet: still-TBD items (income lines, missing categories).
   - Fourth bullet: anomalies / one-time spends worth flagging for the quarterly review.

Do NOT remove the file's existing data without explicit confirmation. If editing an existing partial file, merge.

### Step 7. Log the session

Append to `INGEST_LOG.md` at repo root (newest first), one block:

```markdown
## YYYY-MM-DD — Cashflow close YYYY-MM

**Status**: complete | partial (income TBD) | blocked (reason)

**Sources processed**:
- <source 1>
- <source 2>
- ...

**Output**: `tracking/cashflow/YYYY-MM.md`

**Dedup decisions**: N (M dropped manual entries as dup of bank)

**Flags raised**: <anything user needs to resolve>
```

### Step 8. Archive sources per privacy rule

Per `.claude/ingest-config.md`:

| Source | Destination |
|---|---|
| Bank statement PDF / CSV with account numbers | `_vault/statements/<bank>/YYYY-MM.<ext>` |
| Screenshot of partner's sheet (no account numbers, no signed name) | Discard from `_inbox/`; cashflow file is the mirror |
| Receipt photo with merchant + amount only | Discard if value extracted; vault if it's a contract/warranty receipt |
| Transfer slip with full account info | `_vault/transfers/YYYY-MM-<purpose>.<ext>` |
| Manual notes (free-form text) | Discard from `_inbox/`; mirror is in cashflow file |

Confirm archival actions with the user before moving anything into `_vault/`. Never delete from `_inbox/` without confirmation; move to `_inbox/processed/YYYY-MM/` if user prefers a soft delete.

## Output expectations

When the skill finishes, the user should see:
1. A short summary table: total income, total expenses, savings rate, # transactions processed, # dupes dropped, # items flagged TBD.
2. The path to the new/updated `tracking/cashflow/YYYY-MM.md`.
3. The `INGEST_LOG.md` entry.
4. A list of TBD items needing user input (with specific questions).
5. A list of anomalies worth flagging for the quarterly review.

## Anti-patterns

- ❌ Inferring a property attribution from "feels like an apartment thing" — always require the user to confirm if not explicit.
- ❌ Computing a "total" on a row with TBD sub-items.
- ❌ Aggregating multiple staff payments into one "Household staff" line.
- ❌ Writing raw account numbers into the cashflow `.md` file.
- ❌ Marking `status: final` while income is TBD.
- ❌ Treating `_inbox/` cleanup as more important than the user's confirmation.
- ❌ Silently dropping a manual entry as a dup without surfacing the decision.

## Worked example

`tracking/cashflow/2026-04.md` is the canonical reference. It demonstrates:
- Status `partial` because income is TBD.
- Fixed-expense subtotal computed despite TBD items (subtotal note: "Excluding TBD items").
- Property maintenance breakdown sub-table with mixed property attribution + TBD rows.
- Staff lines split by person (Chị Thanh / Chị Hưởng / cleaning).
- Notes section listing source + flags.

When in doubt about formatting, mirror April.

## Related skills

- `ingest-to-wiki` — generic ingest for non-financial material; this skill is the cashflow specialization.
- `reconcile-properties` — run before a cashflow close if any property income may have changed in `tieubao/properties`.

## Edge cases worth knowing

- **Income spans months**: Dwarves payroll on the 1st and 15th means a "May" payroll run might cover April work. Record by payment date (cash basis), not work date.
- **Construction milestone payments**: Casamia Calm / Panoma can have very large lump sums. Surface these prominently in Notes; they distort savings rate.
- **Property tax / land lease**: Annual, but recorded in the payment month. Don't pro-rate.
- **Wife is the primary bookkeeper today**: if she returns to the system, cashflow files should still merge cleanly. The skill should be runnable by her too (it's just markdown).
- **Drive sync**: partner's contributions land in `Drive/Family Office/Inbox/`. Pull to local `_inbox/` before triage if the user says "she sent stuff via Drive".
