---
id: S-29
title: VHS terminal demo
type: feature
status: planned
old_id: F-15
---

# VHS terminal demo recording

### Problem

The README has no terminal screenshot or demo. A terminal demo at the top of the README is the single most effective way to get someone to try your dotfiles. Static screenshots are ok, but an animated demo of the install wizard is better.

### Spec

Use Charmbracelet VHS to record a terminal demo GIF/SVG:

1. Install VHS: `brew install vhs`

2. Create `docs/demo.tape` (VHS recording script):

```tape
# docs/demo.tape
Output docs/demo.gif
Set FontSize 14
Set Width 900
Set Height 600
Set Theme "Catppuccin Mocha"
Set FontFamily "JetBrains Mono"
Set Padding 20

Type "cd ~/dotfiles && ./install.sh"
Enter
Sleep 2s

# Wizard prompts appear (gum styled)
Sleep 1s
Type "Han"
Enter
Sleep 500ms

Type "han@dwarvesf.com"
Enter
Sleep 500ms

# Editor choice
Sleep 500ms
Down
Enter
Sleep 500ms

# 1Password
Sleep 500ms
Enter
Sleep 1s

# Show progress
Sleep 3s

# Final success box + next steps
Sleep 2s
```

3. Record: `vhs docs/demo.tape`

4. Add to README top:

```markdown
<p align="center">
  <img src="docs/demo.gif" alt="Install demo" width="700" />
</p>
```

### Rules

- Keep the recording under 30 seconds
- Show the gum-styled wizard prompts, not raw text
- Show at least one error recovery (wrong input, correction)
- Show the final success_box + next_steps_box
- Use Catppuccin Mocha theme to match the actual Ghostty config
- GIF should be under 5MB for fast GitHub loading. Use `Set Quality 80` in VHS if needed.
- Alternatively, output as SVG (`Output docs/demo.svg`) for crisp rendering at any size

### Files to create

- `docs/demo.tape`
- `docs/demo.gif` (generated output)
- Modify `README.md` to embed the demo

### Dependencies

- `brew install vhs` (add to Brewfile.dev)
- `brew install ttyd` (VHS dependency)
- `brew install ffmpeg` (VHS dependency for GIF output)
