#!/bin/bash
# One-time: install Rust via rustup

if ! command -v rustc &>/dev/null; then
    echo "==> Installing Rust"
    rustup-init -y --no-modify-path
fi
