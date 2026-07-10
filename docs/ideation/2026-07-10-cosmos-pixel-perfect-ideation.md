---
date: 2026-07-10
topic: cosmos-pixel-perfect
focus: pixel-perfect design quality — spacing rhythm, radius concentricity, color tokens, state coverage, surface completeness
mode: repo-grounded
---

# Ideation: Cosmos pixel-perfect — portare il tema a livello top-tier

## Grounding Context

**Codebase** (scan 2026-07-10): `theme.css` (3.812 righe, ~667KB) = riga 1 base Baseline minificata (~395KB, di fatto read-only) + blocco `@settings` leggibile (righe ~2-2960) + layer Cosmos da riga ~3029. `build.sh` taglia al marker `COSMOS LAYER` e ri-appende `cosmos-layer.css` → `cosmos-islands.css` → `cosmos-tweaks.css` (unico check: brace balance). `deploy.sh` copia nel vault.

**Pain rilevati**: 7 hex dark raw (#141414…#292929) senza step function (ma `color-mix()` ×16 altrove); radii {5,6,8,10,11px} con concentricità mantenuta a mano ("pill 8 + pad 2 = 10"); gap 4/5/6/8/10px (5 e 10 rompono il ritmo 4/8); `--island-gap` definito 2 volte; shadow isola copiata 4× (left/right × light/dark); `:hover` ×6 ma `:focus-visible` ×0, `:active` ×1; due `outline:none !important` non commentati; durate motion 140/180/260ms incoerenti, `--mv-t` bypassato, reduced-motion copre solo lo skin Bases; `!important` ×35 (guerre di specificità contro Baseline); **zero selettori** per tooltip, suggestion popover, input, menu contestuali, righe settings.

**Loop di verifica unico**: `obsidian-cli eval getComputedStyle(...)` + `dev:screenshot` sul vault live → misure pixel economiche e scriptabili.

**Prior art esterno** (ricerca 2026-07-10): obsidian-macos-theme "Tahoe" (radii concentrici via `calc(parent − padding)`, hairline 0.5px, focus ring `color-mix(accent 25%, transparent)`, `:active scale(0.96)` 120-150ms); Minimal di kepano (17-state checkbox come modello di coverage); Border (6 preset Style Settings come JSON). **Marks of a top-tier theme** (ranked cross-source): 1) sistema radius concentrico, 2) full state coverage, 3) completezza edge-surface (menu/tooltip/graph bridge/canvas/print), 4) parità light/dark WCAG AA, 5) reduced-motion ovunque, 6) elevazione via tono superficie, 7) customizzazione esternalizzata, 8) CSS a bassa specificità senza `!important` (linea guida ufficiale).

## Ranked Ideas

### 1. `cosmos-tokens.css` — il layer zero dei token
**Description:** Un quarto file, primo nell'ordine di concatenazione di build.sh, che possiede tutti i token: scala superfici, radius pyramid, spacing, ricetta shadow isola, scala durate motion (con reduced-motion che azzera i token). I tre layer esistenti diventano puri consumatori — nessun valore raw.
**Warrant:** `direct:` "--island-gap definito 2 volte, shadow isola copiata 4×, --mv-t bypassato, gap 5/10 fuori ritmo" — tutti sintomi di token senza proprietario unico. `external:` Tahoe theme — l'identità di un tema Cupertino vive in un token sheet.
**Rationale:** È la mossa strutturale che rende durevoli tutte le altre: il drift diventa impossibile by-construction invece che vigilanza.
**Downsides:** Refactoring trasversale ai 3 layer; build.sh da aggiornare.
**Confidence:** 90%
**Complexity:** Medium
**Status:** Unexplored

### 2. Scala tonale dark + elevazione nominata (⭐ 6/6 frame)
**Description:** Un solo seed `--cosmos-surface-0: #141414`; ogni superficie derivata via `color-mix(in oklab, seed, white N%)` a step fissi, con nomi di elevazione `--elev-0…4` (stile Fluent). Il toggle "Superfici chiare" diventa uno swap di seed.
**Warrant:** `direct:` "7 hex dark raw senza step function nonostante color-mix ×16 altrove". `external:` Material tonal palettes, Fluent elevation ramp; mark #6 top-tier.
**Rationale:** Elevazione provabilmente monotona; ogni superficie futura sceglie uno step invece di inventare un hex; light-parity = 1 seed invece di 7 decisioni.
**Downsides:** I derivati differiranno di 1-2 punti dai hex attuali — serve un giro di taratura visiva.
**Confidence:** 95%
**Complexity:** Low-Medium
**Status:** Unexplored

### 3. Radius concentrici via `calc()` (⭐ 5 frame)
**Description:** Raggio figlio = `calc(var(--r-parent) − var(--pad))`, ancorato ai token base già presenti (`--radius-s 8 / -m 12 / -l 20`). Il set a mano {5,6,8,10,11} collassa su valori derivati.
**Warrant:** `direct:` "concentricità mantenuta A MANO, non calc()". `external:` Tahoe fa esattamente questo; mark #1 dei temi top-tier.
**Rationale:** La concentricità è il dettaglio che l'occhio legge come "pixel-perfect" senza saperlo nominare — e oggi si rompe in silenzio a ogni cambio di padding.
**Downsides:** Quasi nessuno; qualche arrotondamento nei casi limite.
**Confidence:** 90%
**Complexity:** Low
**Status:** Unexplored

