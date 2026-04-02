# R-01: Fix install.sh idempotency gap

**Priority:** High
**Status:** Done
**Related:** F-01 in feature-specs.md

## Problem

install.sh was rewritten to be idempotent (line 69: fast path when link is correct + config exists), but there's still a gap: when the symlink is correct but `chezmoi.toml` doesn't exist yet (e.g. user deleted config but kept the link), line 87 runs `chezmoi init --apply` which re-prompts for all variables.

More importantly, there's no validation that the fast-path `chezmoi apply` actually succeeded. If it fails silently (e.g. broken template), the script still prints "Done!" with exit 0.

## Spec

1. Add `chezmoi apply` exit code check on the fast path (line 70-71):
   ```bash
   if ! chezmoi apply; then
       echo "==> ERROR: chezmoi apply failed"
       exit 2
   fi
   ```

2. Add a `--check` flag that runs `chezmoi apply --dry-run` and reports without applying:
   ```bash
   --check) CHECK_ONLY=1 ;;
   ```

3. Add a post-apply validation step that checks key files exist:
   ```bash
   # Verify critical files were deployed
   for f in ~/.config/fish/config.fish ~/.gitconfig ~/.ssh/config; do
       if [ ! -f "$f" ]; then
           echo "==> WARNING: Expected $f but it doesn't exist"
       fi
   done
   ```

## Files to modify
- `install.sh`

## Test
1. Run `install.sh` on configured machine. Should apply and verify key files.
2. Break a template intentionally. Run `install.sh`. Should exit 2, not print "Done!".
3. Run `install.sh --check`. Should dry-run only, no changes.
