function ghostty-theme --description "Preview or set Ghostty theme"
    set -l config ~/.config/ghostty/config
    set -l themes \
        "Catppuccin Mocha" \
        "TokyoNight Storm" \
        "Kanagawa Wave" \
        "Rose Pine Moon" \
        "Gruvbox Material Dark" \
        "base16-eighties-dark"

    if test (count $argv) -eq 0
        echo "Current theme:"
        grep '^theme' $config
        echo ""
        echo "Available previews:"
        for i in (seq (count $themes))
            echo "  $i) $themes[$i]"
        end
        echo ""
        echo "Usage: ghostty-theme <number>   - switch theme (live reload)"
        echo "       ghostty-theme reset      - restore base16-eighties-dark"
        return
    end

    if test "$argv[1]" = reset
        sed -i '' "s/^theme = .*/theme = base16-eighties-dark/" $config
        echo "Reset to base16-eighties-dark"
        return
    end

    set -l idx $argv[1]
    if test $idx -lt 1 -o $idx -gt (count $themes)
        echo "Pick 1-"(count $themes)
        return 1
    end

    sed -i '' "s/^theme = .*/theme = $themes[$idx]/" $config
    echo "Switched to: $themes[$idx]"
    echo "(Ghostty live-reloads  - check your terminal)"
end
