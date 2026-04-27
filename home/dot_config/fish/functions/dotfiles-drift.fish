function dotfiles-drift -d "Check for local config drift from chezmoi source"
    # --include=files excludes scripts, which never deploy to disk and would
    # otherwise show as perpetual "drift" noise.
    set -l raw (chezmoi diff --no-pager --include=files 2>/dev/null)
    if test -z "$raw"
        echo "No drift. Local files match chezmoi source."
        return 0
    end

    set -l files (printf '%s\n' $raw | grep '^diff' | sed 's/diff --git a\///' | sed 's/ b\/.*//')
    set -l count (count $files)

    echo "Drift detected in $count file(s):"
    echo ""
    for f in $files
        echo "  $f"
    end
    echo ""
    echo "Run 'dotfiles sync' to apply source → local"
    echo "Run 'chezmoi merge <file>' to reconcile interactively"
    echo "Run 'chezmoi re-add <file>' to pull local → source (regular files only)"
    echo "Note: re-add does not work on templates (.tmpl) or modify_ scripts."
    echo "      For those, edit the source file directly to absorb local changes."
    return 1
end
