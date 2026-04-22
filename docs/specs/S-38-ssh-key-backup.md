---
id: S-38
title: SSH key inventory, adoption, and offline backup
type: feature
status: proposed
date: 2026-04-22
depends_on: S-08
---

# S-38: SSH key inventory, adoption, and offline backup

## Problem

SSH key coverage in this repo stops at the `~/.ssh/config` file (S-08). The key material itself is not managed:

1. **No inventory tool.** The user cannot see at a glance which keys exist on disk, which are in the 1Password SSH agent, and which are plaintext without a passphrase.
2. **No primary backup.** Filesystem private keys (today: `id_ed25519_trading_vps` and a 2015-era `id_rsa`, both plaintext on disk) exist only on one machine. A lost Mac loses the key.
3. **No offline escape hatch.** 1Password is the primary secret store for this setup. If the 1P account is locked out or lost, every agent-only key goes with it.

The user's stated concern is specifically backup. An inventory and adoption path are prerequisites: you cannot back up what you cannot see, and you should not back up a plaintext disk key as another plaintext copy without first putting it into the right store.

## Non-goals

- **Auto-deletion of disk keys.** The user explicitly noted uncertainty about what `id_rsa` is used for. Adoption does not remove the disk copy. Retirement is a later, manual step the user performs after observation.
- **Automatic rotation or re-issuance.** This spec does not generate new keys or push public keys to remote hosts. It handles backup, not lifecycle.
- **Runtime usage tracking.** No ssh-wrapping, no log tailing. The walkthrough in `docs/guide.md` gives a human checklist for investigating what a key is used for; automating it is out of scope.
- **`known_hosts` sync.** Per-machine artifact, stays per-machine.
- **GitHub/GitLab public-key audit.** Would require `gh` with elevated scopes and per-provider plumbing. Not in scope.
- **Encrypted offsite sync services.** No iCloud, no Dropbox, no S3. The escape hatch is a single `.age` file the user places on a USB drive themselves.

## Solution

Add an `ssh` subcommand to the existing `dotfiles` fish function dispatcher (sibling to `edit`, `drift`, `secret`, `local`, `backup`, etc.). Three actions:

| Action | Purpose | Side effect |
|---|---|---|
| `dotfiles ssh audit` | Print the inventory table | Read-only |
| `dotfiles ssh adopt <key-path>` | Import a disk private key into 1Password as an SSH Key item | Writes to 1Password; disk copy untouched |
| `dotfiles ssh backup --destination <path>` | Write an age-encrypted bundle of all 1P SSH keys to `<path>` | Writes one `.age` file to the user-specified path |

### A. `dotfiles ssh audit`

Prints a single table. Rows cover:

- Every file matching `~/.ssh/id_*` that is not a `.pub`
- Every key listed by `ssh-add -l` (the active agent, which on this machine is 1P)
- Every 1P item with `category: SSH_KEY` in the configured vault (via `op item list --categories "SSH Key" --vault <VAULT>`)

Columns: `location`, `type`, `storage`, `passphrase`, `age`, `flags`.

```
SSH key inventory
==================================================
 #  location                            type     storage       passphrase  age          flags
 1  ~/.ssh/id_ed25519_trading_vps       ED25519  disk          none        3 days       ⚠ adopt
 2  ~/.ssh/id_rsa                       RSA 2048 disk          none        10y 5mo      ⚠ adopt ⚠ weak ⚠ old
 3  (agent) SHA256:iYBE...              ED25519  1P agent      n/a         -            ok
 4  1P: SSH - GitHub                    ED25519  1P item       n/a         -            ok (matches agent)

Legend:
  ⚠ adopt  = disk key with no 1P backup; run: dotfiles ssh adopt <path>
  ⚠ weak   = RSA < 3072 bits or DSA/ECDSA-256
  ⚠ old    = created more than 5 years ago
  ok       = in 1P, safe
```

Rules for the classifier:

- `storage = disk` when a file exists in `~/.ssh/` and has no matching 1P item (match by public-key fingerprint).
- `storage = 1P agent` when present in `ssh-add -l` output.
- `storage = 1P item` when present in `op item list` output with category `SSH Key`.
- A row can be both `1P agent` and `1P item` (common, safe). Show once with flag `ok (matches agent)`.
- A file row gets `⚠ adopt` when no 1P item has its public-key fingerprint.
- `passphrase` test: `ssh-keygen -y -P "" -f <file>` exits 0 means no passphrase.
- `age` computed from file `mtime`; formatted `Xy Ymo`, `Xd`, or `-` for agent/item rows.

Audit is read-only. It never writes to disk, to the agent, or to 1P. Safe to run anytime.

### B. `dotfiles ssh adopt <key-path> [--title <name>] [--vault <name>]`

