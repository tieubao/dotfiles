---
id: S-27
title: Gum UI helper library
type: feature
status: planned
old_id: F-13
---

# Gum UI helper library (lib/ui.sh)

### Problem

Error messages in install.sh are plain `echo` with no visual hierarchy. When a user enters invalid input (bad email, wrong editor choice, missing 1Password), they see a raw text line that blends with the surrounding output. No visual distinction between errors, successes, warnings, and next-step guidance. No box, no color, no structure.

Gum is already installed, but only used for `gum input`, `gum choose`, `gum confirm`, and `gum spin`. The `gum style`, `gum join`, `gum format`, and `gum log` subcommands are unused. These are the ones that solve the error display problem.

### Spec

Create `lib/ui.sh` as a shared helper library sourced by `install.sh` and all chezmoiscripts.

#### Core functions

```bash
#!/bin/bash
# lib/ui.sh  - Styled terminal output using gum
# Source this in any script: source "$(dirname "$0")/lib/ui.sh"

# Colors (Catppuccin Mocha palette to match Ghostty theme)
RED=196
GREEN=82
YELLOW=214
BLUE=69
DIM=245
WHITE=255
BORDER_DIM=240

# ── Message types ───────────────────────────────────────

error_box() {
  # $1 = title, $2 = detail (optional), $3 = next step (optional)
  local lines=("$(gum style --foreground $RED --bold "$1")")
  [[ -n "$2" ]] && lines+=("" "$(gum style --foreground $DIM "$2")")
  [[ -n "$3" ]] && lines+=("" "$(gum style --foreground $YELLOW "Next: $3")")
  printf "%s\n" "${lines[@]}" | gum style \
    --border double --border-foreground $RED \
    --padding "1 2" --margin "1 0" --width 64
}

success_box() {
  # $1 = message
  gum style --border rounded --border-foreground $GREEN --foreground $GREEN \
    --padding "1 2" --margin "1 0" --width 64 \
    "$1"
}

warn_box() {
  # $1 = message, $2 = detail (optional)
  local lines=("$(gum style --foreground $YELLOW --bold "$1")")
  [[ -n "$2" ]] && lines+=("" "$(gum style --foreground $DIM "$2")")
  printf "%s\n" "${lines[@]}" | gum style \
    --border normal --border-foreground $YELLOW \
    --padding "1 2" --margin "1 0" --width 64
}

info_box() {
  # $1 = message
  gum style --border normal --border-foreground $BLUE --foreground $BLUE \
    --padding "1 2" --margin "0" --width 64 \
    "$1"
}

next_steps_box() {
  # $@ = list of steps (each arg is one step)
  local lines=("$(gum style --foreground $WHITE --bold 'What to do next:')" "")
  local i=1
  for step in "$@"; do
    lines+=("$(gum style --foreground $WHITE "  $i. $step")")
    ((i++))
  done
  printf "%s\n" "${lines[@]}" | gum style \
    --border rounded --border-foreground $BLUE \
    --padding "1 2" --margin "1 0" --width 64
}

# ── Step progress ───────────────────────────────────────

step() {
  # $1 = step number, $2 = total, $3 = description
  gum style --foreground $BLUE --bold "[$1/$2]" | tr -d '\n'
  echo " $3"
}

step_ok() {
  # $1 = what succeeded
  gum style --foreground $GREEN "  ok" | tr -d '\n'
  echo " $1"
}

step_skip() {
  # $1 = what was skipped, $2 = reason
  gum style --foreground $YELLOW "  skip" | tr -d '\n'
  echo " $1 ($2)"
}

step_fail() {
  # $1 = what failed, $2 = error detail
  gum style --foreground $RED "  fail" | tr -d '\n'
  echo " $1"
  [[ -n "$2" ]] && gum style --foreground $DIM "       $2"
}

# ── Validation helpers ──────────────────────────────────

validate_email() {
  local email="$1"
  if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    error_box \
      "Invalid email: $email" \
      "Expected format: user@example.com" \
      "Press Enter to try again"
    return 1
  fi
  return 0
}

validate_choice() {
  local value="$1"
  shift
  local options=("$@")
  for opt in "${options[@]}"; do
    [[ "$value" == "$opt" ]] && return 0
  done
  error_box \
    "Invalid choice: $value" \
    "Valid options: $(IFS=', '; echo "${options[*]}")" \
    "Press Enter to try again"
  return 1
}

# ── Banner ──────────────────────────────────────────────

show_banner() {
  gum style \
    --border double --border-foreground $BLUE \
    --align center --padding "1 4" --margin "1 0" --width 64 \
    "$(gum style --foreground $WHITE --bold 'dwarvesf/dotfiles')" \
    "$(gum style --foreground $DIM 'One command to set up a new Mac')"
}
```

