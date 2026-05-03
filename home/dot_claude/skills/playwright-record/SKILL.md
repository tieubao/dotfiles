---
name: playwright-record
description: Use when the user wants to capture a repeatable browser flow that will be re-run unchanged (monthly payroll, recon, report pulls, scheduled scrapes). Symptoms include "I do this in the browser every month and want to script it", "capture this flow", "record this for next time", "make this a Playwright spec", "automate this browser sequence". Wraps `npx playwright codegen` with the right `--user-data-dir` so the captured flow inherits the user's logged-in Chrome session, then saves the `.spec.ts` under `infra/scripts/browser-flows/<slug>.spec.ts`. NOT for one-off browser exploration (use `/chrome` or `/edge-up` instead) and NOT for stateless headless reads (use `agent-browser --engine lightpanda`).
---

# Capture a repeatable browser flow with Playwright codegen

The hardest, slowest, most token-expensive way to do a monthly ops task is "ask Claude to drive my browser through 12 clicks every time." If the steps never change, capture them once with `playwright codegen` and replay forever at zero per-run agent cost.

## When to fire this skill

The user describes a **repeatable** browser sequence with **stable steps**. Examples:
- "Pull the Airwallex monthly recon CSV and save it to private/finance/"
- "Download last month's Xero P&L to private/finance/reports/"
- "Click through Notion to export the contractor roster every Sunday"
- "I do this same browser dance every payroll cycle"

If the user is exploring or making one-off decisions in the browser, this is the wrong skill. Hand it off:
- Ad-hoc agent-driven browser work → `/chrome` or `/edge-up`.
- Stateless reads of public pages → `agent-browser --engine lightpanda` or `lightpanda fetch`.
- Page performance / Lighthouse audits → `chrome-devtools-mcp`.

Full decision tree: `browser-tool-selection` skill (`~/.claude/skills/browser-tool-selection/SKILL.md`).

## Steps

1. **Confirm scope**. Ask the user for:
   - Target URL (the entry point of the flow).
   - A kebab-case slug for the flow (e.g. `airwallex-monthly-recon`, `xero-quarterly-export`).
   - The repo where the flow lives. Default: dfoundation. Path: `infra/scripts/browser-flows/<slug>.spec.ts`.
   - Whether the flow needs to **mutate** state (sending an invoice, etc.) or is **read-only**. Mutate-flows need an explicit guard pattern.

2. **Pre-flight check**. Chrome must be **fully quit** before recording — Playwright cannot attach to a Chrome process already using the same `--user-data-dir`. Tell the user to quit Chrome and confirm before proceeding.

3. **Run codegen** with the user's real Chrome profile so logins inherit:

   ```bash
   npx playwright codegen \
     --browser=chromium \
     --user-data-dir="$HOME/Library/Application Support/Google/Chrome" \
     --output=infra/scripts/browser-flows/<slug>.spec.ts \
     <url>
   ```

4. **Han performs the flow** in the codegen browser. Codegen writes the `.spec.ts` continuously as he clicks.

5. **After codegen window closes**, inspect the captured spec:

   ```bash
   cat infra/scripts/browser-flows/<slug>.spec.ts
   ```

   Look for brittle selectors (positional CSS, auto-generated class names). If any flag, suggest manual cleanup: prefer `getByRole`, `getByLabel`, `getByText`, `getByTestId` over raw selectors.

6. **Smoke-test the replay**:

   ```bash
   # Headed first (visible window, useful for debugging or 2FA prompts)
   npx playwright test infra/scripts/browser-flows/<slug>.spec.ts --headed

   # Then headless (production replay shape)
   npx playwright test infra/scripts/browser-flows/<slug>.spec.ts
   ```

7. **Note in commit message**: which ops cycle this serves, the recording date, and any selector patches that needed manual fixup.

## Gotchas

- **`--user-data-dir` collision**: if Chrome is running, codegen silently uses a fresh profile and the user is NOT logged in. The captured spec will fail at the login wall. Always quit Chrome first.
- **Storage state JSON for unattended runs**: if the flow needs to run from cron (no UI session), save `storageState.json` to `private/secrets/playwright-state-<slug>.json` (gitignored under existing `private/` rules) and reference it via `playwright.config.ts`. Never commit cookies.
- **Mutation safety**: read-only by default. Any flow that changes state needs an opt-in flag (`--apply` or env var) so the smoke test can run dry.
- **Trace viewer for breakage**: `npx playwright test --trace=on` then `npx playwright show-trace test-results/.../trace.zip`. Faster than re-recording when a single selector broke.

## Token economics

Per Microsoft's Feb 2026 benchmark: ~114k tokens via `@playwright/mcp` vs ~27k tokens via Playwright CLI per browser task (4x cheaper). Once captured as a `.spec.ts`, **replay is zero agent tokens** — Claude only invokes `playwright test`.

This is the leverage: a 5-minute one-time recording session replaces every future monthly invocation.

## Related

- `/playwright-record` slash command — same flow, manual invocation: `~/.claude/commands/playwright-record.md`.
- Decision tree — `browser-tool-selection` skill (`~/.claude/skills/browser-tool-selection/SKILL.md`).
- Conventions for the dfoundation flows folder — `infra/scripts/browser-flows/README.md`.
- Tool-selection rule — `~/.claude/CLAUDE.md` "Tool selection" section.
