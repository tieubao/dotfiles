---
id: S-39
title: Fix dotfiles backup and consolidate 1P vault resolution
type: bugfix
status: done
date: 2026-04-23
depends_on: S-38
---

# S-39: Fix `dotfiles backup` and consolidate 1P vault resolution

## Problem

Two bugs surfaced during S-38 that live in pre-existing code. Both prevent existing commands from working correctly and would have caused confusing failures for any user on a fresh setup.

### Bug 1: `chezmoi config-path` is not a real subcommand

`home/dot_config/fish/functions/dotfiles.fish:729` calls:

```fish
set -l config_path (chezmoi config-path 2>/dev/null)
```

`chezmoi config-path` does not exist in chezmoi 2.x (the valid subcommands are `cat-config`, `dump-config`, `edit-config`, `edit-config-template`, plus the `--config` flag). The substitution silently returns empty, the next guard `test -z "$config_path"` trips, and `dotfiles backup` aborts with `[!!] chezmoi config not found` even when the config exists at the canonical path.

Live repro: running `dotfiles backup` on a fully configured machine exits 1 with that error.

### Bug 2: `op_vault` parsing returns duplicated values

Five sites in `dotfiles.fish` use:

```fish
set -l vault (chezmoi data 2>/dev/null | grep op_vault | awk '{print $NF}' | tr -d '"')
```

