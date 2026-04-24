---
id: S-46
title: Three-vault model for agent-infra secrets (Trading + Infra + Private split)
type: feature
status: proposed
date: 2026-04-24
---

# S-46: Three-vault model for agent-infra secrets

## Problem

S-42 shipped the 1P service account token model for agent subprocess auth. The `trading-agent` SA is scoped read-only to a single vault (`Trading`). This works for secrets that belong to the trading domain (exchange keys, broker keys, HMAC signing keys, webhook URLs).

But agent workflows increasingly touch **agent-infra secrets** that are neither trading-domain nor owner-personal:

- Cloudflare API Token (for `wrangler deploy` of vps-mon Worker, dashboard rollouts, future agent-driven redeploys).
- R2 access keys (for knowledge-capture image uploads; potentially trading-data sinks later).
- Deploy tokens for other services (Helius RPC, VPS provisioner keys, CI webhooks).

These currently live in the `Private` vault. They reach the agent only via fish env vars (chezmoi + Keychain cache at shell start, per S-35). When an agent workflow needs to **`op read`** them at runtime (not just inherit from env), the call fails: `Private` is deliberately outside SA scope by design of S-42.

Two naïve paths are wrong:

1. **Put CF + R2 in `Trading`.** Widens SA blast radius to cover deploy credentials. A compromised agent could push malicious Workers, poison the R2 bucket, or pivot to other Cloudflare resources. Violates the principle of least privilege that motivated S-42.
2. **Run a second service account scoped to `Private`.** Two SA tokens can't share one `OP_SERVICE_ACCOUNT_TOKEN` env var. Requires shell wrappers to pick per-read, which breaks S-42's "zero new code" property.

## Non-goals

- **Moving the SA's own token out of `Private`.** The SA must stay blind to its own storage (defense-in-depth: a compromised agent cannot self-persist or re-emit the token).
- **Adopting 1Password Environments.** Environments solve same-name-different-tier indirection; we use distinct names per tier (`binance-testnet` vs `binance-live`, `vps-mon-host-N`) and don't need tier indirection. Revisit only if we hit "5 live/testnet pairs with identical logical names".
- **Migrating owner-personal secrets** (passwords, authenticator backups, non-infra notes) out of `Private`. Private stays private.
- **Automated vault creation.** 1P vault + SA scope changes are web-UI operations. This spec assumes the owner performs them manually.

## Solution

Introduce a **third vault** for agent-infra secrets. Extend the `trading-agent` SA scope to `Trading + Infra` (both read-only). Owner-personal remains in `Private` (no SA access).

### Target layout

| Vault | Contents | SA scope | Rationale |
|---|---|---|---|
| `Trading` | Exchange keys, broker keys, HMAC signing keys, chat/webhook tokens | read-only | Trading-domain secrets |
| `Infra` (new) | Cloudflare API token, R2 access keys, future deploy/RPC credentials | read-only | Agent-infra; deploy-tier blast radius |
| `Private` | SA's own token, owner-personal items | **no SA access** | Defense-in-depth: SA cannot read own storage + protect owner-personal |

### Vault placement heuristic

For any new secret introduced going forward, decide by asking:

1. **Does the agent `op read` it at runtime?**
   - Yes → must be in SA scope (`Trading` or `Infra`).
   - No → can stay in `Private` (agent inherits value via fish env only; no vault read).
2. **Is it trading-domain?** (Exchange connection, strategy signals, portfolio accounting, alerting tied to a trading host.)
   - Yes → `Trading`.
   - No → `Infra`.
3. **Is it owner-personal?** (Passwords, backup codes, non-infra notes.)
   - Always `Private`, regardless of the above.
4. **Is it the SA's own token?**
   - Always `Private`. Never in a vault the SA can read.

### Why not a second service account

A second SA scoped to `Infra` alone would narrow each token's blast radius further. Rejected because:

- `op read` takes one `OP_SERVICE_ACCOUNT_TOKEN` per process. Picking between two at each call requires a wrapper that encodes vault→token mapping, new code in every call site, or a fish-function indirection. Violates S-42's zero-new-code property.
- Two SAs = two rotation cadences = two Keychain entries = more operational surface. Current scale doesn't warrant it.
- A compromise at `Infra` scope alone is still a full Cloudflare + R2 compromise. Marginal security benefit vs single-SA-with-Trading+Infra is low.

