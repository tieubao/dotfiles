# ADR-001: chezmoi over GNU Stow

## Status: accepted

## Context
Needed a dotfiles manager that supports secret injection (1Password), machine-specific config via templates, and safe public repos (no plaintext secrets ever).

## Decision
Use chezmoi as the dotfiles manager.

## Alternatives considered
- **GNU Stow**: Simple symlink farm. No templates, no secrets, no conditional config per machine. Works fine for a single laptop with no secrets in the repo, but falls apart when you need different configs for work vs personal or want API keys injected at apply time.
- **yadm**: Git wrapper with Jinja2 templates. Template engine depends on unmaintained external tools (envtpl, j2cli). chezmoi uses Go's standard text/template, no extra dependencies.
- **Nix Home Manager**: Full reproducibility but requires learning the Nix language. Overkill when the goal is dotfiles, not system-level package management. The learning curve doesn't justify itself for config file management.
- **Bare git repo**: No template support, no secret injection, easy to accidentally commit sensitive files.

## Consequences
- All configs live in `home/` with chezmoi filename conventions (`dot_`, `.tmpl`, `private_`)
- Secrets use `onepasswordRead` template function, never stored in git
- Contributors need to learn chezmoi basics (apply, edit, diff)
- Repo is safe to make public
