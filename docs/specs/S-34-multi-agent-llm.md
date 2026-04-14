---
id: S-34
title: Multi-agent LLM support
type: docs + feature
status: planned
---

# Multi-agent LLM support

### Problem

The `/dotfiles-sync` workflow currently only works with Claude Code.
The sync prompt lives in `.claude/commands/dotfiles-sync.md`, which is
Claude Code-specific. Users of Codex, OpenCode, Cursor, or Cline
cannot use the LLM sync workflow without manually adapting.

### Goal

Make the LLM sync workflow work with multiple agents by:
1. Documenting how to set up the sync prompt for each agent
2. Adding an `llm_agent` config variable so the install flow deploys
   the right config for the user's chosen agent
3. Updating lifecycle (install, update, uninstall) for each agent

### Agent landscape

| Agent | Shell access | Schema location | Slash commands |
|-------|-------------|----------------|----------------|
| **Claude Code** | Bash tool | `.claude/commands/*.md` | Yes (`/command`) |
| **OpenAI Codex** | Sandbox | `AGENTS.md` in repo root | No (conversational) |
| **OpenCode** | Yes | `opencode.json` + system prompt | Custom commands |
| **Cursor** | Terminal | `.cursorrules` / `.cursor/rules/*.md` | No (conversational) |
| **Cline** | Yes | `.clinerules` | Custom commands |

All agents can run shell commands and edit files. The sync logic
(scan commands, report format, sync actions) is identical. Only the
schema location and invocation method differ.

### Design

#### Config variable

Add `llm_agent` to `.chezmoi.toml.tmpl`:

```
{{- $llm_agent := promptChoiceOnce . "llm_agent" "LLM agent for dotfiles sync" (list "claude-code" "codex" "opencode" "cursor" "none") -}}
```

#### Agent-specific file deployment

The sync prompt content is the same for all agents. Only the filename
and location change:

| Agent | Deployed to | Source in chezmoi |
|-------|------------|-------------------|
| Claude Code | `~/.claude/commands/dotfiles-sync.md` | `home/dot_claude/commands/dotfiles-sync.md` |
| Codex | `~/dotfiles/AGENTS.md` (append sync section) | Generated at apply time |
| OpenCode | `~/.config/opencode/commands/dotfiles-sync.md` | `home/dot_config/opencode/commands/dotfiles-sync.md` |
| Cursor | `~/dotfiles/.cursor/rules/dotfiles-sync.md` | `.cursor/rules/dotfiles-sync.md` |
| Cline | `~/dotfiles/.clinerules` (append sync section) | Generated at apply time |

For Claude Code and OpenCode, the file deploys via chezmoi as today.
For Codex, Cursor, and Cline, the file lives in the repo itself (not
deployed to $HOME).

#### `.chezmoiignore` changes

Skip agent-specific files based on the choice:

```
{{- if ne .llm_agent "claude-code" }}
.claude/
{{- end }}
{{- if ne .llm_agent "opencode" }}
.config/opencode/
{{- end }}
```

#### Brewfile changes

Install the chosen agent:

```
{{- if eq .llm_agent "claude-code" }}
cask "claude"
{{- else if eq .llm_agent "opencode" }}
cask "opencode-desktop"
{{- else if eq .llm_agent "cursor" }}
cask "cursor"
{{- end }}
```

Codex and Cline are typically installed via npm/pip, not Homebrew.
Add install notes to the post-apply summary.

#### Lifecycle

**Install:**
- Wizard prompts for LLM agent choice
- Brewfile installs the chosen agent
- chezmoi deploys the sync prompt to the right location
- Post-apply summary shows the correct invocation:
  - Claude Code: "use /dotfiles-sync"
  - Codex: "tell Codex to 'sync my dotfiles'"
  - Cursor: "tell Cursor to 'sync my dotfiles'"

**Update:**
- Changing agents: `chezmoi init` (re-pick agent), `chezmoi apply`
  deploys new config, old config is ignored via `.chezmoiignore`
- The sync prompt content updates on `chezmoi apply` if the template
  changes

**Uninstall:**
- Guide covers removing agent-specific config dirs
- Claude Code: `~/.claude/commands/`
- OpenCode: `~/.config/opencode/commands/`
- Cursor/Codex/Cline: files are in the repo, removed with the repo

### Files to modify

| File | Change |
|------|--------|
| `home/.chezmoi.toml.tmpl` | Add `llm_agent` prompt |
| `home/.chezmoiignore` | Conditional ignore based on agent choice |
| `home/dot_Brewfile.tmpl` | Conditional agent cask install |
| `home/.chezmoiscripts/run_after_zz-summary.sh` | Agent-specific post-install tip |
| `docs/llm-dotfiles.md` | "Agent-specific setup" section with table + examples |
| `docs/guide.md` | Update section 1 (LLM workflow) for multi-agent |
| `docs/guide.md` | Update section 9 (lifecycle) uninstall for each agent |
| `README.md` | Mention multi-agent support |

#### New files

| File | Purpose |
|------|---------|
| `.cursor/rules/dotfiles-sync.md` | Cursor-specific sync prompt (same content, different location) |
| `AGENTS.md` | Codex-specific sync instructions (same content, Codex format) |

### Acceptance criteria

- [ ] `chezmoi init` prompts for LLM agent (claude-code, codex, opencode, cursor, none)
- [ ] Choosing "claude-code" deploys to `~/.claude/commands/` (current behavior)
- [ ] Choosing "codex" creates `AGENTS.md` with sync instructions in repo root
- [ ] Choosing "cursor" creates `.cursor/rules/dotfiles-sync.md` in repo
- [ ] Choosing "none" skips all LLM config
- [ ] `.chezmoiignore` skips irrelevant agent configs
- [ ] Brewfile installs the chosen agent's app
- [ ] Post-apply summary shows agent-specific invocation tip
- [ ] `docs/llm-dotfiles.md` has "Agent-specific setup" section
- [ ] Guide lifecycle section covers uninstall for each agent
- [ ] Switching agents via `chezmoi init` + `chezmoi apply` works cleanly

### Test plan

```bash
# 1. Fresh init with Codex
chezmoi init --force  # choose "codex"
test -f ~/dotfiles/AGENTS.md && echo "PASS"
test ! -d ~/.claude/commands && echo "PASS (Claude config skipped)"

# 2. Fresh init with Claude Code
chezmoi init --force  # choose "claude-code"
test -f ~/.claude/commands/dotfiles-sync.md && echo "PASS"

# 3. Switch agents
chezmoi init  # change from claude-code to cursor
chezmoi apply
test -f ~/dotfiles/.cursor/rules/dotfiles-sync.md && echo "PASS"

# 4. Standard checks
chezmoi apply --dry-run
fish -n home/dot_config/fish/functions/dotfiles.fish
```

### Non-goals

- Agent-specific API integrations (MCP, tool use protocols)
- Running sync automatically via agent scheduling (each agent has
  different mechanisms; document but don't implement)
- Supporting agents without shell access (the sync workflow requires
  running commands on the machine)

### Phases

**Phase 1 (MVP):** Update `docs/llm-dotfiles.md` with agent-specific
setup table. No code changes. Users manually place the sync prompt
for their agent.

**Phase 2:** Add `llm_agent` config variable, conditional deployment,
conditional Brewfile. Full lifecycle integration.

Phase 1 can ship independently and quickly. Phase 2 requires the
config template changes and testing across agents.