Revisit if: (a) a future deploy credential grants privileges orders of magnitude more dangerous than the current CF + R2 set (e.g. organization-admin tokens), or (b) multiple agents need different infra subsets.

## Implementation steps

Owner-side 1P + chezmoi work. No code changes to the dotfiles install scripts; only `.chezmoidata/secrets.toml` bindings.

1. **1P web UI** → Vaults → Create vault `Infra` (or `DeployOps`; pick final name at migration time).
2. **1P web UI** → move items `cloudflare-api-token`, `r2-*` from `Private` → `Infra`.
3. **1P web UI** → Developer Tools → Service Accounts → `trading-agent` → extend scope to include `Infra:read_items`. Verify the SA detail page now lists `Vaults (2)` with `Trading` + `Infra`, both Read.
4. Update `.chezmoidata/secrets.toml`:
   ```toml
   CLOUDFLARE_API_TOKEN = "op://Infra/cloudflare-api-token/credential"
   # R2 entries similarly updated to op://Infra/...
   ```
5. `chezmoi apply` to re-render `~/.config/fish/conf.d/secrets.fish`.
6. `dotfiles secret refresh CLOUDFLARE_API_TOKEN` (plus each R2 variable) to invalidate the Keychain cache entries that still point at the old `op://Private/...` paths.
7. `exec fish` — Touch ID fires once per refreshed entry; new paths cached.
8. Update consumer repos:
   - `tieubao/trading/docs/specs/SPEC-019-op-service-account-agent-shell.md` §2.1: scope claim updated from "Trading only" to "Trading + Infra"; add a cross-ref to this spec.
   - `tieubao/trading/operations/broker-access.md`: add an `Infra` row to the "Service account + infra secret rotation" table.

## Testing / Done definition

- [ ] From a fresh Claude Code session, `op read op://Infra/cloudflare-api-token/credential` returns the token (no scope denial).
- [ ] From the same session, `op read op://Private/op-service-account-trading/credential` still returns scope denial (SA remains blind to its own storage).
- [ ] `tieubao/trading/operations/scripts/verify-op-trading-access.sh` continues to exit 0 / 5 of 5 (no regression on trading-vault access).
- [ ] `wrangler deploy` from agent shell still works (CF token still loads via fish env; env-inherit behavior unchanged).
- [ ] SPEC-019 §2.1 + broker-access.md updated and committed in the trading repo.
- [ ] This spec's `status` flipped to `done`; `tasks.md` row added.

## Open questions

1. Final vault name: `Infra`, `DeployOps`, `Agent-Infra`, `Shared-Infra`? Bias: `Infra` (terse, parallels existing `Private` + `Trading`). Decide at migration time.
2. Seed `Infra` with the vps-mon Telegram bot token + Discord webhook currently in `Trading`? Argument for move: they are deploy-style secrets (external service tokens). Argument against: they alert on trading hosts and the blast radius of their leak is trading-specific (attacker can spam/suppress trading alerts, nothing else). Lean: keep in `Trading`. The heuristic above prioritises security-domain over technical-layer; these are trading-domain.

## References

- [S-42](S-42-service-account-agent-auth.md) — parent spec: introduces the service-account agent-auth model that this spec extends.
- [S-35](S-35-local-pattern-and-lazy-secrets.md) — pre-registered secret inherit path (still the default for env-var consumers; unaffected).
- `tieubao/trading/docs/specs/SPEC-019-op-service-account-agent-shell.md` — consumer-side spec in the trading repo; mirrors S-42 for that repo's audience. Needs an update when this spec ships.
- `tieubao/trading/operations/broker-access.md` — "Service account + infra secret rotation" table; gets an `Infra` row when this spec ships.

---

**Status note**: proposed, not implemented. Owner-side 1P web UI actions (vault creation, item moves, SA scope extension) cannot be automated. Revisit when: the first agent workflow needs `op read` on CF or R2 credentials at runtime; OR a new agent-infra secret joins the set; OR the next scheduled SA rotation on 2026-07-18 — whichever comes first.
