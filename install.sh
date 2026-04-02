#!/bin/bash
set -e

# Bootstrap script for dotfiles.
# Idempotent: safe to run multiple times on an already-configured machine.
# Use --force to teardown and reinit from scratch.
# Use --check to dry-run without applying changes.
# Use --config-only to deploy configs without running scripts (brew, mas, defaults).
#
# Exit codes:
#   0 = success
#   1 = Homebrew install failed
#   2 = chezmoi init/apply failed

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CHEZMOI_SOURCE="$HOME/.local/share/chezmoi"
CHEZMOI_CONFIG="$HOME/.config/chezmoi/chezmoi.toml"
FORCE=0
CHECK_ONLY=0
CONFIG_ONLY=0

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --check) CHECK_ONLY=1 ;;
        --config-only) CONFIG_ONLY=1 ;;
    esac
done

echo "==> Dotfiles: $DOTFILES"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew"
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        echo "==> ERROR: Homebrew install failed"
        exit 1
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "==> Homebrew: already installed"
fi

# --- chezmoi + gum ---
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi"
    brew install chezmoi
else
    echo "==> chezmoi: already installed"
fi

if ! command -v gum &>/dev/null; then
    echo "==> Installing gum"
    brew install gum
else
    echo "==> gum: already installed"
fi

# --- Helper functions ---
link_is_correct() {
    [ -L "$CHEZMOI_SOURCE" ] && [ "$(readlink "$CHEZMOI_SOURCE")" = "$DOTFILES/home" ]
}

chezmoi_initialized() {
    [ -f "$CHEZMOI_CONFIG" ]
}

ensure_link() {
    if ! link_is_correct; then
        if [ -e "$CHEZMOI_SOURCE" ] && ! [ -L "$CHEZMOI_SOURCE" ]; then
            echo "==> WARNING: $CHEZMOI_SOURCE exists and is not a symlink. Backing up."
            mv "$CHEZMOI_SOURCE" "$CHEZMOI_SOURCE.bak.$(date +%s)"
        elif [ -L "$CHEZMOI_SOURCE" ]; then
            echo "==> Symlink points to wrong location. Relinking."
            rm -f "$CHEZMOI_SOURCE"
        fi
        echo "==> Linking chezmoi source to $DOTFILES/home"
        mkdir -p "$HOME/.local/share"
        ln -sf "$DOTFILES/home" "$CHEZMOI_SOURCE"
    fi
}

apply_flags() {
    if [ "$CONFIG_ONLY" -eq 1 ]; then
        echo "--exclude=scripts"
    fi
}

# --- Gum wizard ---
run_gum_wizard() {
    # Gum reads env vars as config flags. Shell theming vars like UNDERLINE, BOLD,
    # ITALIC (ANSI escape codes) conflict with gum's boolean flags. Unset them.
    unset UNDERLINE BOLD ITALIC
    echo ""
    gum style --border double --padding "1 2" --border-foreground 212 \
        "  dotfiles setup  "
    echo ""

    local name email editor headless use_1password op_account op_vault

    name=$(gum input --prompt "Name: " --placeholder "Full name (for git)" \
        --value "$(git config user.name 2>/dev/null || true)")
    email=$(gum input --prompt "Email: " --placeholder "you@example.com" \
        --value "$(git config user.email 2>/dev/null || true)")
    editor=$(gum choose --header "Default editor:" "code --wait" "zed --wait" "nvim" "vim")

    if gum confirm "Headless/server environment? (skip GUI apps, dev tools)"; then
        headless=true
    else
        headless=false
    fi

    op_account=""
    op_vault=""
    if gum confirm "Use 1Password for secrets?"; then
        use_1password=true
        op_account=$(gum input --prompt "1Password account: " --placeholder "my.1password.com" \
            --value "my.1password.com")
        op_vault=$(gum input --prompt "1Password vault: " --placeholder "Developer" \
            --value "Developer")
    else
        use_1password=false
    fi

    # Write chezmoi config
    mkdir -p "$(dirname "$CHEZMOI_CONFIG")"
    cat > "$CHEZMOI_CONFIG" <<EOF
[data]
  name = "$name"
  email = "$email"
  editor = "$editor"
  headless = $headless
  use_1password = $use_1password
  op_account = "$op_account"
  op_vault = "$op_vault"
EOF

    echo ""
    gum style --foreground 10 "Config saved to $CHEZMOI_CONFIG"
}

