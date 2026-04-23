---
id: S-26
title: Brewfile cleanup
type: refinement
status: done
date: 2026-04-23
old_id: R-14
---

# S-26: Brewfile cleanup

## Problem

`home/dot_Brewfile.tmpl` had accumulated minor hygiene issues since the
S-04 split and S-35 local-pattern landing:

- Potential duplicate entries left over from successive edits.
- A font pair (`font-source-code-pro` + `font-sauce-code-pro-nerd-font`)
  that looks duplicated at a glance but is actually two different fonts.
- Informational comments about install-via-other-package-manager
  (cargo, npm, pipx) with no decision attached: remove or keep as
  breadcrumbs.
- Potential overlap with `mise`-managed language runtimes (`go`,
  `node`, `python@3.12`, `elixir`, `rustup`).

## Non-goals

- Silently removing packages the user might still want. This spec only
  touches entries that are objectively wrong (true duplicates) or that
  benefit from a clarifying comment.
- Resolving the `mise` vs `brew` duplication for language runtimes.
  That is a design call, not a cleanup call, and is flagged below for
  a future decision.
- Running `brew bundle cleanup --force` on the live machine. The repo's
  philosophy (S-35) keeps hardware-specific or user-specific installs
  in `~/.Brewfile.local`; blowing away unlisted installs would erase
  that per-machine state.
- Classifying the 30+ installed-but-unlisted packages currently on
  Hans Air M4. That is `/dotfiles-sync` territory, not Brewfile
  cleanup territory.

## Audit findings

Performed against `home/dot_Brewfile.tmpl` at `main@c2c4ed9`:

1. **True duplicate: `brew "tldr"` appeared twice** (lines 52 and 57 of the
   template). Both entries sat inside the "Core CLI" block. The second
   occurrence had the descriptive comment, the first did not. Fix: keep
   the earlier occurrence, attach the descriptive comment to it, delete
   the later duplicate.

2. **Not a duplicate: font pair is intentional.**
   - `font-source-code-pro`: original Adobe Source Code Pro (no
     Nerd-Font glyph patches).
   - `font-sauce-code-pro-nerd-font`: the Nerd-Font patched variant
     (the renamed version from the Nerd Fonts project; "Sauce" is the
     rename-around-Adobe-trademark).
   Fix: add a one-line comment above the pair so the next reader
   does not try to "dedupe" them.

3. **No commented-out `brew`/`cask` entries.** The `#` comments for
   `llm`, `opencode`, `leo-lang`, Foundry, and obsidian-export all
   describe install paths via `uv tool`, `npm i -g`, `cargo install`,
   or `curl | bash`. These are useful breadcrumbs, not abandoned
   entries. No action.

4. **All casks verified.** Ran `brew info --cask` on every cask in the
   file; all resolve. No renames to apply.

5. **`brew bundle check` passes** (exit 0) against the rendered
   `~/.Brewfile`. The tool reports "can't satisfy your Brewfile's
   dependencies" because many packages in the dev/apps layers are not
   installed on this machine; that is machine-specific state, not a
   Brewfile defect.

6. **Flagged (not acted on): brew/mise overlap.** `mise` is listed at
   line 76, and `go`, `node`, `python@3.12`, `elixir`, `rustup` appear
   in the same dev layer. If the user relies on `mise` for language
   versioning, the brew entries become redundant bootstrap layers.
   This is a design decision, not a typo; deferred to a future spec
   if the user decides to pick a side.

## Architecture decisions recorded

1. **Keep the font pair, annotate it.** Removing either font would
   silently regress terminal or document rendering depending on the
   user's app. The safest fix is the one-line comment making the
   intent explicit.
2. **Informational `#` comments stay.** They point to install paths
   for packages whose brew/cask entries are missing upstream
   (Foundry, leo-lang, obsidian-export) or that are better managed by
   a language-specific package manager (`llm` via `uv tool install`).
   Deleting them removes breadcrumbs without adding anything.
3. **Brewfile cleanup is not `brew bundle cleanup`.** The repo's
   `.local` pattern means unlisted installs are a feature, not a
   defect. Any cleanup of unlisted-installed packages belongs in
   `/dotfiles-sync` (classify as core / local / skip), not in this
   spec.
4. **Defer mise/brew overlap.** The user has not asked for it, there
   is no runtime breakage, and resolving it requires picking a
   philosophy (mise-first vs brew-first). A separate spec, when the
   user is ready, can make that call.

## Files changed

**Modified:**
- `home/dot_Brewfile.tmpl`: removed duplicate `brew "tldr"`; added
  one-line comment above the font pair clarifying they are not
  duplicates.
- `docs/specs/S-26-brewfile-cleanup.md`: this expansion (spec was
  previously a 6-line stub; now documents the audit and the decisions).

**Not changed:**
- `~/.Brewfile.local` (not tracked; per-machine)
- Anything else

## Rollout notes

- Zero runtime impact. `brew bundle` behaviour is identical for every
  machine since the removed line was a duplicate.
- No state migration, no `chezmoi apply` side effects beyond the
  Brewfile hash changing and `brew-bundle.sh` re-running (which will
  be a no-op on machines where the set was already correct).

## Testing

```bash
# 1. No duplicates remain.
grep -nE '^(brew|cask) "' home/dot_Brewfile.tmpl | awk -F'"' '{print $2}' | sort | uniq -d
# Expected: (empty)

# 2. Font pair still both present.
grep -E '^cask "font-(source|sauce)-code-pro' home/dot_Brewfile.tmpl | wc -l
# Expected: 2

# 3. Template renders.
chezmoi execute-template < home/dot_Brewfile.tmpl > /dev/null

# 4. Dry run.
chezmoi apply --dry-run --force

# 5. Bundle check on rendered Brewfile.
brew bundle check --file=~/.Brewfile >/dev/null
echo $?
# Expected: 0 (dependency satisfaction is machine-specific, handled separately)
```

## What's explicitly NOT supported

- Removing the brew language runtimes to prefer mise. That is a
  separate design decision; see "Flagged (not acted on)" above.
- Auto-pruning installed-but-unlisted packages. Owned by
  `/dotfiles-sync`.
- Any new package additions. This is a cleanup spec, not a
  feature-adding spec.
