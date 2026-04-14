---
id: S-05
title: Fish helper commands
type: feature
status: done
old_id: F-05
---

# Fish helper commands (dotfiles CLI)

### Problem
Daily dotfiles operations require remembering `chezmoi edit`, `chezmoi diff`, `chezmoi apply` commands. A wrapper function makes it more ergonomic.

### Spec
Create `home/dot_config/fish/functions/dotfiles.fish`:

```fish
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
```

Also create `home/dot_config/fish/completions/dotfiles.fish`:

```fish
complete -c dotfiles -f
complete -c dotfiles -n "__fish_use_subcommand" -a "edit" -d "Edit managed file"
complete -c dotfiles -n "__fish_use_subcommand" -a "diff" -d "Show pending changes"
complete -c dotfiles -n "__fish_use_subcommand" -a "sync" -d "Apply all changes"
complete -c dotfiles -n "__fish_use_subcommand" -a "status" -d "Show status"
complete -c dotfiles -n "__fish_use_subcommand" -a "cd" -d "Go to source dir"
complete -c dotfiles -n "__fish_use_subcommand" -a "refresh" -d "Re-download externals"
complete -c dotfiles -n "__fish_use_subcommand" -a "add" -d "Add file to chezmoi"
```

### Files to create
- `home/dot_config/fish/functions/dotfiles.fish`
- `home/dot_config/fish/completions/dotfiles.fish`
