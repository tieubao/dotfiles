---
id: S-10
title: Ghostty image rendering
type: feature
status: done
old_id: F-10
---

# Ghostty image rendering

### Problem
Ghostty supports the Kitty graphics protocol for inline image display, but no tools are installed and no helper function exists to render images.

### Spec
Add packages to Brewfile and create a Fish function:

Packages (add to `Brewfile.dev`):
```ruby
brew "chafa"        # terminal image renderer (auto-detects kitty protocol)
brew "librsvg"      # SVG to PNG conversion (rsvg-convert)
brew "imagemagick"  # general image processing
```

Create `home/dot_config/fish/functions/render-img.fish`:

```fish
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

    # Use kitty protocol for Ghostty
    chafa --format=kitty --size="$width"x "$temp"
end
```

Create completion:
```fish
# home/dot_config/fish/completions/render-img.fish
complete -c render-img -f
complete -c render-img -a "(__fish_complete_path)" -d "Image file"
```

### Files to create
- `home/dot_config/fish/functions/render-img.fish`
- `home/dot_config/fish/completions/render-img.fish`
- Modify `Brewfile.dev` (add chafa, librsvg, imagemagick)

### Test
```bash
# In Ghostty terminal:
render-img /path/to/screenshot.png
render-img /path/to/diagram.svg
render-img /path/to/photo.jpg 40  # explicit width
```
