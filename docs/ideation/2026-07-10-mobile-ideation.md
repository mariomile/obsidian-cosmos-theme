---
date: 2026-07-10
topic: mobile-cosmos-e-suite
focus: esperienza mobile (iPhone/iPad) — tema Cosmos + suite plugin marioverse
mode: repo-grounded
---

# Ideation: Mobile — Cosmos + suite marioverse

## Grounding Context

**Tema (scan 2026-07-10):** 33 gate mobile, **100% escludenti** (`:not(.is-phone)`/`:not(.is-mobile)`), 0 additivi, **0 `.is-tablet`** — su iPhone il tema degrada a Baseline nativo (niente island, pill, dark-remap di menu/modal/tooltip: 18 gate solo in cosmos-layer). Mobile mai documentato in PRODUCT/README. Baseline shippa già `@settings` mobile inutilizzati (mobile-sidebar-width-override, tablet sidebar 360/300px, cards-mobile-width, contrast-dark-black-mobile).

**Plugin:** exo `isDesktopOnly=true` CORRETTO (spawna Claude Code CLI via child_process — impossibile su mobile by design). masonry e tabx: `isDesktopOnly=false` ma **zero** `Platform.isMobile`, **zero** `@media` di layout → caricano desktop-first; masonry ha il gotcha WebKit confermato (`aspect-ratio` sui grid item → colonne driftano su phone). horizon/superbasetags/sonar: dichiarano mobile, non verificati.

**Loop di test:** `obsidian-cli dev:mobile` (EmulateMobile) ⚠ ma al boot con EmulateMobile i plugin con `require()` Node muoiono silenziosamente → SEMPRE `dev:mobile off`. Verifica vera solo su WebKit reale (iPhone/iPad).

**Web (fonti in cache run d4626abf):** `is-phone` vs `is-tablet` = rami UI reali (iPad ha split-pane); Minimal usa breakpoint 400pt + token sidebar mobile dedicati; **nessun tema pubblicato usa `env(safe-area-inset-*)`** (gap ecosistemico); Copilot mobile = sidebar AI compressa dal chrome (failure mode → full-screen su phone); Nexus = gating per-feature; **Claude Dispatch** = pattern "phone client ↔ desktop-resident agent" (nessun plugin Obsidian terzo lo fa); WebKit: 100vh rotto → dvh, backdrop-filter `-webkit-` + perf.

## Ranked Ideas

### 1. ~~iPad tier~~ — SCARTATA DA MARIO (2026-07-10)
**Motivo:** Mario usa SOLO iPhone Pro Max, niente iPad. Il target mobile è il phone grande (430pt logici). L'assunzione "iPad = metà del parco" del grounding era sbagliata. `.is-tablet` resta fuori scope.
**Status:** Rejected by user

### 2. Cosmos Phone Edition: polarity flip → layer additivo `is-phone`
**Description:** Da 33 gate escludenti a un layer additivo: il phone come composizione diversa (art direction), brief capture-first/one-thumb (44pt, azioni in thumb-zone, ≤2 tap). Primo commit dimostrativo: dark-remap di menu/modal/tooltip (18 gate, puro colore, zero rischio layout).
**Warrant:** `direct:` "33 gate, 100% escludenti, 0 additivi"; 18 gate dark-remap sono solo colore.
**Rationale:** Con la polarità girata ogni feature futura nasce mobile-safe by default: si inverte la derivata del debito mobile.
**Downsides:** Il layer phone completo è la voce più lunga; da fare a fette.
**Confidence:** 85% · **Complexity:** Medium-High · **Status:** Unexplored

### 3. Token mobile layer zero + correttezza WebKit + ghost settings
**Description:** In cosmos-tokens.css: `--cosmos-safe-*` da `env(safe-area-inset-*)`, `--cosmos-touch-min: 44px`, `dvh` (100vh è rotto su iOS), prefissi `-webkit-` per backdrop-filter. Ricablare i ghost settings mobile di Baseline sui token.
**Warrant:** `external:` nessun tema usa safe-area (gap verificato); `direct:` 0 occorrenze di safe-area/dvh nei layer.
**Rationale:** Differenziazione autentica (primo tema "disegnato per il notch") + tutti i 12 plugin possono consumare gli stessi token.
**Downsides:** Da testare su hardware reale, non solo emulazione.
**Confidence:** 90% · **Complexity:** Medium · **Status:** Unexplored

