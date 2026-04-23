---
id: S-37
title: Surface claude-guardrails upstream releases in /dotfiles-sync
type: feature
status: done
date: 2026-04-17
depends_on: S-36
---

# S-37: Surface claude-guardrails upstream releases in /dotfiles-sync

## Problem

S-36 pins `claude-guardrails` at a git tag inside `run_onchange_after_claude-guardrails.sh.tmpl`. The pin is intentional for reproducibility, but it creates an information gap: when a new guardrails release ships on `dwarvesf/claude-guardrails`, nothing in this repo notifies the user. The `run_onchange_` hash only changes when we edit the script ourselves. So:

- Machines stay on an outdated pin until someone remembers to check.
- Security-relevant fixes (like the 0.3.7 BIP39 false-positive fix) sit unpicked.
- `/dotfiles-sync` reports drift on every other config surface but is silent on this one.

## Non-goals

- **Auto-bumping.** The pin remains deliberate. Security-tool upgrades warrant reading release notes before applying, so an automatic "rolling latest" would make this worse, not better.
- **Full release management.** This is a notification, not a dashboard. No changelog preview, no diff view, no transitive advisory check. Those belong in the upstream project's release notes.
- **Non-guardrails upstream checks.** This spec does not add "is there a newer version of brew/chezmoi/fish" detection. Scope is one tool, intentionally.

## Solution

Extend the `/dotfiles-sync` skill (both `.claude/commands/dotfiles-sync.md` and `home/dot_claude/commands/dotfiles-sync.md` mirror copies) with three small additions:

### A. Step 2 detection: one new subsection

Check the pinned ref in the onchange script against the latest GitHub release on `dwarvesf/claude-guardrails`. Skip silently if:

- The user set `.guardrails_variant = "none"` (they opted out; no upgrade relevant).
- `gh` CLI is not installed.
- Network is unavailable.

```bash
VARIANT=$(grep -oE 'guardrails_variant = "[^"]+"' ~/.config/chezmoi/chezmoi.toml 2>/dev/null | cut -d'"' -f2)
if [ "$VARIANT" != "none" ] && command -v gh >/dev/null 2>&1; then
  PINNED=$(grep -oE '^REF="v[0-9.]+"' home/.chezmoiscripts/run_onchange_after_claude-guardrails.sh.tmpl 2>/dev/null | cut -d'"' -f2)
  # Tags, not Releases: the upstream project tags every version but
  # does not always create a GitHub Release entry.
  LATEST=$(gh api repos/dwarvesf/claude-guardrails/tags --jq '.[0].name' 2>/dev/null)
  if [ -n "$PINNED" ] && [ -n "$LATEST" ] && [ "$PINNED" != "$LATEST" ]; then
    echo "guardrails: pinned=$PINNED, latest=$LATEST"
  fi
fi
```

### B. Step 3 report: optional "Guardrails upgrade available" section

Only appears when the detection emits something. Format:

```
Guardrails upgrade available (optional):
  Pinned: v0.3.7    Latest: v0.3.8
  Release notes: https://github.com/dwarvesf/claude-guardrails/releases/tag/v0.3.8
  (Notification only; the pin is not auto-updated.)
```

Placement: between the "Already local" section and "Stale entries" so it reads as informational rather than actionable drift.

### C. Step 5 execute: one new action row

```
| Bump guardrails pin | Replace the two v{OLD} occurrences in home/.chezmoiscripts/run_onchange_after_claude-guardrails.sh.tmpl with v{NEW} (the REF="v..." line and the ref=v... hash comment) |
```

If the user says "bump guardrails to v0.3.8" or similar, the skill edits the file. If they say nothing or "not now", the pin stays.

## Test

1. On a machine with a current pin equal to latest: detection emits nothing, report omits the section, no change.
2. With a stale pin (`REF="v0.3.0"`, latest is v0.3.7): detection emits one line, report includes the "Guardrails upgrade available" section with correct URL.
3. With `.guardrails_variant = "none"`: detection is silent even when stale. User opted out.
4. Without `gh` installed or with network off: detection silent. Sync report has no guardrails section but otherwise completes normally.
5. After user approves "bump guardrails to v0.3.8": `grep -c 'v0.3.8' home/.chezmoiscripts/run_onchange_after_claude-guardrails.sh.tmpl` returns 2 (hash comment + REF=). Next `chezmoi apply` re-fires the onchange script.

## Out of this spec

- Notifying on non-guardrails upstream drift (brew, chezmoi, fish plugins). Separate, bigger scope.
- A `dotfiles guardrails upgrade` standalone fish subcommand. Could be a thin wrapper around the same edit logic but unnecessary if `/dotfiles-sync` already covers the workflow.
- CI-driven PR bots that watch upstream releases. Possible future enhancement; out of scope because the LLM-assisted sync already handles the human-in-the-loop step.
