You are maintaining a chezmoi-managed dotfiles repo. The user operates their Mac freely (installs packages, edits configs, adds API keys). Your job is to detect what changed on the machine, report it clearly, and sync approved changes back into the repo.

Packages are classified as **core** (shared across all machines, committed to repo) or **local** (this machine only, stored in `~/.Brewfile.local`). The sync workflow must ask the user to classify new packages.

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
# Installed but not in Brewfile or Brewfile.local
comm -23 <(brew leaves | sort) \
  <(cat <(grep '^brew "' ~/.Brewfile 2>/dev/null) \
        <(grep '^brew "' ~/.Brewfile.local 2>/dev/null) \
  | sed 's/brew "//;s/".*//' | sort -u)

# In Brewfile but not installed
comm -13 <(brew leaves | sort) <(grep '^brew "' ~/.Brewfile 2>/dev/null | sed 's/brew "//;s/".*//' | sort)
```

### Cask apps
```bash
# Installed but not in Brewfile or Brewfile.local
comm -23 <(brew list --cask 2>/dev/null | sort) \
  <(cat <(grep '^cask "' ~/.Brewfile 2>/dev/null) \
        <(grep '^cask "' ~/.Brewfile.local 2>/dev/null) \
  | sed 's/cask "//;s/".*//' | sort -u)

# In Brewfile but not installed
comm -13 <(brew list --cask 2>/dev/null | sort) <(grep '^cask "' ~/.Brewfile 2>/dev/null | sed 's/cask "//;s/".*//' | sort)
```

### VS Code extensions
```bash
# Installed but not tracked (core or local)
comm -23 <(code --list-extensions 2>/dev/null | sort) \
  <(cat ~/.config/code/extensions.txt ~/.config/code/extensions.local.txt 2>/dev/null | sort -u)

# Tracked (core) but not installed
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

### Already-local packages
```bash
# Show what's in .local files for context
echo "--- Brewfile.local ---"
grep -E '^(brew|cask) "' ~/.Brewfile.local 2>/dev/null | sed 's/".*/"/' || echo "(none)"
echo "--- extensions.local.txt ---"
cat ~/.config/code/extensions.local.txt 2>/dev/null || echo "(none)"
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

Already local (tracked in ~/.Brewfile.local):
  Brew: localpkg1, ...
  Cask: localapp1, ...

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

**For new packages/extensions, ask the user to classify:**

```
For new packages, classify as:
  [Core]  - shared across all machines (committed to repo)
  [Local] - this machine only (~/.Brewfile.local)
  [Skip]  - don't track

You can say: "all core", "all local", or classify individually
  e.g. "chrysalis and lunar are local, rest is core"
```

If the user says "do it all" without classifying, ask once: "Should new packages go to core (repo) or local (this machine)?" Default to local if the user doesn't specify.

## Step 5: Execute

Based on the user's decisions:

| Action | Method |
|--------|--------|
| Absorb config drift | `chezmoi re-add <paths>` |
| Add brew to core | Edit `home/dot_Brewfile.tmpl`, add `brew "pkg"` in correct section |
| Add brew to local | Append `brew "pkg"` to `~/.Brewfile.local` (create if needed) |
| Remove stale brew | Edit `home/dot_Brewfile.tmpl`, delete lines |
| Add cask to core | Edit `home/dot_Brewfile.tmpl`, add `cask "app"` in correct section |
| Add cask to local | Append `cask "app"` to `~/.Brewfile.local` (create if needed) |
| Remove stale casks | Edit `home/dot_Brewfile.tmpl`, delete lines |
| Add VS Code ext to core | Update `home/dot_config/code/extensions.txt` |
| Add VS Code ext to local | Append to `~/.config/code/extensions.local.txt` (create if needed) |
| Track fish functions | `chezmoi add ~/.config/fish/functions/NAME.fish` |
| Track SSH configs | `chezmoi add ~/.ssh/config.d/NAME` |
| Register secrets | Append to `home/.chezmoidata/secrets.toml` |

When editing the Brewfile, preserve the existing section structure (base/dev/apps). Place new entries in the appropriate section.

When creating `~/.Brewfile.local` for the first time, add this header:
```ruby
# ~/.Brewfile.local - machine-specific packages (not committed to dotfiles repo)
# Sourced automatically by ~/.Brewfile via eval()
# Managed by /dotfiles-sync - classify packages as "local" during sync
```

## Step 6: Log

Append an entry to `docs/sync-log.md`, distinguishing core vs local:

```markdown
## [YYYY-MM-DD] sync

Brewfile (core):
  - added brew: pkg1, pkg2
  - added cask: app1

Brewfile (local - ~/.Brewfile.local):
  - added cask: localapp1, localapp2

[Other categories]:
  - [what changed]

---
```

## Step 7: Commit

Stage all repo changes and commit with a descriptive message. Local file changes (`~/.Brewfile.local`, `extensions.local.txt`) are NOT committed since they live outside the repo.

```
chore(sync): dotfiles sync YYYY-MM-DD

[Summary of core changes by category]
Local: N packages added to ~/.Brewfile.local (not committed)
```

Then ask: "Push to remote?" Only push if the user confirms.