### 4. Contratto di interazione: focus-visible + active
**Description:** Token ring `color-mix(in srgb, var(--interactive-accent) 25%, transparent)` + `:active scale(0.96)` 120-150ms su ogni superficie interattiva; eliminare i due `outline:none !important` non commentati.
**Warrant:** `direct:` ":hover ×6 ma :focus-visible ×0, :active ×1; due outline:none non commentati" — unica area rotta (non solo incoerente): fail WCAG per utenti tastiera. `external:` ricetta Tahoe; Minimal 17-state come modello; mark #2 top-tier.
**Rationale:** Il mark top-tier più economico da chiudere, ed è accessibilità di base.
**Downsides:** Nessuno reale.
**Confidence:** 95%
**Complexity:** Low-Medium
**Status:** Unexplored

### 5. Sweep "anglage" — le superfici invisibili
**Description:** Stilare le superfici oggi a zero selettori: tooltip, suggestion popover, input, menu contestuali, righe settings + graph bridge (`.graph-view.color-*`, ~11 classi). Stretch: print/PDF CSS. Da eseguire DOPO le idee 1-4 così le nuove superfici nascono on-system.
**Warrant:** `direct:` "ZERO selectors per tooltips, popovers, inputs, context menus, settings rows" + "graph view = superficie più dimenticata cross-source". `reasoned:` analogia anglage (orologeria): finire le superfici che nessuno apre è ciò che separa buono da top-tier — ogni right-click oggi butta l'utente fuori da Cosmos dentro Baseline raw.
**Rationale:** Mark #3 top-tier; è dove l'aspirazione "one designed environment" (PRODUCT.md) si rompe decine di volte al giorno.
**Downsides:** La più lunga; superfici transient difficili da testare.
**Confidence:** 85%
**Complexity:** Medium-High
**Status:** Unexplored

### 6. Design contract: preflight lint + verify.sh + golden screenshots (⭐ 6/6 frame)
**Description:** (a) Preflight in build.sh: hex raw fuori token-list, `!important` sopra soglia, `:hover` senza `:focus-visible`, custom property duplicate, ms raw → build rosso. (b) `verify.sh`: asserzioni `getComputedStyle` live + screenshot golden per flavour × light/dark. (c) La coverage map (superficie × stato × modo) è il file di spec dichiarativo che verify.sh legge — docs + test + burn-down in un solo artefatto.
**Warrant:** `direct:` "unique verification loop … cheap e scriptabile" + "build.sh: unico check = brace balance". `external:` golden files standard (Chromium pixel tests, Chromatic); stesso pattern del release-contract di obsidian-masonry già provato nella suite di Mario.
**Rationale:** Rende le altre sei idee garantite per sempre invece che fatte una volta. Quasi nessun theme author ha un oracolo DOM live scriptabile.
**Downsides:** Manutenzione dei golden screenshot a ogni cambio intenzionale.
**Confidence:** 90%
**Complexity:** Medium
**Status:** Unexplored

### 7. Wrap `@layer` a build-time → `!important` ×35 → ~0
**Description:** build.sh avvolge la base minificata in `@layer baseline { … }`; i layer Cosmos restano dopo/unlayered e vincono per cascade, non per specificità. I 35 `!important` diventano cancellabili; gli snippet utente tornano a funzionare (linea guida ufficiale Obsidian).
**Warrant:** `direct:` "!important ×35 — specificity wars vs Baseline, fragile se la base si aggiorna" + build.sh possiede già il punto di concatenazione. `external:` CSS Cascade Layers (baseline 2022); mark #8 top-tier.
**Rationale:** Trasforma la fragilità strutturale più grande (update Baseline che rompe 35 override) in garanzia architetturale, con ~10 righe di build.
**Downsides:** Meccanica cascade da verificare (unlayered vince su layered — il wrap va nel verso giusto); rischio regressioni al primo colpo → richiede la #6 come rete.
**Confidence:** 80%
**Complexity:** Medium
**Status:** Unexplored

**Sequenza consigliata:** 6 → 1+2+3 → 4 → 7 → 5.

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | Vendorare il sorgente Baseline non-minificato + patch queue | Deferita: più pesante della #7 che risolve la stessa fragilità; rivalutare al primo update reale di Baseline |
| 2 | Flavour → trait ortogonali + potatura @settings | Ristrutturazione step-function con payoff incerto per un tema personale mono-flavour; rischia i settings salvati → variante da brainstorm |
| 3 | De-escalation `:where()` caso-per-caso | Superata dalla #7 (stesso goal, più manuale) |
| 4 | Audit semi-automatico `!important` | Superata dalla #7 |
| 5 | Generatore di stub per gli stati mancanti | Overkill per ~12 selettori; la #4 copre |
| 6 | Coverage map standalone | Fusa nella #6 (la mappa È la spec) |
| 7 | Spacing rhythm standalone | Fusa nella #1 |
| 8 | Shadow isola / motion tokens standalone | Fuse nella #1 |
| 9 | Styling PDF export dedicato | Valore basso ora; stretch item dentro la #5 |
