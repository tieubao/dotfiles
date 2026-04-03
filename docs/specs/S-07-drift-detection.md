---
id: S-07
title: Drift detection
type: feature
status: done
old_id: F-07
---

# Drift detection

### Problem
You manually edit `~/.config/ghostty/config` directly instead of through `chezmoi edit`. The edit works but is never committed back. Weeks later you wonder why your new machine has different settings.

### Spec
Create `home/dot_config/fish/functions/dotfiles-drift.fish`:

```fish
function dotfiles-drift -d "Check for local config drift from chezmoi source"
    set -l diffs (chezmoi diff --no-pager 2>/dev/null)
    if test -n "$diffs"
        echo "Drift detected in "(chezmoi diff --no-pager | grep '^diff' | wc -l | string trim)" files:"
        echo ""
        chezmoi diff --no-pager | grep '^diff' | sed 's/diff --git a\//  /' | sed 's/ b\/.*//'
        echo ""
        echo "Run 'dotfiles sync' to apply source → local"
        echo "Run 'chezmoi merge <file>' to reconcile"
        echo "Run 'chezmoi re-add <file>' to pull local → source"
        return 1
    else
        echo "No drift. Local files match chezmoi source."
        return 0
    end
end
```

Optional: add a periodic check hook in `config.fish.tmpl` that runs on shell startup (but only once per day):

```fish
# Drift check (once per day, non-blocking)
set -l drift_check_file ~/.cache/dotfiles-drift-check
set -l today (date +%Y-%m-%d)
if not test -f $drift_check_file; or test (cat $drift_check_file) != $today
    echo $today > $drift_check_file
    set -l drift_count (chezmoi diff --no-pager 2>/dev/null | grep '^diff' | wc -l | string trim)
    if test "$drift_count" -gt 0
        echo "dotfiles: $drift_count files have drifted. Run 'dotfiles-drift' to see details."
    end
end
```

### Rules
- Daily check must be non-blocking (fast, no network calls)
- Never auto-apply. Only inform.
- `dotfiles-drift` is the explicit command to see full details
- Cache the check result in `~/.cache/` (XDG-compliant)

### Files to create
- `home/dot_config/fish/functions/dotfiles-drift.fish`
- Modify `home/dot_config/fish/config.fish.tmpl` (add daily drift check block)
