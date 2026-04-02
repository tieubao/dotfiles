# ADR-003: Ghostty over Kitty

## Status: accepted

## Context
Needed a GPU-accelerated terminal emulator for macOS that supports the Kitty graphics protocol (inline images), has native macOS feel, and is actively maintained.

## Decision
Use Ghostty as the primary terminal emulator.

## Alternatives considered
- **Kitty**: The original Kitty graphics protocol implementation. Fast, feature-rich, cross-platform. But the macOS experience feels like a Linux app ported to Mac: non-native window chrome, keyboard shortcuts that conflict with macOS conventions, no native tabs.
- **WezTerm**: Lua-based config, cross-platform. Very configurable but the config complexity is high for what we need. Multiplexing built in but we already have tmux.
- **iTerm2**: macOS-native and feature-complete but not GPU-accelerated. Slower rendering on large outputs. The feature set is massive but most of it goes unused.
- **Alacritty**: Fast and minimal but no image protocol support at all. Intentionally excludes features like tabs and splits, delegating to tmux.
- **Warp**: Requires login and account creation. Sends telemetry to servers. Not acceptable for a developer terminal.

## Consequences
- Inline image rendering works via Kitty graphics protocol (chafa --format=kitty)
- Config lives at `~/.config/ghostty/config`
- macOS-only: Linux users would need a different terminal choice
- Ghostty is relatively new, so occasional breaking changes are expected
