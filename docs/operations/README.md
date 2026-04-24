# docs/operations/

Logs of specific migrations, secret rotations, and one-off ops runs. Dated filenames.

These are **records of things done**, not reusable patterns. For reusable patterns see [`../specs/`](../specs/). For hostname-tagged per-change entries see [`../sync-log.md`](../sync-log.md).

## File naming

`YYYY-MM-<slug>.md`. The date is when the operation was planned or executed, not when the file was last edited.

## When to add an entry

- Applying a pattern spec to the author's specific setup (vault migrations, SA rotations, machine re-provisioning).
- Any multi-step ops run where the exact steps, item names, or timing matter for future audit or rollback.
- Anything that would otherwise pollute a pattern spec with personal identifiers, item names, or cross-repo references.

## When NOT to add an entry

- Routine `chezmoi apply` runs → `sync-log.md`.
- Reusable design decisions → `../specs/` or `../decisions/`.
- Single-line changes → commit message is enough.
