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
