---
name: cloudflare-tool-selection
description: Use BEFORE reaching for any Cloudflare tool. Cloudflare has one of the best APIs in the industry; reaching for a browser is almost always wrong. Picks the right tool: Cloudflare Developer MCP for Workers/D1/R2/KV/Hyperdrive/docs, `wrangler` in bash for deploys/tail/secrets/dev loops, Cloudflare API + curl for everything else (DNS, firewall, Zero Trust IdP, Access apps), Terraform only for codified IaC, `/chrome` only for genuinely browser-only steps (rare). Symptoms include "deploy a Worker", "add a DNS record", "set up Cloudflare Access", "create an IdP", "configure Zero Trust", "R2 bucket", "KV namespace", "I'm in the Cloudflare dashboard and need to ...", "Cloudflare API token". Anti-pattern: dashboard-tutorial framing ("go to Zero Trust > Team & Resources > ...").
---

# Cloudflare tool selection

Cloudflare has one of the best APIs in the industry. Reaching for a browser is almost always the wrong call.

## Quick decision

| Task | Tool |
|---|---|
| Worker deploy, R2 bucket, KV namespace, D1 query | Cloudflare Developer MCP |
| `wrangler tail`, `wrangler secret put`, dev loop | wrangler in bash |
| DNS records, firewall rules, page rules | Cloudflare API + curl |
| Zero Trust IdP, Access apps, Access policies | Cloudflare API + curl |
| Anything you'll do twice across multiple environments | Terraform |
| GCP OAuth client creation (no API exists) | `/chrome` |
| Cloudflare dashboard click-through | **Stop. There's an API.** |

## Tool-by-tool

### Cloudflare Developer MCP

Already loaded in Claude Code. 25 tools covering Workers, D1, R2, KV, Hyperdrive, plus `search_cloudflare_documentation` (excellent for getting unstuck). Zero setup.

Use for: anything in the developer platform proper. The MCP often beats wrangler for one-shot read/inspect tasks because Claude Code can call it directly without spawning a subprocess.

### wrangler in bash

```bash
wrangler deploy --env production
wrangler tail
wrangler secret put MY_SECRET
wrangler types
wrangler dev
```

Use for: anything the MCP doesn't expose, plus dev loops that need live reload.

### Cloudflare API + curl

The widest surface. Everything in Cloudflare is here. Use when MCP and wrangler don't cover it.

```bash
export CLOUDFLARE_API_TOKEN="..."
export ACCOUNT_ID="..."

curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/<resource>" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq
```

Token scopes worth remembering:

- `Access: Organizations, Identity Providers, and Groups Write` for IdP
- `Access: Apps and Policies Write` for app/policy changes
- `Workers Scripts Write` for worker deploys via API
- `DNS Write` for zone DNS changes

### Terraform (cloudflare provider)

Use only when:

- The user explicitly asked for IaC.
- The same config will run across multiple environments / accounts.
- The change is part of a larger codified infra repo.

Don't reach for Terraform on a one-shot task. The setup overhead beats the benefit.

### Browser (`/chrome`)

Last resort. Genuinely needed only when:

- The thing has no API (rare for Cloudflare).
- A truly dashboard-only beta feature.
- Account-level billing changes that have no API surface.

If reaching for a browser feels right, re-check whether an API exists. The Cloudflare docs explicitly tell LLMs to use the markdown API docs:

```
https://developers.cloudflare.com/<product>/llms-full.txt
```

Always check there before assuming "no API."

## The vps-mon case (May 2026 chat)

The original task description was dashboard-tutorial style:

> Zero Trust > Team & Resources > Authentication > Add Google
> Click toggle "Use Cloudflare's OAuth credentials"
> ...

That framing made it look like a browser job. The right framing was:

1. Cloudflare API supports IdP creation. Use it.
2. The "Use Cloudflare's OAuth credentials" toggle has no API equivalent. Skip it. Use the user's own OAuth client (10 min one-time GCP setup, reusable across all Cloudflare Access apps).
3. The only browser-required step is creating that GCP OAuth client. Use `/chrome` for it because Google + cloud browsers = pain.

Net: 90% of the work is curl. Browser is a 5-minute supporting role.

## Anti-patterns

- Asking the user to "go to the dashboard and click..." when an API exists.
- Setting up Terraform for a one-shot task.
- Using `agent-browser` or Browserbase to drive the Cloudflare dashboard. The API is right there.
- Using the dashboard "Use Cloudflare's OAuth credentials" toggle. It creates a hidden dependency you can't reproduce via API later.

## Related

- Tool-selection rule: `~/.claude/CLAUDE.md` "Tool selection" section (always-loaded global)
- Browser-specific picks (when a browser IS justified): `browser-tool-selection` skill
