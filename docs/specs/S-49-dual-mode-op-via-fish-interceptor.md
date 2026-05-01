---
id: S-49
title: Dual-mode `op` via fish interceptor (interactive biometric, subprocess bearer)
type: feature
status: done
date: 2026-05-01
amends: S-47
---

# S-49: Dual-mode `op` via fish interceptor

## Problem

[S-47](S-47-agent-token-opt-in-wrapper.md) restored multi-vault biometric
access in the daily fish shell by removing `OP_SERVICE_ACCOUNT_TOKEN` from
auto-load. The cost: any subprocess launched from a plain fish shell (most
notably Claude Code's Bash tool, which actually runs zsh) cannot do ad-hoc
`op read op://...` -- no token in env, no TTY for biometric, fails silently.
The `with-agent-token` wrapper exists but only fixes the case where the user
remembers to prefix the launch.

The user wants both:

1. Daily `op vault list` returns all vaults (biometric).
2. Any subprocess (Claude Code, scripts, bash one-liners) can `op read` headlessly.

S-47 chose (1) at the cost of (2). S-42 chose (2) at the cost of (1). We need
both.

## Solution

The two requirements operate at different layers:

- (1) is about how `op` behaves **when invoked from interactive fish**.
- (2) is about how `op` behaves **when invoked from a non-fish subprocess**.

These can be decoupled. Auto-load the token globally (so subprocess inherit
it via env), then intercept `op` *only inside fish* and unset the token
inline for interactive invocations. Subprocesses don't see the fish function
at all and call the binary directly with the token in env.

```
fish login → set -gx OP_SERVICE_ACCOUNT_TOKEN ...
   │
   ├─ Interactive `op vault list` typed at prompt
   │     → fish function `op` runs
   │     → status is-interactive = true
   │     → env -u OP_SERVICE_ACCOUNT_TOKEN command op vault list
   │     → biometric, all vaults
   │
   └─ Subprocess (zsh/bash/script/claude)
         → no fish function in scope
         → calls /opt/homebrew/bin/op directly
         → sees OP_SERVICE_ACCOUNT_TOKEN in env → bearer auth → headless
```

Net: daily `op` is biometric and multi-vault, every subprocess is headless
and SA-scoped. No prefixing required for agents.

### `op.fish` (new file)

`home/dot_config/fish/functions/op.fish`:

```fish
function op --description 'op CLI: biometric in interactive shells, SA bearer auth in subprocesses (S-49)'
    if status is-interactive
        env -u OP_SERVICE_ACCOUNT_TOKEN command op $argv
    else
        command op $argv
    end
end
```

Five lines. `command op` skips the function definition and calls the binary
directly. `status is-interactive` is true iff the fish shell is running
interactively (login shell or `fish -i`). Scripts run via `fish file.fish`
have it false; subprocess shells of any kind have it false (they're not
fish, so the function isn't even visible).

### Re-register `OP_SERVICE_ACCOUNT_TOKEN` in `secrets.toml`

Restore the entry that S-47 removed. The interceptor neutralises the daily-shell
side effect, so the original auto-load is safe again.

### Relax the S-47 guard in `dotfiles secret add`

The S-47 guard refused `dotfiles secret add OP_SERVICE_ACCOUNT_TOKEN`. With
the dual-mode design, registration is the intended path again. Remove the
guard. The wrapper (`with-agent-token`) is kept as a debug/testing escape
hatch, not as the primary flow.

## Trade-offs accepted

| Trade-off | Rationale |
|---|---|
| Token is back in shell env (S-47's strict guarantee gone) | Same blast radius as S-42, which we accepted before. The interceptor only changes interactive UX, not security profile. |
| Adds a fish function around a frequently-used binary | Negligible perf cost. Function adds ~1 ms per invocation. |
| Behavior diverges between fish-typed `op` and subprocess `op` | Intentional and documented. Anyone confused can read `function op` in fish. |
| `op` invocation from a fish *script* (not interactive) gets bearer auth | Correct -- scripts ARE the agent case. If a script needs biometric, it can `command op` to bypass. |

## Non-goals

- Wrapping `op` in zsh/bash. Subprocess paths intentionally use the env-var-driven default.
- Removing `with-agent-token`. Kept as an escape hatch for "run this command interactively under SA scope" (e.g., debugging vault scope).
- Solving the S-42 blast-radius concern beyond what S-42 already accepted.

## Files changed

**New:**
- `docs/specs/S-49-dual-mode-op-via-fish-interceptor.md` (this spec)
- `home/dot_config/fish/functions/op.fish`

**Modified:**
- `home/.chezmoidata/secrets.toml`: re-add `OP_SERVICE_ACCOUNT_TOKEN`; replace S-47 comment with a one-line note pointing to S-49
- `home/dot_config/fish/functions/dotfiles.fish`: remove the S-47 guard in `secret add`
- `docs/specs/S-47-agent-token-opt-in-wrapper.md`: frontmatter `status: amended by S-49`; postscript noting the interceptor design replaces the guard
- `CLAUDE.md`: rewrite the secret-injection bullet to describe the dual-mode design
- `docs/guide.md`: rewrite the "Service account for agent subprocess `op read`" section
- `docs/tasks.md`: add S-49 entry
- `docs/sync-log.md`: hostname-tagged entry
- Auto-memory `feedback_op_token_opt_in.md`: rewrite to describe the dual-mode design

**Not changed:**
- `home/dot_config/fish/functions/with-agent-token.fish`: still works as a debug escape hatch
- `home/dot_local/bin/executable_secret-cache-read`: unchanged
- `home/dot_config/fish/conf.d/secrets.fish.tmpl`: unchanged (it just iterates `.secrets`)

## Testing

```fish
# Pre-state: re-register, apply, reload.
chezmoi apply
exec fish

# 1. Interactive op = biometric, all vaults.
op whoami | grep "User Type:"           # USER_OF_ACCOUNT
op vault list | tail -n +2 | wc -l      # > 1

# 2. Token IS in env (auto-loaded).
echo $OP_SERVICE_ACCOUNT_TOKEN | head -c 4  # ops_

# 3. Subprocess op = bearer auth, SA scope.
bash -c 'op whoami | grep "User Type:"'  # SERVICE_ACCOUNT
bash -c 'op vault list | tail -n +2 | wc -l'  # 1 (Trading)

# 4. Fish script (non-interactive fish) = bearer.
echo 'op whoami' | fish -c 'source /dev/stdin' 2>&1 | grep "User Type"  # SERVICE_ACCOUNT

# 5. with-agent-token still functions as escape hatch.
with-agent-token op whoami | grep "User Type"  # SERVICE_ACCOUNT (redundant but works)

# 6. dotfiles secret add OP_SERVICE_ACCOUNT_TOKEN now succeeds without --force.
#    (already registered, so this just confirms guard removed; expect "already registered" warning, NOT the S-47 guard.)
dotfiles secret add OP_SERVICE_ACCOUNT_TOKEN "op://..." 2>&1 | grep -v "S-47"
```

All six should pass.
