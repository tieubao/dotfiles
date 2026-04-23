# Dotfiles sync log

Append-only record of Claude-assisted sync sessions. Each entry logs
what changed and when. Read by Claude at the start of each sync for
context.

---

## [2026-04-23] S-45 stop echoing secrets in refresh @ Hans Air M4

Incident + fix in one entry.

**Incident (earlier same day):** during S-43 verification I simulated
the "empty Keychain" doctor branch by deleting an entry and then
re-cached it with `dotfiles secret refresh OP_SERVICE_ACCOUNT_TOKEN`.
The function printed `"Restart shell or: set -gx OP_SERVICE_ACCOUNT_TOKEN 'ops_...'"`
which echoed the raw service account token into the terminal (and
therefore into the Claude Code session transcript). User decided to
rotate the token in 1P; the rotation itself is out of scope of the
dotfiles repo.

**Root cause:** `home/dot_config/fish/functions/dotfiles.fish:257` in
the `dotfiles secret refresh` path had a success hint that interpolated
`$val` into its output. Any transcript-capturing environment
(screen recorder, LLM tool-call log, `script -a`, etc.) captured the
value.

**Fix (this PR, spec [S-45](specs/S-45-secret-refresh-no-echo.md)):**
Replaced the leaky hint with phrasing that references the variable
name only (`"Open a new shell ... to load the new value into $VAR"`).
Matches the already-safe wording in the `secret add` success path.

**Standing rule now in CLAUDE.md:** never echo resolved secret values.
Reference the var name or op:// ref instead. `secret-cache-read` is the
one exception (its stdout is captured by `()`, not printed).

**Audit result:** only one leak site existed. `dotfiles secret add/rm/list`
paths were checked and are clean. `secret-cache-read` is correct.
`chezmoi apply` path was cleaned up in S-35 and remains secret-free.

**Open follow-up** (not in this PR): `dotfiles secret add` passes the
value to `op item create` as a command-line argument, briefly visible
to local `ps`. Lower severity; documented in the spec as a known
limitation.

Repo changes:
  - docs/specs/S-45-secret-refresh-no-echo.md (new)
  - home/dot_config/fish/functions/dotfiles.fish: 2-line hint replacement
  - CLAUDE.md: new "Never echo resolved secret values" convention
  - docs/tasks.md: ticked S-45

---

## [2026-04-23] S-26 Brewfile cleanup @ Hans Air M4

Audit per spec [S-26](specs/S-26-brewfile-cleanup.md). Two changes
landed; everything else intentionally deferred.

Findings:
  - Real duplicate: `brew "tldr"` listed twice in the Core CLI block
    (the second had the descriptive comment). Fixed: kept the earlier
    occurrence, moved the comment onto it, deleted the duplicate.
  - False duplicate: `font-source-code-pro` and
    `font-sauce-code-pro-nerd-font` are separate fonts (original Adobe
    vs Nerd-Font patched). Added a one-line comment above the pair so
    future readers (including LLMs) do not dedupe them.

Verified but not acted on:
  - All casks resolve via `brew info --cask` (no renames needed).
  - No commented-out brew/cask entries exist; all `#` comments are
    install-path breadcrumbs for packages managed via cargo, npm, uv,
    or curl | bash. Keeping them.
  - `brew bundle check` exits 0 on the rendered `~/.Brewfile`.

Flagged for future decision:
  - `mise` + brew language runtimes (`go`, `node`, `python@3.12`,
    `elixir`, `rustup`) overlap. Not a typo, a design question. Left
    alone until the user picks a side.

Repo changes:
  - home/dot_Brewfile.tmpl: removed duplicate tldr, added font-pair comment
  - docs/specs/S-26-brewfile-cleanup.md: replaced stub with full audit
    spec, status=done
  - docs/tasks.md: ticked S-26

Standing rule from S-44 applied in this PR.

---

## [2026-04-23] S-44 spec status housekeeping @ Hans Air M4

Audit found 6 specs with stale status frontmatter despite having shipped:
S-32 (`planned`), S-36, S-37, S-38, S-39, S-41 (`proposed`). Root cause is procedural:
the SDD flow never required flipping status to `done` at ship time, so
frontmatter drifted from reality.

Two-part fix (spec [S-44](specs/S-44-spec-status-housekeeping.md)):
  - One-time: flip the five stale statuses, refresh tasks.md to list
    S-35 through S-44 in the appropriate section, document S-40 as
    intentionally unused (number gap, no spec).
  - Standing rule: from now on, shipping a spec includes flipping its
    status to done AND ticking its entry in tasks.md AND appending to
    the sync log. All three, not optional.

No runtime changes. No chezmoi apply needed. Pure bookkeeping.

Files changed:
  - docs/specs/S-44-spec-status-housekeeping.md (new)
  - docs/specs/S-{32,36,37,38,39,41}-*.md: status frontmatter only
  - docs/tasks.md: date + reconciliation for S-24 through S-44
  - docs/sync-log.md: this entry

---

## [2026-04-23] S-43 sync secret cache visibility @ Hans Air M4

