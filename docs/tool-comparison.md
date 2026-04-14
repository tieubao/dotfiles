# Tool Comparison & Audit (2026-04)

A full audit of installed software against modern alternatives.

## CLI Tools

| Tool | Verdict | Action |
|---|---|---|
| bat, eza, fd, fzf, ripgrep | Best-in-class | **Keep** |
| the_silver_searcher (ag) | Unmaintained since 2018, ripgrep is better | **Remove** |
| htop | Good, but btop is prettier + GPU support | **Consider btop** |
| z | Slower, older algorithm | **Replace with zoxide** |
| dust, duf, procs, choose-rust, tldr, lnav | Still solid, no better alternatives | **Keep** |
| git-delta, git-filter-repo, git-sizer | Best-in-class | **Keep** |
| gitup | Not actively developed | **Keep if you use it** |
| hub | Deprecated since 2020 | **Replace with gh** |
| youtube-dl | Dead since 2021, yt-dlp already installed | **Remove** |
| pipx | Redundant  - `uv tool install` replaces it | **Remove** |
| rbenv | Single-language manager | **Replace with mise** |
| yarn | Redundant with pnpm unless projects require it | **Remove if possible** |
| subversion | Legacy, unless you have SVN repos | **Remove** |
| certbot | Unnecessary if using Caddy (auto-TLS) | **Remove if Caddy-only** |
| aichat | All-in-one LLM CLI, 19k+ stars, actively maintained | **Keep** |
| llm (uv tool) | Complementary to aichat, great plugin ecosystem | **Keep** |
| duckdb | Thriving, v1.5.0+ | **Keep** |
| httpie, wget | Both still useful for different purposes | **Keep** |
| ffmpeg, imagemagick, optipng, qpdf, qrencode | Irreplaceable in their niches | **Keep** |
| cloudflared, caddy, nginx | All serve different purposes | **Keep** |
| kubernetes-cli, k9s | Best-in-class for K8s | **Keep** |
| flyctl | Keep if using Fly.io | **Keep** |
| lume | Actively developed macOS VM manager | **Keep** |
| cmake | Still dominant C/C++ build system | **Keep** |
| sentencepiece | Required by some ML models | **Keep if doing ML** |

## GUI Apps

| App | Verdict | Action |
|---|---|---|
| Ghostty | Best terminal on macOS (by Mitchell Hashimoto) | **Keep** |
| Zed | Fast native editor, growing extensions | **Keep** |
| VS Code | Unmatched extension ecosystem | **Keep** |
| OrbStack | Best container runtime on Mac | **Keep, drop Colima** |
| Skype | Shut down May 2025 by Microsoft | **Remove** |
| Arc | Maintenance mode, team pivoted to "Dia" | **Replace with Zen Browser** |
| Zen Browser | Firefox-based, rising star, privacy-focused | **Keep/adopt** |
| Google Chrome | Still needed for compatibility | **Keep** |
| Microsoft Edge | Redundant Chromium browser | **Remove** |
| Tor Browser | Unique purpose, nothing replaces it | **Keep** |
| Discord | Dominant for communities | **Keep** |
| Zoom | Standard for video meetings | **Keep** |
| Slack | Standard for workplace chat | **Keep** |
| Messenger | No alternative for FB contacts | **Keep if needed** |
| Moom Classic | macOS Sequoia has native tiling | **Replace with Aerospace** |
| Hidden Bar | Stale, not actively maintained | **Replace with Ice** |
| MeetingBar | Best in its category, open-source | **Keep** |
| MindNode Classic | Still good, dev has slowed | **Keep or consider Xmind** |
| Craft | Overlaps with Obsidian | **Remove if using Obsidian** |
| DevUtils | No better macOS-native alternative | **Keep** |
| Disk Inventory X | Abandoned | **Replace with DaisyDisk** |
| Skitch | Abandoned by Evernote | **Replace with CleanShot X** |
| Gifski | High-quality GIF encoding | **Keep for specialized use** |
| Lunar + MonitorControl | Redundant to have both | **Pick one (MonitorControl = free)** |
| 1Password + Proton Pass | Two password managers = confusion | **Pick one primary** |
| NordVPN | Redundant if using Proton VPN | **Consider consolidating** |
| qBittorrent | Best torrent client on macOS | **Keep** |
| Raycast Companion | Keep for launcher features | **Keep** |

