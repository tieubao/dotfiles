#!/bin/bash
# ~/.config/dotfiles/lib.sh — sourced by chezmoi after-scripts
# gum-first styled output with ANSI fallback
#
# Usage:
#   LIB="$HOME/.config/dotfiles/lib.sh"
#   # shellcheck source=/dev/null
#   [ -f "$LIB" ] && source "$LIB" || { echo "dotfiles lib not found"; exit 1; }

# ── Color palette (256-color, matches install.sh) ────────────────────────────
CLR_OK=78       # green
CLR_INFO=86     # cyan
CLR_WARN=192    # yellow
CLR_ERR=204     # red
CLR_ACCENT=75   # blue
CLR_DIM=245     # gray

# ── State ─────────────────────────────────────────────────────────────────────
DOTFILES_LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-apply.log"
_HAS_GUM=$(command -v gum &>/dev/null && echo 1 || echo 0)

# Wrap gum to unset env vars that clash with its flags (e.g. UNDERLINE, BOLD).
# Shell color setup often exports these, causing "bool value must be true" errors.
_gum() { env -u UNDERLINE -u BOLD -u ITALIC -u FAINT -u STRIKETHROUGH gum "$@"; }

# ── Output helpers ────────────────────────────────────────────────────────────

# section "title"
section() {
    if [ "$_HAS_GUM" = 1 ]; then
        _gum style --bold --foreground $CLR_ACCENT "==> $*"
    else
        printf '\n\033[1;38;5;%sm==> %s\033[0m\n' "$CLR_ACCENT" "$*"
    fi
}

# info "message"
info() {
    if [ "$_HAS_GUM" = 1 ]; then
        _gum log --level info "$*"
    else
        printf '\033[38;5;%sm  ✓\033[0m %s\n' "$CLR_OK" "$*"
    fi
}

# warn "what" ["why"] ["fix command"]
warn() {
    if [ "$_HAS_GUM" = 1 ]; then
        _gum log --level warn "$1"
        [ -n "${2:-}" ] && _gum style --faint --foreground $CLR_DIM --padding "0 0 0 8" "$2"
        [ -n "${3:-}" ] && _gum style --padding "0 0 0 8" \
            "$(_gum join "$(_gum style --faint --foreground $CLR_DIM "Fix: ")" "$(_gum style --foreground $CLR_OK "$3")")"
    else
        printf '\033[38;5;%sm  ⚠\033[0m \033[1m%s\033[0m\n' "$CLR_WARN" "$1"
        [ -n "${2:-}" ] && printf '\033[38;5;%sm    %s\033[0m\n' "$CLR_DIM" "$2"
        [ -n "${3:-}" ] && printf '\033[38;5;%sm    Fix: \033[38;5;%sm%s\033[0m\n' "$CLR_DIM" "$CLR_OK" "$3"
    fi
    echo "$(date +%Y-%m-%dT%H:%M:%S) WARN: $1${3:+ | Fix: $3}" >> "$DOTFILES_LOG"
}

# err "what" ["why"] ["fix command"]
err() {
    if [ "$_HAS_GUM" = 1 ]; then
        _gum log --level error "$1"
        [ -n "${2:-}" ] && _gum style --faint --foreground $CLR_DIM --padding "0 0 0 8" "$2"
        [ -n "${3:-}" ] && _gum style --padding "0 0 0 8" \
            "$(_gum join "$(_gum style --faint --foreground $CLR_DIM "Fix: ")" "$(_gum style --foreground $CLR_OK "$3")")"
    else
        printf '\033[38;5;%sm  ✗\033[0m \033[1m%s\033[0m\n' "$CLR_ERR" "$1" >&2
        [ -n "${2:-}" ] && printf '\033[38;5;%sm    %s\033[0m\n' "$CLR_DIM" "$2" >&2
        [ -n "${3:-}" ] && printf '\033[38;5;%sm    Fix: \033[38;5;%sm%s\033[0m\n' "$CLR_DIM" "$CLR_OK" "$3" >&2
    fi
    echo "$(date +%Y-%m-%dT%H:%M:%S) FAIL: $1${3:+ | Fix: $3}" >> "$DOTFILES_LOG"
}

# die "what" ["why"] ["fix command"] — prints error then exits
die() { err "$@"; exit 1; }

# require_cmd "cmd" ["why needed"] ["install command"]
require_cmd() {
    command -v "$1" &>/dev/null || die \
        "$1 not found" \
        "${2:-Required for this step.}" \
        "${3:-brew install $1}"
}

# script_ok ["name"] — call at end of each script to log success
script_ok() {
    local name="${1:-$(basename "$0" | sed 's/^run_[a-z_]*_//' | sed 's/\.sh.*//')}"
    info "$name complete"
    echo "$(date +%Y-%m-%dT%H:%M:%S) OK: $name" >> "$DOTFILES_LOG"
}
