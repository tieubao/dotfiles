# Severity ladder examples

Default ladder: `P0` / `P1` / `P2` / `P3`. Calibrate at filing time based on observed impact.

## Generic definitions

| Level | Definition | Time-to-respond |
|---|---|---|
| **P0** | Funds at risk OR live operation blocked OR data loss | Drop everything, fix now |
| **P1** | Monitoring blind OR alerts unreliable OR meaningful business impact | Fix today |
| **P2** | Degraded surface, no funds risk | Fix this week |
| **P3** | Cosmetic / informational | Backlog |

## Per-repo-type calibration

Adjust the examples to your repo's domain. Below are common shapes:

### Trading / financial-ops repos

| Level | Example |
|---|---|
| P0 | `trade --live` rejects every invocation; risk module returns wrong sign; broker API silently double-fills; portfolio snapshot file overwrites with empty |
| P1 | Monitoring agent silent for >1h; signal alerts stop firing for held positions; daily PnL roll-up fails to compute |
| P2 | Discord alerts duplicated on retry; dashboard tile shows stale data >24h; non-critical CLI subcommand throws |
| P3 | Doc drift in handoff; ASCII diagram render issue in INDEX |

### Infrastructure / monitoring repos

| Level | Example |
|---|---|
| P0 | Worker returning 5xx on every request; cron not firing for >1h; data store unwritable |
| P1 | Per-host rate limiter rejecting legit traffic; alert dispatch silently null-sinking; backup job not completing |
| P2 | Dashboard slow to load; one rule firing duplicate alerts; retention cron failing one of N tables |
| P3 | Wrangler.toml comment outdated; README link broken |

### Knowledge / docs repos

| Level | Example |
|---|---|
| P0 | (rare) Repo corrupt or PRs failing to merge globally |
| P1 | Cross-references broken across many docs; index file removed; ingest pipeline not picking up files |
| P2 | Some links broken; staleness tracker not updating |
| P3 | Format inconsistency; typo |

### Personal / family-office repos

| Level | Example |
|---|---|
| P0 | Net-worth roll-up shows wrong total; rental income misrecorded in shared properties data |
| P1 | Monthly close skipped; deadline-tracking alerts not firing |
| P2 | One rental's status field stale; one ADR moved without redirect |
| P3 | Doc reorg needed |

## How to set severity at filing

Pick the highest matching definition. **Do not** downgrade based on "I can fix it quickly" — severity reflects impact, not effort. A P0 that takes 30s to fix is still a P0; the value of the severity tag is in the post-incident review.

If severity rises during investigation (e.g. a P2 turns out to also be silently dropping signals), update both the frontmatter AND a Timeline row noting the re-grade. This is normal and expected; many incidents start at P2 and end at P1.

Severity is **not** a queue priority. A P3 doc-rot incident might get prioritized over a P1 monitoring blind because the latter has a workaround. Use HANDOFF + your normal task queue for prioritization; severity is metadata for the historical record.
