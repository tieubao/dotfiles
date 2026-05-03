---
name: reconcile-properties
description: Use when the user asks to reconcile, sync, or check drift between tieubao/family-office and tieubao/properties for shared property data (rent, ownership, status, addresses). Also invoke automatically before running /health-check or monthly net-worth/cashflow snapshots in family-office, to catch stale figures before they get committed. Read-only by default; mutates only on user confirmation.
---

# Reconcile properties

Detect and resolve drift between two local personal repos: `tieubao/family-office` (financial truth) and `tieubao/properties` (operational detail). Enforces the Single Source Of Truth (SSOT) rule declared in `family-office/decisions/0011-cross-repo-ssot-properties.md`.

## When to use

- User says: `reconcile properties`, `sync properties`, `check properties drift`, `is family-office in sync with properties`, or variants.
- Before running `/health-check` in family-office (catch drift before the check reports it).
- Before writing a new `tracking/net-worth/YYYY-MM.md` or `tracking/pnl/YYYY.md` snapshot (snapshots cement whatever figures are in `assets/real-estate.md`; reconcile first).
- After the user edits `properties/catalog.yaml` or any `listings/*/property.yaml` and returns to a family-office session.

## When NOT to use

- General property questions. This skill is specifically for the drift-and-sync pass.
- When only `family-office` is being edited (no cross-repo concern).
- When the user is still brainstorming what to own; run after a decision is made.

## Field-ownership table (SSOT)

This is the rule the skill enforces. The canonical version lives at `family-office/decisions/0011-cross-repo-ssot-properties.md` — if that file disagrees with this table, the ADR wins.

| Field | Master repo | Master file | Mirror location(s) |
|---|---|---|---|
| Slug, name, address, city, type, status, category, bedrooms | properties | `catalog.yaml` + `listings/<slug>/property.yaml` | family-office narrative only (no table duplication) |
| Monthly rent (`rent_vnd`) | properties | `catalog.yaml` | `family-office/assets/real-estate.md` § "Current cashflow" + § "Income-producing" |
| Ownership at catalog level (`ownership`: self / parents / partner) | properties | `catalog.yaml` | family-office narrative |
| Ownership legal split (`ownership_legal`: sole / joint-with-partner) | properties | `listings/<slug>/property.yaml` | `family-office/assets/real-estate.md` § "Ownership structure" |
| Tenant name, type, contact, lease dates | properties | `listings/<slug>/property.yaml` + `contracts/` | family-office NEVER; PII stays in properties or `_vault/` |
| Photos, red book scans, contracts | properties | `listings/<slug>/` | family-office references by path only |
| Purchase price, current estimated value | family-office | `assets/real-estate.md` | properties NEVER |
| Gross / net yield, ROI | family-office | `assets/real-estate.md` | properties NEVER |
| Mortgages, loans, debt-to-asset | family-office | `assets/liabilities.md` | properties NEVER |
| PnL, rental ledger, tax filings | family-office | `tracking/`, `operations/rental-tax/`, `scripts/` | properties NEVER |

## Workflow (7 steps)

### Step 1. Locate both repos

Repos live at:
- `~/workspace/tieubao/family-office` (or user's current cwd if it ends in `family-office`)
- `~/workspace/tieubao/properties` (sibling directory)

If the properties repo cannot be found at the expected path, ask the user. Do not guess alternate paths.

### Step 2. Read masters (properties side)

Read:
- `properties/catalog.yaml` — the master index
- `properties/listings/<slug>/property.yaml` for each slug (only the ones with `status: occupied` or `status: renovation` + rent-bearing; skip land-bank / watchlist unless the user asks)

Parse the relevant fields from the SSOT table.

### Step 3. Read mirrors (family-office side)

Read:
- `family-office/assets/real-estate.md` — the main mirror target
- Any other `assets/*.md` file that references specific properties
- `family-office/INDEX.md` — if it shows rent totals

### Step 4. Diff

Produce a drift table:

| Field | Property | Master value | Mirror value | Mirror location | Action |
|---|---|---|---|---|---|
| rent_vnd | hado-centrosa-d10-apartment | 25,000,000 | 25M | assets/real-estate.md § Income-producing | ok |
| rent_vnd | le-hong-phong-dalat-house | 14,000,000 | 14M | assets/real-estate.md § Income-producing | ok |
| ownership_legal | hado-centrosa-d10-apartment | (not filled) | (not filled) | assets/real-estate.md § Ownership structure | missing both sides |

Classify each row:
- **ok** — master and mirror agree
- **drift** — values differ; master wins
- **missing-mirror** — master has value, mirror does not
- **missing-master** — mirror has value, master does not (investigate; may indicate the wrong direction was taken earlier)
- **contradiction** — values differ AND the mirror has a non-trivial annotation suggesting intent. Surface both; do not auto-resolve.

### Step 5. Report

Show the drift table to the user. Call out:
- How many rows need action
- Any contradictions (blocking)
- Any missing-master rows (these are unusual; worth a second look)

### Step 6. Apply (on confirmation)

On user `yes` / `apply` / `go`:

1. For each **drift** row: rewrite the mirror value to match master. Keep the mirror's formatting (e.g., if mirror uses "25M" shorthand, keep the shorthand but update the number).
2. For each **missing-mirror** row where master has a value: add the mirror entry.
3. For **contradictions**: do nothing; leave for the user to resolve manually.
4. Where appropriate, add an HTML comment above the updated block:

   ```markdown
   <!-- mirrored from tieubao/properties/catalog.yaml; update there first, then run /reconcile-properties -->
   ```

5. Update the `last_updated` frontmatter in any file modified.

### Step 7. Report + log

Print a summary: N fixed, M unchanged, P flagged. If family-office has an `INGEST_LOG.md`, append a short block (type: `reconcile`, status: `done`). No separate log file.

Do NOT auto-commit. User runs git.

## Output format expectations

Structured markdown. Always show the drift table, not prose. Always ask for explicit confirmation before mutating anything.

## What NOT to do

- Never write to `properties/` for any field mastered in `family-office` (purchase price, yield, etc.).
- Never write tenant names or contact info into family-office.
- Never silently resolve a contradiction.
- Never re-read the SSOT table from memory; always re-read the ADR file fresh each invocation (it may have been updated).
- Never run this headless / unattended; it requires user confirmation on every mutation.
- Never commit. The user decides when to commit.

## Trigger phrases

Equivalent: `reconcile properties`, `sync properties`, `check properties drift`, `diff properties`, `properties drift check`.

## Future extensions (deferred)

- `tieubao/books` mirror: royalties live in family-office, manuscript in books. Same pattern, new field table.
- `tieubao/crypto-tracker` mirror: when the repo exists, holdings live there, valuations / cost basis live in family-office.
- Automated run from `/health-check`: a hook could invoke this skill before the check runs, so stale data is flagged in one pass.
