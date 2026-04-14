function dfe --description "Edit a managed dotfile and auto-apply on save"
    if test (count $argv) -lt 1
        echo "Usage: dfe <path-to-managed-file>"
        echo "Examples:"
        echo "  dfe ~/.config/fish/config.fish"
        echo "  dfe ~/.Brewfile"
        return 1
    end
    chezmoi edit --apply $argv
end
