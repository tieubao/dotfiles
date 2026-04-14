function dotfiles -d "Manage dotfiles via chezmoi"
    switch $argv[1]
        case edit e
            if test (count $argv) -lt 2
                echo "Usage: dotfiles edit <path> [--no-commit]"
                echo "  Edits the source, applies on save, auto-commits the diff."
                return 1
            end

            set -l no_commit 0
            set -l paths
            for a in $argv[2..]
                switch $a
                    case --no-commit
                        set no_commit 1
                    case '*'
                        set -a paths $a
                end
            end

            chezmoi edit --apply $paths; or return 1

            if test $no_commit -eq 1
                return 0
            end

            set -l repo (dirname (chezmoi source-path))
            if not git -C $repo diff --quiet -- home/
                set -l changed (git -C $repo diff --name-only -- home/)
                if test (count $changed) -gt 0
                    git -C $repo add $changed
                    set -l summary (string join ", " (for p in $changed; basename $p; end))
                    git -C $repo commit -m "chore(config): update $summary via dotfiles edit" >/dev/null
                    echo "✓ committed: $summary"
                    echo "  push with: git -C $repo push"
                end
            end

        case drift
            set -l no_commit 0
            contains -- --no-commit $argv; and set no_commit 1

            set -l drifted (chezmoi status 2>/dev/null | string match -r '^ M\s+(.+)$' | string replace -r '^ M\s+' '')
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
            echo "Run 'chezmoi diff $paths[1]' to preview; 'dotfiles drift' will re-absorb all of them."
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

        case secret
            switch $argv[2]
                case add
                    if test (count $argv) -lt 4
                        echo "Usage: dotfiles secret add VAR_NAME \"op://Vault/Item/field\" [--no-commit]"
                        echo "Example: dotfiles secret add OPENAI_API_KEY \"op://Private/OpenAI/credential\""
                        echo ""
                        echo "If the 1Password item doesn't exist yet you'll be prompted for the"
                        echo "value and the item will be created automatically."
                        return 1
                    end

                    set -l var $argv[3]
                    set -l ref $argv[4]
                    set -l do_commit 1
                    contains -- --no-commit $argv; and set do_commit 0

                    if not string match -qr '^[A-Z_][A-Z0-9_]*$' -- $var
                        echo "✗ VAR_NAME must be UPPER_SNAKE_CASE, got: $var"
                        return 1
                    end

                    set -l parts (string split / -- (string replace 'op://' '' -- $ref))
                    if test (count $parts) -lt 3
                        echo "✗ reference must be op://Vault/Item/field , got: $ref"
                        return 1
                    end
                    set -l op_vault $parts[1]
                    set -l op_field $parts[-1]
                    set -l op_item (string join / $parts[2..-2])

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
                        echo "⚠ $var already registered; use 'dotfiles secret rm' first to replace"
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

                case rm
                    if test (count $argv) -lt 3
                        echo "Usage: dotfiles secret rm VAR_NAME [--no-commit]"
                        return 1
                    end

                    set -l var $argv[3]
                    set -l do_commit 1
                    contains -- --no-commit $argv; and set do_commit 0

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

                case list ls
                    set -l data (chezmoi source-path)/.chezmoidata/secrets.toml
                    if test ! -f $data
                        echo "(no secrets registered)"
                        return 0
                    end
                    grep -E '^[A-Z_][A-Z0-9_]* = ' $data | sed 's/ = / → /; s/"//g'

                case ''
                    echo "Usage: dotfiles secret <add|rm|list>"
                    echo ""
                    echo "  add VAR \"op://...\"  Register a secret"
                    echo "  rm VAR              Unregister a secret"
                    echo "  list                Show all bindings"

                case '*'
                    echo "Unknown secret command: $argv[2]"
                    echo "Usage: dotfiles secret <add|rm|list>"
                    return 1
            end

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
        case doctor
            set -l issues 0

            echo "Dotfiles health check"
            echo "====================="
            echo ""

            if command -q chezmoi
                echo "[ok] chezmoi installed"
            else
                echo "[!!] chezmoi not installed"
                set issues (math $issues + 1)
            end

            if test -L ~/.local/share/chezmoi
                echo "[ok] chezmoi source linked"
            else
                echo "[!!] chezmoi source not symlinked"
                set issues (math $issues + 1)
            end

            if string match -q "*/fish" $SHELL
                echo "[ok] fish is default shell"
            else
                echo "[!!] default shell is $SHELL (not fish)"
                set issues (math $issues + 1)
            end

            if command -q brew
                echo "[ok] homebrew installed"
            else
                echo "[!!] homebrew not found"
                set issues (math $issues + 1)
            end

            if command -q op
                if op account list &>/dev/null
                    echo "[ok] 1Password CLI: signed in"
                else
                    echo "[--] 1Password CLI: installed but not signed in"
                end
            else
                echo "[--] 1Password CLI: not installed (optional)"
            end

            if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
                echo "[ok] 1Password SSH agent: socket exists"
            else
                echo "[--] 1Password SSH agent: not found (optional)"
            end

            for f in ~/.gitconfig ~/.config/fish/config.fish ~/.ssh/config
                if test -f $f
                    echo "[ok] $f exists"
                else
                    echo "[!!] $f missing"
                    set issues (math $issues + 1)
                end
            end

            set -l git_name (git config --global user.name 2>/dev/null)
            if test -n "$git_name"
                echo "[ok] git identity: $git_name <"(git config --global user.email)">"
            else
                echo "[!!] git identity not configured"
                set issues (math $issues + 1)
            end

            for tool in fzf bat eza zoxide delta mise starship
                if command -q $tool
                    echo "[ok] $tool"
                else
                    echo "[!!] $tool not found (run: brew bundle)"
                    set issues (math $issues + 1)
                end
            end

            if test -f ~/.config/chezmoi/key.txt
                echo "[ok] age encryption key exists"
            else
                echo "[--] age encryption key: not set up (optional)"
            end

            set -l drift_count (chezmoi diff --no-pager 2>/dev/null | grep '^diff' | wc -l | string trim)
            if test "$drift_count" -gt 0
                echo "[!!] $drift_count file(s) have drifted from source"
                set issues (math $issues + 1)
            else
                echo "[ok] no drift detected"
            end

            echo ""
            if test $issues -eq 0
                echo "All checks passed."
            else
                echo "$issues issue(s) found."
            end
            return $issues

        case encrypt-setup
            set -l key_path "$HOME/.config/chezmoi/key.txt"

            if test -f $key_path
                echo "Age key already exists at $key_path"
                echo "Public key:"
                grep "public key:" $key_path | string replace "# public key: " ""
                return 0
            end

            echo "Setting up age encryption for chezmoi..."
            echo ""

            if not command -q age-keygen
                echo "Installing age..."
                brew install age
            end

            mkdir -p (dirname $key_path)
            age-keygen -o $key_path 2>&1
            chmod 600 $key_path

            set -l pubkey (grep "public key:" $key_path | string replace "# public key: " "")
            echo ""
            echo "Public key: $pubkey"
            echo ""
            echo "Next steps:"
            echo "  1. Edit chezmoi config:"
            echo "     chezmoi edit-config"
            echo ""
            echo "  2. Add these lines:"
            echo "     encryption = \"age\""
            echo "     [age]"
            echo "     identity = \"$key_path\""
            echo "     recipient = \"$pubkey\""
            echo ""
            set -l vault (chezmoi data 2>/dev/null | grep op_vault | awk '{print $NF}' | tr -d '"'); or set vault Private
            echo "  3. Back up the key to 1Password:"
            echo "     op document create $key_path --title 'chezmoi age key' --vault=$vault"
            echo ""
            echo "  4. Add encrypted files:"
            echo "     chezmoi add --encrypt ~/.kube/config"

        case update u
            set -l src (chezmoi source-path)
            if not test -d $src
                echo "chezmoi source not found"
                return 1
            end
            set -l repo (git -C $src rev-parse --show-toplevel 2>/dev/null)
            if test -z "$repo"
                echo "Not a git repo: $src"
                return 1
            end

            echo "==> Pulling latest..."
            git -C $repo pull --ff-only
            or begin
                echo "Pull failed. Resolve manually in $repo"
                return 1
            end

            echo "==> Applying..."
            chezmoi apply
            and echo "Updated and applied."

        case bench
            echo "Fish shell startup benchmark (10 runs):"
            echo ""
            set -l total 0
            for i in (seq 10)
                set -l start (perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000')
                fish -i -c exit 2>/dev/null
                set -l end (perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000')
                set -l ms (math "$end - $start")
                set total (math "$total + $ms")
                printf "  run %2d: %d ms\n" $i $ms
            end
            set -l avg (math "$total / 10")
            echo ""
            echo "Average: $avg ms"
            if test $avg -gt 500
                echo "Slow! (>500ms). Check config.fish for expensive init calls."
            else if test $avg -gt 200
                echo "Acceptable (200-500ms)."
            else
                echo "Fast (<200ms)."
            end

        case backup
            echo "Dotfiles backup"
            echo "==============="
            echo ""

            set -l config_path (chezmoi config-path 2>/dev/null)
            set -l key_path "$HOME/.config/chezmoi/key.txt"
            set -l vault (chezmoi data 2>/dev/null | grep op_vault | awk '{print $NF}' | tr -d '"'); or set vault Private

            if test -z "$config_path"; or not test -f "$config_path"
                echo "[!!] chezmoi config not found"
                return 1
            end

            echo "[1/3] chezmoi config: $config_path"
            if command -q op
                echo "      Backing up to 1Password..."
                op document create "$config_path" --title "chezmoi config (dotfiles backup)" --vault="$vault" 2>/dev/null
                and echo "      [ok] Uploaded to 1Password"
                or echo "      [!!] Upload failed. Are you signed in? (op signin)"
            else
                echo "      [--] 1Password CLI not found, skipping"
            end

            echo ""
            echo "[2/3] age encryption key: $key_path"
            if test -f "$key_path"
                if command -q op
                    echo "      Backing up to 1Password..."
                    op document create "$key_path" --title "chezmoi age key (dotfiles backup)" --vault="$vault" 2>/dev/null
                    and echo "      [ok] Uploaded to 1Password"
                    or echo "      [!!] Upload failed"
                else
                    echo "      [--] 1Password CLI not found, skipping"
                end
            else
                echo "      [--] No age key (not set up)"
            end

            echo ""
            echo "[3/3] Local fallback: ~/dotfiles-backup/"
            mkdir -p ~/dotfiles-backup
            cp "$config_path" ~/dotfiles-backup/chezmoi.toml 2>/dev/null
            and echo "      [ok] chezmoi.toml copied"
            if test -f "$key_path"
                cp "$key_path" ~/dotfiles-backup/key.txt 2>/dev/null
                chmod 600 ~/dotfiles-backup/key.txt
                and echo "      [ok] key.txt copied (mode 600)"
            end
            echo ""
            echo "Done. Restore on a new machine:"
            echo "  mkdir -p ~/.config/chezmoi"
            echo "  cp ~/dotfiles-backup/chezmoi.toml ~/.config/chezmoi/"
            echo "  cp ~/dotfiles-backup/key.txt ~/.config/chezmoi/  # if using age"

        case ''
            echo "Usage: dotfiles <command>"
            echo ""
            echo "Commands:"
            echo "  edit <file>       Edit + apply + auto-commit"
            echo "  drift             Detect and re-absorb drifted files"
            echo "  secret <cmd>      Manage 1Password secrets (add/rm/list)"
            echo "  diff              Show pending changes"
            echo "  sync              Apply all changes"
            echo "  update            Pull latest + apply"
            echo "  status            Show managed file count + pending diffs"
            echo "  cd                cd to chezmoi source directory"
            echo "  refresh           Re-download external files (fish plugins)"
            echo "  add <file>        Add a new file to chezmoi"
            echo "  doctor            Run health check on dotfiles setup"
            echo "  bench             Benchmark shell startup time"
            echo "  backup            Back up chezmoi config + age key"
            echo "  encrypt-setup     Set up age encryption"
        case '*'
            chezmoi $argv
    end
end
