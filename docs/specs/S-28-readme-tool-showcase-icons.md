---
id: S-28
title: README tool showcase icons
type: feature
status: done
old_id: F-14
---

# README tool showcase icons

### Problem

The "What's included" table lists tools by name but has no visual identity. A visitor scanning the README can't quickly associate tools with their logos. The shields.io badges at the top are status indicators, not a visual showcase.

### Spec

Add a visual tool grid below the opening paragraph using a combination of three sources:

#### Option A: skillicons.dev (for common tools)

```markdown
<p align="center">
  <a href="https://skillicons.dev">
    <img src="https://skillicons.dev/icons?i=fish,bash,git,docker,go,nodejs,python,rust,vscode&theme=light&perline=9" />
  </a>
</p>
```

skillicons.dev provides consistent, high-quality SVG icons in a grid. Supports `theme=light` and `theme=dark`. Has 200+ icons. Missing: Ghostty, chezmoi, Starship, 1Password, Zed, tmux, mise.

#### Option B: custom-icon-badges.demolab.com (for niche tools)

For tools not in skillicons.dev, use DenverCoder1/custom-icon-badges which lets you upload custom SVG logos:

```markdown
![Ghostty](https://custom-icon-badges.demolab.com/badge/Ghostty-1a1a2e?style=for-the-badge&logo=ghostty-custom&logoColor=white)
![chezmoi](https://custom-icon-badges.demolab.com/badge/chezmoi-blue?style=for-the-badge&logo=chezmoi-custom&logoColor=white)
![Starship](https://custom-icon-badges.demolab.com/badge/Starship-DD0B78?style=for-the-badge&logo=starship&logoColor=white)
```

Requires uploading SVG logos to custom-icon-badges. One-time setup per icon.

#### Option C: Hybrid (recommended)

Use skillicons.dev for the main grid and shields.io/custom-icon-badges for the missing tools. Group by category:

```markdown
### Core stack

<p align="center">
  <img src="https://skillicons.dev/icons?i=fish,git,docker,vscode&theme=light&perline=8" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Ghostty-Terminal-1a1a2e?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Starship-Prompt-DD0B78?style=for-the-badge&logo=starship&logoColor=white" />
  <img src="https://img.shields.io/badge/chezmoi-Dotfiles-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/1Password-Secrets-0572EC?style=for-the-badge&logo=1password&logoColor=white" />
  <img src="https://img.shields.io/badge/tmux-Multiplexer-1BB91F?style=for-the-badge&logo=tmux&logoColor=white" />
</p>
```

#### Placement in README

Insert AFTER the opening paragraph and BEFORE "Quick start". Replace nothing, just add a visual section. The shields.io status badges at the very top stay as-is (they serve a different purpose: status vs showcase).

```markdown
# dotfiles

[existing shields.io badges - keep]

A modern developer tooling stack for macOS...

<!-- Tool showcase - NEW -->
<p align="center">
  [skillicons grid here]
</p>
<p align="center">
  [shields.io badges for niche tools here]
</p>

## Quick start
...
```

### Rules

- Keep it to ONE visual block, not scattered throughout
- skillicons.dev `perline` should match the number of icons (no awkward wrapping)
- Use `theme=light` since your SVG diagrams also use white backgrounds
- Do not duplicate info already in the "What's included" table
- The icon grid is a visual hook, not documentation. Keep it minimal.
- If a tool doesn't have an icon available anywhere, skip it. Don't use placeholder icons.

### Research for Claude Code

- skillicons.dev full icon list: https://skillicons.dev
- Simple Icons slugs: https://simpleicons.org/
- custom-icon-badges: https://github.com/DenverCoder1/custom-icon-badges
- shields.io endpoint builder: https://shields.io/badges
- Check which of these tools have Simple Icons slugs: fish, ghostty, chezmoi, starship, tmux, mise, zed, orbstack

### Files to modify

- `README.md` (add icon grid section)

### Test

1. View README on GitHub in light mode. Icons should be visible and consistent.
2. View README on GitHub in dark mode. Icons should still be legible (skillicons.dev auto-adapts, shields.io badges have colored backgrounds so they work on both).
3. All icon links should resolve (no broken images).
