function dotfiles -d "Manage dotfiles via chezmoi"
    switch $argv[1]
        case edit e
            chezmoi edit $argv[2..]
        case diff d
            chezmoi diff --no-pager
        case sync s
            chezmoi apply
            and echo "Applied."
        case status st
            echo "Managed files:"
            chezmoi managed | wc -l
            echo ""
            echo "Pending changes:"
            chezmoi diff --no-pager | head -30
        case cd
            cd (chezmoi source-path)
        case refresh r
            chezmoi apply --refresh-externals
        case add a
            chezmoi add $argv[2..]
        case ''
            echo "Usage: dotfiles <command>"
            echo ""
            echo "Commands:"
            echo "  edit <file>   Edit a managed file"
            echo "  diff          Show pending changes"
            echo "  sync          Apply all changes"
            echo "  status        Show managed file count + pending diffs"
            echo "  cd            cd to chezmoi source directory"
            echo "  refresh       Re-download external files (fish plugins)"
            echo "  add <file>    Add a new file to chezmoi"
        case '*'
            chezmoi $argv
    end
end