## Safari Extensions

| Extension | Verdict | Action |
|---|---|---|
| AdGuard for Safari | Best-maintained Safari content blocker | **Keep** |
| Adblock Plus | Weaker blocking, "acceptable ads" default | **Remove  - redundant with AdGuard** |
| uBlock Origin Lite | Heavily limited by Apple's APIs in Safari | **Remove  - redundant with AdGuard** |
| 1Password for Safari | Essential for 1Password users | **Keep** |
| StopTheMadness Pro | Unique functionality, nothing else does this | **Keep** |
| Vimari | Best vim navigation for Safari | **Keep** |
| SponsorBlock | Auto-skips YouTube sponsors | **Keep** |
| Bonjourr Startpage | Clean new-tab page | **Keep** |
| Obsidian Web Clipper | Essential for Obsidian users | **Keep** |
| Proton Pass for Safari | Tied to Proton Pass decision | **Depends on password manager choice** |

## VS Code Extensions

| Extension | Verdict | Action |
|---|---|---|
| Claude Code | Primary AI coding tool | **Keep** |
| OpenAI ChatGPT (both) | Redundant with Claude Code | **Remove** |
| Go, Python/Pylance/debugpy | Standard language support | **Keep** |
| Elixir LS, Erlang | Standard | **Keep** |
| Ruby LSP (Shopify) | Current standard | **Keep** |
| Docker, Remote SSH/Containers | Standard | **Keep** |
| Rainbow CSV | Niche but useful | **Keep** |
| Makefile Tools | Keep if using Makefiles | **Keep** |
| Devbox (Jetify) | Still active | **Keep if using Nix, else remove** |
| GitHub Codespaces | Keep if using Codespaces | **Keep** |
| GitHub Actions | Useful for CI workflow editing | **Keep** |

## npm Global Tools

| Tool | Verdict | Action |
|---|---|---|
| ccusage | Actively maintained (v18+) | **Keep** |
| imageoptim-cli | Stale (~2024), optipng/webp in Brewfile | **Consider removing** |
| markdownlint-cli | cli2 is where new development happens | **Replace with markdownlint-cli2** |
| npm-check-updates | Still standard, taze is a modern alt | **Keep** |
| opencode-ai | Actively maintained AI coding agent | **Keep** |
| browser-tools-server | MCP server for AI frontend debugging | **Keep if using MCP tools** |

## Cargo & Go Tools

| Tool | Verdict | Action |
|---|---|---|
| leo-lang | Active, Aleo ZK language | **Keep if doing ZK/Aleo work** |
| obsidian-export | Actively maintained | **Keep** |
| gopls | Standard Go language server | **Keep** |
| staticcheck | Standard Go linter | **Keep** |
| up | Internet connectivity checker | **Keep** |

## Coding Fonts

| Font | Verdict | Action |
|---|---|---|
| Fira Code Nerd Font | Still excellent, great ligatures | **Keep** |
| Source Code Pro | Aging, not updated significantly | **Replace with JetBrains Mono NF** |

## New Tools to Consider

| Tool | Category | Why |
|---|---|---|
| gh | GitHub CLI | Official replacement for hub |
| zoxide | Directory jumper | Faster, smarter z replacement (Rust-based) |
| mise | Version manager | One tool for all language versions (replaces rbenv, nvm, pyenv) |
| btop | System monitor | Modern htop with GPU monitoring |
| Aerospace | Window manager | i3-like tiling WM for macOS |
| Ice | Menu bar manager | Open-source, replaces Hidden Bar/Bartender |
| CleanShot X | Screenshots | Best screenshot/recording tool on Mac |
| DaisyDisk | Disk analyzer | Replaces abandoned Disk Inventory X |
| JetBrains Mono NF | Coding font | Most popular coding font of 2025 |
