#!/bin/bash
# One-time: install global npm and uv tools

if command -v npm &>/dev/null; then
    echo "==> Installing npm global tools"
    npm i -g ccusage markdownlint-cli2 npm-check-updates opencode-ai 2>/dev/null || true
fi

if command -v uv &>/dev/null; then
    echo "==> Installing uv tools"
    uv tool install llm 2>/dev/null || true
fi
