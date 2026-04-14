function rm-secret --description "Unregister an auto-loaded 1Password secret"
    if test (count $argv) -lt 1
        echo "Usage: rm-secret VAR_NAME [--commit]"
        return 1
    end

    set -l var $argv[1]
    set -l do_commit 0
    contains -- --commit $argv; and set do_commit 1

    set -l data (chezmoi source-path)/.chezmoidata/secrets.toml
    if not grep -q "^$var = " $data
        echo "⚠ $var not registered"
        return 1
    end

    sed -i '' "/^$var = /d" $data
    echo "✓ removed $var"

    echo "→ chezmoi apply"
    chezmoi apply; or return 1
    echo "✓ applied. \$$var will be absent from new shells."

    if test $do_commit -eq 1
        set -l repo (dirname (chezmoi source-path))
        git -C $repo add .chezmoidata/secrets.toml
        git -C $repo commit -m "chore(secrets): unregister $var" >/dev/null
        echo "✓ committed."
    end
end
