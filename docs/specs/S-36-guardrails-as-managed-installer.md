---
id: S-36
title: Claude-guardrails as a managed installer (not vendored)
type: feature
status: proposed
date: 2026-04-17
---

# S-36: Claude-guardrails as a managed installer (not vendored)

## Problem

`~/.claude/settings.json` has two owners today, and they collide:

1. **claude-guardrails** (installed via `npx claude-guardrails install`) owns the security layer: 21 deny rules, PreToolUse hooks (scan-commit, push guard, pipe-to-shell, rm-rf), the UserPromptSubmit scan-secrets hook, plus the critical `$schema` URL that Claude Code uses to validate the file.

2. **This dotfiles repo** currently tries to own the whole file via `home/dot_claude/settings.json`. That copy is an older, hand-forked snapshot of guardrails lite that:
   - Has `"schema"` (wrong key, should be `$schema`) pointed at the pre-v0.3.5 URL. Claude Code silently discards any settings.json with that schema value. Any fresh machine running `chezmoi apply` from this repo gets zero active guardrails and no warning.
   - Is missing everything added in guardrails 0.3.4+ (scan-commit, patterns/secrets.json, BIP39 wordlist, schema-remediation).
   - Mixes personal preferences (statusLine, Stop hook for learning capture, enabled plugins, `skipDangerousModePermissionPrompt`) into the same file with no separation.

Vendoring the full guardrails bundle into the dotfiles repo is tempting but worse long-term: upstream releases (like the 0.3.7 BIP39 fix this week) would require manual re-import and drift silently.

## Non-goals

- Replacing claude-guardrails with a homegrown equivalent.
- Managing guardrails state per-project (`.claude/settings.json` in individual repos). Scope is user-level config only.
- Handling the `full` variant's `prompt-injection-defender.sh` differently from `lite`. The installer already handles variant selection.

## Solution

Stop vendoring. Treat `~/.claude/settings.json` as a file chezmoi *patches* (not owns), with guardrails installed on a pinned version by a chezmoi-managed script.

### A. Stop managing settings.json as a regular file

Rename `home/dot_claude/settings.json` to `home/dot_claude/modify_settings.json.tmpl`. `modify_` is a chezmoi file prefix that changes the semantics: chezmoi feeds the current live file on stdin to the script, and writes the script's stdout back to the file. This lets us patch specific fields without replacing the whole file.

The script's job: idempotently ensure the personal fields are present, leave everything else untouched.

```bash
#!/usr/bin/env bash
# Reads ~/.claude/settings.json on stdin, patches in personal fields,
# prints result on stdout. chezmoi handles the I/O.
jq '
  . + {
    statusLine: {type: "command", command: "bash ~/.claude/statusline-command.sh"},
    enableAllProjectMcpServers: false,
    skipDangerousModePermissionPrompt: true,
    enabledPlugins: (.enabledPlugins // {}) + {
      "ouroboros@ouroboros": true,
      "telegram@claude-plugins-official": true
    },
    extraKnownMarketplaces: (.extraKnownMarketplaces // {}) + {
      "ouroboros": {source: {source: "github", repo: "Q00/ouroboros"}},
      "claude-plugins-official": {source: {source: "github", repo: "anthropics/claude-plugins-official"}}
    },
    hooks: (.hooks // {}) + {
      Stop: ((.hooks.Stop // []) + [{
        hooks: [{
          type: "command",
          command: "echo '"'"'{\"decision\":\"approve\",\"reason\":\"LEARNING CAPTURE CHECK...\"}'"'"'",
          timeout: 5
        }]
      }] | unique)
    }
  }
'
```

The `| unique` on the Stop hook keeps repeated applies idempotent. Guardrails deny rules, PreToolUse/UserPromptSubmit hooks, and `$schema` are NOT touched.

### B. New chezmoi init variable: `.guardrails_variant`

Values: `"lite"` (default), `"full"`, `"none"`. Prompted on `chezmoi init` alongside `.editor`, `.headless`, etc. Cached in chezmoi state.

### C. New script: `home/.chezmoiscripts/run_onchange_after_claude-guardrails.sh.tmpl`

