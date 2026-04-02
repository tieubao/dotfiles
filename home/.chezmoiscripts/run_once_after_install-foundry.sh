#!/bin/bash
# One-time: install Foundry (cast, forge, anvil, chisel)

if ! command -v cast &>/dev/null; then
    echo "==> Installing Foundry"
    curl -L https://foundry.paradigm.xyz | bash
    "${HOME}/.foundry/bin/foundryup"
fi
