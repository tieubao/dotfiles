# ADR-004: 1Password for secrets management

## Status: accepted

## Context
Dotfiles repo must be safe to make public. API keys, tokens, and credentials cannot exist in plaintext in git. Need a way to inject secrets at `chezmoi apply` time.

## Decision
Use 1Password as the primary secrets backend via chezmoi's `onepasswordRead` template function. macOS Keychain as secondary for simple key-value secrets.

## Alternatives considered
- **Environment variables in .env files**: Still plaintext on disk. Easy to accidentally commit. No central management across machines.
- **git-crypt**: Encrypts files in the repo but requires GPG key management. Decrypted files are plaintext on disk after clone. Doesn't integrate with chezmoi templates.
- **SOPS**: Good for encrypting YAML/JSON config. Overkill for dotfiles where we just need individual values injected into templates.
- **macOS Keychain only**: Works but not cross-machine. No CLI-friendly way to bulk manage secrets. Used as secondary for simple cases.
- **age encryption**: Good for whole-file encryption (kubeconfig, VPN configs) but not for injecting individual values into templates. Complementary to 1Password, not a replacement.

## Consequences
- All `.tmpl` files with secrets use `{{ onepasswordRead "op://vault/item/field" }}` syntax
- Users must have 1Password CLI installed and authenticated
- `use_1password` flag in chezmoi config gates all secret sections for graceful degradation
- Secret rotation happens in 1Password, then `chezmoi apply` picks up new values