```bash
#!/usr/bin/env bash
# hash: {{ printf "variant=%s version=%s" .guardrails_variant "0.3.7" }}
#
# Installs or upgrades claude-guardrails on this machine. Runs only when
# the pinned version or variant changes. Uses npx so there's nothing to
# clone or cache manually.
set -euo pipefail

{{- if or (eq .guardrails_variant "none") .headless }}
echo "guardrails: skipped (variant=none or headless)"
exit 0
{{- end }}

VARIANT="{{ .guardrails_variant }}"
VERSION="0.3.7"

if ! command -v npx >/dev/null 2>&1; then
  echo "guardrails: npx not found; install node first" >&2
  exit 1
fi

echo "guardrails: installing claude-guardrails@${VERSION} (${VARIANT})"
npx -y "claude-guardrails@${VERSION}" install "${VARIANT}"
```

Hash comment pins `variant=X version=Y`. Chezmoi re-runs the script whenever either changes. Bumping guardrails = edit one line in this script + commit.

### D. Apply order (no conflicts)

Chezmoi execution order is documented in `CLAUDE.md`:

1. `run_before_*` scripts (unchanged).
2. Regular files deployed, **including `modify_settings.json.tmpl`** — runs against the currently-live file.
3. `run_once_after_*` and `run_onchange_after_*` — `claude-guardrails.sh` fires here if variant/version changed. Its install.sh merges guardrails on top of whatever settings.json now contains.
4. `run_after_zz-summary.sh`.

On a fresh machine:
- Step 2 finds no settings.json, modify script creates one with just personal fields.
- Step 3 runs guardrails install.sh, which jq-merges guardrails fields in.
- End state: personal + guardrails.

On every subsequent apply:
- Step 2: modify script patches personal fields into the live (already-merged) file. Idempotent.
- Step 3: no-op unless version/variant changed.

No ordering race because the modify script and the installer both use additive jq merges.

## Migration

One-shot manual steps for the current machine:
1. `chezmoi add ~/.claude/statusline-command.sh` has already happened (S-35).
2. Edit `home/dot_claude/settings.json` → convert to `home/dot_claude/modify_settings.json.tmpl` with the script above.
3. Add `.guardrails_variant` to `home/.chezmoidata/*.toml` defaults, or let `chezmoi init` prompt on next bootstrap.
4. Add `home/.chezmoiscripts/run_onchange_after_claude-guardrails.sh.tmpl`.
5. Run `chezmoi apply --dry-run` to confirm no surprises, then `chezmoi apply`.
6. Verify: `jq '."$schema", (.permissions.deny | length), (.hooks.PreToolUse | length), .statusLine' ~/.claude/settings.json` shows schemastore URL, 21+ deny rules, 3+ PreToolUse hooks, and the statusLine intact.

Rollback: revert the commit, run `chezmoi apply`. The old `home/dot_claude/settings.json` returns (broken schema and all). No data loss since `~/.claude/settings.json.backup` from the current install is preserved.

## Risks

| Risk | Mitigation |
|------|-----------|
| npx needs network on first apply | Acceptable: fresh-machine bootstrap already requires network for brew/mas/fish plugins. |
| Guardrails upstream breaking change | Version is pinned; bumping is a deliberate edit. |
| `modify_` script bug corrupts settings.json | Chezmoi stages changes to a tempfile and only moves on success. Add a jq syntax check at the top of the script as defense. |
| User edits settings.json manually between applies | Personal fields survive (modify merges additively). Fields outside the personal set and the guardrails set are left alone by both layers. |

## Test

1. `chezmoi apply --dry-run` — no errors, shows the modify script running + guardrails script running.
2. Force both scripts to fire on a clean machine:
   ```bash
   rm ~/.claude/settings.json
   chezmoi apply
   jq '."$schema", (.permissions.deny | length), .statusLine.type' ~/.claude/settings.json
   ```
   Expected: `"https://json.schemastore.org/claude-code-settings.json"`, `21`, `"command"`.
3. Flip `.guardrails_variant` from `lite` to `full` via `chezmoi init`, re-apply. Verify `.hooks.PostToolUse` now contains the prompt-injection-defender entry.
4. Set `.guardrails_variant` to `none`, re-apply. Verify the script prints `skipped` and does not call npx.
5. Run `chezmoi apply` twice in a row with no underlying change. Second run should not re-fire the guardrails install (hash unchanged).

## Out of this spec

- Bootstrapping `install.sh` in this dotfiles repo to run guardrails install directly (redundant with the chezmoi script, and install.sh is meant to be pre-chezmoi).
- `~/.claude/CLAUDE.md` management — the guardrails "Security Rules" section is already there; personal content dominates the file. Leave unmanaged for now.
- The `schema-remediation` notice from guardrails 0.3.6. The pinned-version approach already sidesteps it (we start from 0.3.7).
