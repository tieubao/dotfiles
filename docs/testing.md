# Test plan

End-to-end verification for dotfiles features that need cross-machine or cross-session validation. Each test block has: setup, commands, expected output, failure diagnosis.

Current coverage:
- Core/local pattern ([S-35](specs/S-35-local-pattern-and-lazy-secrets.md))
- Lazy 1Password secret resolution ([S-35](specs/S-35-local-pattern-and-lazy-secrets.md))

---

## 1. Lazy secret resolution (single machine)

**Goal:** `chezmoi apply` never triggers 1Password popups; secrets are resolved lazily at shell startup, cached in macOS Keychain.

### 1.1 Apply is silent for 1Password

**Setup:** At least one secret registered (e.g., `dotfiles secret add TEST_TOKEN "op://Private/TestItem/credential"`).

**Command:**
```bash
chezmoi apply
```

**Expected:**
- Apply completes without any 1Password biometric/password popup
- Log tail shows no `op read` invocations

**Pass criteria:**
- No 1Password UI interaction required
- `~/.config/fish/conf.d/secrets.fish` contains the lazy call pattern:
  ```
  set -gx TEST_TOKEN ($HOME/.local/bin/secret-cache-read "TEST_TOKEN" "op://...")
  ```
- The rendered file does NOT contain the literal secret value

**Fail diagnosis:**
- Popup during apply → template still has `{{ onepasswordRead ... }}`; check `home/dot_config/fish/conf.d/secrets.fish.tmpl`
- Literal secret in rendered file → same as above

### 1.2 First shell populates Keychain (one popup per secret)

**Setup:** Ensure Keychain has no entries for the registered secrets:
```bash
security delete-generic-password -a "$USER" -s "TEST_TOKEN" 2>/dev/null
```

**Command:**
```bash
exec fish
```

**Expected:**
- Exactly one 1Password prompt per secret that was empty in Keychain
- After dismissing, shell starts and `$TEST_TOKEN` is set

**Pass criteria:**
```bash
echo $TEST_TOKEN               # prints the secret
security find-generic-password -a "$USER" -s "TEST_TOKEN" -w   # prints same secret
```

**Fail diagnosis:**
- No popup, empty `$TEST_TOKEN` → `op` not signed in; `eval (op signin)`
- Popup but empty `$TEST_TOKEN` → reference in secrets.toml points to nonexistent item; verify with `op read`
- Popup per shell startup instead of once → Keychain write failing; check `security add-generic-password` exit code

### 1.3 Subsequent shells are silent

**Setup:** 1.2 passed; Keychain populated.

**Command:**
```bash
exec fish
```

**Expected:**
- Zero 1Password popups
- `$TEST_TOKEN` set immediately

**Pass criteria:** shell starts within 100 ms of normal, no UI interaction.

**Fail diagnosis:**
- Popup every shell → Keychain read failing silently; run `security find-generic-password -a "$USER" -s "TEST_TOKEN" -w` manually

### 1.4 Refresh invalidates cache

**Command:**
```bash
dotfiles secret refresh TEST_TOKEN
```

**Expected:**
- Keychain entry deleted
- Immediately re-fetched from 1Password (one popup)
- Re-cached in Keychain

**Pass criteria:**
```bash
security find-generic-password -a "$USER" -s "TEST_TOKEN" -w   # prints fresh value
```

---

## 2. Promote/demote round-trip (single machine)

**Goal:** `dotfiles local` moves items between `.Brewfile.local` and `dot_Brewfile.tmpl` without data loss.

### 2.1 Demote then promote is idempotent

**Command:**
```bash
dotfiles local demote cask raycast
# inspect: raycast should be in ~/.Brewfile.local, not in dot_Brewfile.tmpl
dotfiles local promote cask raycast
# inspect: raycast back in dot_Brewfile.tmpl, not in ~/.Brewfile.local
git -C ~/workspace/tieubao/dotfiles diff home/dot_Brewfile.tmpl
```

**Pass criteria:** diff shows only the trailing `# promoted from local` comment difference (or no diff if annotation stripped on demote).

### 2.2 List reflects file state

**Command:**
```bash
dotfiles local list
```

**Expected:** each `.local` file is listed with either its contents (Brewfile/extensions) or line count (fish/tmux/git configs), or `(not created)`.

---

## 3. `dotfiles doctor` .local integrity checks

**Goal:** doctor flags all four `.local`-related failure modes.

### 3.1 All checks pass under normal state

**Command:**
```bash
dotfiles doctor
```

**Expected lines:**
```
[ok] .local files correctly excluded from chezmoi
[ok] ~/.Brewfile.local is valid Ruby
[ok] no .local files leaked into git history
```

