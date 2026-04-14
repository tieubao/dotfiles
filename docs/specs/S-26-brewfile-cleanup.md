---
id: S-26
title: Brewfile cleanup
type: refinement
status: planned
old_id: R-14
---

# Brewfile cleanup

### Problem

`home/dot_Brewfile.tmpl` may contain stale, redundant, or unused entries. Some packages may be installed by both brew and another manager. Commented-out entries need a decision: remove or uncomment.

### Spec

- Verify `font-sauce-code-pro-nerd-font` vs `font-source-code-pro`  - possible duplicate or misname
- Check commented-out entries (AI tools, Web3 tools)  - remove or uncomment
- Verify all casks still exist in Homebrew (`brew info <name>`)
- Check for packages installed by both brew and another manager (e.g. `mise` vs brew for language runtimes)
- Remove any packages no longer used day-to-day
- Run `brew bundle cleanup --file=~/.Brewfile` to find installed-but-unlisted packages worth adding
