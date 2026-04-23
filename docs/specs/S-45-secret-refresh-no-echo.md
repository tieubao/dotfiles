---
id: S-45
title: Stop echoing secret values in dotfiles secret refresh
type: fix
status: done
date: 2026-04-23
---

# S-45: Stop echoing secret values in dotfiles secret refresh

## Problem

`dotfiles secret refresh VAR` printed the raw secret value back to
stdout in a "Restart shell or: ..." hint at
`home/dot_config/fish/functions/dotfiles.fish:257`:

```fish
if test -n "$val"
    echo "✓ re-fetched from 1Password and cached"
    echo "  Restart shell or: set -gx $var '$val'"
end
```

The hint was trying to help the user paste a one-liner into the current
shell, but had two problems:

1. **It leaks the secret value to stdout.** The value lands in terminal
   scrollback, shell history if piped, screen recordings, and any
   process transcript capturing the TTY (including LLM tool-call
   logs). On 2026-04-23 during S-43 verification, a service account
   token was leaked into the Claude Code session transcript this way,
   causing the token to need rotation.

2. **The one-liner does not actually work the way the hint implies.**
   `set -gx VAR VALUE` called from the current fish shell sets the
   variable for that shell, but the hint was printed from inside the
   `dotfiles` function. A user who literally copy-pasted the hint's
   command into their shell would be setting it correctly; but the
   phrasing "Restart shell or:" misleadingly suggests a script-level
   equivalence that is not guaranteed across shells or tmux panes.

A hint that leaks the value AND is half-wrong is worse than no hint.

## Non-goals

- Replacing all of `dotfiles secret refresh` with a silent no-op. The
  command still runs, still clears the Keychain, still re-fetches from
  1P, still re-caches. Only the trailing echo that exposed `$val` is
  removed.
- Auditing `chezmoi apply` output for secret leaks. S-35 already
  eliminated apply-time `onepasswordRead` calls from this path; the
  only remaining `onepasswordRead` sites (`dot_gitconfig.tmpl`,
  `dot_config/zed/settings.json.tmpl`) write secrets into rendered
  files, not into stdout, and are out of scope for this spec.
- Process-argv leaks. `dotfiles secret add` still passes `$value` to
  `op item create` as a command-line argument (line 128), which is
  briefly visible to `ps` on the local machine. That is a smaller
  attack surface and a bigger refactor; deferred.
- CI lint to detect future `echo "$<value>"` patterns. Considered and
  rejected for now: the set of secret-holding variable names is not
  enumerable, and a heuristic would produce false positives. The
  principle is documented instead; see "Standing rule" below.

## Solution

### A. The fix

Replace the two-line block at `dotfiles.fish:255-257`:

```fish
# before
if test -n "$val"
    echo "✓ re-fetched from 1Password and cached"
    echo "  Restart shell or: set -gx $var '$val'"
else
    ...

# after
if test -n "$val"
    echo "✓ re-fetched from 1Password and cached in Keychain."
    echo "  Open a new shell (or run 'exec fish') to load the new value into \$$var."
else
    ...
```

The phrasing matches the already-safe `dotfiles secret add` success
message at line 160 (`"✓ applied. Open a new shell (or exec fish) to
load $var."`).

### B. Standing rule

Never echo or print a resolved secret value from any script, function,
or template in this repo. This applies to:

- Success hints ("here is the value" style messages)
- Debug output (`echo "DEBUG: val=$val"`)
- Error messages ("failed to set $var to $val")
- Comments in rendered files that include the value

Acceptable alternatives:
- Name the variable: "loaded into `$VAR`"
- Show the reference: "cached from `op://Vault/Item/field`"
- Show a status, not a payload: "cached" / "empty" / "refreshed"

The `secret-cache-read` helper is the one exception: it prints to
stdout by design because its output is captured by `()` in
`secrets.fish.tmpl`. Any caller that prints its return value directly
to the terminal (rather than capturing it) is violating the rule.

## Architecture decisions recorded

1. **Minimal fix, no refactor.** The leak is one echo line. Replacing
   it with a safe hint is trivial and carries zero regression risk.
   Refactoring the `$val` variable to never exist in the function scope
   was considered and rejected: `secret-cache-read` returns the value
   and we want to observe "did it return anything non-empty?" to
   distinguish success from auth failure.
2. **No CI enforcement.** A lint rule that flags `echo .*\$val` would
   not scale across the codebase; different functions use different
   variable names for secret payloads. The rule is principle-based,
   enforceable by code review, and documented in this spec and in the
   updated CLAUDE.md security section.
3. **Rotation is the user's responsibility, not the fix's.** This
   spec fixes the leak going forward; it does not and cannot rotate
   already-leaked values. The sync-log entry accompanying this PR
   documents the 2026-04-23 leak event explicitly so the audit trail
   is complete.
4. **Process-argv leak in `secret add`** (line 128) is a real but
   lower-severity issue (requires local `ps` access to exploit) and
   remediating it properly needs either `op item create --stdin`
   support (which the CLI does not offer as of op 2.x) or a temp-file
   dance. Not worth doing in this spec; filed as a follow-up note.

## Files changed

**New:**
- `docs/specs/S-45-secret-refresh-no-echo.md`: this spec

**Modified:**
- `home/dot_config/fish/functions/dotfiles.fish`: two-line change in
  `dotfiles secret refresh` hint
- `CLAUDE.md`: add "never echo resolved secret values" to the
  Important conventions section
- `docs/tasks.md`: tick S-45
- `docs/sync-log.md`: hostname-tagged entry noting the 2026-04-23
  leak event and the fix

**Not changed:**
- `secret-cache-read` helper (correct as-is)
- `secrets.fish.tmpl` template (no value echo path)
- `dotfiles secret add`, `rm`, `list` paths (audited, no value echo)

## Rollout notes

- Existing machines pick up the fix on next `chezmoi apply` after pull.
- No state migration. No Keychain touch. No 1P interaction.
- The leak was a one-time event on Hans Air M4; no other machine has
  been observed running `dotfiles secret refresh` interactively in a
  shared-transcript context, so no retroactive rotation is needed
  beyond the service account token the user is rotating separately.

## Testing

```fish
# 1. Delete a cache entry and refresh; confirm value is NOT printed.
security delete-generic-password -a "$USER" -s "OP_SERVICE_ACCOUNT_TOKEN" >/dev/null 2>&1
dotfiles secret refresh OP_SERVICE_ACCOUNT_TOKEN 2>&1 | tee /tmp/refresh-out.txt
grep -c '^ops_' /tmp/refresh-out.txt
# Expected: 0

# 2. Output still informative.
grep -E 'cached in Keychain|Open a new shell' /tmp/refresh-out.txt
# Expected: both phrases present

# 3. Fish syntax.
fish -n home/dot_config/fish/functions/dotfiles.fish

# 4. Dry run.
chezmoi apply --dry-run --force
```

## What's explicitly NOT supported

- Auto-detection of prior secret leaks in shell history, scrollback, or
  external logs. Users who had the prior behaviour leak a token need
  to rotate that specific secret in 1P and refresh the Keychain.
- A generalised "scan my scrollback for ops_... / eyJhb... / AKIA..."
  audit command. Out of scope and of limited value (scrollback
  retention varies by terminal).
- Preventing value exposure via `ps` when `secret add` calls
  `op item create`. Documented limitation; see decision 4 above.
