function dfs --description "Sync drifted deployed files back into the dotfiles source"
    set -l no_commit 0
    contains -- --no-commit $argv; and set no_commit 1

    # chezmoi status columns: "MX ~/path" where M=deployed differs from source.
    # A=missing from target, R=would be run script. We only care about M.
    set -l drifted (chezmoi status 2>/dev/null | string match -r '^ M\s+(.+)$' | string replace -r '^ M\s+' '')
    # string match/replace pipeline returns matches + replacements; take odd indices.
    set -l paths
    set -l i 2
    while test $i -le (count $drifted)
        set -a paths $drifted[$i]
        set i (math $i + 2)
    end

    if test (count $paths) -eq 0
        echo "✓ no drift — deployed files match source"
        return 0
    end

    echo "Drifted files (deployed ≠ source):"
    for p in $paths
        echo "  $p"
    end
    echo ""
    echo "Run 'chezmoi diff $paths[1]' to preview; 'dfs' will re-absorb all of them."
    read -P "Re-absorb into source? [y/N] " ans
    if not string match -qri '^y' -- $ans
        echo "aborted"
        return 1
    end

    chezmoi re-add $paths; or return 1
    echo "✓ source updated"

    if test $no_commit -eq 1
        return 0
    end

    set -l repo (dirname (chezmoi source-path))
    if not git -C $repo diff --quiet -- home/
        set -l changed (git -C $repo diff --name-only -- home/)
        git -C $repo add $changed
        set -l summary (string join ", " (for p in $changed; basename $p; end))
        git -C $repo commit -m "chore(config): sync drift from machine ($summary)" >/dev/null
        echo "✓ committed. Push with: git -C $repo push"
    end
end
