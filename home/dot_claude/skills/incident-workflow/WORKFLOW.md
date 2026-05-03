# Incident Filing Workflow

Per-incident lifecycle. Read this when filing or updating an incident report.

## Lifecycle

| Phase | Status | What you fill in |
|---|---|---|
| Investigation in progress | `status: open` | TL;DR + Timeline + Symptoms + Diagnostic steps as the investigation runs. Mark Fix sections `[in progress]`. |
| Fix landed | `status: open` (still) | Fix(es) applied table with PR + commit links. Add Lessons section. Follow-ups can be open `H-NN` items. |
| All follow-ups closed | `status: closed` | Bump `last_updated`, mark closed. Do **not** delete. Add a row to the index. |

An open incident is a debt against the repo. Closed incidents are pure historical reference.

## Filing steps

### 1. Decide the slug

Kebab-case, 2-5 words, describes the **mechanism** if known, else the **symptom**.

- Good: `vps-mon-buffer-deathspiral`, `binance-testnet-tls-handshake`, `hermes-plugin-import-throw`
- Bad: `bug-fix-1`, `monday-debug`, `the-incident`

### 2. Copy the template

```sh
cp <incidents_path>/_TEMPLATE.md <incidents_path>/$(date -u +%Y-%m-%d)-<slug>.md
```

If `template_path` points to the skill (`skill:incident-workflow/templates/_TEMPLATE-<visibility>.md`), copy from there instead.

### 3. Pick the ID

Next sequential `INC-NNN` (zero-padded to 3 digits, frontmatter only; **not** in the filename).

### 4. Fill TL;DR + Timeline + Symptoms first

Even before root cause is named. Future-you re-reading this in 6 months should be able to grasp the shape of the incident in 30 seconds from the TL;DR.

Timeline format (use epoch + UTC + local-tz columns):

```markdown
| Epoch | UTC | Local | Event |
|---|---|---|---|
| 1776986700 | 2026-04-23T23:25 | 2026-04-24T06:25 | First Discord CRIT alert |
| ... | ... | ... | ... |
```

Epoch column makes timeline events grep-able + cross-reference-able with logs / D1 queries / wrangler tails.

### 5. Fill Diagnostic steps as you go

Each step:

```markdown
### Step N — <name>

`<command actually run>`

Result: <relevant slice of output>. Inference: <what this tells you>.
```

Mark hypotheses as **falsified** vs **confirmed**. Pin the smoking-gun evidence explicitly.

### 6. When root cause is named

Write the `## Root cause` section as a single paragraph. Mechanism, not trigger.

Trigger = "yesterday's deploy".
Mechanism = "agent buffer-flush vs Worker rate-limit interaction".

**For P0/P1** incidents, also write the `## ELI5` section now (150-300 words, plain-language analogy, end with the fix in one sentence). Write while analogies are fresh; it's hard to reconstruct weeks later. Optional for P2/P3 unless the incident touches something owner-facing.

### 7. When fix lands

Fill `## Fixes applied` table with PR + commit links. Add `## Lessons` (concrete process or code shifts; not "be more careful"). Open follow-up `H-NN` items if they exist.

### 8. Cross-references (mandatory both directions)

- Update HANDOFF.md "Last session" entry to link the incident report.
- Update any new SPEC `## References` section to link back.
- Update any new ADR scope/notes to mention the incident ID.
- The incident's own `## References` section closes the loop.

### 9. When all follow-ups close

- Bump `last_updated` in frontmatter.
- Flip `status: closed`.
- Add a row to `<incidents_path>/README.md` index.

## Severity

| Level | Definition | Example |
|---|---|---|
| P0 | Funds at risk OR live trading blocked OR data loss | Engine throws on every `trade --live` |
| P1 | Monitoring blind OR alerts unreliable | vps-mon agent-silent for >1h |
| P2 | Degraded surface, no funds risk | Discord alerts duplicated, dashboard slow |
| P3 | Cosmetic / informational | Doc drift, ASCII rendering issue |

Set at filing time based on observed impact. If severity rises during investigation, update both frontmatter AND a Timeline row noting the re-grade.

See `references/severity-ladder.md` for examples calibrated per repo type (trading, infra, docs).

## Privacy

- **Private repos**: full forensic detail OK. HMAC hashes, account IDs, internal IPs all fine.
- **Public repos**: sanitization-first. The template includes explicit "do NOT include" callouts. Run `references/privacy-gate.md` checklist before save.
- **Sanitized cross-publish**: incidents that have lessons reusable in a generic context can publish to a public TIL repo (e.g. `~/workspace/tieubao/til/ops-incidents/`) under that repo's privacy gate. **Default is private only; never auto-publish.**

## Anti-patterns

- **Filing for operational toil** ("I forgot a flag, then fixed it"). Not an incident.
- **Filing for routine deploys** even if they ship fixes for prior incidents. The prior incident report owns the fix.
- **Re-writing closed incidents.** New investigation = new file with `## References` link.
- **Skipping cross-references** because "it's obvious." Future-you in 6 months won't remember.
- **Over-detail on hypotheses that were obviously wrong.** Brief mention is enough; pin the ones that informed real direction changes.
- **Forgetting the timeline epoch column.** The wall-clock time alone isn't enough for cross-referencing logs.
