---
id: S-50
title: `/dotfiles-sync` detects user-authored Claude skill drift
type: feature
status: done
date: 2026-05-03
---

# S-50: `/dotfiles-sync` detects user-authored Claude skill drift

## Problem

Commit `0ce60e8` (#63, 2026-04-30) wired `~/.claude/skills/` into the
chezmoi-managed surface so user-authored Claude skills become versioned and
portable across machines. But adoption is opt-in per skill: each new skill
needs an explicit `chezmoi add` to enter the source tree. There is no
detection on the daily sync path.

Snapshot today (Hans Air M4): 9 user-authored skills exist under
`~/.claude/skills/`, only 1 (`doc-compaction`) is tracked under
`home/dot_claude/skills/`. The other 8 are unversioned and would not survive
a fresh-machine bootstrap:

- `browser-tool-selection`
- `cashflow-close`
- `cloudflare-tool-selection`
- `extract-workflow`
- `incident-workflow`
- `ingest-to-wiki`
- `playwright-record`
- `reconcile-properties`

The pattern matches every other "managed surface" in this repo (Brewfile,
fish functions, SSH config fragments, VS Code extensions): `/dotfiles-sync`
detects new items, prompts core/local/skip, and the user decides. Skills are
the one surface that escaped that net.

## Solution

Two changes in this spec, sized to land in one PR:

### 1. One-shot absorption

Promote the 8 unversioned skills into chezmoi (all as **core**: every skill
is a generic personal workflow with no machine-specific paths or identifiers
- verified by `grep -lE '/Users/tieubao|nntruonghan|Han-'` returning only a
documentation example in `incident-workflow/references/privacy-gate.md`).

```fish
chezmoi add ~/.claude/skills/{browser-tool-selection,cashflow-close,cloudflare-tool-selection,extract-workflow,incident-workflow,ingest-to-wiki,playwright-record,reconcile-properties}
```

### 2. Ongoing detection in `/dotfiles-sync`

Extend `home/dot_claude/commands/dotfiles-sync.md` (and mirror the byte-identical
`.claude/commands/dotfiles-sync.md` project copy) to add a "New Claude skills"
section in Step 2's drift scan, a re-verify row in Step 2.5, a report-template
slot in Step 3, a classification line in Step 4, and an Execute table row in
Step 5.

**Detection command** (added to Step 2):

```bash
# Skills authored by the user, present on disk but not in chezmoi nor explicitly
# marked local. Plugin-installed skills live under ~/.claude/plugins/, NOT
# ~/.claude/skills/, so this scan is naturally filtered to user-authored ones.
comm -23 <(ls ~/.claude/skills/ 2>/dev/null | sort) \
        <(cat <(chezmoi managed 2>/dev/null \
                  | grep '^\.claude/skills/' \
                  | awk -F/ '{print $3}' | sort -u) \
              <(cat ~/.config/dotfiles/skills.local 2>/dev/null | sort) \
              | sort -u)
```

**Three-way classification** (Step 4):

| Choice | Action |
|---|---|
| **core** | `chezmoi add ~/.claude/skills/<name>` -- the whole directory tree, committed |
| **local** | append `<name>` (one per line) to `~/.config/dotfiles/skills.local`. The file is consulted by the next sync's detection command. Never committed. |
| **skip** | no-op for this run; same skill will resurface in the next sync |

`~/.config/dotfiles/skills.local` is a plain newline-delimited list of skill
directory names, mirroring the `.Brewfile.local` / `extensions.local.txt`
pattern. It does not need to exist; absence means "no local-marked skills."

## Test

1. **Absorption sanity:** `chezmoi managed | grep '^\.claude/skills/' | awk -F/ '{print $3}' | sort -u` returns 9 entries (8 newly absorbed + `doc-compaction`). Note: `chezmoi managed` reports *target* paths (relative to `$HOME`), not source paths under `home/`.
2. **Idempotence:** `chezmoi apply --dry-run` after absorption shows no changes for the skill directories (already in sync).
3. **Detection clean state:** Running the new Step 2 command after absorption returns empty.
4. **Detection positive case:** `mkdir -p ~/.claude/skills/test-skill && touch ~/.claude/skills/test-skill/SKILL.md`, then re-run the Step 2 command -- `test-skill` appears.
5. **Local-mark suppression:** `mkdir -p ~/.config/dotfiles && echo test-skill > ~/.config/dotfiles/skills.local`, re-run the detection -- `test-skill` no longer appears.
6. **Cleanup:** `rm -rf ~/.claude/skills/test-skill` and `rm ~/.config/dotfiles/skills.local`.
7. **Plugin filter:** Plugin skills (`ouroboros:*`, `superpowers:*`, etc., installed under `~/.claude/plugins/`) MUST NOT appear in the drift list. Verified by inspection: the scan globs `~/.claude/skills/`, plugins live under `~/.claude/plugins/`.
8. **Project / user copy parity:** `diff .claude/commands/dotfiles-sync.md home/dot_claude/commands/dotfiles-sync.md` returns exit 0.

## Out of scope

- **Per-skill update detection.** v1 only catches new skills. Modifying an
  already-tracked skill goes through the existing `chezmoi status` config-drift
  flow.
- **Auto-promote.** Per design philosophy item 1 ("LLM does bookkeeping, user
  makes decisions"), the sync skill never absorbs without prompting.
- **Plugin update notifications.** Plugins have their own update path via the
  marketplace; surfacing those is a separate spec.

## Definition of done (per S-44)

- [x] Spec frontmatter `status: done`
- [x] Tick in `docs/tasks.md`
- [x] Hostname-tagged entry in `docs/sync-log.md`
