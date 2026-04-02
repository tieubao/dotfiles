# ADR-005: No plugin manager for Fish

## Status: accepted

## Context
Fish plugins (syntax highlighting extensions, completions, themes) are typically managed by Fisher, Oh My Fish, or plug.fish. These add a dependency and their own update lifecycle on top of the shell.

## Decision
Manage Fish plugins as direct GitHub URL downloads via chezmoi's `.chezmoiexternal.toml`. No plugin manager.

## Alternatives considered
- **Fisher**: The most popular Fish plugin manager. Lightweight, but it's another tool to install, update, and debug. Its `fish_plugins` file is another config to track.
- **Oh My Fish**: Framework approach for Fish. Adds startup overhead and complexity for what amounts to downloading a few files from GitHub.
- **plug.fish**: Minimal plugin manager. Better than OMF but still an unnecessary layer when chezmoi already handles file downloads.

## How it works
```toml
# .chezmoiexternal.toml
[".config/fish/functions/fzf_key_bindings.fish"]
type = "file"
url = "https://raw.githubusercontent.com/.../functions/fzf_key_bindings.fish"
refreshPeriod = "720h"  # 30 days
```

chezmoi downloads the file, caches it, and refreshes on the configured interval. `chezmoi apply --refresh-externals` forces a re-download.

## Consequences
- Adding a plugin means adding a URL entry to `.chezmoiexternal.toml`
- No plugin manager to install or bootstrap
- Updates happen on `chezmoi apply` based on refresh period
- Slightly more manual than Fisher but one fewer dependency in the chain
