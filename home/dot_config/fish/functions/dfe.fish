function dfe --description "Edit a managed dotfile, apply on save, commit the change"
    if test (count $argv) -lt 1
        echo "Usage: dfe <path> [--no-commit]"
        echo "  Edits the source, applies on save, auto-commits the diff."
        echo "  Pass --no-commit to leave the change unstaged."
        return 1
    end

    set -l no_commit 0
    set -l paths
    for a in $argv
        switch $a
            case --no-commit
                set no_commit 1
            case '*'
                set -a paths $a
        end
    end

    chezmoi edit --apply $paths; or return 1

    if test $no_commit -eq 1
        return 0
    end

    set -l repo (dirname (chezmoi source-path))
    if not git -C $repo diff --quiet -- home/
        # Stage only the files inside home/ that changed.
        set -l changed (git -C $repo diff --name-only -- home/)
        if test (count $changed) -gt 0
            git -C $repo add $changed
            set -l summary (string join ", " (for p in $changed; basename $p; end))
            git -C $repo commit -m "chore(config): update $summary via dfe" >/dev/null
            echo "✓ committed: $summary"
            echo "  push with: git -C $repo push"
        end
    end
end
