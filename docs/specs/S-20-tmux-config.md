---
id: S-20
title: Tmux config
type: refinement
status: done
old_id: R-08
---

# Tmux config

**Priority:** Low
**Status:** Not needed (tmux.conf already exists in repo)

## Problem

tmux is in the Brewfile and config.fish has 4 tmux abbreviations (`tx`, `tml`, `tma`, `tmk`), but there's no `.tmux.conf` in the repo. Users get default tmux behavior which has poor defaults:
- No mouse support
- Prefix is Ctrl-b (hard to reach)
- No status bar customization
- No vim-style navigation
- Window/pane indexing starts at 0

## Spec

Create `home/dot_tmux.conf` with sensible defaults:

```tmux
# Prefix: Ctrl-a (easier to reach than Ctrl-b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Quality of life
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g display-time 4000
set -s escape-time 0

# True color support (Ghostty)
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",ghostty:Tc"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Split panes with | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.tmux.conf \; display "Reloaded"

# Status bar (minimal)
set -g status-position top
set -g status-style "bg=default,fg=white"
set -g status-left " #S "
set -g status-right " %H:%M "
```

Keep it minimal. No TPM (tmux plugin manager), no complex themes. Matches the repo's philosophy of avoiding plugin managers.

## Files to create
- `home/dot_tmux.conf`

## Test
1. `chezmoi apply` deploys `~/.tmux.conf`
2. Start tmux. Ctrl-a works as prefix.
3. Mouse scrolling works.
4. Pane splits use current directory.
