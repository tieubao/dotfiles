---
id: S-01
title: Idempotent install.sh
type: feature
status: done
old_id: F-01
---

### Problem
Running `install.sh` twice currently nukes the chezmoi symlink (`rm -rf ~/.local/share/chezmoi`) and re-runs `chezmoi init --apply`, which re-prompts for name, email, editor, 1Password vault. This is annoying on an already-configured machine.

### Spec
Modify `install.sh` to detect existing state and skip accordingly:

```bash
# Pseudocode
if chezmoi is installed AND ~/.local/share/chezmoi exists AND .chezmoi.toml exists:
    echo "Already initialized. Running chezmoi apply..."
    chezmoi apply
elif chezmoi is installed:
    # chezmoi exists but not initialized for this repo
    link source dir + chezmoi init --apply
else:
    # fresh machine
    install homebrew + chezmoi + link + init --apply
fi
```

Rules:
- Never re-prompt if `.chezmoi.toml.tmpl` has already been rendered to `~/.config/chezmoi/chezmoi.toml`
- The `rm -rf` of the symlink should only happen if the existing link points somewhere OTHER than `$DOTFILES/home`
- Add a `--force` flag that does the full teardown+reinit for edge cases
- Print what it is doing at each step (keep existing `echo "==>"` style)
- Exit codes: 0 = success, 1 = homebrew install failed, 2 = chezmoi init failed

### Files to modify
- `install.sh`

### Test
1. Run `install.sh` on configured machine. Should NOT prompt for name/email. Should just run `chezmoi apply`.
2. Run `install.sh --force` on configured machine. Should teardown and re-prompt.
3. Run on fresh machine (or fresh user account). Should do full bootstrap.
