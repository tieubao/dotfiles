function add-secret --description "Register a 1Password secret as an auto-loaded env var"
    if test (count $argv) -lt 2
        echo "Usage: add-secret VAR_NAME \"op://Vault/Item/field\" [--commit]"
        echo "Example: add-secret OPENAI_API_KEY \"op://Private/OpenAI/credential\""
        echo ""
        echo "If the 1Password item doesn't exist yet you'll be prompted for the"
        echo "value and the item will be created automatically."
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

    # Parse op://Vault/Item/field — the Item segment may contain spaces.
    set -l parts (string split / -- (string replace 'op://' '' -- $ref))
    if test (count $parts) -lt 3
        echo "✗ reference must be op://Vault/Item/field , got: $ref"
        return 1
    end
    set -l op_vault $parts[1]
    set -l op_field $parts[-1]
    set -l op_item (string join / $parts[2..-2])

    # Create the item if it doesn't exist yet.
    if not op read "$ref" >/dev/null 2>&1
        echo "No item found at $ref — creating it now."
        if not op account list >/dev/null 2>&1
            echo "✗ 1Password CLI is not signed in. Run: eval (op signin)"
            return 1
        end
        read -s -P "Enter value for $var: " value
        echo ""
        if test -z "$value"
            echo "✗ empty value, aborting"
            return 1
        end
        if not op item create --vault="$op_vault" --category="API Credential" \
                --title="$op_item" "$op_field=$value" >/dev/null 2>&1
            echo "✗ op item create failed (vault=$op_vault title=$op_item)"
            return 1
        end
        echo "✓ created 1Password item: $op_item"
        if not op read "$ref" >/dev/null 2>&1
            echo "✗ item created but $ref still unreadable; check field name"
            return 1
        end
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
        echo "✗ chezmoi apply failed; reverting registry"
        sed -i '' "/^$var = /d" $data
        return 1
    end

    echo "✓ applied. Open a new shell (or `exec fish`) to load \$$var."

    set -l repo (dirname (chezmoi source-path))
    if test $do_commit -eq 1
        git -C $repo add .chezmoidata/secrets.toml
        git -C $repo commit -m "feat(secrets): register $var" >/dev/null
        echo "✓ committed. Push with: git -C $repo push"
    else
        echo "Commit: git -C $repo add .chezmoidata/secrets.toml && git commit -m 'feat(secrets): register $var'"
    end
end
