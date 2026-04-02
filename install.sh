#!/bin/bash
set -e

# Bootstrap script — only needs to run once on a fresh machine.
# After initial setup, `chezmoi apply` handles everything:
#   - Brewfile changes → auto brew bundle (run_onchange_)
#   - Fish/Foundry/Rust/npm tools → auto install (run_once_)
#   - Fish plugins → auto download (.chezmoiexternal.toml)
#   - Config files → templated + applied

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
echo "==> Dotfiles: $DOTFILES"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- chezmoi ---
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi"
    brew install chezmoi
fi

# --- Point chezmoi to this repo ---
echo "==> Linking chezmoi source to $DOTFILES/home"
rm -rf "$HOME/.local/share/chezmoi"
mkdir -p "$HOME/.local/share"
ln -sf "$DOTFILES/home" "$HOME/.local/share/chezmoi"

# --- Init + apply (prompts for 1Password vault, then runs all scripts) ---
echo "==> Running chezmoi init + apply"
chezmoi init --apply

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
