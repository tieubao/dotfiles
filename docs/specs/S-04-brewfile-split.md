---
id: S-04
title: Brewfile split
type: feature
status: done
old_id: F-04
---

### Problem
One `dot_Brewfile` with ~80 packages is hard to scan, and on a minimal machine (e.g., CI, server, borrowed laptop) you might want just the essentials without 30 GUI casks.

### Spec
Split into three files:

```
home/
  dot_Brewfile.tmpl              # main entry point, includes the others
  dot_config/brew/
    Brewfile.base                # essentials: git, fish, chezmoi, coreutils, starship, etc.
    Brewfile.dev                 # dev tools: mise, go, node, docker, kubectl, etc.
    Brewfile.apps                # GUI casks: Ghostty, VS Code, 1Password, Arc, etc.
    Brewfile.mas                 # Mac App Store apps (mas IDs)
```

The main `dot_Brewfile.tmpl` uses chezmoi templating:

```ruby
# Base (always)
{{ include "dot_config/brew/Brewfile.base" }}

# Dev tools
{{ if .dev_computer }}
{{ include "dot_config/brew/Brewfile.dev" }}
{{ end }}

# GUI apps (skip in CI/headless)
{{ if not .headless }}
{{ include "dot_config/brew/Brewfile.apps" }}
{{ end }}

# Mac App Store
{{ if and (not .headless) (eq .chezmoi.os "darwin") }}
{{ include "dot_config/brew/Brewfile.mas" }}
{{ end }}
```

New chezmoi init prompt:

```
Is this a headless/server environment? (true/false) → .headless
Is this a development machine? (true/false) → .dev_computer
```

Rules:
- `Brewfile.base` should be < 20 items. Only things you need on EVERY machine.
- `Brewfile.dev` is language toolchains, databases, cloud CLIs
- `Brewfile.apps` is GUI casks only
- `Brewfile.mas` is Mac App Store apps (using `mas` IDs)
- The `run_onchange_before_brew-bundle.sh` script must still trigger on ANY sub-file change. Use chezmoi's hash tracking on the rendered output.
- Add `chafa`, `librsvg`, `imagemagick` to `Brewfile.dev` (for F-10)

### Files to create/modify
- Split `home/dot_Brewfile` into 4 files under `home/dot_config/brew/`
- Create `home/dot_Brewfile.tmpl` as the aggregator
- Modify `home/.chezmoi.toml.tmpl` to add `headless` and `dev_computer` prompts
- Verify `run_onchange_before_brew-bundle.sh` still triggers correctly
