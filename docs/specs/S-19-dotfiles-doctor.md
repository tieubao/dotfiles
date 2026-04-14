---
id: S-19
title: Dotfiles doctor
type: refinement
status: done
old_id: R-07
---

# Dotfiles doctor

**Priority:** Medium
**Status:** Done

## Problem

When something breaks (SSH not working, 1Password not responding, fish not default shell), there's no single command to diagnose the setup. Users have to check each component manually.

## Spec

Add a `doctor` subcommand to the `dotfiles` fish function:

```fish
case doctor
    set -l issues 0
    
    echo "Dotfiles health check"
    echo "====================="
    echo ""
    
    # chezmoi
    if command -q chezmoi
        echo "[ok] chezmoi installed: "(chezmoi --version | string split ' ')[3]
    else
        echo "[!!] chezmoi not installed"
        set issues (math $issues + 1)
    end
    
    # Source link
    if test -L ~/.local/share/chezmoi
        echo "[ok] chezmoi source linked: "(readlink ~/.local/share/chezmoi)
    else
        echo "[!!] chezmoi source not symlinked"
        set issues (math $issues + 1)
    end
    
    # Fish is default shell
    if string match -q "*/fish" $SHELL
        echo "[ok] fish is default shell"
    else
        echo "[!!] default shell is $SHELL (not fish)"
        set issues (math $issues + 1)
    end
    
    # Homebrew
    if command -q brew
        echo "[ok] homebrew installed"
    else
        echo "[!!] homebrew not found"
        set issues (math $issues + 1)
    end
    
    # 1Password CLI
    if command -q op
        if op account list &>/dev/null
            echo "[ok] 1Password CLI: signed in"
        else
            echo "[--] 1Password CLI: installed but not signed in"
        end
    else
        echo "[--] 1Password CLI: not installed (optional)"
    end
    
    # 1Password SSH Agent
    if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        echo "[ok] 1Password SSH agent: socket exists"
    else
        echo "[--] 1Password SSH agent: socket not found (optional)"
    end
    
    # SSH config
    if test -f ~/.ssh/config
        echo "[ok] SSH config exists"
    else
        echo "[!!] SSH config missing"
        set issues (math $issues + 1)
    end
    
    # Git identity
    set -l git_name (git config --global user.name 2>/dev/null)
    if test -n "$git_name"
        echo "[ok] git identity: $git_name <"(git config --global user.email)">"
    else
        echo "[!!] git identity not configured"
        set issues (math $issues + 1)
    end
    
    # Key tools
    for tool in fzf bat eza zoxide delta mise
        if command -q $tool
            echo "[ok] $tool installed"
        else
            echo "[!!] $tool not found (run: brew bundle)"
            set issues (math $issues + 1)
        end
    end
    
    # Age key (if encryption enabled)
    if test -f ~/.config/chezmoi/key.txt
        echo "[ok] age encryption key exists"
    else
        echo "[--] age encryption key: not set up (optional)"
    end
    
    # Drift
    set -l drift_count (chezmoi diff --no-pager 2>/dev/null | grep '^diff' | wc -l | string trim)
    if test "$drift_count" -gt 0
        echo "[!!] $drift_count file(s) have drifted from source"
        set issues (math $issues + 1)
    else
        echo "[ok] no drift detected"
    end
    
    echo ""
    if test $issues -eq 0
        echo "All checks passed."
    else
        echo "$issues issue(s) found."
    end
    return $issues
```

Also add to completions:
```fish
complete -c dotfiles -n "__fish_use_subcommand" -a "doctor" -d "Health check"
```

## Files to modify
- `home/dot_config/fish/functions/dotfiles.fish` (add doctor case)
- `home/dot_config/fish/completions/dotfiles.fish` (add doctor completion)

## Test
1. Run `dotfiles doctor` on healthy machine. All checks green.
2. Uninstall `bat`. Run `dotfiles doctor`. Should flag missing tool.
3. Kill 1Password. Run `dotfiles doctor`. Should show SSH agent socket missing.
