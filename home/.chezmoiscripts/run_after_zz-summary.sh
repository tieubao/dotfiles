#!/bin/bash
# Apply summary — runs at the end of every chezmoi apply.
# Reads the apply log and prints a styled status box.

set -eo pipefail

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-apply.log"
_has_gum() { command -v gum &>/dev/null; }
_gum() { env -u UNDERLINE -u BOLD -u ITALIC -u FAINT -u STRIKETHROUGH gum "$@"; }

# ── Count results ─────────────────────────────────────────────────────────────
ok_count=0; warn_count=0; fail_count=0
if [ -f "$LOG" ] && [ -s "$LOG" ]; then
    ok_count=$(grep -c "^[^ ]* OK:" "$LOG" 2>/dev/null || echo 0)
    warn_count=$(grep -c "^[^ ]* WARN:" "$LOG" 2>/dev/null || echo 0)
    fail_count=$(grep -c "^[^ ]* FAIL:" "$LOG" 2>/dev/null || echo 0)
fi

# ── Determine border color ───────────────────────────────────────────────────
if [ "$fail_count" -gt 0 ]; then
    border_color=204   # red
elif [ "$warn_count" -gt 0 ]; then
    border_color=192   # yellow
else
    border_color=78    # green
fi

# ── Build summary content ────────────────────────────────────────────────────
if [ "$warn_count" -eq 0 ] && [ "$fail_count" -eq 0 ]; then
    # All OK — short message
    if _has_gum; then
        BODY=$(_gum style --foreground 78 --bold "✓ dotfiles apply complete — all OK")
        _gum style --border rounded --border-foreground $border_color --padding "1 2" --margin "1 0" "$BODY"
    else
        echo ""
        printf '\033[38;5;78m  ✓ dotfiles apply complete — all OK\033[0m\n'
        echo ""
    fi
    exit 0
fi

# ── Detailed summary ─────────────────────────────────────────────────────────
if _has_gum; then
    TITLE=$(_gum style --bold "dotfiles apply complete")

    # Status counts
    LINES=""
    [ "$ok_count" -gt 0 ] && LINES="$(_gum style --foreground 78 "  ✓  $ok_count scripts OK")"
    if [ "$warn_count" -gt 0 ]; then
        L=$(_gum style --foreground 192 "  ⚠  $warn_count warning(s)")
        [ -n "$LINES" ] && LINES=$(_gum join --vertical "$LINES" "$L") || LINES="$L"
    fi
    if [ "$fail_count" -gt 0 ]; then
        L=$(_gum style --foreground 204 "  ✗  $fail_count failure(s)")
        [ -n "$LINES" ] && LINES=$(_gum join --vertical "$LINES" "$L") || LINES="$L"
    fi

    # Warning/failure details
    DETAILS=""
    if [ -f "$LOG" ]; then
        while IFS= read -r line; do
            msg=$(echo "$line" | sed 's/^[^ ]* \(WARN\|FAIL\): //')
            msg=$(echo "$msg" | sed 's/ | Fix:.*$//')
            L=$(_gum style --faint "    $msg")
            [ -n "$DETAILS" ] && DETAILS=$(_gum join --vertical "$DETAILS" "$L") || DETAILS="$L"
        done < <(grep -E "^[^ ]* (WARN|FAIL):" "$LOG" 2>/dev/null)
    fi

    if [ -n "$DETAILS" ]; then
        DETAIL_HEADER=$(_gum style --bold --foreground 117 "  Details")
        DETAILS=$(_gum join --vertical "$DETAIL_HEADER" "$DETAILS")
    fi

    # Next steps — extract fix commands from log
    STEPS=""
    step_num=1
    if [ -f "$LOG" ]; then
        while IFS= read -r line; do
            fix=$(echo "$line" | sed -n 's/.*| Fix: //p')
            if [ -n "$fix" ]; then
                L=$(_gum join \
                    "$(_gum style --foreground 78 "    $step_num.")" \
                    "$(_gum style --faint " $fix")")
                [ -n "$STEPS" ] && STEPS=$(_gum join --vertical "$STEPS" "$L") || STEPS="$L"
                step_num=$((step_num + 1))
            fi
        done < <(grep -E "^[^ ]* (WARN|FAIL):.*\| Fix:" "$LOG" 2>/dev/null)
    fi

    if [ -n "$STEPS" ]; then
        STEPS_HEADER=$(_gum style --bold --foreground 117 "  Next steps")
        STEPS=$(_gum join --vertical "$STEPS_HEADER" "$STEPS")
    fi

    # Compose
    BODY="$TITLE"
    [ -n "$LINES" ] && BODY=$(_gum join --vertical "$BODY" "" "$LINES")
    [ -n "$DETAILS" ] && BODY=$(_gum join --vertical "$BODY" "" "$DETAILS")
    [ -n "$STEPS" ] && BODY=$(_gum join --vertical "$BODY" "" "$STEPS")

    # Log path
    LOG_LINE=$(_gum style --faint --foreground 245 "  Log: $LOG")
    BODY=$(_gum join --vertical "$BODY" "" "$LOG_LINE")

    _gum style --border rounded --border-foreground $border_color --padding "1 2" --margin "1 0" "$BODY"
else
    # ── ANSI fallback ─────────────────────────────────────────────────────
    echo ""
    printf '\033[1m==> Apply complete\033[0m\n'
    [ "$ok_count" -gt 0 ] && printf '\033[38;5;78m  ✓ %s scripts OK\033[0m\n' "$ok_count"
    [ "$warn_count" -gt 0 ] && printf '\033[38;5;192m  ⚠ %s warning(s)\033[0m\n' "$warn_count"
    [ "$fail_count" -gt 0 ] && printf '\033[38;5;204m  ✗ %s failure(s)\033[0m\n' "$fail_count"

    if [ -f "$LOG" ]; then
        has_details=0
        while IFS= read -r line; do
            if [ "$has_details" -eq 0 ]; then
                echo ""
                printf '\033[1m  Details:\033[0m\n'
                has_details=1
            fi
            msg=$(echo "$line" | sed 's/^[^ ]* \(WARN\|FAIL\): //' | sed 's/ | Fix:.*$//')
            printf '\033[38;5;245m    %s\033[0m\n' "$msg"
        done < <(grep -E "^[^ ]* (WARN|FAIL):" "$LOG" 2>/dev/null)

        step_num=1
        has_steps=0
        while IFS= read -r line; do
            fix=$(echo "$line" | sed -n 's/.*| Fix: //p')
            if [ -n "$fix" ]; then
                if [ "$has_steps" -eq 0 ]; then
                    echo ""
                    printf '\033[1m  Next steps:\033[0m\n'
                    has_steps=1
                fi
                printf '\033[38;5;78m    %s.\033[0m \033[38;5;245m%s\033[0m\n' "$step_num" "$fix"
                step_num=$((step_num + 1))
            fi
        done < <(grep -E "^[^ ]* (WARN|FAIL):.*\| Fix:" "$LOG" 2>/dev/null)
    fi

    echo ""
    printf '\033[38;5;245m  Log: %s\033[0m\n' "$LOG"
    echo ""
fi
