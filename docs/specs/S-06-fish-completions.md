---
id: S-06
title: Fish completions
type: feature
status: done
old_id: F-06
---

# Fish completions for custom functions

### Problem
Custom Fish functions (cdg, op_env, keychain_env, tx, web3_env) have no tab completions. They feel like second-class citizens compared to system commands.

### Spec
Create completion files for each existing function. Inspect what each function accepts and generate appropriate completions.

Example for `tx` (assuming it is a tmux session helper):

```fish
# home/dot_config/fish/completions/tx.fish
complete -c tx -f
complete -c tx -a "(tmux list-sessions -F '#{session_name}' 2>/dev/null)"
```

Example for `cdg` (assuming it cd's to git repos):

```fish
# home/dot_config/fish/completions/cdg.fish
complete -c cdg -f
complete -c cdg -a "(find ~/Projects ~/src -maxdepth 2 -name .git -type d 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {})"
```

### Rules
- Read the actual function implementations in `home/dot_config/fish/functions/` first
- Only create completions where they add value (skip if the function takes no arguments)
- Keep completions fast. No expensive operations on every tab press.
- Use `2>/dev/null` on all commands that might fail

### Files to create
- `home/dot_config/fish/completions/cdg.fish`
- `home/dot_config/fish/completions/op_env.fish`
- `home/dot_config/fish/completions/keychain_env.fish`
- `home/dot_config/fish/completions/tx.fish`
- Others as applicable based on function signatures
