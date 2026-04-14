function add-secret --description "Register a 1Password secret as an auto-loaded env var"
    if test (count $argv) -lt 2
        echo "Usage: add-secret VAR_NAME \"op://Vault/Item/field\" [--commit]"
        echo "Example: add-secret OPENAI_API_KEY \"op://Private/OpenAI/credential\""
        return 1
    end

    set -l var $argv[1]
    set -l ref $argv[2]
    set -l do_commit 0
    contains -- --commit $argv; and set do_commit 1

    if not string match -qr '^[A-Z_][A-Z0-9_]*$' -- $var
        echo "✗ VAR_NAME must be UPPER_SNAKE_CASE, got: $var"
        return 1
    end

    if not string match -q 'op://*' -- $ref
        echo "✗ reference must start with op:// , got: $ref"
        return 1
    end

    if not op read "$ref" >/dev/null 2>&1
        echo "✗ op read failed — sign in with `eval (op signin)` or check the ref"
        return 1
    end

    set -l data (chezmoi source-path)/.chezmoidata/secrets.toml
    if test ! -f $data
        echo "✗ $data missing; dotfiles may need reinstall"
        return 1
    end

    if grep -q "^$var = " $data
        echo "⚠ $var already registered; use rm-secret first to replace"
        return 1
    end

    printf '%s = "%s"\n' "$var" "$ref" >> $data
    echo "✓ added $var → $ref"

    echo "→ chezmoi apply"
    chezmoi apply; or begin
        echo "✗ chezmoi apply failed; reverting data file"
        sed -i '' "/^$var = /d" $data
        return 1
    end

    echo "✓ applied. Open a new shell (or `exec fish`) to load \$$var."

    if test $do_commit -eq 1
        set -l repo (dirname (chezmoi source-path))
        git -C $repo add .chezmoidata/secrets.toml
        git -C $repo commit -m "feat(secrets): register $var" >/dev/null
        echo "✓ committed. Push with: git -C "(dirname (chezmoi source-path))" push"
    else
        echo "Commit: git -C "(dirname (chezmoi source-path))" add .chezmoidata/secrets.toml && git commit -m 'feat(secrets): register $var'"
    end
end
