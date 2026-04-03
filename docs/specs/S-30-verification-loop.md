---
id: S-30
title: Verification loop
type: infra
status: planned
old_id: F-16
---

# Autonomous implement-test-fix loop

### Problem

After giving Claude Code a feature spec, the current workflow is: implement, report, user tests manually, finds issues, asks Claude Code to fix, repeat 3-5 times. This wastes 15-30 minutes per feature on human-in-the-loop testing that Claude Code could do itself.

### Spec

Four files to create/modify. Each has a specific scope.

---

### Part A: Project CLAUDE.md additions

**File:** `CLAUDE.md` (append to existing, do not replace)

Add this section to the existing CLAUDE.md in the dwarvesf/dotfiles repo:

```markdown
## Verification rules

After implementing any feature from docs/feature-specs.md or docs/feature-specs-addendum.md:

### Mandatory self-check (do NOT skip)
1. Run the relevant verification commands (see table below)
2. If ANY check fails, fix the issue and re-run
3. Repeat until all checks pass or you've made 5 fix attempts
4. Do NOT ask the user to verify. Run verification yourself.
5. Only report back when all checks are green, or when you've hit the 5-attempt limit and need human help
6. When reporting, include the actual test output, not a summary of what you think happened

### Verification commands by file type

| File pattern | Command | What it checks |
|-------------|---------|---------------|
| `*.sh` | `shellcheck --severity=warning FILE` | Shell script lint |
| `*.fish` | `fish -n FILE` | Fish syntax check |
| `*.tmpl` | `chezmoi execute-template < FILE > /dev/null` | Template rendering |
| `home/dot_Brewfile*` | `chezmoi apply --dry-run 2>&1 \| head -50` | Brewfile validity |
| Any chezmoi file | `chezmoi apply --dry-run --verbose 2>&1 \| tail -20` | Full dry run |
| `install.sh` | `bash -n install.sh && shellcheck install.sh` | Syntax + lint |
| `lib/ui.sh` | `bash -n lib/ui.sh && shellcheck lib/ui.sh` | Syntax + lint |

### After every feature implementation
Run the full verification suite:
```bash
# 1. Lint all shell scripts
find . -name "*.sh" -not -path "./.git/*" | xargs shellcheck --severity=warning

# 2. Syntax check all fish files
find home -name "*.fish" | while read f; do fish -n "$f" || echo "FAIL: $f"; done

# 3. Dry run chezmoi
chezmoi apply --dry-run 2>&1 | tail -20

# 4. Check managed file list is not empty
test $(chezmoi managed | wc -l) -gt 10 || echo "FAIL: too few managed files"
```

### Git workflow
- Commit each feature separately with conventional commit format
- Commit message: `feat(F-XX): short description`
- Do NOT batch multiple features into one commit
- Run verification BEFORE committing, not after
```

---

### Part B: User CLAUDE.md (global preferences)

**File:** `~/.claude/CLAUDE.md`

This applies to ALL projects, not just dotfiles. Create or append:

```markdown
## Self-verification rules (all projects)

- After implementing a change, ALWAYS verify it works before reporting success
- If a test command exists in the project (npm test, pytest, go test, shellcheck, etc.), run it
- If tests fail, fix and re-run. Do not report "done" with known failures.
- Maximum 5 fix attempts before escalating to the user
- When reporting results, show the actual command output, not "all tests passed"
- Never say "I believe this should work" or "this looks correct". Run the command.

## Commit style
- Use conventional commits: feat(), fix(), docs(), refactor(), test(), chore()
- One logical change per commit
- If a feature requires multiple files, that's fine in one commit. But separate features get separate commits.

## When implementing from specs
- Read the full spec before starting
- Implement exactly what the spec says, no creative additions
- If the spec is ambiguous, ask before guessing
- After implementation, check the spec's "Test" section and run those exact tests
```

---

### Part C: Subagent for dotfiles verification

**File:** `.claude/agents/verify-dotfiles.md`

```markdown
---
name: verify-dotfiles
description: QA agent for dotfiles repo. Use PROACTIVELY after implementing any feature. Runs shellcheck, fish syntax, chezmoi dry-run, and file existence checks.
tools: Bash, Read, Grep, Glob
model: sonnet
---

You are a QA engineer for the dwarvesf/dotfiles repository.

When invoked, run ALL of these checks and report results as a checklist.

## Checks

### 1. Shell script lint
Run shellcheck on every .sh file:
```
find . -name "*.sh" -not -path "./.git/*" -exec shellcheck --severity=warning {} \;
```

### 2. Fish syntax
Syntax-check every .fish file:
```
find home -name "*.fish" -exec fish -n {} \;
```

### 3. chezmoi template rendering
Dry run to catch template errors:
```
chezmoi apply --dry-run 2>&1
```

### 4. File existence
Check that key files exist:
- install.sh
- lib/ui.sh
- CLAUDE.md
- home/.chezmoi.toml.tmpl
- home/dot_Brewfile.tmpl
- home/dot_config/fish/config.fish.tmpl
- home/dot_config/ghostty/config

### 5. Managed file count
```
MANAGED=$(chezmoi managed | wc -l | tr -d ' ')
echo "Managed files: $MANAGED"
test "$MANAGED" -gt 10
```

## Report format

```
Dotfiles verification
=====================

