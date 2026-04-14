---
id: S-08
title: SSH config hardening
type: feature
status: done
old_id: F-08
---

# SSH config hardening

### Problem
SSH config with 1Password SSH Agent needs specific settings to be secure and functional. Missing `IdentitiesOnly yes` can leak key identifiers. Missing `Include` pattern makes the config monolithic.

### Spec
Restructure `home/dot_ssh/config.tmpl` to use a modular include pattern:

```ssh-config
# ~/.ssh/config (managed by chezmoi)

# Global defaults
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

{{ if .use_1password }}
# 1Password SSH Agent
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
{{ end }}

# Include modular configs
Include config.d/*
```

Create `home/dot_ssh/config.d/` directory for per-context SSH configs:

```
home/dot_ssh/
  config.tmpl            # main config (above)
  config.d/
    personal.tmpl        # personal servers
    work.tmpl            # Dwarves servers
```

### Rules
- `IdentitiesOnly yes` is mandatory when using 1Password SSH Agent. Without it, SSH tries all keys and the agent might expose key identifiers to hostile servers.
- `Include config.d/*` must come after the global `Host *` blocks
- Each file in `config.d/` should have `private_` prefix in chezmoi (mode 0600)
- The `config.d/` directory must exist even if empty (create with `.gitkeep` or chezmoi `create_` prefix)

### Files to modify/create
- `home/dot_ssh/config.tmpl` (restructure)
- `home/dot_ssh/config.d/` (new directory with sample files)
