# R-03: Clean up secrets.fish.tmpl (dead code)

**Priority:** Medium
**Status:** Done

## Problem

`home/dot_config/fish/conf.d/secrets.fish.tmpl` is 43 lines of commented-out examples. After `chezmoi apply`, it renders into a file that does nothing. It's documentation pretending to be config.

This is confusing because:
- Users see the file in `conf.d/` and expect it to do something
- The comments explain two different secret backends but none are active
- The runtime functions (`op_env`, `keychain_env`) already handle on-demand loading, making the template-time approach redundant for most users

## Spec

### Option A: Convert to documentation (recommended)

1. Move the examples to a new section in README.md under "Secret management"
2. Replace `secrets.fish.tmpl` with a minimal file that only documents the runtime approach:

```fish
# secrets.fish -- Load secrets on demand via fish functions:
#   op_env GITHUB_TOKEN "op://Vault/GitHub Token/password"
#   keychain_env MY_TOKEN [service-name]
#   web3_env [vault-name]
#
# For apply-time injection, add lines like:
#   set -gx OPENAI_API_KEY "op://..." 
# to this file via: chezmoi edit ~/.config/fish/conf.d/secrets.fish
```

This is 6 lines instead of 43, and it points users to the right workflow.

### Option B: Ship one real secret (if user has a default they always want)

If there's a secret you always need (e.g., GITHUB_TOKEN), uncomment that one line so the file has at least one working example. Keep the rest as comments.

## Files to modify
- `home/dot_config/fish/conf.d/secrets.fish.tmpl`
- `README.md` (add "Secret management" section with the moved examples)

## Test
1. `chezmoi apply` renders a clean, minimal secrets.fish
2. `op_env` and `keychain_env` still work as runtime loaders
