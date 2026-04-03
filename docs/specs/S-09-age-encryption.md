---
id: S-09
title: Age encryption
type: feature
status: done
old_id: F-09
---

# Age encryption for sensitive files

### Problem
Some files are too complex for template injection (e.g., kubeconfig with multiple contexts, VPN configs, certificate bundles) but too sensitive for plaintext in git. 1Password `op://` works for single values, not entire files.

### Spec
Set up chezmoi's age encryption:

1. Generate an age key (one-time, manual):
```bash
age-keygen -o ~/.config/chezmoi/key.txt
```

2. Configure chezmoi to use it in `home/.chezmoi.toml.tmpl`:
```toml
encryption = "age"

[age]
identity = "~/.config/chezmoi/key.txt"
recipient = "age1..." # from key.txt public key
```

3. Add encrypted files with:
```bash
chezmoi add --encrypt ~/.kube/config
# creates home/encrypted_dot_kube/config.age
```

### Rules
- `~/.config/chezmoi/key.txt` must NEVER be in git. Add to `.gitignore`.
- Document the backup procedure for the age key (store in 1Password as a Secure Note)
- Add `age` to `Brewfile.base`
- Document in README how to add/decrypt files
- The age key is machine-specific. On a new machine, retrieve from 1Password and place at the expected path before `chezmoi apply`.

### Files to modify
- `home/.chezmoi.toml.tmpl` (add age encryption config)
- `.gitignore` (add `key.txt` pattern)
- `README.md` (add "Encrypted files" section)
- `Brewfile.base` (add `age`)
