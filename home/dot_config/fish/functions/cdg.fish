# Fuzzy cd to bookmarked directories (ported from zshrc)
# Reads dirs from ~/.cdscuts if it exists, otherwise scans ~/workspace
function cdg --description "Fuzzy cd to project directory"
    set -l dirs
    if test -f $HOME/.cdscuts
        set dirs (cat $HOME/.cdscuts)
    else
        set dirs (fd --type d --max-depth 2 . ~/workspace 2>/dev/null)
    end

    set -l dest (printf '%s\n' $dirs | fzf --reverse --header='Jump to directory')
    if test -n "$dest"
        cd $dest
    end
end
