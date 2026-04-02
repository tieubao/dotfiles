function render-img -d "Render images inline in Ghostty terminal"
    set -l file $argv[1]
    set -l width (math (tput cols) - 4)

    if test -z "$file"
        echo "Usage: render-img <file> [width]"
        echo "Supports: png, jpg, svg, gif, webp"
        return 1
    end

    if test (count $argv) -ge 2
        set width $argv[2]
    end

    if not test -f "$file"
        echo "File not found: $file"
        return 1
    end

    set -l ext (string lower (string split -r -m1 '.' $file)[2])
    set -l temp /tmp/render-img-preview.png

    switch $ext
        case svg
            if command -q rsvg-convert
                rsvg-convert "$file" -o $temp 2>/dev/null
            else
                echo "Need rsvg-convert: brew install librsvg"
                return 1
            end
        case png jpg jpeg gif webp
            set temp "$file"
        case '*'
            echo "Unsupported format: $ext"
            return 1
    end

    if not command -q chafa
        echo "Need chafa: brew install chafa"
        return 1
    end

    chafa --format=kitty --size="$width"x "$temp"
end
