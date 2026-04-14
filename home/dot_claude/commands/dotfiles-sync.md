You are maintaining a chezmoi-managed dotfiles repo. The user operates their Mac freely (installs packages, edits configs, adds API keys). Your job is to detect what changed on the machine, report it clearly, and sync approved changes back into the repo.

## Step 1: Read context

Read `docs/sync-log.md` to understand when the last sync happened and what changed. If the file doesn't exist, this is the first sync.

## Step 2: Scan for drift

Run these detection commands in parallel where possible:

### Config drift
```bash
chezmoi status 2>/dev/null
```
Look for lines starting with ` M` (modified) or `MM` (modified both sides).

### Brew packages
```bash
# Installed but not in Brewfile
comm -23 <(brew leaves | sort) <(grep '^brew "' ~/.Brewfile 2>/dev/null | sed 's/brew "//;s/".*//' | sort)

# In Brewfile but not installed
comm -13 <(brew leaves | sort) <(grep '^brew "' ~/.Brewfile 2>/dev/null | sed 's/brew "//;s/".*//' | sort)
```

### Cask apps
```bash
# Installed but not in Brewfile
comm -23 <(brew list --cask 2>/dev/null | sort) <(grep '^cask "' ~/.Brewfile 2>/dev/null | sed 's/cask "//;s/".*//' | sort)

# In Brewfile but not installed
comm -13 <(brew list --cask 2>/dev/null | sort) <(grep '^cask "' ~/.Brewfile 2>/dev/null | sed 's/cask "//;s/".*//' | sort)
```

### VS Code extensions
```bash
# Installed but not tracked
comm -23 <(code --list-extensions 2>/dev/null | sort) <(sort ~/.config/code/extensions.txt 2>/dev/null)

# Tracked but not installed
comm -13 <(code --list-extensions 2>/dev/null | sort) <(sort ~/.config/code/extensions.txt 2>/dev/null)
```

### New fish functions (not managed by chezmoi)
```bash
# Functions on disk but not in source
comm -23 <(ls ~/.config/fish/functions/ 2>/dev/null | sort) <(chezmoi managed | grep 'fish/functions/' | xargs -I{} basename {} | sort)
```

### New SSH config fragments
```bash
# SSH config.d files not managed
comm -23 <(ls ~/.ssh/config.d/ 2>/dev/null | sort) <(chezmoi managed | grep 'ssh/config.d/' | xargs -I{} basename {} | sort)
```

### Hardcoded secrets in fish config
```bash
# Look for set -gx with what looks like API keys (long alphanumeric strings)
grep -n 'set -gx.*[A-Za-z0-9_]\{20,\}' ~/.config/fish/config.fish ~/.config/fish/conf.d/*.fish 2>/dev/null | grep -v 'onepasswordRead\|op://' || true
```

## Step 3: Report

Present findings in plain language, grouped by category. For each category, show:
- What changed (specific names, not counts)
- Brief context if you can infer it ("ollama is probably for local LLM testing")

Use this format:

```
Dotfiles sync report (YYYY-MM-DD)

Config drift (N files):
  - path  - what changed (brief description of the diff)

New packages (N brew, N casks):
  Brew: pkg1, pkg2, ...
  Cask: app1, app2, ...

Stale entries (N brew, N casks):
  Brew: pkg1, pkg2, ... (in Brewfile but not installed)
  Cask: app1, app2, ... (in Brewfile but not installed)

VS Code extensions:
  New: ext1, ext2, ...
  Removed: ext1, ...

New fish functions (N):
  func1, func2, ...

New SSH configs (N):
  host1, host2, ...

Secrets:
  [any findings or "no issues"]

What would you like me to do?
```

If a category has no findings, omit it from the report.

## Step 4: Wait for decisions

Do NOT make any changes yet. Ask the user what to do. They'll respond in plain language:
- "Add the new packages"
- "Drop raycast and slack"
- "Keep btop in Brewfile even though not installed"
- "Sync the Zed config"
- "Do it all"

## Step 5: Execute

Based on the user's decisions:

| Action | Method |
|--------|--------|
| Absorb config drift | `chezmoi re-add <paths>` |
| Add brew packages | Edit `home/dot_Brewfile.tmpl`, add `brew "pkg"` in correct section |
| Remove stale brew | Edit `home/dot_Brewfile.tmpl`, delete lines |
| Add casks | Edit `home/dot_Brewfile.tmpl`, add `cask "app"` in correct section |
| Remove stale casks | Edit `home/dot_Brewfile.tmpl`, delete lines |
| Sync VS Code extensions | Update `home/dot_config/code/extensions.txt` |
| Track fish functions | `chezmoi add ~/.config/fish/functions/NAME.fish` |
| Track SSH configs | `chezmoi add ~/.ssh/config.d/NAME` |
| Register secrets | Append to `home/.chezmoidata/secrets.toml` |

When editing the Brewfile, preserve the existing section structure (base/dev/apps). Place new entries in the appropriate section.

## Step 6: Log

Append an entry to `docs/sync-log.md`:

```markdown
## [YYYY-MM-DD] sync

[Category]:
  - [what changed]

---
```

## Step 7: Commit

Stage all changes and commit with a descriptive message:

```
chore(sync): dotfiles sync YYYY-MM-DD

[Summary of changes by category]
```

Then ask: "Push to remote?" Only push if the user confirms.
