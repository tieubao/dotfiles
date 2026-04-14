function list-secrets --description "List auto-loaded 1Password secret bindings"
    set -l data (chezmoi source-path)/.chezmoidata/secrets.toml
    if test ! -f $data
        echo "(no secrets registered)"
        return 0
    end
    grep -E '^[A-Z_][A-Z0-9_]* = ' $data | sed 's/ = / → /; s/"//g'
end
