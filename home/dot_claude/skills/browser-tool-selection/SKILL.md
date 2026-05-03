---
name: browser-tool-selection
description: Use BEFORE reaching for any browser-automation tool. Picks the right tool for the situation: `/chrome` or `/edge-up` for logged-in SaaS (Notion, Gmail, Drive, Airwallex, Xero, Google Cloud Console), Playwright CLI for repeatable scripted replay (monthly payroll/recon/report pulls), `agent-browser --engine lightpanda` or `lightpanda fetch` for stateless headless reads of public pages, `chrome-devtools-mcp` for page performance / Lighthouse / network debugging, Browserbase MCP for unattended cloud / anti-bot work. Symptoms include "open this in a browser", "scrape this page", "automate this site", "fill this form", "log into ...", "click through ...", "headless browser", "what tool should I use to drive this site". Always check for an API or CLI first (API-first principle); browser is the last resort.
---

# Browser tool selection

When you genuinely need a browser, pick the right one. Distilled from the May 2026 audit + empirical Lightpanda + Playwright validation.

## Quick decision

| Situation | Tool |
|---|---|
| Logged-in SaaS, ad-hoc, agent-driven (Notion, Gmail, Drive, Airwallex, Xero, banking, OAuth) | `/chrome` (default) |
| Logged-in SaaS, ad-hoc, no Chrome extension available | `/edge-up` + `agent-browser connect` |
| Repeatable scripted flow with login state (monthly payroll, recon, report pulls) | Playwright CLI + `--user-data-dir` (capture via `/playwright-record`) |
| Reproducible flow, no login needed | Playwright CLI with storage-state JSON |
| Stateless headless read of public page (status, rate cards, RSS-less polling) | `lightpanda fetch` or `AGENT_BROWSER_ENGINE=lightpanda agent-browser ...` |
| Page performance / network trace / Lighthouse audit / memory snapshot | `chrome-devtools-mcp` |
| Unattended cloud, heavy anti-bot, parallel scraping | Browserbase MCP |
| Cloudflare dashboard click-through | **Stop. Use the Cloudflare API.** See `cloudflare-tool-selection` skill. |
| Google Cloud Console | `/chrome` only. Never cloud browsers (Google flags cloud IPs). |
| Anything with an API or CLI | Use the API/CLI, not a browser. |

## Why /chrome wins for most logged-in tasks

- Uses the user's real Chrome with their real session. Already logged into everything.
- Pauses on CAPTCHA / 2FA prompts and lets the user handle them. Doesn't try to script the unscriptable.
- Lowest detection risk: real local IP, real session, real fingerprint.
- Zero setup beyond installing the Claude in Chrome extension once.

## When `/edge-up` is the answer instead

`agent-browser`-via-CDP is functionally equivalent to `/chrome` for "drive my real session" tasks, with one operational difference: Edge has to be launched with the debug port. `/edge-up` (slash command at `~/.claude/commands/edge-up.md`) automates that — the launcher logic is inlined into the slash command (no external script).

Use `/edge-up` when:
- The Chrome extension isn't installed or isn't binding to the current Claude Code session.
- The user wants Edge-driven flows (e.g., a separate browser identity).

Verified May 2026 against notion.so: returned the user's actual Google identity prompt. Real session, full state.

## When agent-browser is actually better than `/chrome`

Three cases:

1. Scripting a flow that will be re-run, where a separate profile keeps the script portable from the user's main browser state.
2. Touching a service the user hasn't logged into in their main browser and doesn't want to (throwaway accounts).
3. Running unattended later via cron / scheduler.

When `agent-browser open <url>` is called with no prior `connect`, it spawns the bundled Chrome for Testing into a fresh temp profile.

## When Playwright CLI is the answer (scripted replay)

`/chrome` and `/edge-up` are agent-driven: every run burns tokens to re-decide what to click. For monthly ops cycles where steps never change, `playwright codegen` captures the flow once, `playwright test` replays it forever at zero per-run agent cost.

Decision rule: **agent-driven exploration → `/chrome` or `/edge-up`; deterministic scripted replay → Playwright CLI.**

Capture a flow:

```bash
npx playwright codegen \
  --browser=chromium \
  --user-data-dir="$HOME/Library/Application Support/Google/Chrome" \
  https://target.example.com
```

Save the generated `.spec.ts` under `infra/scripts/browser-flows/<flow-name>.spec.ts` in the relevant repo. Replay on demand or via cron:

```bash
npx playwright test infra/scripts/browser-flows/<flow-name>.spec.ts --headed
```

Convenience: invoke the `playwright-record` skill or the `/playwright-record` slash command (`~/.claude/commands/playwright-record.md`) to wrap codegen with the right flags.