[ok] shellcheck: 8/8 scripts passed
[ok] fish syntax: 12/12 files passed
[FAIL] chezmoi dry-run: template error in dot_gitconfig.tmpl line 5
[ok] file existence: all key files present
[ok] managed files: 47

Result: 4/5 checks passed. See failures above.
```

Be specific about failures. Include the file path, line number, and actual error message. Do not summarize or paraphrase error output.
```

---

### Part D: Hooks for auto-linting on edit

**File:** `.claude/settings.json`

Merge into existing settings (do not replace the whole file):

```json
{
  "permissions": {
    "allow": [
      "Edit",
      "MultiEdit",
      "Read",
      "Bash(shellcheck *)",
      "Bash(fish -n *)",
      "Bash(chezmoi apply --dry-run *)",
      "Bash(chezmoi execute-template *)",
      "Bash(chezmoi managed *)",
      "Bash(chezmoi diff *)",
      "Bash(find *)",
      "Bash(wc *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(cat *)",
      "Bash(test *)",
      "Bash(git diff *)",
      "Bash(git status *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git log *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(chezmoi apply)",
      "Bash(brew *)",
      "Bash(curl *)",
      "Bash(sudo *)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "bash -c 'INPUT=$(cat); FILE=$(echo \"$INPUT\" | jq -r \".tool_input.file_path // empty\" 2>/dev/null); if [[ -z \"$FILE\" ]]; then exit 0; fi; EXT=\"${FILE##*.}\"; case \"$EXT\" in sh) shellcheck --severity=warning \"$FILE\" 2>&1 | head -10 ;; fish) fish -n \"$FILE\" 2>&1 ;; esac'"
      }
    ]
  }
}
```

Key decisions in the permissions:
- `allow`: all read/lint/verify commands + git operations. Claude Code can run these without asking.
- `deny`: destructive operations. `chezmoi apply` (without --dry-run) is denied because we want dry-run only during development. `brew` is denied to prevent accidental installs. `curl` and `sudo` for safety.
- The PostToolUse hook runs shellcheck on .sh files and fish -n on .fish files automatically after every edit. Claude sees the output immediately and self-corrects.

---

### Part E: Slash command for running the full spec

**File:** `.claude/commands/implement-feature.md`

```markdown
---
description: Implement a feature from the spec and verify it works
allowed-tools: Read, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [feature-id, e.g. F-13]
---

Implement feature $ARGUMENTS from the dotfiles feature specs.

Steps:
1. Read docs/feature-specs.md and docs/feature-specs-addendum.md
2. Find the section for $ARGUMENTS
3. Read the full spec including the "Test" section
4. Implement exactly what the spec describes
5. After implementation, use the verify-dotfiles subagent to run all checks
6. If any check fails, fix the issue and re-verify
7. Repeat until all checks pass (max 5 attempts)
8. Commit with: git add -A && git commit -m "feat($ARGUMENTS): [description from spec]"
9. Report the final verification output

Do NOT ask for permission at any step. Execute the full pipeline.
```

Usage:
```
claude> /implement-feature F-13
```

Claude Code reads the spec, implements, verifies via subagent, fixes, re-verifies, commits. You watch.

---

### How the pieces work together

```
User types: /implement-feature F-13
                |
                v
    Slash command reads spec
                |
                v
    Claude Code implements (Edit files)
                |
                v
    PostToolUse hook auto-runs shellcheck/fish -n
    (Claude sees lint errors immediately, fixes inline)
                |
                v
    Claude Code spawns verify-dotfiles subagent
                |
                v
    Subagent runs full check suite
    Returns checklist with pass/fail
                |
                v
    If failures: Claude Code fixes + re-spawns subagent
    If all pass: Claude Code commits
                |
                v
    Reports final state to user
```

The user's role: type `/implement-feature F-13`, watch the output scroll, review the final commit.

### Files to create

- `.claude/agents/verify-dotfiles.md` (Part C)
- `.claude/settings.json` (Part D, merge with existing)
- `.claude/commands/implement-feature.md` (Part E)

### Files to modify

- `CLAUDE.md` (Part A, append verification rules section)
- `~/.claude/CLAUDE.md` (Part B, user-level, create if not exists)

### Test

1. Open Claude Code in the dotfiles repo
2. Type `/implement-feature F-05` (Fish dotfiles command, moderate complexity)
3. Watch: Claude should implement, auto-lint via hook, run subagent verification, fix issues, and commit
4. Check git log: should see a clean conventional commit
5. Run `chezmoi apply --dry-run` manually to double-check
