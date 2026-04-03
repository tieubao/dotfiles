---
id: S-12
title: Tag v0.1.0 release
type: feature
status: done
old_id: F-12
---

# Tag v0.1.0 release

### Problem
No versioning. Can't rollback if a change breaks the setup.

### Spec
Once Phase 1 and Phase 2 features are merged and tested:

```bash
git tag -a v0.1.0 -m "Initial stable release: Fish + Ghostty + chezmoi + 1Password"
git push origin v0.1.0
```

Also create a GitHub Release with a changelog summarizing what's included.

### Rules
- Only tag after at least one successful fresh-machine test
- Changelog should list: tools included, what install.sh does, known limitations
- Future changes should be tagged incrementally (v0.2.0 for new features, v0.1.1 for fixes)

### Files to create
- None (git tag operation)
- Optional: `CHANGELOG.md` at repo root
