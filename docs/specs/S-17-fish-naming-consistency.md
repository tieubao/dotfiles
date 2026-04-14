---
id: S-17
title: Fish naming consistency
type: refinement
status: done
old_id: R-05
---

# Fish naming consistency

**Priority:** Low
**Status:** Done

## Problem

Fish functions use inconsistent naming:
- Hyphens: `dotfiles-drift`, `render-img`
- Underscores: `op_env`, `keychain_env`, `keychain_set`, `web3_env`

Fish convention: hyphens for user-facing commands, underscores for internal/helper functions. All of these are user-facing commands.

## Current state

| Function | Convention | Should be |
|----------|-----------|-----------|
| `dotfiles` | correct | (no change) |
| `dotfiles-drift` | hyphen | (no change) |
| `render-img` | hyphen | (no change) |
| `cdg` | single word | (no change) |
| `tx` | single word | (no change) |
| `op_env` | underscore | `op-env` |
| `keychain_env` | underscore | `keychain-env` |
| `keychain_set` | underscore | `keychain-set` |
| `web3_env` | underscore | `web3-env` |

## Spec

Rename 4 functions from underscore to hyphen convention:

1. Rename files:
   - `functions/op_env.fish` -> `functions/op-env.fish`
   - `functions/keychain_env.fish` -> `functions/keychain-env.fish`
   - `functions/keychain_set.fish` -> `functions/keychain-set.fish`
   - `functions/web3_env.fish` -> `functions/web3-env.fish`

2. Rename completions:
   - `completions/op_env.fish` -> `completions/op-env.fish`
   - `completions/keychain_env.fish` -> `completions/keychain-env.fish`
   - `completions/keychain_set.fish` -> `completions/keychain-set.fish`

3. Update references:
   - `web3_env.fish` calls `op_env` internally, update to `op-env`
   - `config.fish.tmpl` drift check: no references to these (clean)
   - `secrets.fish.tmpl` comments reference `op_env` and `keychain_env`, update

4. Update function definitions inside each file (`function op_env` -> `function op-env`)

### Breaking change note

Anyone who has `op_env` in their shell history or scripts will need to update. Since this is a personal repo, the blast radius is just you. Consider adding temporary aliases:

```fish
# Backwards compat (remove after 2026-05-01)
function op_env; op-env $argv; end
```

## Files to modify
- 4 function files (rename + update function name)
- 3 completion files (rename + update command name)
- `home/dot_config/fish/conf.d/secrets.fish.tmpl` (update comments)

## Test
1. `op-env GITHUB_TOKEN "op://..."` works
2. `keychain-env MY_TOKEN` works
3. Tab completion works for all renamed functions
4. `web3-env` calls `op-env` correctly
