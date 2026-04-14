---
id: S-21
title: Consolidate toolchain scripts
type: refinement
status: done
old_id: R-09
---

# Consolidate toolchain scripts

**Priority:** Low
**Status:** Done

## Problem

Three separate `run_once_after_*` scripts do the same pattern (check if tool exists, curl installer, install):
- `run_once_after_install-rust.sh` (8 lines)
- `run_once_after_install-foundry.sh` (8 lines)
- `run_once_after_install-npm-tools.sh` (15 lines)

Each runs as a separate chezmoi step, tracked independently in chezmoi's state DB. This means three separate entries to debug if something goes wrong, and the pattern is duplicated.

## Spec

Consolidate into a single `run_once_after_install-toolchains.sh`:

```bash
#!/bin/bash
# Install language toolchains and global tools not available via Homebrew.
# Each section is idempotent: checks if the tool exists before installing.

set -e

echo "==> Installing toolchains..."

# Rust (via rustup)
if ! command -v rustc &>/dev/null; then
    echo "==> Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "==> Rust: already installed ($(rustc --version))"
fi

# Foundry (cast, forge, anvil)
if ! command -v cast &>/dev/null; then
    echo "==> Installing Foundry"
    curl -L https://foundry.paradigm.xyz | bash
    "$HOME/.foundry/bin/foundryup"
else
    echo "==> Foundry: already installed ($(cast --version 2>/dev/null | head -1))"
fi

# Global npm tools
if command -v npm &>/dev/null; then
    for pkg in ccusage markdownlint-cli2 npm-check-updates opencode-ai; do
        if ! command -v "$pkg" &>/dev/null 2>&1; then
            echo "==> npm: installing $pkg"
            npm install -g "$pkg" 2>/dev/null || true
        fi
    done
fi

# Global uv tools
if command -v uv &>/dev/null; then
    for pkg in llm; do
        if ! uv tool list 2>/dev/null | grep -q "$pkg"; then
            echo "==> uv: installing $pkg"
            uv tool install "$pkg" 2>/dev/null || true
        fi
    done
fi

echo "==> Toolchains done."
```

### Migration

Since chezmoi tracks `run_once_` scripts by filename hash, the old scripts won't re-run and the new consolidated script will run once on next `chezmoi apply`. This is fine because:
- Each section checks if the tool exists (idempotent)
- Already-installed tools are skipped with a version print

Remove the 3 old scripts after the consolidated one is verified.

## Files to create
- `home/.chezmoiscripts/run_once_after_install-toolchains.sh`

## Files to remove
- `home/.chezmoiscripts/run_once_after_install-rust.sh`
- `home/.chezmoiscripts/run_once_after_install-foundry.sh`
- `home/.chezmoiscripts/run_once_after_install-npm-tools.sh`

## Test
1. Run `chezmoi apply` on machine with all tools installed. Should print "already installed" for each.
2. Remove Foundry (`rm -rf ~/.foundry`). Run `chezmoi apply`. Should reinstall only Foundry.
