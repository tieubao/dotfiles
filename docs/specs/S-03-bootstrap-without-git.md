---
id: S-03
title: Bootstrap without git
type: feature
status: done
old_id: F-03
---

### Problem
The README requires `git clone` as the first step. On a truly fresh Mac, git requires Xcode CLT which takes 10+ minutes to install. chezmoi can bootstrap directly from a GitHub repo.

### Spec
Add an alternative one-liner to README:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply dwarvesf
```

Also add a second method using Homebrew (no git needed, brew installs via curl):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
chezmoi init --apply dwarvesf
```

Rules:
- Keep the `git clone` method as primary (better for development workflow)
- Add "without git" as a clearly labeled alternative section
- The `chezmoi init dwarvesf` approach means chezmoi clones to `~/.local/share/chezmoi/` itself (no symlink trick). Document this difference.
- Both methods should produce the same end state

### Files to modify
- `README.md` (add "Alternative: bootstrap without git" section)
