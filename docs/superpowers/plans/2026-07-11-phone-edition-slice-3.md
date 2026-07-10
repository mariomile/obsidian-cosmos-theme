# Phone Edition Slice 3 — Gate Audit & Ratchet Implementation Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit the 25 mobile-excluding `:not(.is-phone)`/`:not(.is-mobile)` gates across the 4 Cosmos CSS layers, flip the ones where Cosmos chrome makes sense on touch, document every KEEP/FLIP decision, inventory ghost mobile settings, and lower the design-contract ratchet to the new count.

**Architecture:** The theme has 4 source layers (`cosmos-tokens.css`, `cosmos-layer.css`, `cosmos-islands.css`, `cosmos-tweaks.css`) compiled into `theme.css` by `build.sh`. `contract.sh` counts gates (comments stripped) and asserts the count `<= design-contract.json:mobile_excluding_gates_max` (ratchet — down only). Verification runs through class-injection (`verify-mobile.sh`), NEVER EmulateMobile.

**Tech Stack:** Vanilla CSS, bash + python3 harness, jq, obsidian-cli (class-injection eval).

## Global Constraints

- NEVER touch EmulateMobile (localStorage flag) anywhere. Mobile verification is class-injection only.
- design-contract.json ratchet only goes DOWN. `mobile_excluding_gates_max` must end strictly < 25.
- No version bump in manifest.json.
- Every commit ends with trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Gate count is measured by contract.sh: `re.findall(r':not\(\.is-(?:phone|mobile)\)', strip_comments(css))` over the 4 layer files. Comments do NOT count.

---

## Gate Inventory & Decisions (25 gates)

### cosmos-layer.css — 11 gates (Craft-card pill tab bar)
All 11 are `body:is(.tab-floating, .tab-floating-center):not(.is-phone):not(.layout-baseline)` (+ theme-dark variant). **DECISION: KEEP all 11.** Baseline itself gates every `.mod-root .workspace-tab-header` pill rule behind `:not(.is-phone)` — floating pill tabs are a desktop-only UI tree. Phone uses Obsidian's mobile tab switcher, no pill headers. Flipping would paint Cosmos pill geometry onto a tree that doesn't exist on phone.

### cosmos-islands.css — 4 gates (floating sidebar islands)
All 4 are `body:is(.layout-cupertino, .layout-fusion):not(.is-phone)` on `.mod-right-split`/`.mod-left-split`. **DECISION: KEEP all 4.** On phone, sidebars are full-screen `.workspace-drawer` overlays, not floating `.mod-*-split` islands. The island recipe (margin/radius/outline/shadow that detaches a panel from window edges) is meaningless for a full-screen drawer.

### cosmos-tweaks.css — 10 gates
| Line | Selector | Decision | Rationale |
|---|---|---|---|
| 10 | `.workspace-ribbon.mod-left:not(.is-collapsed)` | KEEP | No left ribbon on phone (mobile has no ribbon UI). |
| 13 | `.workspace-ribbon.mod-left` | KEEP | Same — ribbon absent on phone. |
| 14 | `.workspace-ribbon.mod-left .side-dock-actions` | KEEP | Same. |
| 82 | `.workspace-split.mod-sidedock ... icon gap 0` | KEEP | Targets the desktop sidedock icon strip geometry; phone drawer header isn't a sidedock strip. |
| 93 | `.cosmos-right-island-off ... .mod-right-split` | KEEP | Mirror of island rule (islands are KEEP); must stay gated in lockstep. |
| 95 | `.cosmos-left-island-off ... .mod-left-split` | KEEP | Mirror of island rule. |
| 102 | `.cosmos-right-island-off ... header-container` | KEEP | Mirror of island rule. |
| 104 | `.cosmos-left-island-off ... header-container` | KEEP | Mirror of island rule. |
| 115 | `.workspace-split.mod-sidedock .workspace-leaf-resize-handle` | KEEP | Sidebar stacked-panel divider; phone uses drawers, no stacked resize handles. |
| 138 | `.workspace-tab-header:active { transform: scale }` | **FLIP** | Press feedback. `:active` fires on tap on touch. Pure composited transform, zero layout risk. This is exactly the tap-tactility Craft feel. Translate desktop press → touch tap. |

**Result:** 1 FLIP (line 138), 24 KEEP → new count = 24 (< 25).

## Ghost Settings (from docs/ideation/2026-07-10-mobile-ideation.md)
| Setting | Consumer? | Decision |
|---|---|---|
| `mobile-sidebar-width-override` | Baseline already reads it: `body.is-phone .workspace-drawer{width:var(--mobile-sidebar-width-override,...)}` | SKIP — already consumed by Baseline; Cosmos has no differing default to inject. |
| tablet sidebar 360/300px | `.is-tablet` only | SKIP — iPad/tablet tier rejected by Mario (ideation #1); out of scope. |
| `cards-mobile-width` | Baseline reads it in `@media(max-width:400pt){body{--cards-min-width:var(--cards-mobile-width)}}` | SKIP — already consumed by Baseline; Cosmos ships no cards layout of its own. |
| `contrast-dark-black-mobile` | Baseline setting scoped to `layout-minimal`/`layout-cards`; Cosmos ships its own non-OLED dark-remap (`--cosmos-surface-0:#141414`) | SKIP — a Cosmos OLED-black toggle is explicitly a FUTURE item (tokens comment: "OLED-black: eventuale toggle futuro"); not inventing an unrequested consumer this slice. |

All 4 ghost settings SKIP with documented rationale — none has a real, named *Cosmos* consumer to wire without inventing scope.

---

### Task 1: Inventory + decision doc
- [ ] Create `docs/2026-07-11-mobile-gate-audit.md` with the full 25-gate table above.
- [ ] Commit.

### Task 2: Flip the press-scale gate (cosmos-tweaks.css:138)
- [ ] Remove `body:not(.is-phone)` from the `.workspace-tab-header:active` rule; add a KEEP/FLIP comment referencing the audit doc.
- [ ] Annotate the KEEP gates with brief inline comments pointing to the audit doc (where not already obvious).
- [ ] Run `./build.sh` — expect gate count 24, contract still OK after ratchet lowered (Task 3).
- [ ] Commit.

### Task 3: Lower ratchet + extend mobile spec
- [ ] Set `design-contract.json:mobile_excluding_gates_max` = 24; update its comment.
- [ ] Add a `verify-mobile-spec.json` assertion for the flipped press-scale (transform reachable on phone via `:active` — assert the token `--cosmos-press-scale` resolves under is-phone).
- [ ] Run `./build.sh`, `./verify.sh`, `./verify-mobile.sh` — all pass.
- [ ] Commit.

### Task 4: Deploy
- [ ] Run `./deploy.sh` against the vault.
- [ ] Commit any tracked deploy artifacts (theme.css already rebuilt).