Follow-up to S-42. The sync workflow did not surface registered-but-uncached
secrets, so a fresh machine that inherited the `OP_SERVICE_ACCOUNT_TOKEN`
registration but never triggered the first interactive biometric had no
feedback loop. Agents calling `op read op://...` would just fail silently.

Two additive, notify-only probes added (see spec
[S-43](specs/S-43-sync-secret-cache-visibility.md)):

  - `/dotfiles-sync` step 2: new "Secret cache status" block. Silent when
    all registered secrets are cached or when op is absent/unauthed.
    Gated on `op account list &>/dev/null` so headless machines stay quiet.
    Report category: "Secret cache (optional)" under step-3 format.
  - `dotfiles doctor`: new check after the SSH backup block. Iterates
    `secrets.toml`, probes Keychain per var. Reports `[ok]` when everything
    is cached, `[--]` (info) when any are empty, with a hint to run
    `exec fish` or wait for the next interactive shell.

Design choices recorded in the spec:
  - Info-level (`[--]`) not error (`[!!]`). Empty cache is a legitimate
    transient state on fresh machines.
  - Reachability of the 1P ref is NOT checked (would require live op call,
    would popup on miss). Presence of Keychain entry only.
  - Token identity is not special-cased. The probe is uniform across all
    registered vars; `OP_SERVICE_ACCOUNT_TOKEN` shows up like any other.

Verified both branches (all-cached, one-missing) on this machine.

Repo changes:
  - docs/specs/S-43-sync-secret-cache-visibility.md (new)
  - .claude/commands/dotfiles-sync.md: + "Secret cache status" scan block, + report line
  - home/dot_claude/commands/dotfiles-sync.md: identical mirror of project copy
  - home/dot_config/fish/functions/dotfiles.fish: + secrets.toml iterator in doctor

Not changed (intentionally):
  - secret-cache-read (probes are observational only)
  - secrets.fish.tmpl loop (no new registrations)
  - any .chezmoiscripts/ (apply path stays popup-free per S-35)

---

## [2026-04-23] S-42 service account agent auth @ Hans Air M4

New spec: [S-42](specs/S-42-service-account-agent-auth.md) -- document the
1Password service account pattern so Claude Code subprocesses can
`op read op://...` headlessly.

Root cause recap: `op` refuses to trigger biometric when stdin is not a TTY,
so agent subprocess reads fail silently. Service account bearer auth
bypasses biometric entirely once `OP_SERVICE_ACCOUNT_TOKEN` is in env.

Registered locally (this machine only, per-user action, not shared):
  - `dotfiles secret add OP_SERVICE_ACCOUNT_TOKEN "op://Private/op-service-account-trading/credential"`
  - Token scoped server-side to the `Trading` vault in 1Password
  - First fish login triggered one biometric; all subsequent shells silent

