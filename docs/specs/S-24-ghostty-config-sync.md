---
id: S-24
title: Ghostty config sync
type: refinement
status: planned
old_id: R-12
---

# Ghostty config sync

### Problem

Ghostty config is a plain file (`home/dot_config/ghostty/config`) with no template. Settings like font, theme, and shell path are hardcoded. The `command = /opt/homebrew/bin/fish --login` path breaks on Intel Macs where brew is at `//usr/local/bin`. Config keys may have drifted from latest Ghostty docs since initial setup.

### Spec

- Convert to `.tmpl` if any values need to vary per machine (e.g. font size, theme)
- Review settings against latest Ghostty docs  - config keys may have changed since initial setup
- Consider whether `command = /opt/homebrew/bin/fish --login` should use a template variable (breaks on Intel Macs where brew is at `/usr/local/bin`)
- Add Ghostty to `dotfiles doctor` checks (verify binary exists, config is valid)