# --- Plain fallback wizard (no gum / no TTY) ---
run_plain_wizard() {
    echo ""
    echo "==> dotfiles setup"
    echo ""

    local name email editor headless use_1password op_account op_vault

    read -rp "Full name (for git): " name
    read -rp "Email address: " email
    echo "Default editor:"
    echo "  1) code --wait"
    echo "  2) zed --wait"
    echo "  3) nvim"
    echo "  4) vim"
    read -rp "Choice [1-4]: " editor_choice
    case "$editor_choice" in
        1) editor="code --wait" ;;
        2) editor="zed --wait" ;;
        3) editor="nvim" ;;
        *) editor="vim" ;;
    esac

    read -rp "Headless/server environment? (y/N): " headless_input
    if [ "$headless_input" = "y" ] || [ "$headless_input" = "Y" ]; then
        headless=true
    else
        headless=false
    fi

    op_account=""
    op_vault=""
    read -rp "Use 1Password for secrets? (y/N): " op_input
    if [ "$op_input" = "y" ] || [ "$op_input" = "Y" ]; then
        use_1password=true
        read -rp "1Password account [my.1password.com]: " op_account
        op_account="${op_account:-my.1password.com}"
        read -rp "1Password vault [Developer]: " op_vault
        op_vault="${op_vault:-Developer}"
    else
        use_1password=false
    fi

    mkdir -p "$(dirname "$CHEZMOI_CONFIG")"
    cat > "$CHEZMOI_CONFIG" <<EOF
[data]
  name = "$name"
  email = "$email"
  editor = "$editor"
  headless = $headless
  use_1password = $use_1password
  op_account = "$op_account"
  op_vault = "$op_vault"
EOF

    echo ""
    echo "==> Config saved to $CHEZMOI_CONFIG"
}

# --- Run wizard (gum or fallback) ---
run_wizard() {
    if command -v gum &>/dev/null && [ -t 0 ]; then
        run_gum_wizard
        # Let chezmoi init validate template + fill any gaps the wizard missed
        chezmoi init
    elif [ -t 0 ]; then
        run_plain_wizard
        chezmoi init
    else
        # Non-interactive: chezmoi init reads from existing config or fails
        echo "==> Non-interactive mode. Running chezmoi init."
        chezmoi init
    fi
}

# --- Apply ---
run_apply() {
    if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "==> Dry run (--check mode)"
        if ! chezmoi apply --dry-run --verbose; then
            echo "==> ERROR: chezmoi dry-run failed"
            exit 2
        fi
        echo "==> Dry run passed. No changes applied."
        return 0
    fi

    if [ "$CONFIG_ONLY" -eq 1 ]; then
        echo "==> Config-only mode: deploying files, skipping scripts"
    fi

    if command -v gum &>/dev/null && [ -t 0 ]; then
        # shellcheck disable=SC2046
        if ! gum spin --spinner dot --title "Applying configs..." -- chezmoi apply $(apply_flags); then
            echo "==> ERROR: chezmoi apply failed"
            exit 2
        fi
    else
        # shellcheck disable=SC2046
        if ! chezmoi apply $(apply_flags); then
            echo "==> ERROR: chezmoi apply failed"
            exit 2
        fi
    fi
}

verify_deployment() {
    echo "==> Verifying deployment..."
    local warnings=0
    for f in ~/.config/fish/config.fish ~/.gitconfig ~/.ssh/config; do
        if [ ! -f "$f" ]; then
            echo "==> WARNING: Expected $f but it doesn't exist"
            warnings=$((warnings + 1))
        fi
    done
    if [ "$warnings" -eq 0 ]; then
        if command -v gum &>/dev/null; then
            gum style --foreground 10 "All key files verified."
        else
            echo "==> All key files verified."
        fi
    fi
}

# --- Determine what to do ---
if [ "$FORCE" -eq 1 ]; then
    echo "==> --force: tearing down existing state"
    rm -rf "$CHEZMOI_SOURCE"
    rm -f "$CHEZMOI_CONFIG"
    ensure_link
    run_wizard
    run_apply

elif command -v chezmoi &>/dev/null && link_is_correct && chezmoi_initialized; then
    echo "==> Already initialized. Running chezmoi apply..."
    run_apply

elif command -v chezmoi &>/dev/null; then
    ensure_link
    if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "==> Dry run (--check mode, not yet initialized)"
        echo "==> Run without --check first to set up config."
        exit 0
    fi
    run_wizard
    run_apply
fi

# --- Post-apply verification ---
if [ "$CHECK_ONLY" -eq 0 ]; then
    verify_deployment
fi

echo ""
echo "==> Done!"
echo ""
if command -v gum &>/dev/null; then
    gum style --foreground 212 "chezmoi now manages everything."
    echo ""
    echo "Daily commands:"
    echo "  dotfiles sync         Apply all changes"
    echo "  dotfiles edit <file>  Edit a managed file"
    echo "  dotfiles doctor       Health check"
    echo "  dotfiles update       Pull latest + apply"
else
    echo "chezmoi now manages everything. Future changes:"
    echo "  chezmoi edit ~/.config/fish/config.fish   # edit a config"
    echo "  chezmoi apply                             # apply all changes"
    echo "  chezmoi diff                              # preview changes"
fi
echo ""
echo "Next steps:"
echo "  1. Open a new terminal (or: exec fish)"
echo "  2. Sign into 1Password:  op signin"
echo "  3. Enable 1Password SSH agent: 1Password > Settings > Developer > SSH Agent"
echo "  4. Run: dotfiles doctor"