### 4. Verifica mobile: harness anti-footgun + ratchet + scorecard
**Description:** `verify-mobile.sh` con `trap EXIT` che garantisce `dev:mobile off` (footgun EmulateMobile impossibile); ratchet nel design-contract (`excluding_gates_max: 33` può solo scendere, `raw_100vh_max: 0`); dimensione `viewports` in verify-spec; scorecard mobile per i 12 repo (stile Steam Deck Verified: Verified/Playable/Unsupported nel README).
**Warrant:** `direct:` "verify assume desktop"; il footgun EmulateMobile è documentato e ha già morso; masonry/tabx = claim mobile non verificato.
**Rationale:** Definition-of-done dell'intero sforzo mobile: senza, ogni miglioria decade in silenzio.
**Downsides:** L'emulazione è Chromium: il sign-off WebKit resta manuale (checklist).
**Confidence:** 90% · **Complexity:** Medium · **Status:** Unexplored

### 5. mobile-kit nel template della suite + fix masonry primo consumatore
**Description:** Modulo CSS+TS condiviso nel template masonry/horizon: ricetta grid WebKit-safe (niente `aspect-ratio` sui grid item; container-adaptive via ResizeObserver), helper `isPhone()/isTablet()`, bottom-sheet primitive, tap-target rules. Masonry (bug di drift confermato) è il primo consumatore.
**Warrant:** `direct:` masonry/tabx zero codice mobile; fix del drift documentato in memoria ma non in codice; masonry/horizon = template della suite.
**Rationale:** La qualità mobile diventa proprietà della suite: il prossimo plugin nasce mobile-corretto a `git init`.
**Downsides:** Tocca il meccanismo di template (12 repo a valle).
**Confidence:** 85% · **Complexity:** Medium · **Status:** Unexplored

### 6. Gating per-feature (`capabilities.ts`, modello Nexus)
**Description:** Ogni feature dichiara `requiresNode/requiresHover/requiresWideViewport`; su mobile il plugin carica il sottoinsieme possibile, con degrado esplicito (notice) invece di rottura silente. Oggi il binario produce entrambi i failure mode: exo tutto-off, masonry on-ma-rotto.
**Warrant:** `external:` Nexus (chat ovunque, MCP/desktop-provider desktop-only).
**Rationale:** "Mobile support" passa da yes/no per-plugin a contratto dichiarato e lintabile (si aggancia alla scorecard della #4).
**Downsides:** Convenzione da applicare progressivamente nei 12 repo.
**Confidence:** 80% · **Complexity:** Medium · **Status:** Unexplored

### 7. Exo in tasca: remote head via Obsidian Sync (fase 2: Dispatch live)
**Description:** L'agente resta sul Mac; il trasporto è Obsidian Sync: il phone scrive richieste in `_system/exo-queue/`, il desktop-Exo (già residente) le esegue e risponde con note che sincronizzano indietro. UI mobile full-screen/bottom-sheet (mai sidebar — failure mode Copilot). Fase 2: pairing live stile Claude Dispatch (QR, streaming).
**Warrant:** `external:` Claude Dispatch valida l'architettura phone-client↔desktop-agent; nessun plugin Obsidian la implementa (novità nell'ecosistema). `direct:` "exo su mobile ≠ CSS: richiede remote-execution o niente"; Sync già propaga a iPhone/iPad.
**Rationale:** L'unico modo per avere il plugin di più valore della suite sul device che Mario porta sempre; l'outbox valida la domanda a costo minimo prima del live.
**Downsides:** Latenza da Sync (30-90s) accettabile per capture-and-ask, non per chat live; richiede Mac acceso.
**Confidence:** 75% · **Complexity:** Medium-High · **Status:** Unexplored

**Sequenza (rivista da Mario 2026-07-10):** PRIMA IL TEMA: 4 (harness) → 3 (token) → 2 (Phone Edition). POI I PLUGIN, più strong: 5 (kit+masonry) → 6 (gating) → 7 (Exo outbox). iPad: fuori scope.

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | "Phone = capture cockpit / complications / one-thumb" standalone | È il brief di design della #2, non un progetto a sé — fusa |
| 2 | Handheld preset / perf budget | Fusa in #3 (correttezza WebKit) + #4 (enforcement) |
| 3 | Dark-remap standalone | Prima slice della #2 |
| 4 | mobile-lint standalone | Fusa nella #4 (scorecard) |
| 5 | Dispatch live pairing subito | Fase 2 della #7: l'outbox via Sync valida la domanda a costo minimo |
| 6 | Force-tablet hack su iPhone | Override fragile di Platform, non sopravvive agli update |
