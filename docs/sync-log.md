# Dotfiles sync log

Append-only record of Claude-assisted sync sessions. Each entry logs
what changed and when. Read by Claude at the start of each sync for
context.

---

## [2026-04-16] sync

Config:
  - re-add Zed settings.json (removed agent_servers block, absorbed local edits)
  - chezmoi apply deployed all pending repo changes (fish config, starship, lib.sh, dotfiles CLI, completions, Claude config)

Brewfile:
  - added tap: hashicorp/tap
  - added brew: chezmoi, mdq, certbot, hashicorp/tap/vault, colima, docker, docker-compose, docker-credential-helper, sentencepiece
  - added cask: codex, chrysalis, disk-inventory-x, google-cloud-sdk, lunar, monitorcontrol, skype, zen-browser
  - skipped legacy packages already superseded (htop->btop, hub->gh, z->zoxide, pipx->uv, youtube-dl->yt-dlp, etc.)

VS Code extensions:
  - synced to match installed: added openai.chatgpt, removed 4 uninstalled (docker.docker, dwarvesf.md-ar-ext, ms-vsliveshare.vsliveshare, ocamllabs.ocaml-platform)

Fish functions:
  - tracked 4 unmanaged: keychain_env.fish, keychain_set.fish, op_env.fish, web3_env.fish

Secrets:
  - CLOUDFLARE_API_TOKEN already registered in secrets.toml, resolved from 1Password at apply time

---

## [2026-04-14] sync

Config:
  - re-add Zed settings.json (MCP server changes, local edits absorbed)

VS Code extensions:
  - add 5: docker.docker, dwarvesf.md-ar-ext, ms-vsliveshare.vsliveshare, ocamllabs.ocaml-platform, openai.openai-chatgpt-adhoc

Fish functions:
  - removed 5 orphaned standalone functions from machine (add-secret, dfe, dfs, list-secrets, rm-secret)  - consolidated into dotfiles subcommands

Brew/casks: deferred to next sync

---
