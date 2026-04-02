#!/bin/bash
set -e

# Bootstrap script for dotfiles.
# Idempotent: safe to run multiple times on an already-configured machine.
# Use --force to teardown and reinit from scratch.
#
# Exit codes:
#   0 = success
#   1 = Homebrew install failed
#   2 = chezmoi init failed

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CHEZMOI_SOURCE="$HOME/.local/share/chezmoi"
CHEZMOI_CONFIG="$HOME/.config/chezmoi/chezmoi.toml"
FORCE=0

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
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

# --- Determine what to do ---
link_is_correct() {
    [ -L "$CHEZMOI_SOURCE" ] && [ "$(readlink "$CHEZMOI_SOURCE")" = "$DOTFILES/home" ]
}

chezmoi_initialized() {
    [ -f "$CHEZMOI_CONFIG" ]
}

if [ "$FORCE" -eq 1 ]; then
    echo "==> --force: tearing down existing state"
    rm -rf "$CHEZMOI_SOURCE"
    rm -f "$CHEZMOI_CONFIG"
    echo "==> Linking chezmoi source to $DOTFILES/home"
    mkdir -p "$HOME/.local/share"
    ln -sf "$DOTFILES/home" "$CHEZMOI_SOURCE"
    echo "==> Running chezmoi init + apply (will prompt for config)"
    if ! chezmoi init --apply; then
        echo "==> ERROR: chezmoi init failed"
        exit 2
    fi

elif command -v chezmoi &>/dev/null && link_is_correct && chezmoi_initialized; then
    echo "==> Already initialized. Running chezmoi apply..."
    chezmoi apply

elif command -v chezmoi &>/dev/null; then
    # chezmoi exists but not fully initialized for this repo
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
    echo "==> Running chezmoi init + apply"
    if ! chezmoi init --apply; then
        echo "==> ERROR: chezmoi init failed"
        exit 2
    fi
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
