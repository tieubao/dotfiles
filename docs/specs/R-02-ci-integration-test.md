# R-02: Upgrade CI from dry-run to real integration test

**Priority:** High
**Status:** Done
**Related:** F-02 in feature-specs.md

## Problem

Current CI (`.github/workflows/test.yml`) runs `chezmoi apply --dry-run`, which catches template syntax errors but misses:
- Scripts that assume interactive TTY (`chsh` in `run_once_after_setup-fish-shell.sh` requires password)
- Missing runtime dependencies (tools referenced in config but not installed)
- Permission errors on file deployment
- Scripts that silently fail with `2>/dev/null || true`

A dry-run is better than nothing, but it's a false sense of security.

## Spec

### Phase 1: Shellcheck in CI (quick win)

Add a shellcheck step to the existing workflow:

```yaml
- name: Lint shell scripts
  run: |
    brew install shellcheck
    # Check install.sh directly
    shellcheck install.sh
    # Check chezmoi scripts (render templates first, then lint)
    for f in home/.chezmoiscripts/*.sh*; do
      # Skip .tmpl files (shellcheck can't parse Go templates)
      case "$f" in *.tmpl) continue ;; esac
      shellcheck "$f"
    done
```

### Phase 2: Actual apply test (with guardrails)

Add a second job that does a real apply (not dry-run) in CI:

```yaml
test-macos-apply:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - name: Install chezmoi
      run: brew install chezmoi
    - name: Setup
      run: |
        mkdir -p ~/.local/share
        ln -sf "$GITHUB_WORKSPACE/home" ~/.local/share/chezmoi
        mkdir -p ~/.config/chezmoi
        cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
        [data]
          name = "CI Test"
          email = "ci@test.com"
          editor = "vim"
          use_1password = false
          op_account = ""
          op_vault = ""
        EOF
    - name: Apply (real, not dry-run)
      run: chezmoi apply --exclude=scripts  # Deploy files, skip scripts
    - name: Verify key files
      run: |
        test -f ~/.gitconfig
        test -f ~/.config/fish/config.fish
        test -f ~/.ssh/config
        test -f ~/.config/fish/conf.d/secrets.fish
        echo "All key files deployed successfully"
```

Using `--exclude=scripts` avoids the `chsh`/`brew bundle` problems while still testing file deployment and template rendering.

### Phase 3: Fresh-machine runbook (manual)

Document a manual test procedure in `docs/testing-runbook.md`:
1. Create a fresh macOS user account
2. Run `install.sh`
3. Verify checklist: fish is default shell, git identity set, SSH agent working, etc.

## Files to modify
- `.github/workflows/test.yml`

## Files to create
- `docs/testing-runbook.md` (Phase 3)

## Test
Push to branch, verify both CI jobs pass green.
