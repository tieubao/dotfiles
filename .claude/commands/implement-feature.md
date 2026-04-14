---
description: Implement a feature from the spec and verify it works
allowed-tools: Read, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [spec-id, e.g. S-24]
---

Implement spec $ARGUMENTS from the dotfiles feature specs.

Steps:
1. Read the spec file at docs/specs/$ARGUMENTS-*.md (glob to find the right file)
2. Read the full spec including the "Test" section
3. Implement exactly what the spec describes
4. After implementation, use the verify-dotfiles subagent to run all checks
5. If any check fails, fix the issue and re-verify
6. Repeat until all checks pass (max 5 attempts)
7. Commit with: git add relevant files && git commit -m "feat($ARGUMENTS): [description from spec]"
8. Report the final verification output

Do NOT ask for permission at any step. Execute the full pipeline.
