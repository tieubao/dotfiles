#!/usr/bin/env bash
# Bootstrap the incident-workflow scaffolding in the current repo.
# Idempotent: skips files that already exist. Run with --dry-run to preview.
#
# Usage:
#   bootstrap.sh [--dry-run] [--public] [--path <incidents_path>] [--no-claude-md]
#
# Defaults:
#   --path docs/incidents/
#   visibility: private
#   touches CLAUDE.md if present (use --no-claude-md to skip)
#
# Idempotent contracts:
#   - Never overwrites an existing file.
#   - Append-only for shared files (CLAUDE.md, INDEX.md, HANDOFF.md). Detects
#     "section already present" by grepping for the heading.
#   - Dry-run prints what would change without writing.

set -euo pipefail

# ---------------------------------------------------------------- defaults
INCIDENTS_PATH="docs/incidents/"
VISIBILITY="private"
DRY_RUN="false"
TOUCH_CLAUDE_MD="true"

SKILL_DIR="${HOME}/.claude/skills/incident-workflow"

# ---------------------------------------------------------------- args
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)        DRY_RUN="true"; shift ;;
    --public)         VISIBILITY="public"; shift ;;
    --path)           INCIDENTS_PATH="$2"; shift 2 ;;
    --no-claude-md)   TOUCH_CLAUDE_MD="false"; shift ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# Normalize path to end with /
case "$INCIDENTS_PATH" in
  */) ;;
  *) INCIDENTS_PATH="${INCIDENTS_PATH}/" ;;
esac

# ---------------------------------------------------------------- helpers
log() { printf '%s\n' "$*"; }

check() {
  local label="$1" path="$2"
  if [ -e "$path" ]; then
    log "  [exists]  $label: $path"
  else
    log "  [missing] $label: $path"
  fi
}

write_or_skip() {
  local label="$1" path="$2" body="$3"
  if [ -e "$path" ]; then
    log "  [skip]    $label exists: $path"
    return 0
  fi
  if [ "$DRY_RUN" = "true" ]; then
    log "  [would]   write $label: $path"
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s' "$body" > "$path"
  log "  [wrote]   $label: $path"
}

append_if_missing() {
  local label="$1" target="$2" marker="$3" body="$4"
  if [ ! -f "$target" ]; then
    log "  [skip]    $label: target file does not exist: $target"
    return 0
  fi
  if grep -qF "$marker" "$target"; then
    log "  [skip]    $label already present in $target (marker: $marker)"
    return 0
  fi
  if [ "$DRY_RUN" = "true" ]; then
    log "  [would]   append $label to $target"
    return 0
  fi
  printf '\n%s\n' "$body" >> "$target"
  log "  [appended] $label to $target"
}

# ---------------------------------------------------------------- pre-flight
log "incident-workflow bootstrap"
log "  cwd:           $(pwd)"
log "  incidents_path: $INCIDENTS_PATH"
log "  visibility:    $VISIBILITY"
log "  dry_run:       $DRY_RUN"
log ""

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "warning: not inside a git repo. Continuing anyway."
fi

log "Pre-flight check (existing state):"
check "incidents dir"           "$INCIDENTS_PATH"
check "incidents README"        "${INCIDENTS_PATH}README.md"
check "incidents template"      "${INCIDENTS_PATH}_TEMPLATE.md"
check "per-repo config"         ".claude/incident-config.md"
check "CLAUDE.md"               "CLAUDE.md"
check "INDEX.md"                "INDEX.md"
check "HANDOFF.md"              "HANDOFF.md"
log ""

# ---------------------------------------------------------------- substitute helpers
REPO_NAME="$(basename "$(pwd)")"
TODAY="$(date -u +%Y-%m-%d)"

if [ "$VISIBILITY" = "public" ]; then
  TEMPLATE_VARIANT="_TEMPLATE-public.md"
  CLAUDE_SECTION_VARIANT="claude-md-section-public.md"
  PRIVACY_NOTE="**Public repo** — sanitization is mandatory. Run \`~/.claude/skills/incident-workflow/references/privacy-gate.md\` checklist before every save."
else
  TEMPLATE_VARIANT="_TEMPLATE-private.md"
  CLAUDE_SECTION_VARIANT="claude-md-section-private.md"
  PRIVACY_NOTE="**Private repo** — full forensic detail OK. See \`~/.claude/skills/incident-workflow/references/privacy-gate.md\` for the never-include list."