Why CLI not MCP: `@playwright/mcp` is enabled but burns ~4x the tokens for the same task (Microsoft's own benchmark, Feb 2026). For repeatable scripted flows the CLI shape is the right tool; the MCP plugin remains available for one-off exploratory composition.

## When chrome-devtools-mcp is the answer (debug visibility)

Google's `chrome-devtools-mcp` is **orthogonal** to driving. It exposes Lighthouse audits, network/request replay, memory snapshots, and performance traces. Use it when an agent needs to understand why a page misbehaved, not to click on it.

Install (once):

```bash
claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp@latest
```

After install, restart Claude Code, then `/mcp` should list `chrome-devtools`. Coexists with `claude-in-chrome` and Playwright; no CDP attachment conflict in normal use.

## When Lightpanda is the answer (stateless headless reads)

`agent-browser` v0.26+ supports Lightpanda as an alternative engine via the `AGENT_BROWSER_ENGINE=lightpanda` env var. Lightpanda is a Zig-built headless browser optimised for AI agents: ~31 MB resident vs Chrome's 2 GB (verified locally). Two usage shapes:

1. **Direct fetch** (`lightpanda fetch --dump html <url>`) — simplest and fastest for one-shot HTML reads, no agent-browser daemon needed.
2. **Via agent-browser** (`AGENT_BROWSER_ENGINE=lightpanda agent-browser open <url>`) — when you need agent-browser's command surface (snapshot/refs/click).

Decision rule: **stateless headless reads of public pages → Lightpanda. Logged-in flows or modern SPAs → stay on Chrome/Edge.**

When Lightpanda is the right tool:

- Health checks and uptime probes (status pages, public dashboards).
- Rate-card scrapes and pricing-page polling.
- Fetching rendered HTML for agent context where Playwright headless Chrome would be overkill.
- Future Mac Mini scheduled jobs needing a browser without auth.

When Lightpanda is the **wrong** tool (verified empirically May 2026):

- **Notion** — crashes with `Application error: a client-side exception has occurred` (`TypeError: e.close is not a function`, Sentry + Next.js init failures). Service workers + heavy SPA.
- **Gmail, Capacities** — same service-worker dependency, assume broken until proven otherwise.
- **Airwallex, Xero, modern SPA stacks** — limited heavy-framework compatibility.
- **Anything requiring login-session reuse** — no profile-dir story; stateless by design.

Install (no Homebrew formula yet; persisted via dwarvesf/dotfiles `.chezmoiscripts/run_onchange_after_install-lightpanda.sh.tmpl`):

```bash
mkdir -p ~/.local/bin
curl -fL -o ~/.local/bin/lightpanda \
  https://github.com/lightpanda-io/browser/releases/download/nightly/lightpanda-aarch64-macos
chmod +x ~/.local/bin/lightpanda
~/.local/bin/lightpanda help   # sanity check (no --version flag exists)
```

Smoke tests:

```bash
# Direct fetch (preferred for stateless reads)
~/.local/bin/lightpanda fetch --dump html --strip-mode full https://example.com

# Via agent-browser (when you need its command surface)
AGENT_BROWSER_ENGINE=lightpanda agent-browser open https://example.com
agent-browser get title   # expect: "Example Domain"

# Negative smoke: confirms the SPA caveat is real
~/.local/bin/lightpanda fetch --dump html https://notion.so | head -5
# Expect: "Application error: a client-side exception has occurred"
```

Port conflict warning: Lightpanda's `serve` mode binds to `127.0.0.1:9222` by default — the **same port** `/edge-up` uses for Edge CDP. Do not run `lightpanda serve` and `/edge-up` simultaneously. If you need both, pass `lightpanda serve --port=<other>`.

## When cloud browsers (Browserbase) earn their place

Narrow cases:

- Anti-bot sites that block residential IPs and need rotating proxies.
- High-volume scraping where local Chrome would melt the laptop.
- A scheduled agent on a server with no display.

Never for Google services. Cloud IPs trigger "unusual activity" hell.

Install:

```bash
claude mcp add --transport http browserbase \
  "https://mcp.browserbase.com/mcp?browserbaseApiKey=$BROWSERBASE_API_KEY"
```

## Setup commands

### `/chrome` (one-time)

```bash
# Install the Claude in Chrome extension from Chrome Web Store
# Pin it, sign in with Claude credentials
# Then in any Claude Code session:
/chrome
# Pick "Enabled by default" if you want it on always
```

### `agent-browser`

```bash
brew install agent-browser    # preferred (per dwarvesf/dotfiles Brewfile)
# or: npm install -g agent-browser
agent-browser install         # downloads Chrome for Testing
```

## Anti-pattern

Reaching for any browser tool on a service that has an API. If Cloudflare, GitHub, AWS, GCP (the API surface), or any standard SaaS is involved, check for an API or CLI first. Browser is the last resort, not the first.

## Related

- Tool-selection rule: `~/.claude/CLAUDE.md` "Tool selection" section (always-loaded global)
- Cloudflare-specific picks: `cloudflare-tool-selection` skill
- Capture a Playwright flow: `playwright-record` skill or `/playwright-record` slash command
- dfoundation flows folder: `infra/scripts/browser-flows/README.md`
