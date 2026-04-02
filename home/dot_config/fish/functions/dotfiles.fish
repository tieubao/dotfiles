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
        case doctor
            set -l issues 0

            echo "Dotfiles health check"
            echo "====================="
            echo ""

            # chezmoi
            if command -q chezmoi
                echo "[ok] chezmoi installed"
            else
                echo "[!!] chezmoi not installed"
                set issues (math $issues + 1)
            end

            # Source link
            if test -L ~/.local/share/chezmoi
                echo "[ok] chezmoi source linked"
            else
                echo "[!!] chezmoi source not symlinked"
                set issues (math $issues + 1)
            end

            # Fish is default shell
            if string match -q "*/fish" $SHELL
                echo "[ok] fish is default shell"
            else
                echo "[!!] default shell is $SHELL (not fish)"
                set issues (math $issues + 1)
            end

            # Homebrew
            if command -q brew
                echo "[ok] homebrew installed"
            else
                echo "[!!] homebrew not found"
                set issues (math $issues + 1)
            end

            # 1Password CLI
            if command -q op
                if op account list &>/dev/null
                    echo "[ok] 1Password CLI: signed in"
                else
                    echo "[--] 1Password CLI: installed but not signed in"
                end
            else
                echo "[--] 1Password CLI: not installed (optional)"
            end

            # 1Password SSH Agent
            if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
                echo "[ok] 1Password SSH agent: socket exists"
            else
                echo "[--] 1Password SSH agent: not found (optional)"
            end

            # Key config files
            for f in ~/.gitconfig ~/.config/fish/config.fish ~/.ssh/config
                if test -f $f
                    echo "[ok] $f exists"
                else
                    echo "[!!] $f missing"
                    set issues (math $issues + 1)
                end
            end

            # Git identity
            set -l git_name (git config --global user.name 2>/dev/null)
            if test -n "$git_name"
                echo "[ok] git identity: $git_name <"(git config --global user.email)">"
            else
                echo "[!!] git identity not configured"
                set issues (math $issues + 1)
            end

            # Key CLI tools
            for tool in fzf bat eza zoxide delta mise starship
                if command -q $tool
                    echo "[ok] $tool"
                else
                    echo "[!!] $tool not found (run: brew bundle)"
                    set issues (math $issues + 1)
                end
            end

            # Age key
            if test -f ~/.config/chezmoi/key.txt
                echo "[ok] age encryption key exists"
            else
                echo "[--] age encryption key: not set up (optional)"
            end

            # Drift
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
            echo "  3. Back up the key to 1Password:"
            echo "     op document create $key_path --title 'chezmoi age key' --vault=Developer"
            echo ""
            echo "  4. Add encrypted files:"
            echo "     chezmoi add --encrypt ~/.kube/config"

        case update u
            # Source path is home/ inside the git repo; find the repo root
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

        case ''
            echo "Usage: dotfiles <command>"
            echo ""
            echo "Commands:"
            echo "  edit <file>     Edit a managed file"
            echo "  diff            Show pending changes"
            echo "  sync            Apply all changes"
            echo "  update          Pull latest + apply"
            echo "  status          Show managed file count + pending diffs"
            echo "  cd              cd to chezmoi source directory"
            echo "  refresh         Re-download external files (fish plugins)"
            echo "  add <file>      Add a new file to chezmoi"
            echo "  doctor          Run health check on dotfiles setup"
            echo "  bench           Benchmark shell startup time"
            echo "  encrypt-setup   Set up age encryption"
        case '*'
            chezmoi $argv
    end
end
