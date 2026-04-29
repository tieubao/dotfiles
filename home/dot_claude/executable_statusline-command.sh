#!/usr/bin/env bash
# Claude Code statusLine  - Catppuccin Mocha palette
input=$(cat)

# Catppuccin Mocha colors
BLUE='\033[38;2;137;180;250m'    # blue
GREEN='\033[38;2;166;227;161m'   # green
YELLOW='\033[38;2;249;226;175m'  # yellow
RED='\033[38;2;243;139;168m'     # red
MAUVE='\033[38;2;203;166;247m'   # mauve
SAPPHIRE='\033[38;2;116;199;236m' # sapphire (5h low)
PEACH='\033[38;2;250;179;135m'   # peach (7d warn)
DIM='\033[38;2;108;112;134m'     # overlay0
RESET='\033[0m'

# --- Directory ---
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
  cwd="${cwd/#$HOME/\~}"
  count=$(echo "$cwd" | tr '/' '\n' | grep -c -v '^$')
  if [ "$count" -gt 3 ]; then
    dir="…/$(echo "$cwd" | rev | cut -d'/' -f1-3 | rev)"
  else
    dir="$cwd"
  fi
else
  dir="?"
fi

# --- Git ---
git_part=""
real_cwd=$(echo "$input" | jq -r '.cwd // empty')
if git -C "$real_cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$real_cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$real_cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    flags=""
    porcelain=$(git -C "$real_cwd" status --porcelain 2>/dev/null)
    echo "$porcelain" | grep -q '^?? '       && flags="${flags}?"
    echo "$porcelain" | grep -q '^ M\|^M '   && flags="${flags}!"
    echo "$porcelain" | grep -q '^A \|^M '    && flags="${flags}+"
    ahead=$(git -C "$real_cwd" rev-list '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git -C "$real_cwd" rev-list 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
    [ "$ahead" -gt 0 ] 2>/dev/null  && flags="${flags}⇡"
    [ "$behind" -gt 0 ] 2>/dev/null && flags="${flags}⇣"
    if [ -n "$flags" ]; then
      git_part=" ${GREEN} ${branch}${RESET} ${YELLOW}[${flags}]${RESET}"
    else
      git_part=" ${GREEN} ${branch}${RESET}"
    fi
  fi
fi

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // .model // empty')
# If it's still a JSON object, extract display_name
if echo "$model" | grep -q '^{'; then
  model=$(echo "$model" | jq -r '.display_name // .id // empty')
fi
[ -n "$model" ] && model_part=" ${DIM}│${RESET} ${MAUVE}${model}${RESET}" || model_part=""

# --- Context ---
ctx_part=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 80 ]; then
    color="$RED"
  elif [ "$used_int" -ge 50 ]; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi
  ctx_part=" ${DIM}│${RESET} ${color}${used_int}%${RESET}"
fi

# --- Rate limit ---
rate_part=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  if [ "$five_int" -ge 80 ]; then
    color="$RED"
  elif [ "$five_int" -ge 50 ]; then
    color="$YELLOW"
  else
    color="$SAPPHIRE"
  fi
  rate_part=" ${color}5h:${five_int}%${RESET}"
fi

# --- Weekly rate limit ---
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$seven_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_pct")
  if [ "$seven_int" -ge 80 ]; then
    color="$RED"
  elif [ "$seven_int" -ge 50 ]; then
    color="$PEACH"
  else
    color="$MAUVE"
  fi
  rate_part="${rate_part} ${color}7d:${seven_int}%${RESET}"
fi

# --- Session duration ---
duration_part=""
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
  duration_sec=$((duration_ms / 1000))
  hours=$((duration_sec / 3600))
  mins=$(( (duration_sec % 3600) / 60 ))
  if [ "$hours" -gt 0 ]; then
    duration_part=" ${DIM}${hours}h${mins}m${RESET}"
  elif [ "$mins" -gt 0 ]; then
    duration_part=" ${DIM}${mins}m${RESET}"
  fi
fi

printf '%b' "${BLUE}${dir}${RESET}${git_part}${model_part}${ctx_part}${rate_part}${duration_part}"
