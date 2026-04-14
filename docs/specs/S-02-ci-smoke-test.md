---
id: S-02
title: CI smoke test
type: feature
status: done
old_id: F-02
---

### Problem
No automated testing. Config changes might break `chezmoi apply` on a fresh machine and you won't know until you actually set up a new Mac.

### Spec
Create `.github/workflows/test.yml`:

```yaml
name: dotfiles-test
on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 9 * * 1'  # weekly Monday 9am UTC

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install chezmoi
        run: brew install chezmoi
      - name: Link source
        run: |
          mkdir -p ~/.local/share
          ln -sf $GITHUB_WORKSPACE/home ~/.local/share/chezmoi
      - name: Dry run (no 1Password)
        run: |
          chezmoi init --data=false --no-tty <<EOF
          {
            "name": "CI Test",
            "email": "ci@test.com",
            "editor": "vim",
            "use_1password": false
          }
          EOF
          chezmoi apply --dry-run --verbose
      - name: Validate managed files
        run: chezmoi managed | head -50
      - name: Check templates render
        run: chezmoi execute-template '{{ .chezmoi.os }}' | grep darwin
```

Rules:
- Must work WITHOUT 1Password (set `use_1password: false` in test data)
- Must NOT actually apply (dry-run only) since we can't install all casks in CI
- Template rendering errors should fail the build
- Weekly schedule catches upstream breakage (e.g., chezmoi version bumps)

### Files to create
- `.github/workflows/test.yml`

### Test
Push to a branch, verify the Action runs green.