Repo changes (shared):
  - docs/specs/S-42-service-account-agent-auth.md (new)
  - CLAUDE.md: expanded "Secret injection" section from two backends to three patterns
  - docs/guide.md: added "Service account for agent subprocess `op read`" subsection under §6
  - home/.chezmoidata/secrets.toml: added `OP_SERVICE_ACCOUNT_TOKEN` registry entry (op:// ref only, not a value)

Not changed (intentional -- existing infra absorbs this):
  - secret-cache-read helper
  - secrets.fish.tmpl template loop
  - dotfiles secret subcommands

Blast radius note recorded in the spec: service account token reads every
vault scoped to it. Keychain entry is per-user encrypted at rest, same
threat model as `ANTHROPIC_API_KEY`. Recommended mitigation (dedicated
`Agents` vault) is documented but not enforced; this machine uses the
pre-existing `Private` vault for convenience, accepted risk.

---

## [2026-04-23] sync @ Hans Air M4

Track A (minimal): rename drift + guardrails pin bump, plus 4 requested new casks.

Brewfile (core):
  - rename: `cask "zen"` -> `cask "zen-browser"` (upstream renamed back)
  - added cask: wispr-flow (voice-to-text dictation)
  - added cask: font-ibm-plex-sans, font-ibm-plex-sans-hebrew, font-ibm-plex-serif

Guardrails:
  - bumped pin v0.3.7 -> v0.3.8 in run_onchange_after_claude-guardrails.sh.tmpl
    (release notes: https://github.com/dwarvesf/claude-guardrails/releases/tag/v0.3.8)

Not classified this session (deferred; surfaced in report only):
  - 22 untracked brew packages (duti, gitup, hub, jpeg-xl, libiconv, lume,
    markdown-oxide, ocaml, ollama, opencode, pandoc, pipx, playwright-cli,
    python@3.10, rclone, rust, shared-mime-info, subversion,
    the_silver_searcher, tldx, wireguard-tools, xcodegen, yarn, z, zsh)
  - 13 untracked casks (antigravity, calibre, chrysalis, codexbar, cursor,
    grandperspective, hyprnote, microsoft-auto-update, opencode-desktop,
    swiftdefaultappsprefpane, tana, tor-browser)
  - 1 new fish function: fisher.fish (Fisher plugin manager bootstrap)
  - 54 brew + 8 casks tracked-but-not-installed noise (never ran brew bundle here)
  - 25 VS Code extensions tracked-but-not-installed (user is on Cursor/Zed)

SSH backup status:
  - 2 of 2 on-disk keys still have no 1Password backup (action: `dotfiles ssh adopt`)

Earlier in same session (pre-sync):
  - feat(secrets): split Cloudflare API token from R2 credentials
  - feat(claude): sync personal PreToolUse hooks + Self-verification rules
    section into dotfiles modify_ overlay (below marker)
  - removed "# Self-verification rules" block from above-marker region of
    ~/.claude/CLAUDE.md since it was fragile against sync-claude-context.sh

---

## [2026-04-16] design session @ Mac mini

Big architectural session extending the core/local pattern and rewriting secret
loading. Full spec: [S-35](specs/S-35-local-pattern-and-lazy-secrets.md).
Test plan: [testing.md](testing.md).

Config includes:
  - fish: source ~/.config/fish/config.local.fish (new)
  - tmux: source-file -q ~/.config/tmux/tmux.local.conf (new)
  - git/ssh: already had native includes

dotfiles local CLI (new subcommand):
  - list / promote / demote / edit
  - dynamic completions for brew / cask / ext
  - auto-commits core changes; never commits .local files

Secrets rearchitected (lazy + Keychain):
  - Removed {{ onepasswordRead }} from secrets.fish.tmpl
  - New helper ~/.local/bin/secret-cache-read (Keychain first, op fallback)
  - dotfiles secret list now shows [cached]/[empty]
  - dotfiles secret refresh VAR (clear cache + re-fetch)
  - chezmoi apply no longer triggers any 1Password popups

Brewfile housekeeping:
  - Added 12 modern tools: tldr, sd, gping, atuin, lazygit, difftastic,
    kubectx, kubecolor, stern, opentofu, dive, buf
  - Removed deprecated taps: homebrew/bundle, homebrew/services
  - Fixed renames: zen-browser->zen, google-cloud-sdk->gcloud-cli
  - Fixed cask->formula: gifski, lume
  - Fixed formula->cask: nordvpn
  - Demoted to ~/.Brewfile.local: sentencepiece, tor-browser, lume, meetingbar
    (kept nordvpn, microsoft-edge, cloudflared, elixir in core per user)

Verification hooks:
  - Hostname tag in sync log entries (@ Mac mini)
  - Three new dotfiles doctor checks for .local pattern integrity

Audit:
  - git log --all scanned for hardcoded secrets: clean
  - No tokens, keys, or op:// values with plaintext ever committed

Post-session fixes (same day):
  - fix(doctor): exclude always-run scripts (R status) from drift count
  - fix(doctor): check login shell via dscl, not $SHELL (was misreporting after chsh)
  - chezmoi apply --force resolved Zed One Light/Dark drift
  - Default shell confirmed via dscl: /opt/homebrew/bin/fish (chsh worked previously,
    $SHELL was just stale in inherited processes)

Documentation refresh:
  - README.md: multi-machine positioning, .local pattern, lazy secrets section
  - docs/llm-dotfiles.md: added multi-machine sync + lazy secrets sections
    (stack-agnostic, shareable patterns)
  - CLAUDE.md: explicit design philosophy section (6 principles)

---

## [2026-04-16] sync

Config:
  - re-add Zed settings.json (removed agent_servers block, absorbed local edits)
  - chezmoi apply deployed all pending repo changes (fish config, starship, lib.sh, dotfiles CLI, completions, Claude config)

Brewfile:
  - added tap: hashicorp/tap
  - added brew: chezmoi, mdq, certbot, hashicorp/tap/vault, colima, docker, docker-compose, docker-credential-helper, sentencepiece
  - added cask: codex, chrysalis, disk-inventory-x, google-cloud-sdk, lunar, monitorcontrol, skype, zen-browser
  - skipped legacy packages already superseded (htop->btop, hub->gh, z->zoxide, pipx->uv, youtube-dl->yt-dlp, etc.)

VS Code extensions:
  - synced to match installed: added openai.chatgpt, removed 4 uninstalled (docker.docker, dwarvesf.md-ar-ext, ms-vsliveshare.vsliveshare, ocamllabs.ocaml-platform)

Fish functions:
  - tracked 4 unmanaged: keychain_env.fish, keychain_set.fish, op_env.fish, web3_env.fish

Secrets:
  - CLOUDFLARE_API_TOKEN already registered in secrets.toml, resolved from 1Password at apply time

---

## [2026-04-14] sync

Config:
  - re-add Zed settings.json (MCP server changes, local edits absorbed)

VS Code extensions:
  - add 5: docker.docker, dwarvesf.md-ar-ext, ms-vsliveshare.vsliveshare, ocamllabs.ocaml-platform, openai.openai-chatgpt-adhoc

Fish functions:
  - removed 5 orphaned standalone functions from machine (add-secret, dfe, dfs, list-secrets, rm-secret)  - consolidated into dotfiles subcommands

Brew/casks: deferred to next sync

---
