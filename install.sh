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

# Colors: 75=steel blue, 117=light blue, 251=light gray, 10=green
WIZ_ACCENT=75
WIZ_LIGHT=117
WIZ_DIM=251

# Draw the wizard header + progress bar + completed answers
draw_wizard() {
    local step=$1 total=4
    clear
    gum style --border rounded --padding "1 2" --border-foreground "$WIZ_ACCENT" \
        "  dotfiles setup  "
    echo ""

    # Progress bar
    local filled=$((step * 20 / total))
    local empty=$((20 - filled))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    gum style --foreground "$WIZ_ACCENT" "  $bar  Step $step/$total"
    echo ""

    # Show completed answers
    [ -n "${wiz_name+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ Name:      $wiz_name"
    [ -n "${wiz_email+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ Email:     $wiz_email"
    [ -n "${wiz_editor+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ Editor:    $wiz_editor"
    [ -n "${wiz_headless+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ Headless:  $wiz_headless"
    [ -n "${wiz_1pass+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ 1Password: $wiz_1pass"
    [ -n "${wiz_account+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ Account:   $wiz_account"
    [ -n "${wiz_vault+x}" ] && gum style --foreground "$WIZ_DIM" "  ✓ Vault:     $wiz_vault"
    echo ""
}

# Erase gum's residual output lines (header + input value)
erase_gum_residual() {
    tput cuu1 2>/dev/null; tput el 2>/dev/null  # input value line
    tput cuu1 2>/dev/null; tput el 2>/dev/null  # header line
}

run_gum_wizard() {
    # Gum reads env vars as config flags. Shell theming vars like UNDERLINE, BOLD,
    # ITALIC (ANSI escape codes) conflict with gum's boolean flags. Unset them.
    unset UNDERLINE BOLD ITALIC

    local name email editor headless use_1password op_account op_vault

    # --- Step 1: Name ---
    draw_wizard 1
    gum style --foreground "$WIZ_LIGHT" --bold "  Identity"
    echo ""
    name=$(gum input --header "  Name:" --placeholder "Full name (for git)" \
        --value "$(git config user.name 2>/dev/null || true)" \
        --header.foreground "$WIZ_DIM" --cursor.foreground "$WIZ_ACCENT")
    erase_gum_residual
    wiz_name="$name"

    # --- Step 1b: Email ---
    draw_wizard 1
    gum style --foreground "$WIZ_LIGHT" --bold "  Identity"
    echo ""
    email=$(gum input --header "  Email:" --placeholder "you@example.com" \
        --value "$(git config user.email 2>/dev/null || true)" \
        --header.foreground "$WIZ_DIM" --cursor.foreground "$WIZ_ACCENT")
    erase_gum_residual
    wiz_email="$email"

    # --- Step 2: Editor ---
    draw_wizard 2
    gum style --foreground "$WIZ_LIGHT" --bold "  Editor"
    echo ""
    editor=$(gum choose --header "  Pick your default editor:" \
        --cursor.foreground "$WIZ_ACCENT" --selected.foreground 10 \
        --header.foreground "$WIZ_DIM" \
        "code --wait" "zed --wait" "nvim" "vim")
    wiz_editor="$editor"

    # --- Step 3: Environment ---
    draw_wizard 3
    gum style --foreground "$WIZ_LIGHT" --bold "  Environment"
    echo ""
    if gum confirm "  Headless/server? (skip GUI apps, dev tools)"; then
        headless=true
    else
        headless=false
    fi
    wiz_headless="$headless"

    # --- Step 4: Secrets ---
    draw_wizard 4
    gum style --foreground "$WIZ_LIGHT" --bold "  Secrets"
    echo ""
    op_account=""
    op_vault=""
    if gum confirm "  Use 1Password for secrets?"; then
        use_1password=true
        wiz_1pass="enabled"

        draw_wizard 4
        gum style --foreground "$WIZ_LIGHT" --bold "  Secrets"
        echo ""
        op_account=$(gum input --header "  1Password account:" --placeholder "my.1password.com" \
            --value "my.1password.com" --header.foreground "$WIZ_DIM" --cursor.foreground "$WIZ_ACCENT")
        erase_gum_residual
        wiz_account="$op_account"

        draw_wizard 4
        gum style --foreground "$WIZ_LIGHT" --bold "  Secrets"
        echo ""
        op_vault=$(gum input --header "  1Password vault:" --placeholder "Developer" \
            --value "Developer" --header.foreground "$WIZ_DIM" --cursor.foreground "$WIZ_ACCENT")
        erase_gum_residual
        wiz_vault="$op_vault"
    else
        use_1password=false
        wiz_1pass="disabled"
    fi

    # --- Summary ---
    draw_wizard 4
    gum style --foreground "$WIZ_LIGHT" --bold "  All set!"
    echo ""
    if ! gum confirm --affirmative "Apply" --negative "Cancel" "  Save this config?"; then
        echo "==> Cancelled."
        exit 0
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
    gum style --foreground 10 "  Config saved."
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

    # Run apply, show spinner if gum available. Use temp file to capture errors
    # since gum spin suppresses output.
    local apply_log
    apply_log=$(mktemp)
    # shellcheck disable=SC2046
    if command -v gum &>/dev/null && [ -t 0 ]; then
        if ! gum spin --spinner dot --title "Applying configs..." -- \
            bash -c "chezmoi apply $(apply_flags) 2>'$apply_log'"; then
            echo "==> ERROR: chezmoi apply failed"
            cat "$apply_log" 2>/dev/null
            rm -f "$apply_log"
            exit 2
        fi
    else
        if ! chezmoi apply $(apply_flags) 2>"$apply_log"; then
            echo "==> ERROR: chezmoi apply failed"
            cat "$apply_log" 2>/dev/null
            rm -f "$apply_log"
            exit 2
        fi
    fi
    rm -f "$apply_log"
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
            gum style --foreground 10 "  All key files verified."
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
    gum style --foreground "$WIZ_ACCENT" "chezmoi now manages everything."
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