fi

# Render templates with substitutions
render() {
  local source_file="$1"
  sed \
    -e "s#{{REPO_NAME}}#${REPO_NAME}#g" \
    -e "s#{{INCIDENTS_PATH}}#${INCIDENTS_PATH}#g" \
    -e "s#{{VISIBILITY}}#${VISIBILITY}#g" \
    -e "s#{{TEMPLATE_PATH}}#${INCIDENTS_PATH}_TEMPLATE.md#g" \
    -e "s#{{CROSS_REF_TARGETS}}#HANDOFF.md, INDEX.md, docs/specs/, docs/decisions.md#g" \
    -e "s#{{PRIVACY_NOTE}}#${PRIVACY_NOTE}#g" \
    -e "s#YYYY-MM-DD#${TODAY}#g" \
    "$source_file"
}

# ---------------------------------------------------------------- writes
log "Writes:"

# 1. README index
write_or_skip "incidents README" \
  "${INCIDENTS_PATH}README.md" \
  "$(render "${SKILL_DIR}/templates/README-index.md")"

# 2. Per-incident template (local copy; users can later switch to skill: pointer)
write_or_skip "incidents _TEMPLATE.md" \
  "${INCIDENTS_PATH}_TEMPLATE.md" \
  "$(cat "${SKILL_DIR}/templates/${TEMPLATE_VARIANT}")"

# 3. Per-repo config
CONFIG_BODY=$(cat <<EOF
---
skill: incident-workflow
skill_version: 0.1.0
bootstrapped: ${TODAY}
---

# Incident workflow config (per-repo)

- **repo_visibility**: ${VISIBILITY}
- **incidents_path**: ${INCIDENTS_PATH}
- **template_path**: ${INCIDENTS_PATH}_TEMPLATE.md
- **severity_ladder**: default (P0..P3)
- **cross_ref_targets**: HANDOFF.md, INDEX.md, docs/specs/, docs/decisions.md

## Bootstrap notes

- Scaffolded by the \`incident-workflow\` skill on ${TODAY}.
- Bump \`skill_version\` + re-read \`~/.claude/skills/incident-workflow/SKILL.md\` after upstream changes.
- To migrate to the skill's canonical template (so upstream improvements flow in automatically), change \`template_path\` to \`skill:incident-workflow/templates/${TEMPLATE_VARIANT}\` and delete the local copy.
EOF
)
write_or_skip "per-repo config" \
  ".claude/incident-config.md" \
  "${CONFIG_BODY}"

# 4. CLAUDE.md section (append if file exists, marker missing)
if [ "$TOUCH_CLAUDE_MD" = "true" ]; then
  CLAUDE_SECTION_BODY="$(render "${SKILL_DIR}/templates/${CLAUDE_SECTION_VARIANT}")"
  append_if_missing "CLAUDE.md incident section" \
    "CLAUDE.md" \
    "## Incident reports (binding)" \
    "${CLAUDE_SECTION_BODY}"
fi

# 5. INDEX.md row (only if INDEX.md exists)
INDEX_ROW="| Incident reports | \`${INCIDENTS_PATH}\` | Forensic post-mortems for real defects. Trigger rule + workflow defined in \`CLAUDE.md\` §\"Incident reports (binding)\". Index at \`${INCIDENTS_PATH}README.md\`. |"
append_if_missing "INDEX.md incidents row" \
  "INDEX.md" \
  "${INCIDENTS_PATH}\` | Forensic post-mortems" \
  "${INDEX_ROW}"

# 6. HANDOFF.md note
HANDOFF_NOTE="<!-- incident-workflow installed via skill on ${TODAY}; see .claude/incident-config.md -->"
append_if_missing "HANDOFF.md skill-install note" \
  "HANDOFF.md" \
  "incident-workflow installed via skill" \
  "${HANDOFF_NOTE}"

# ---------------------------------------------------------------- summary
log ""
log "Done."
if [ "$DRY_RUN" = "true" ]; then
  log "(dry-run: no files were written. Re-run without --dry-run to apply.)"
else
  log "Next: when a defect investigation crosses the trigger rule, copy"
  log "${INCIDENTS_PATH}_TEMPLATE.md to ${INCIDENTS_PATH}\$(date -u +%Y-%m-%d)-<slug>.md"
  log "and follow the workflow in ~/.claude/skills/incident-workflow/WORKFLOW.md"
fi
