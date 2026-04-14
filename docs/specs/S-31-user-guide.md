---
id: S-31
title: User guide
type: docs
status: done
---

# Comprehensive user guide

### Problem

The repo has good docs scattered across multiple files:
- **README.md**  - quick start, what's included, daily usage summary
- **docs/customization.md**  - the editing workflow, secrets, troubleshooting
- **docs/decisions/*.md**  - 6 ADRs explaining architectural choices
- **docs/tool-comparison.md**  - why each tool over alternatives
- **7 SVG workflow diagrams**  - visual references

But three user journeys are poorly served:

1. **Day-1 newcomer**: installed, now staring at a fish prompt. Doesn't know what tools are available, what the keybindings are, what the fish plugins do, or how chezmoi's two-layer model works. README says "what's included" as a table but doesn't orient them.

2. **Day-2 customizer**: wants to change things but keeps hitting chezmoi's source-vs-target confusion. `customization.md` helps but lacks a guided walkthrough with a real example end-to-end.

3. **Returning user**: hasn't touched dotfiles in 6 months. Needs a quick refresher on the workflow without re-reading everything. Needs a cheat sheet.

### Approach

Expand `docs/customization.md` into `docs/guide.md`  - a single comprehensive user guide. Don't create a separate manual that duplicates existing content. The README stays as the "front door" (quick start + overview) and links to the guide for depth.

### Proposed structure

```
docs/guide.md
├── 1. How this works (mental model)
│   ├── The two layers: source vs target
│   ├── What chezmoi does (diagram: dotfiles_chezmoi_model.svg)
│   ├── Where things live (directory map)
│   └── Templates and secrets (diagram: dotfiles_secrets_flow.svg)
│
├── 2. Your first 30 minutes
│   ├── What just got installed (tool tour with one-liner for each)
│   ├── Fish shell orientation (keybindings, abbreviations, autosuggestions)
│   ├── Terminal: Ghostty basics (theme switching, splits, font)
│   ├── Editor setup check (VS Code / Zed / nvim)
│   └── Verify everything works: dotfiles doctor
│
├── 3. Daily workflows
│   ├── Editing any config (diagram: dotfiles_dfe_workflow.svg)
│   ├── Adding a Homebrew package (diagram: dotfiles_workflow_brew.svg)
│   ├── Handling drift (diagram: dotfiles_dfs_workflow.svg)
│   ├── The dotfiles CLI (subcommand reference table)
│   └── Cheat sheet (one-page quick reference)
│
├── 4. Customization cookbook
│   ├── Quick-change table (migrated from customization.md)
│   ├── Walkthrough: add a new fish function
│   ├── Walkthrough: change your Starship prompt
│   ├── Walkthrough: add a new Homebrew package
│   ├── Walkthrough: add a VS Code extension
│   ├── Walkthrough: switch Ghostty theme
│   └── Walkthrough: add an SSH host
│
├── 5. Secrets management
│   ├── The three tiers (auto-loaded, runtime, one-off)
│   ├── Adding a new secret (diagram: dotfiles_workflow_secrets.svg)
│   ├── Rotating a token
│   ├── Removing a secret
│   └── How it works under the hood
│
├── 6. Multi-machine setup
│   ├── Deploying to a second Mac
│   ├── Headless/server mode
│   ├── Keeping machines in sync (git pull + apply)
│   └── Machine-specific overrides (chezmoi templates)
│
├── 7. Troubleshooting
│   ├── Common issues (migrated + expanded from customization.md)
│   ├── "I edited the wrong file"
│   ├── "chezmoi apply wants to overwrite my change"
│   ├── "1Password errors"
│   ├── "Template rendering failed"
│   └── Nuclear options (reinit, state reset)
│
├── 8. Architecture reference
│   ├── Directory layout (diagram: dotfiles_architecture.svg)
│   ├── Script execution order
│   ├── How templates work
│   ├── How external downloads work
│   └── Design decisions (links to ADRs)
│
└── Appendix: cheat sheet
    ├── Commands at a glance (1-page table)
    ├── File locations
    └── "I want to X" → command mapping
```

### What gets migrated vs written new

| Section | Source | Work needed |
|---------|--------|-------------|
| Mental model | New | Write ~300 words wrapping the chezmoi model diagram |
| First 30 minutes | New | Write tool tour, fish orientation, editor check |
| Daily workflows | customization.md (partial) | Restructure + add diagrams |
| Customization cookbook | customization.md quick-change table | Migrate table + write 6 walkthroughs |
| Secrets management | customization.md secrets section | Migrate + add diagrams |
| Multi-machine | New | Write ~400 words |
| Troubleshooting | customization.md troubleshooting | Migrate + expand |
| Architecture | CLAUDE.md + README | Extract into reader-friendly prose |
| Cheat sheet | New | Compile from all sections |

### What happens to existing docs

- `docs/customization.md` → **deleted**, content migrated to `docs/guide.md`
- `README.md` → **updated**: "Customization" section links to guide instead of duplicating
- `docs/decisions/*.md` → **unchanged**, linked from guide section 8
- `docs/tool-comparison.md` → **unchanged**, linked from guide section 2

### Diagrams placement

| Diagram | Section |
|---------|---------|
| `dotfiles_chezmoi_model.svg` | 1. Mental model |
| `dotfiles_bootstrap_flow.svg` | 1. Mental model (or section 8) |
| `dotfiles_secrets_flow.svg` | 1. Mental model + 5. Secrets |
| `dotfiles_dfe_workflow.svg` | 3. Daily workflows |
| `dotfiles_dfs_workflow.svg` | 3. Daily workflows |
| `dotfiles_workflow_brew.svg` | 3. Daily workflows + 4. Cookbook |
| `dotfiles_workflow_config.svg` | 3. Daily workflows |
| `dotfiles_workflow_secrets.svg` | 5. Secrets management |
| `dotfiles_architecture.svg` | 8. Architecture |

### Acceptance criteria

- [ ] `docs/guide.md` exists with all 8 sections + appendix
- [ ] `docs/customization.md` removed, no broken links
- [ ] README "Customization" section links to `docs/guide.md`
- [ ] All 9 SVG diagrams embedded in appropriate sections
- [ ] Each walkthrough in section 4 has: goal, file to edit, exact command, expected result
- [ ] Cheat sheet fits in one screen (terminal height)
- [ ] No content duplication between README and guide (README = overview, guide = depth)
- [ ] `docs/guide.md` reads well as a standalone doc (no assumed context from README)
- [ ] Troubleshooting covers at least 8 common issues
- [ ] Multi-machine section covers fresh Mac, headless server, and sync workflow

### Estimated size

~2000-2500 words (excluding diagrams). Target: 15-minute read for the full guide, 2-minute skim via cheat sheet.

### Non-goals

- Video/screencast (that's S-29: VHS demo)
- Contributing guide (not needed yet, single-user repo)
- Plugin development guide (no custom plugin system)
