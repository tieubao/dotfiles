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

# --- chezmoi ---
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi"
    brew install chezmoi
else
    echo "==> chezmoi: already installed"
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

    # shellcheck disable=SC2046
    if ! chezmoi apply $(apply_flags); then
        echo "==> ERROR: chezmoi apply failed"
        exit 2
    fi
}

run_init_apply() {
    if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "==> Dry run (--check mode, init required)"
        echo "==> Note: chezmoi is not initialized yet. Run without --check first."
        echo "==> Checking template syntax only..."
        if ! chezmoi execute-template < /dev/null 2>/dev/null; then
            echo "==> WARNING: template engine check failed (expected before init)"
        fi
        echo "==> Dry run complete. Run './install.sh' to initialize and apply."
        return 0
    fi

    echo "==> Running chezmoi init (will prompt for config)"
    if ! chezmoi init; then
        echo "==> ERROR: chezmoi init failed"
        exit 2
    fi

    if [ "$CONFIG_ONLY" -eq 1 ]; then
        echo "==> Config-only mode: deploying files, skipping scripts"
    fi

    # shellcheck disable=SC2046
    if ! chezmoi apply $(apply_flags); then
        echo "==> ERROR: chezmoi apply failed"
        exit 2
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
        echo "==> All key files verified."
    fi
}

# --- Determine what to do ---
if [ "$FORCE" -eq 1 ]; then
    echo "==> --force: tearing down existing state"
    rm -rf "$CHEZMOI_SOURCE"
    rm -f "$CHEZMOI_CONFIG"
    ensure_link
    run_init_apply

elif command -v chezmoi &>/dev/null && link_is_correct && chezmoi_initialized; then
    echo "==> Already initialized. Running chezmoi apply..."
    run_apply

elif command -v chezmoi &>/dev/null; then
    ensure_link
    run_init_apply
fi

# --- Post-apply verification ---
if [ "$CHECK_ONLY" -eq 0 ]; then
    verify_deployment
fi

echo ""
echo "==> Done!"
echo ""
echo "chezmoi now manages everything. Future changes:"
echo "  chezmoi edit ~/.config/fish/config.fish   # edit a config"
echo "  chezmoi apply                             # apply all changes"
echo "  chezmoi diff                              # preview changes"
echo ""
echo "Next steps:"
echo "  1. Restart Ghostty (or open a new tab)"
echo "  2. Sign into 1Password:  op signin"
echo "  3. Enable 1Password SSH agent: 1Password > Settings > Developer > SSH Agent"
echo "  4. Move plaintext API keys from ~/.zshrc → 1Password:"
echo "     op item create --vault=Developer --category=api_credential --title='OpenAI' password='sk-...'"
echo "  5. Uncomment secrets: chezmoi edit ~/.config/fish/conf.d/secrets.fish"
echo "  6. Apply: chezmoi apply"