Takes an on-disk private-key path. **Guided manual flow**, because 1Password CLI (op 2.x) does not support importing existing SSH private keys; only key generation is CLI-automatable. SSH Key item creation from pasted private-key material must go through the 1P desktop app per Agilebits' key-integrity policy.

The command:

1. Computes the disk key's fingerprint.
2. Queries 1P for existing SSH Key items; if one already matches the fingerprint, prints `already adopted` and exits 0 (idempotency guard).
3. Confirms with the user: prints key path, fingerprint, suggested title, target vault. `[y/N]`, default no.
4. On yes: copies the private-key content to the macOS clipboard (`pbcopy`), opens the 1Password desktop app.
5. Prints a five-step paste guide (category SSH Key, title, paste into `private key` field, move to vault, save).
6. Waits on `read -P "Press Enter after you've saved..."`.
7. Clears the clipboard (`printf "" | pbcopy`).
8. Re-queries 1P, walks all SSH Key items in the target vault, matches by fingerprint.
9. On fingerprint match: prints ✓ confirmation + retirement hint. On no match: prints ✗ with possible causes (wrong vault, sync delay, paste corrupted).

Arguments:
- `--title` defaults to `SSH - <basename-of-keyfile>`.
- `--vault` defaults to the `op_vault` field from `chezmoi data`, falling back to `Private`.

Guards:
- Refuses if `op` not installed or not signed in; prints actionable next step.
- Refuses passphrase-protected keys (fingerprint cannot be derived); user must decrypt first.
- Refuses on missing `pbcopy` (non-macOS).
- The disk copy is **never** touched, regardless of outcome.

Output on success:

```
✓ Verified in 1P: 'SSH - id_ed25519_trading_vps' (vault: Private)
  Fingerprint: SHA256:tOYG...

  The disk copy at ~/.ssh/id_ed25519_trading_vps is untouched.
  When you are confident nothing needs the disk copy:
    mv ~/.ssh/id_ed25519_trading_vps{,.pub} ~/.Trash/
  Re-run 'dotfiles ssh audit' to confirm the 1P agent serves this key.
```

### C. `dotfiles ssh backup --destination <path>`

Produces a single `.age` file at `<path>/ssh-keys-YYYY-MM-DD.age`. The plaintext inside is a simple, line-delimited format:

```
# ssh key bundle, generated YYYY-MM-DD HH:MM:SS by dotfiles ssh backup
# bundle format v1

=== BEGIN KEY: SSH - GitHub ===
PUBLIC: ssh-ed25519 AAAAC3... user@host
PRIVATE:
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
=== END KEY ===

=== BEGIN KEY: SSH - id_ed25519_trading_vps ===
...
```

Pulls keys via `op item list --categories "SSH Key"` then `op item get <id> --fields "private key,public key"` per item. Writes plaintext to a `mktemp` file with mode 0600, pipes through `age --encrypt -r <recipient>`, writes the result to the destination path, shreds the tempfile.

**Recipient selection (strict, no fallbacks):**

- Prefer `~/.config/chezmoi/key.txt` if present: extract the public key with `age-keygen -y ~/.config/chezmoi/key.txt` and use that. This is the same age identity chezmoi uses for `encrypted_` files, so restore works with tooling the user already has.
- If not present: print a clear error with the exact setup command and exit non-zero. Do not silently generate a new key.

```
✗ no age identity found at ~/.config/chezmoi/key.txt
  Set one up first:
    age-keygen -o ~/.config/chezmoi/key.txt
    chmod 600 ~/.config/chezmoi/key.txt
  Then back it up to 1P:
    dotfiles backup
```

Required tools: `op`, `age`. Missing tool → actionable error. Never silently continue.

`--destination` is mandatory. No default path. The user must point at a USB drive, external volume, or deliberate filesystem path. This is the one-time, hands-on step that makes the escape hatch real; a default would undermine it.

Output after success:

```
✓ Wrote /Volumes/USB/ssh-keys-2026-04-22.age
  Size: 3.2 KB (4 keys)
  Recipient: age1qyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqy5... (from ~/.config/chezmoi/key.txt)

  Restore on a new machine:
    age --decrypt -i ~/.config/chezmoi/key.txt /Volumes/USB/ssh-keys-2026-04-22.age
  Then create a new 1P SSH Key item in the desktop app and paste each
  === BEGIN KEY block's private key field. op CLI cannot import SSH keys.
```

### D. Walkthrough in docs/guide.md

A new section `### Walkthrough: back up your SSH keys` covering:

1. `dotfiles ssh audit` → read the table.
2. For each `⚠ adopt` row: `dotfiles ssh adopt ~/.ssh/<name>` → 1P primary backup in place.
3. For unknown-usage keys (`id_rsa` in this repo's case): how to investigate before retiring.
   - `grep "tieubao@Hans.local" ~/.ssh/authorized_keys* ~/.ssh/config` on hosts you can reach.
   - `ssh -v <host> 2>&1 | grep -i offering` to see which key an existing ssh session offers.
   - Check GitHub / GitLab / Bitbucket / VPS provider SSH key lists in-browser.
   - Re-run `dotfiles ssh audit` monthly; if no surprises surface, rotate only after ≥3 months of observation.
4. Once a quarter: `dotfiles ssh backup --destination /Volumes/<usb>/` → offline escape hatch.
5. Restore drill: decrypt the age file on a test machine, confirm the plaintext is readable.

## Rules

- **Adoption never deletes disk keys.** Every deletion decision is explicit and manual. The spec documents the deletion command but the tool never runs it.
- **Audit is read-only.** No writes to disk, agent, or 1P.
- **Backup requires an explicit destination.** No default path. The user chooses where the `.age` file lands.
- **Plaintext never touches unencrypted disk outside a `mktemp` file.** The tempfile is mode 0600 and removed with `shred`/`rm -P` after encryption. If either age or op errors mid-flight, the tempfile is still cleaned.
- **No new age identity is generated silently.** If `~/.config/chezmoi/key.txt` is absent, the tool errors with the setup command.
- **Idempotency.** `ssh adopt` on an already-adopted key is a no-op. `ssh audit` is idempotent by construction. `ssh backup` produces a new dated file on each run; old files are the user's problem.
- **No commit side effects.** Unlike `dotfiles edit` and `dotfiles drift`, the `ssh` subcommand does not touch the git repo. These actions affect 1P and the user's filesystem only.

## Files to create or modify

| File | Change |
|---|---|
| `docs/specs/S-38-ssh-key-backup.md` | This spec (new) |
| `home/dot_config/fish/functions/dotfiles.fish` | Add `case ssh` block with `audit`, `adopt`, `backup` sub-actions |
| `docs/guide.md` | New `### Walkthrough: back up your SSH keys` section |

## Test

1. **Audit, clean machine.** On a fresh Mac with one 1P-managed agent key and no disk keys: `dotfiles ssh audit` prints one row, `storage = 1P agent`, no `⚠` flags.
2. **Audit, mixed state (current machine).** Prints 4 rows matching the inventory we captured for S-38 design: two disk keys flagged `⚠ adopt`, one with `⚠ weak ⚠ old` (the 2015 RSA), one ED25519 in 1P agent.
3. **Adopt, happy path (guided).** `dotfiles ssh adopt ~/.ssh/id_ed25519_trading_vps` prints fingerprint + target, confirms, copies key to clipboard, opens 1P desktop, waits for Enter, clears clipboard, re-queries 1P, verifies by fingerprint, prints ✓. Disk file untouched (`test -f ~/.ssh/id_ed25519_trading_vps`). Re-run: prints `already adopted`, exits 0 without re-prompting.
4. **Adopt, no op session.** With `op` signed out: prints `op signin` as the next step, exits 1. No clipboard writes.
5. **Backup, happy path.** `dotfiles ssh backup --destination /tmp/ssh-bak` creates `/tmp/ssh-bak/ssh-keys-$(date +%F).age`. `age --decrypt -i ~/.config/chezmoi/key.txt <file>` produces the plaintext bundle. `grep -c '=== BEGIN KEY' <plaintext>` equals the 1P SSH-item count.
6. **Backup, no age identity.** With `~/.config/chezmoi/key.txt` absent: prints the exact setup command, exits 1. No file written.
7. **Backup, missing tool.** With `age` uninstalled: prints `age not found; brew install age`, exits 1.
8. **Tempfile hygiene.** After any success or failure in step 5 or 6: `ls /tmp/tmp.*.ssh-bundle 2>/dev/null` returns nothing. Cleanup runs in a `trap` equivalent (fish `--on-event fish_exit` or explicit cleanup in every branch).
9. **Verification commands pass.**
   - `fish -n home/dot_config/fish/functions/dotfiles.fish` exits 0
   - `chezmoi apply --dry-run 2>&1 | tail -20` reports no new errors
   - `verify-dotfiles` subagent reports green

## Out of this spec

- **Automated rotation / re-issuance.** Separate future spec if needed.
- **Restore subcommand.** The age-decrypt + manual re-import is a one-liner; a full automated restore would need vault-selection, conflict handling, and a dry-run mode. Revisit if the manual path becomes painful.
- **`known_hosts` management.** Per-machine; stays per-machine.
- **Automatic backup scheduling.** Auto-mode violation. The user runs `dotfiles ssh backup` when they plug in the USB drive.
- **Git-signing-key backup.** Git SSH signing keys are already covered by this spec if they live in `~/.ssh/` or 1P. Nothing special beyond that.