`chezmoi data` emits `op_vault` twice (once per scope in the template-data tree), so `grep` matches both lines. `awk '{print $NF}'` extracts `Private,` from each (with trailing comma). The resulting variable becomes the two-element list `(Private, Private,)`. Downstream callers either concatenate it into a malformed CLI arg (`--vault="Private, Private,"`) or display it ugly in output (e.g. `(vault: Private, Private,)` as I saw during S-38's first smoke test).

Three of the five sites (the ones I added in S-38) already have a partial fix: `| head -1` and `tr -d '",'`. Two pre-existing sites (lines 671 and 731) still have the bug. Fixing them individually is fine for now but invites future drift; a shared helper is the clean move.

Site inventory:

| Line | Context | Status before S-39 |
|---|---|---|
| 671 | `case encrypt-setup` | ⚠ broken (pre-existing) |
| 731 | `case backup` | ⚠ broken (pre-existing) |
| 783 | `case ssh` → `audit` | ✓ partial fix (S-38) |
| 951 | `case ssh` → `adopt` | ✓ partial fix (S-38) |
| 1117 | `case ssh` → `backup` | ✓ partial fix (S-38) |

The fallback to `Private` is also inconsistent. Broken sites use `; or set vault Private` which never fires because `tr` returns 0 on empty input. Correct behavior requires an explicit `test -z "$vault"; and set vault Private` after the substitution.

## Non-goals

- Reworking `dotfiles backup`'s output format or restructure. Keep the existing UX; only fix what's broken.
- Migrating off `chezmoi data` to a different data-retrieval mechanism. The data command is canonical; the parsing is what's wrong.
- Fixing any other latent bugs in the file. Scope is these two, full stop.
- Adding tests for shell functions. The repo's verification model is `fish -n`, `shellcheck`, `chezmoi apply --dry-run`, and `verify-dotfiles` subagent; S-39 uses the same.

## Solution

### A. Replace `chezmoi config-path` with direct canonical-path lookup

chezmoi stores its config at `$XDG_CONFIG_HOME/chezmoi/chezmoi.{toml,yaml,json,jsonnet}` (from chezmoi docs). On macOS with unset `XDG_CONFIG_HOME`, that resolves to `$HOME/.config/chezmoi/chezmoi.{ext}`. Check each supported format:

```fish
set -l config_path
for ext in toml yaml json jsonnet
    if test -f "$HOME/.config/chezmoi/chezmoi.$ext"
        set config_path "$HOME/.config/chezmoi/chezmoi.$ext"
        break
    end
end
```

This handles the 99% case (users have one of the four formats). If the user has set `$XDG_CONFIG_HOME` to a non-default path, the lookup misses, `config_path` stays empty, and the existing `test -z "$config_path"` guard fires cleanly. That failure mode is acceptable (and rare); adding XDG resolution would be premature.

### B. Extract `__dotfiles_op_vault` helper

New file: `home/dot_config/fish/functions/__dotfiles_op_vault.fish`

```fish
function __dotfiles_op_vault --description "Resolve the 1Password vault name from chezmoi data, defaulting to Private."
    # chezmoi data emits op_vault twice (once per scope), so `head -1` is required.
    # tr strips both the JSON quoting and any trailing comma.
    set -l v (chezmoi data 2>/dev/null | grep op_vault | head -1 | awk '{print $NF}' | tr -d '",')
    test -z "$v"; and set v Private
    echo $v
end
```

The `__dotfiles_` prefix signals "private implementation detail" per fish convention. Autoloaded on first reference.

### C. Replace all 5 sites in `dotfiles.fish`

Every site becomes:

```fish
set -l vault (__dotfiles_op_vault)
```

Removes 5 lines of shell pipelines, their inconsistent fallback logic, and the maintenance burden of keeping five copies in sync.

## Rules

- **Helper goes in its own file.** Fish function autoloading expects one function per file for clean lazy loading. Keeping `__dotfiles_op_vault` inside `dotfiles.fish` would work but would bundle it into every `dotfiles` invocation.
- **Private prefix.** `__dotfiles_` marks the helper as not-for-direct-use. Don't document it in the main help output.
- **No behavior change at the user layer.** `dotfiles backup`, `dotfiles encrypt-setup`, and `dotfiles ssh {audit,adopt,backup}` all continue to work the same way from the user's perspective; the only difference is that `dotfiles backup` starts succeeding instead of aborting.
- **No new Brewfile entries.** All tools used (`awk`, `grep`, `head`, `tr`, `test`) are base macOS.

## Files to create or modify

| File | Change |
|---|---|
| `docs/specs/S-39-dotfiles-backup-fixes.md` | This spec (new) |
| `home/dot_config/fish/functions/__dotfiles_op_vault.fish` | New helper function |
| `home/dot_config/fish/functions/dotfiles.fish` | Replace 5 op_vault parsing sites with `(__dotfiles_op_vault)`; replace `chezmoi config-path` at line 729 with the canonical-path lookup |

## Test

1. **Helper, defaulted.** With `chezmoi data` returning nothing (unset / uninitialised machine), `__dotfiles_op_vault` returns `Private`. Verify via: `chezmoi data 2>/dev/null | grep -v op_vault > /tmp/stub; and PATH=/tmp:$PATH __dotfiles_op_vault` (or equivalent isolation). Acceptance: function prints `Private` on its own line, exit 0.
2. **Helper, real vault.** On this machine (`op_vault = "Private"` set twice in chezmoi data): `__dotfiles_op_vault` prints exactly `Private` (no doubling, no commas), exit 0.
3. **`dotfiles backup` happy path.** Run on this machine. Expected: prints three stages, uploads `chezmoi.toml` and `key.txt` to 1P as Documents, copies both to `~/dotfiles-backup/`, exits 0. No `[!!] chezmoi config not found`.
4. **`dotfiles backup` no-op-CLI path.** Temporarily unset path to `op` (or mock). Prints `[--] 1Password CLI not found, skipping` for the two upload steps but still does the local fallback copy, exits 0.
5. **`dotfiles backup` missing chezmoi config.** Move `~/.config/chezmoi/chezmoi.toml` aside temporarily. Expected: `[!!] chezmoi config not found`, exit 1. Restore.
6. **Five-site consolidation.** `grep -c '__dotfiles_op_vault' home/dot_config/fish/functions/dotfiles.fish` returns 5. `grep -c 'chezmoi data 2>/dev/null | grep op_vault' home/dot_config/fish/functions/dotfiles.fish` returns 0 (no stragglers).
7. **Verification commands pass.** `fish -n` on both fish files, `chezmoi apply --dry-run` shows only the pre-existing two warnings, `verify-dotfiles` subagent returns green.

## Out of this spec

- A helper for chezmoi config path resolution. Only one call site currently; extracting is premature.
- Supporting `$XDG_CONFIG_HOME` overrides. The direct path check covers the canonical macOS default; alternate paths are a rare edge case and failures are loud.
- Refactoring `dotfiles backup` to match `dotfiles ssh backup`'s separation (encrypted bundle vs. plaintext upload). Separate design conversation if needed.
- Adding a fish completions entry for `__dotfiles_op_vault`. It's private; no completion needed.