#### Usage in install.sh

Replace raw echo statements:

```bash
# Before (current)
echo "==> Error: chezmoi init failed"

# After
source "$(dirname "$0")/lib/ui.sh"
error_box "chezmoi init failed" \
  "This usually means .chezmoi.toml.tmpl has a syntax error." \
  "Run: chezmoi init --debug to see the full error"
```

Replace the wizard flow:

```bash
# Show banner at start
show_banner

# Step progress
step 1 6 "Checking Homebrew..."
if command -v brew &>/dev/null; then
  step_ok "Homebrew installed"
else
  step_fail "Homebrew not found" "Installing..."
  # install brew
  step_ok "Homebrew installed"
fi

# Input validation with retry loop
while true; do
  EMAIL=$(gum input --placeholder "you@example.com" --header "Email address")
  validate_email "$EMAIL" && break
done

# End with next steps
success_box "Setup complete!"
next_steps_box \
  "Open Ghostty (or a new terminal tab)" \
  "Sign into 1Password: op signin" \
  "Enable SSH agent: 1Password > Settings > Developer > SSH Agent" \
  "Apply secrets: chezmoi apply"
```

#### Error scenarios to handle

Each of these should show `error_box` with specific guidance:

| Scenario | Title | Detail | Next step |
|----------|-------|--------|-----------|
| Invalid email | "Invalid email: {input}" | "Expected format: user@example.com" | "Press Enter to try again" |
| Invalid editor choice | "Unknown editor: {input}" | "Valid options: code, zed, nvim, vim" | "Press Enter to choose again" |
| brew install fails | "Homebrew installation failed" | "Check your internet connection" | "Run the Homebrew installer manually" |
| chezmoi init fails | "chezmoi init failed" | "Template syntax error in .chezmoi.toml.tmpl" | "Run: chezmoi init --debug" |
| 1Password not signed in | "1Password CLI not authenticated" | "Secrets will be skipped this run" | "Run: op signin, then: chezmoi apply" |
| brew bundle fails | "brew bundle failed" | "Some packages may not be available" | "Run: brew bundle --file=~/.Brewfile --verbose" |
| Fish not in /etc/shells | "Fish shell not registered" | "Need sudo to add to /etc/shells" | "Run: echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells" |
| Git identity empty | "Git name/email not set" | "chezmoi template will leave blanks" | "Run: chezmoi init to re-enter" |

### Rules

- All gum style widths should be 64 (fits 80-col terminal with margin)
- Colors use numeric ANSI codes for portability
- Every error_box MUST include a "next step" third argument
- Never show a raw error without guidance on what to do
- lib/ui.sh must work when sourced from any directory (use absolute/relative paths carefully)
- If gum is not installed yet (early in install.sh), fall back to plain echo with ANSI escapes:
  ```bash
  if ! command -v gum &>/dev/null; then
    error_box() { echo -e "\033[31mERROR: $1\033[0m"; [[ -n "$2" ]] && echo "  $2"; }
    success_box() { echo -e "\033[32m$1\033[0m"; }
    # ... minimal fallbacks for all functions
  fi
  ```

### Files to create/modify

- Create `lib/ui.sh`
- Modify `install.sh` to source `lib/ui.sh` and replace all echo/printf with styled functions
- Modify all `.chezmoiscripts/run_*` that have user-facing output to source `lib/ui.sh`

### Test

1. Run `./install.sh` with invalid email. Should show red double-border box with correction guidance.
2. Run `./install.sh` with invalid editor. Should show error + valid options.
3. Run `./install.sh --check`. Should show step progress with ok/skip/fail indicators.
4. Run on a machine without gum installed. Should fall back to plain ANSI echo, not crash.
