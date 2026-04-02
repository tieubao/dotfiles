# ADR-002: Fish over Zsh

## Status: accepted

## Context
Needed a daily-driver shell that is fast, has good defaults out of the box, and doesn't require a framework (Oh My Zsh, Prezto) to be usable.

## Decision
Use Fish as the default interactive shell.

## Alternatives considered
- **Zsh + Oh My Zsh**: The popular choice, but OMZ adds 55%+ startup time with synchronous plugin loading. Requires careful plugin management to stay fast. Most of what OMZ provides (syntax highlighting, autosuggestions, completions) Fish has built in.
- **Zsh + Prezto**: Faster than OMZ but still a monolithic framework. Better architecture but same fundamental issue: you're bolting features onto a shell that doesn't have them natively.
- **Zsh (bare)**: Fast but then you're manually configuring autosuggestions, syntax highlighting, completions, and history search. At that point you're rebuilding Fish.
- **Bash**: Excellent for scripts, painful for interactive use. No autosuggestions, weak completions.

## Consequences
- Shell scripts that need POSIX compatibility still use `#!/bin/bash`
- Fish functions auto-load from `~/.config/fish/functions/` (one function per file)
- Fish plugins managed via `.chezmoiexternal.toml` URLs, no plugin manager needed
- Some tools (nvm, virtualenv activate) need Fish-specific wrappers or alternatives (mise handles this)
