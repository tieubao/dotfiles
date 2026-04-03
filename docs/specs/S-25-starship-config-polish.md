---
id: S-25
title: Starship config polish
type: refinement
status: done
old_id: R-13
---

# Starship config polish

### Problem

Starship config (`home/dot_config/starship.toml`) is functional but could be tuned. Module list may be missing languages/tools used daily, and some modules may not be optimally configured.

### Spec

- Review module list — add any missing languages/tools used daily (e.g. `ruby`, `java`, `aws`)
- Check if `detect_folders`/`detect_env_vars` are optimal for k8s module
- Consider adding `time` module (useful for long-running sessions)
- Consider adding `git_metrics` (insertions/deletions) — disabled by default in starship
- Verify Nerd Font symbols render correctly in Ghostty
