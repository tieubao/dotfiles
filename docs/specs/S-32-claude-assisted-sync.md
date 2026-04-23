---
id: S-32
title: Claude-assisted dotfiles sync
type: workflow
status: done
---

# Claude-assisted dotfiles sync

## The core idea

Most dotfiles setups assume the user will manually keep the repo in sync
with their machine. Edit the source, run apply, commit, push. In
practice, nobody does this consistently. You `brew install` something in
the heat of debugging, tweak a config file directly, add an API key for
a new tool. The changes accumulate on your machine but never make it
back to the repo. After a few weeks, the repo is stale.

The idea here is different. Instead of expecting the user to maintain
the repo, **the LLM maintains it.** You operate your machine naturally.
Periodically (weekly, or whenever you think of it), you ask Claude to
catch up. Claude scans your machine, detects everything that drifted,
reports it in plain language, and waits for your decisions. Then Claude
syncs the changes back into the chezmoi source, commits, and pushes.

This is the same pattern as the LLM Wiki: the human curates and
decides, the LLM does the bookkeeping. The tedious part of dotfiles
management is not choosing your tools  - it's keeping the repo in sync
with your choices. Claude handles that.

## Architecture

Three layers, mirroring the LLM Wiki:

**Machine state** (the "raw sources")  - what's actually installed and
configured on your Mac right now. Brew packages, cask apps, config
files, secrets, shell functions. This is the source of truth. You
change it freely by installing tools, editing configs, whatever.

**The repo** (the "wiki")  - the chezmoi source at `~/dotfiles/home/`.
This is the persistent artifact that Claude maintains. It should reflect
your machine state, but it often lags behind. Claude's job is to close
the gap.

**The schema** (the "CLAUDE.md")  - instructions that tell Claude how to
scan, what to detect, how to report, and how to sync. Lives in
`.claude/commands/dotfiles-sync.md` as a slash command, plus detection
logic in the CLAUDE.md project instructions.

## Operations

### Scan (detect)

Claude runs detection across multiple dimensions:

| Dimension | Detection method | What it finds |
|-----------|-----------------|---------------|
| **Config drift** | `chezmoi status` | Managed files where deployed differs from source (Ghostty, Starship, tmux, Git, Zed, SSH, fish config, etc.) |
| **New brew packages** | `brew leaves` vs `dot_Brewfile.tmpl` | Packages you installed but didn't track |
| **Removed brew packages** | `dot_Brewfile.tmpl` vs `brew leaves` | Packages in Brewfile but no longer installed |
| **New casks** | `brew list --cask` vs `dot_Brewfile.tmpl` | GUI apps you installed but didn't track |
| **Removed casks** | `dot_Brewfile.tmpl` vs `brew list --cask` | Casks in Brewfile but no longer installed |
| **VS Code extensions** | `code --list-extensions` vs `extensions.txt` | New or removed extensions |
| **New fish functions** | `ls ~/.config/fish/functions/` vs `chezmoi managed` | Functions created outside chezmoi |
| **New SSH config** | `ls ~/.ssh/config.d/` vs `chezmoi managed` | SSH host configs added directly |
| **Secrets** | `secrets.toml` entries vs `op read` | Stale or broken secret refs |
| **Env vars** | Scan fish config for `set -gx` with hardcoded keys | API keys that should be in 1Password |

Note: `chezmoi status` covers most config drift (any file chezmoi
already manages). The "new files" checks cover the gap: files that
exist on the machine but chezmoi doesn't know about yet.

macOS defaults (`defaults write`) are not detectable  - those are
fire-and-forget commands with no clean diff mechanism.

Each scan produces a structured finding. Claude collects all findings
into a plain-language report.

### Report (review)

Claude presents findings grouped by category, not as raw diffs. Example:

```
Dotfiles sync report (2026-04-14)

Config drift (1 file):
  - Zed settings.json  - modified outside chezmoi
    (MCP server config changed, 2 new servers added)

New packages (25 brew, 10 casks):
  Brew: chezmoi, ollama, rclone, pandoc, opencode, ...
  Cask: claude, cursor, calibre, codexbar, ...

Stale entries (9 brew, 9 casks):
  Brew: age, btop, caddy, ... (in Brewfile but not installed)
  Cask: raycast, slack, meetingbar, ... (in Brewfile but not installed)

New VS Code extensions (3):
  github.copilot-chat, ms-python.debugpy, ...

No secret drift detected.

What would you like me to do?
```

The report is conversational. Claude may add context: "ollama was
probably installed for local LLM testing" or "raycast might have been
replaced by spotlight." The user decides what to sync.

### Sync (act)

Based on the user's decisions, Claude executes:

| Action | Method |
|--------|--------|
| Absorb config drift | `chezmoi re-add <paths>` |
| Add brew packages to Brewfile | Edit `dot_Brewfile.tmpl`, add `brew "pkg"` lines |
| Remove stale Brewfile entries | Edit `dot_Brewfile.tmpl`, delete lines |
| Add casks to Brewfile | Edit `dot_Brewfile.tmpl`, add `cask "app"` lines |
| Remove stale cask entries | Edit `dot_Brewfile.tmpl`, delete lines |
| Sync VS Code extensions | Update `extensions.txt` |
| Register new secrets | Append to `secrets.toml` |
| Track new fish functions | `chezmoi add <path>` |

Each action modifies the chezmoi source. Claude batches related changes
and commits with a descriptive message:

```
chore(sync): weekly dotfiles sync

Config:
  - re-add Zed settings (2 new MCP servers)

Brewfile:
  - add 25 packages: chezmoi, ollama, rclone, ...
  - add 10 casks: claude, cursor, calibre, ...
  - remove 9 stale packages: age, btop, ...
  - remove 9 stale casks: raycast, slack, ...

VS Code:
  - add 3 extensions
```

### Log (record)

After every sync, Claude appends an entry to `docs/sync-log.md`. This
is an append-only chronological record of what changed and when.

```markdown
## [2026-04-14] sync

Config:
  - re-add Zed settings (2 new MCP servers)

Brewfile:
  - add 25 packages: chezmoi, ollama, rclone, ...
  - remove 9 stale: raycast, slack, ...

Secrets:
  - no changes

---
```

The log serves two purposes:

**Context for future syncs.** Claude reads the log at the start of each
session. "Last sync was 2 weeks ago, you added ollama and cursor." This
helps Claude spot patterns ("you keep installing ML tools, want me to
add a comment group in the Brewfile?") and ask smarter questions.

**Audit trail.** "When did I add rclone?" Grep the log instead of
digging through git history. Each entry starts with a consistent
`## [date] sync` prefix so it's parseable with unix tools.

The log is committed alongside the sync changes. It's part of the repo,
not ephemeral.

### Publish (push)

Claude asks before pushing. The user can review the commit, amend, or
just say "push it."

## The sync session flow

A typical sync session looks like this:

```
User: /dotfiles-sync
Claude: [runs scan, produces report]
Claude: "Here's what I found. What should I do?"
User: "Add the new packages. Drop raycast and slack, I use Spotlight now.
       Keep btop in the Brewfile even though it's not installed, I want it
       on my next machine. Sync the Zed config."
Claude: [executes sync, commits]
Claude: "Done. 1 commit ready. Push?"
User: "Push."
Claude: [pushes]
```

The user speaks in plain language. Claude translates to chezmoi/git
operations. No commands to remember.

## What happens to existing commands

The manual commands (`dfe`, `dfs`, `add-secret`, etc.) stay in the repo
as **escape hatches** for when you're not in a Claude session:

| Scenario | Tool |
|----------|------|
| Weekly sync, batch changes | `/dotfiles-sync` (Claude) |
| Quick edit during a Claude session | Ask Claude directly |
| On a plane, no Claude | `dfe`, `dfs`, `dotfiles` CLI |
| SSH into a server | `dotfiles` CLI |
| CI/CD | `chezmoi apply` directly |

The guide and README reframe: Claude-assisted sync is the primary
workflow. Manual commands are the fallback for offline/headless use.

## What to build

### Phase 1: the slash command (MVP)

| Artifact | Purpose |
|----------|---------|
| `.claude/commands/dotfiles-sync.md` | Slash command prompt template. Tells Claude what to scan, how to report, how to sync. |
| `docs/sync-log.md` | Append-only sync history. Created on first sync. |

The slash command is the core artifact. It instructs Claude to:

1. Read `docs/sync-log.md` for context on last sync
2. Run detection commands (chezmoi status, brew leaves, code --list-extensions, ls key dirs, etc.)
3. Diff against the repo state
4. Format a plain-language report
5. Wait for user decisions
6. Execute sync actions
7. Append to `docs/sync-log.md`
8. Commit and optionally push

No shell scripts needed. Claude runs the detection commands directly
via Bash tool. The intelligence is in the prompt, not in code.

### Phase 2: scan helper (optional optimization)

If the scan step takes too long interactively, extract it into a fish
function that outputs structured JSON:

```fish
dotfiles scan    # outputs machine state as JSON
```

Claude reads the JSON instead of running 8 separate commands. This is
an optimization, not a requirement. Start without it.

### Phase 3: scheduled sync (optional)

Use Claude Code's cron/schedule feature to run the scan weekly and
notify the user if drift is detected. The user can then start a sync
session or ignore it.

## Design principles

**Claude does the bookkeeping, you make the decisions.** Claude never
auto-syncs without asking. It scans, reports, and waits. You decide
what to sync, what to drop, what to keep.

**Plain language over commands.** You say "drop raycast, I switched to
Spotlight." Claude figures out which line to delete from the Brewfile.

**One sync session covers everything.** Brew packages, casks, configs,
extensions, secrets  - all in one pass. No separate workflows for
different types of drift.

**The repo is the persistent artifact.** Like the LLM Wiki, the repo
compounds over time. Every sync session makes it more accurate. Claude
writes good commit messages so the history is readable.

**No daemon, no watcher, no automation.** You trigger the sync when you
want it. This is intentional: dotfiles sync should be a conscious
decision, not a background process that might commit garbage.

## Acceptance criteria

- [ ] `.claude/commands/dotfiles-sync.md` exists
- [ ] Running `/dotfiles-sync` produces a scan report
- [ ] Report covers: config drift, brew packages, casks, VS Code extensions, new fish functions, new SSH configs, secrets, env vars
- [ ] Claude reads `docs/sync-log.md` for context at start of scan
- [ ] Claude waits for user decisions before making changes
- [ ] Sync modifies the correct chezmoi source files
- [ ] Commit message summarizes all changes by category
- [ ] Claude appends entry to `docs/sync-log.md` after sync
- [ ] Claude asks before pushing
- [ ] Works as a normal conversation too ("catch up with my dotfiles")
- [ ] Guide updated to describe Claude-assisted sync as primary workflow

## Non-goals

- Automated/scheduled sync (Phase 3, not MVP)
- `dotfiles scan` fish helper (Phase 2, not MVP)
- Syncing across multiple machines (separate concern)
- Replacing `chezmoi apply` (that's deployment, not sync)
