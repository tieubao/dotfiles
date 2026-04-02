#!/bin/bash
# One-time: add fish to /etc/shells and set as default

FISH_PATH="/opt/homebrew/bin/fish"

if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
    echo "==> Adding fish to /etc/shells (requires sudo)"
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    echo "==> Setting fish as default shell (requires password)"
    chsh -s "$FISH_PATH" || echo "   Run manually: chsh -s $FISH_PATH"
fi
