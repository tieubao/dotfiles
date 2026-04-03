#!/bin/bash
# One-time: add fish to /etc/shells and set as default
set -eo pipefail

LIB="$HOME/.config/dotfiles/lib.sh"
# shellcheck source=/dev/null
if [ -f "$LIB" ]; then source "$LIB"; else echo "dotfiles lib not found"; exit 1; fi

FISH_PATH="/opt/homebrew/bin/fish"

if ! [ -x "$FISH_PATH" ]; then
    die "fish not found at $FISH_PATH" \
        "Homebrew fish must be installed first." \
        "brew install fish"
fi

section "Setting up fish shell"

if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
    info "Adding fish to /etc/shells (requires sudo)"
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    if chsh -s "$FISH_PATH" 2>/dev/null; then
        info "Fish set as default shell"
    else
        warn "Could not set fish as default shell" \
             "chsh may require a password or may be restricted." \
             "chsh -s $FISH_PATH"
    fi
else
    info "Fish already set as default shell"
fi

script_ok "fish-shell"
