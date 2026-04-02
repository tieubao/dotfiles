#!/bin/bash
# One-time: install language toolchains and global tools not in Homebrew.
# Each section is idempotent.

set -e

# Rust (via rustup)
if ! command -v rustc &>/dev/null; then
    echo "==> Installing Rust"
    rustup-init -y --no-modify-path
else
    echo "==> Rust: already installed"
fi

# Foundry (cast, forge, anvil, chisel)
if ! command -v cast &>/dev/null; then
    echo "==> Installing Foundry"
    curl -L https://foundry.paradigm.xyz | bash
    "${HOME}/.foundry/bin/foundryup"
else
    echo "==> Foundry: already installed"
fi

# Global npm tools
if command -v npm &>/dev/null; then
    for pkg in ccusage markdownlint-cli2 npm-check-updates opencode-ai; do
        if ! npm list -g "$pkg" &>/dev/null; then
            echo "==> npm: installing $pkg"
            npm i -g "$pkg" 2>/dev/null || true
        fi
    done
fi

# Global uv tools
if command -v uv &>/dev/null; then
    if ! uv tool list 2>/dev/null | grep -q "^llm "; then
        echo "==> uv: installing llm"
        uv tool install llm 2>/dev/null || true
    fi
fi

echo "==> Toolchains done"