### 3.2 Catches Brewfile.local syntax error

**Setup:** corrupt the local file:
```bash
cp ~/.Brewfile.local ~/.Brewfile.local.bak
echo 'this is not ruby !!!' >> ~/.Brewfile.local
```

**Command:**
```bash
dotfiles doctor
```

**Expected:** `[!!] ~/.Brewfile.local has syntax errors`

**Cleanup:** `mv ~/.Brewfile.local.bak ~/.Brewfile.local`

### 3.3 Catches accidentally tracked .local

**Setup:** temporarily remove the ignore rule:
```bash
# manually edit .chezmoiignore to delete the .Brewfile.local line
chezmoi add ~/.Brewfile.local   # now chezmoi tracks it
```

**Command:**
```bash
dotfiles doctor
```

**Expected:** `[!!] .local files are being tracked by chezmoi (should be ignored)`

**Cleanup:** restore `.chezmoiignore`; `chezmoi forget ~/.Brewfile.local`.

---

## 4. Multi-machine sanity (Machine B)

**Goal:** a second Mac can clone, apply, and not inherit Machine A's local-only packages.

### 4.1 Fresh clone + install

**Setup on Machine B:**
```bash
git clone git@github.com:USER/dotfiles.git ~/workspace/tieubao/dotfiles
cd ~/workspace/tieubao/dotfiles
./install.sh
```

**Expected:**
- Install completes without errors
- Shell starts; `$CLOUDFLARE_API_TOKEN` etc. populated on first shell (one popup each)

**Pass criteria:**
```bash
# Machine A's local-only apps are NOT installed on Machine B:
brew list --cask 2>/dev/null | grep -E '^(chrysalis|lunar|monitorcontrol)$' | wc -l
# must return: 0
```

### 4.2 /dotfiles-sync on Machine B

**Setup:** Machine B has some unique installs (e.g., `brew install fastfetch`).

**Command in Claude Code on Machine B:**
```
/dotfiles-sync
```

**Expected:**
- Report shows `fastfetch` under "New packages"
- Claude prompts for core/local classification
- Sync log entry created with `@ <Machine-B-hostname>` tag

**Pass criteria:**
```bash
grep '^## ' docs/sync-log.md | head -5
# should show ## [date] sync @ <Machine-B-hostname>
```

---

## 5. Round-trip sync via git (Machine A ↔ Machine B)

**Goal:** a promote on Machine A reaches Machine B via git, and vice versa.

### 5.1 A promotes, B inherits

**On Machine A:**
```bash
dotfiles local promote cask some-app-a-wants-everywhere
git push
```

**On Machine B:**
```bash
git pull
chezmoi apply
brew list --cask | grep some-app-a-wants-everywhere
# must be present
```

### 5.2 A demotes, B loses it from Brewfile

**On Machine A:**
```bash
dotfiles local demote brew some-thing-only-a-needs
git push
```

**On Machine B:**
```bash
git pull
chezmoi apply
grep 'some-thing-only-a-needs' ~/.Brewfile
# must be empty (no match)
```

**Note:** `brew bundle` does NOT uninstall on apply (it's `--no-upgrade` + additive). The package stays installed on B until `brew bundle cleanup` is run manually. This is intentional -- automatic uninstalls across machines are too destructive.

---

## 6. Secret leakage audit

**Goal:** no secrets have been committed to git (ever, any branch).

**Command:**
```bash
# Search full history (all branches, all commits) for common secret patterns
for pattern in 'sk-[A-Za-z0-9]\{20,\}' 'ghp_[A-Za-z0-9]\{20,\}' 'gho_[A-Za-z0-9]\{20,\}' \
               'xoxb-[0-9]' 'AKIA[A-Z0-9]\{16\}' 'AIza[A-Za-z0-9_-]\{30,\}' \
               'eyJ[A-Za-z0-9_-]\{20,\}\.eyJ' '[a-f0-9]\{64\}'; do
    hits=$(git log --all -p 2>/dev/null | grep -cE "$pattern" || true)
    printf "  %-40s %d hit(s)\n" "$pattern" "$hits"
done
```

**Pass criteria:** all patterns return 0 hits (except possibly `[a-f0-9]{64}` which can match SHA256 checksums in `.chezmoiscripts/` or `.chezmoiexternal.toml` -- inspect those manually).

**Fail diagnosis:**
- Real secret found → rotate it in the source system (1Password, GitHub, AWS, etc.) immediately; then rewrite history with `git filter-repo --replace-text` and force-push. Notify collaborators.
