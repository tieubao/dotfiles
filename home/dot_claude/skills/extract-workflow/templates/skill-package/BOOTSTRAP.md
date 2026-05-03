# BOOTSTRAP: set up SKILL-NAME-HERE in a fresh repo

Run once per repo. After this, the per-run `WORKFLOW.md` works against existing repo state.

## What this creates

[List the files / directories the bootstrap stamps out:]
- `<path>/<file>` — purpose
- `<dir>/` — purpose

## Steps

1. **Detect existing state.** Check whether `<expected-files>` already exist. If yes, skip ahead to "configure" — don't overwrite.

2. **Create skeleton files** from `templates/`:
   ```bash
   mkdir -p <repo>/<dirs>
   cp <skill-dir>/templates/<file> <repo>/<path>/<file>
   ```

3. **Write the per-repo adapter** at `<repo>/.claude/<skill-name>-config.md`. Default content:
   ```markdown
   # <skill-name> config (per-repo)

   <key1>: <default-value>
   <key2>: <default-value>
   <key3>: <default-value>
   ```
   Surface the defaults to the user; ask if any need overriding.

4. **Update `<repo>/CLAUDE.md`** with a short pointer to the new skill (1-2 lines). Place under the closest existing section header.

5. **Verify**:
   - `ls <expected-paths>` resolves
   - The config file exists with the correct keys
   - User confirms ready to run the per-run workflow

## What NOT to do

- Don't bootstrap if existing files would be overwritten. Surface conflicts to the user first.
- Don't add the per-repo adapter to global skill state — it lives **inside the calling repo**.
- Don't commit the bootstrap files automatically. User commits when ready.
