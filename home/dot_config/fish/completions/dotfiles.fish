complete -c dotfiles -f
complete -c dotfiles -n "__fish_use_subcommand" -a "edit" -d "Edit + apply + auto-commit"
complete -c dotfiles -n "__fish_use_subcommand" -a "drift" -d "Detect and re-absorb drifted files"
complete -c dotfiles -n "__fish_use_subcommand" -a "secret" -d "Manage 1Password secrets"
complete -c dotfiles -n "__fish_use_subcommand" -a "diff" -d "Show pending changes"
complete -c dotfiles -n "__fish_use_subcommand" -a "sync" -d "Apply all changes"
complete -c dotfiles -n "__fish_use_subcommand" -a "status" -d "Show status"
complete -c dotfiles -n "__fish_use_subcommand" -a "cd" -d "Go to source dir"
complete -c dotfiles -n "__fish_use_subcommand" -a "refresh" -d "Re-download externals"
complete -c dotfiles -n "__fish_use_subcommand" -a "add" -d "Add file to chezmoi"
complete -c dotfiles -n "__fish_use_subcommand" -a "update" -d "Pull latest + apply"
complete -c dotfiles -n "__fish_use_subcommand" -a "doctor" -d "Health check"
complete -c dotfiles -n "__fish_use_subcommand" -a "bench" -d "Benchmark shell startup"
complete -c dotfiles -n "__fish_use_subcommand" -a "backup" -d "Back up config + age key"
complete -c dotfiles -n "__fish_use_subcommand" -a "encrypt-setup" -d "Set up age encryption"

# dotfiles edit accepts file paths
complete -c dotfiles -n "__fish_seen_subcommand_from edit" -a "--no-commit" -d "Skip auto-commit"
complete -c dotfiles -n "__fish_seen_subcommand_from edit" -F

# dotfiles drift
complete -c dotfiles -n "__fish_seen_subcommand_from drift" -a "--no-commit" -d "Skip auto-commit"

# dotfiles secret subcommands
complete -c dotfiles -n "__fish_seen_subcommand_from secret; and not __fish_seen_subcommand_from add rm list ls" -a "add" -d "Register a secret"
complete -c dotfiles -n "__fish_seen_subcommand_from secret; and not __fish_seen_subcommand_from add rm list ls" -a "rm" -d "Unregister a secret"
complete -c dotfiles -n "__fish_seen_subcommand_from secret; and not __fish_seen_subcommand_from add rm list ls" -a "list" -d "Show all bindings"
