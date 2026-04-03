---
id: S-18
title: VS Code extension sync
type: refinement
status: done
old_id: R-06
---

# VS Code extension sync

**Priority:** Low
**Status:** Done

## Problem

`run_onchange_after_vscode.sh.tmpl` runs `code --install-extension --force` for every extension in `extensions.txt` whenever VS Code settings change. The `--force` flag reinstalls even if the extension is already present, which:
- Takes time (downloads + installs ~24 extensions)
- Could override user-installed versions with older ones
- Triggers on any settings.json edit, not just extension list changes

## Spec

Replace the force-install loop with a diff-based approach:

```bash
#!/bin/bash
# Install only missing VS Code extensions

EXTENSIONS_FILE="$HOME/.config/code/extensions.txt"
if [ ! -f "$EXTENSIONS_FILE" ]; then
    exit 0
fi

# Get currently installed extensions (lowercase for comparison)
installed=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

while IFS= read -r ext; do
    # Skip empty lines and comments
    [[ -z "$ext" || "$ext" =~ ^# ]] && continue
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if ! echo "$installed" | grep -qx "$ext_lower"; then
        echo "Installing: $ext"
        code --install-extension "$ext"
    fi
done < "$EXTENSIONS_FILE"
```

This only installs extensions that are missing, skipping those already present.

### Separate hash triggers

Currently the script triggers on a combined hash of settings.json + extensions.txt. Split into two scripts:
- `run_onchange_after_vscode-settings.sh.tmpl` - copies settings.json only
- `run_onchange_after_vscode-extensions.sh.tmpl` - installs missing extensions only

This way editing a font size in settings.json doesn't re-check all extensions.

## Files to modify
- `home/.chezmoiscripts/run_onchange_after_vscode.sh.tmpl` (split into two)

## Test
1. Run `chezmoi apply` with all extensions installed. Should print nothing (no installs).
2. Remove one extension manually. Run `chezmoi apply`. Should install only that one.
3. Edit settings.json. Run `chezmoi apply`. Should NOT trigger extension check.
