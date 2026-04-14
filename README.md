# dotfiles

![macOS](https://img.shields.io/badge/macOS-Apple%20Silicon-000?logo=apple&logoColor=white)
![Fish](https://img.shields.io/badge/Fish-Shell-4AAE46?logo=gnubash&logoColor=white)
![Starship](https://img.shields.io/badge/Starship-Prompt-DD0B78?logo=starship&logoColor=white)
![Ghostty](https://img.shields.io/badge/Ghostty-Terminal-1a1a2e)
![chezmoi](https://img.shields.io/badge/chezmoi-Managed-blue)
![1Password](https://img.shields.io/badge/1Password-Secrets-0572EC?logo=1password&logoColor=white)
![CI](https://img.shields.io/github/actions/workflow/status/dwarvesf/dotfiles/test.yml?label=CI&logo=github)

A dotfiles repo maintained by an LLM. You operate your Mac freely; Claude detects what drifted and syncs it back to the repo on your approval. **You never manually keep this repo in sync.**

## The idea

Most dotfiles repos expect you to edit the source, apply, commit, push. In practice, nobody does this consistently. You `brew install` while debugging, tweak a config directly, add an API key, and move on. After a few weeks, the repo is stale.

This repo works differently. You change things on your machine. Periodically, you ask Claude to catch up:

```
You:    /dotfiles-sync
Claude: [scans machine — packages, configs, extensions, secrets]

Claude: Dotfiles sync report
          Config drift: Zed settings (2 new MCP servers)
          New packages: ollama, rclone, pandoc
          Stale: raycast, slack (not installed)
          VS Code: 5 new extensions
        What should I do?

You:    sync everything, drop raycast and slack

Claude: [edits Brewfile, re-adds configs, updates extensions,
         logs to sync-log.md, commits]
        Done. Push?

You:    push
```

Two sentences from you. The LLM handled 6 file edits, a commit message, and a push.

The pattern is general and works with any dotfiles manager and any LLM agent. The full write-up, including setup instructions, is in **[docs/llm-dotfiles.md](docs/llm-dotfiles.md)**.

## How it works

<p align="center">
  <img src="docs/dotfiles_llm_sync_workflow.svg" alt="LLM sync workflow: machine drifts, Claude syncs" width="680">
</p>

[chezmoi](https://www.chezmoi.io/) is the backbone. It separates the source (repo) from the target ($HOME), renders templates with injected secrets, and provides drift detection via `chezmoi status`. This two-layer model is what makes LLM-maintained sync possible: the LLM can safely scan, diff, and re-add without touching secrets in git.

The `/dotfiles-sync` command is installed to `~/.claude/commands/` during setup, so it's available in Claude Code from any directory. The command prompt (at [.claude/commands/dotfiles-sync.md](.claude/commands/dotfiles-sync.md)) teaches Claude what to scan:

| Dimension | What it detects |
|-----------|----------------|
| Config drift | Files changed on machine but not in repo |
| Brew packages | Installed but not in Brewfile (and vice versa) |
| Cask apps | GUI apps installed but not tracked |
| VS Code extensions | New or removed extensions |
| Fish functions | Functions created outside chezmoi |
| SSH configs | New host configs in config.d/ |
| Secrets | Hardcoded keys that should be in 1Password |

Every sync is logged in [docs/sync-log.md](docs/sync-log.md) so future syncs have context.

## Quick start

```bash
git clone https://github.com/dwarvesf/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

A [gum](https://github.com/charmbracelet/gum)-powered wizard prompts for your name, email, editor, headless mode, and 1Password. First run takes ~30 minutes (Homebrew downloads). After that, just use `/dotfiles-sync` to keep things current.

**Requirements:** macOS 12+, Apple Silicon (Intel works too).

<details>
<summary><b>Other install methods</b></summary>

**Existing Mac** (configs only, skip brew/mas/defaults):
```bash
cd ~/dotfiles && ./install.sh --config-only
```

**Without git** (fresh Mac, no Xcode CLT):
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply dwarvesf
```

**Flags:** `--check` (dry-run), `--force` (reinit from scratch)

</details>

## The stack

| Layer | Tools |
|-------|-------|
| **Shell** | Fish + Starship prompt + plugins (autopair, done, sponge, async-prompt) |
| **Terminal** | Ghostty (GPU-rendered, catppuccin-mocha, JetBrains Mono) |
| **Multiplexer** | tmux (C-a prefix, vim nav, fzf session picker) |
| **Editors** | VS Code + Zed (settings, extensions, MCP servers with 1P secrets) |
| **Git** | delta diffs, aliases, commit template |
| **SSH** | 1Password SSH Agent, modular config.d/ |
| **Secrets** | 1Password `op://` templates + data-driven registry |
| **Packages** | Layered Brewfile (base/dev/apps) + Mac App Store |
| **Languages** | mise (Node, Python, Go, Ruby) |
| **macOS** | 30+ `defaults write` (Dock, Finder, keyboard, screenshots) |

Every tool is chosen for speed, ergonomics, and native macOS integration. No legacy defaults, no bloat.

## Offline fallback

When you're not in a Claude session (SSH, airplane, quick edit), the `dotfiles` CLI works standalone:

```fish
dotfiles edit ~/.config/fish/config.fish   # edit + apply + auto-commit
dotfiles drift                              # detect and re-absorb drift
dotfiles doctor                             # health check
```

Full command reference, walkthroughs, secrets management, multi-machine setup, and troubleshooting are in the **[user guide](docs/guide.md)**.

## Lifecycle

| Stage | Command |
|-------|---------|
| **Install** | `git clone ... ~/dotfiles && cd ~/dotfiles && ./install.sh` |
| **Update** (LLM) | `/dotfiles-sync` in Claude Code |
| **Update** (manual) | `dotfiles update` (pull + apply) |
| **Reinstall** | `./install.sh --force` |
| **Uninstall** | See [guide](docs/guide.md#9-lifecycle-install-update-uninstall) |

## Security

This repo is safe to make public. Actual secrets (API keys, tokens, passwords) are never committed; only `op://` references to 1Password items appear in the source. Real values are resolved at `chezmoi apply` time and only exist on your machine.

The `op://` references do reveal 1Password vault and item names (e.g. `op://Private/OpenAI/credential`). This is intentional: it makes the repo forkable. If you fork, replace the item names with your own. The vault structure tells someone what services you use, not how to access them.

## Docs

| Document | What it covers |
|----------|---------------|
| **[docs/llm-dotfiles.md](docs/llm-dotfiles.md)** | The LLM-maintained dotfiles pattern. Shareable, stack-agnostic. Includes setup instructions. |
| **[docs/guide.md](docs/guide.md)** | Full user guide. chezmoi details, manual commands, customization, secrets, multi-machine, troubleshooting. |
| **[docs/decisions/](docs/decisions/)** | Architecture decision records (why chezmoi, Fish, Ghostty, 1Password, auto-commit). |
| **[docs/sync-log.md](docs/sync-log.md)** | Sync history. Append-only log of every Claude-assisted sync. |

## Credits

Built with [chezmoi](https://www.chezmoi.io/). Inspired by [halostatue/dotfiles](https://github.com/halostatue/dotfiles) and [narze/dotfiles](https://github.com/narze/dotfiles).

## License

MIT
