---
date: 2026-07-11
topic: phone-edition-slice-3
focus: audit KEEP/FLIP di ogni gate mobile-excluding + ghost settings + ratchet
mode: repo-grounded
---

# Mobile Gate Audit — Phone Edition Slice 3

Audit gate-by-gate dei 25 gate `:not(.is-phone)` / `:not(.is-mobile)` nei 4 layer
Cosmos (conteggio come `contract.sh` lines 79-85: regex su `strip_comments(css)`,
i gate nei commenti NON contano). Ogni gate ha una decisione **KEEP** o **FLIP**
esplicita. I commenti inline nei file CSS puntano a questa nota.

**Esito:** 1 FLIP (`cosmos-tweaks.css` press-scale), 24 KEEP → count 25 → **24**.
`design-contract.json:mobile_excluding_gates_max` abbassato a 24 (ratchet, solo giù).

## Principio guida

Un gate `:not(.is-phone)` va **FLIPpato** solo se il chrome Cosmos che protegge ha
senso su touch e l'albero DOM che stila esiste anche su phone. Va **KEPT** se
protegge il layout mobile nativo di Obsidian — in particolare quando lo stesso
Baseline gata quell'albero fuori dal phone (pill tab, island sidebar): riproporlo
su phone dipingerebbe su un DOM che lì non esiste. Gli stati `:hover` non esistono
su touch: dove serve tattilità, si traduce in `:active`/tap, non si de-gata e basta.

## cosmos-layer.css — 11 gate → KEEP × 11

Tutti `body:is(.tab-floating, .tab-floating-center):not(.is-phone):not(.layout-baseline)`
(+ la variante `theme-dark` che deriva `--craft-tab-active`). È la barra tab
Craft-card (pill paper + soft lift). Righe: 81, 96, 104, 118, 138, 141, 144, 152,
158, 165, 170.

**KEEP.** Baseline stesso gata OGNI regola `.mod-root .workspace-tab-header` dietro
`:not(.is-phone)` (verificato in theme.css: `body:not(.is-phone) .workspace .mod-root
.workspace-tab-header{...}`). Le pill floating sono un albero UI desktop-only: su
phone Obsidian usa il tab-switcher mobile, senza header pill. Flippare dipingerebbe
geometria pill su un DOM inesistente su phone.

## cosmos-islands.css — 4 gate → KEEP × 4

Tutti `body:is(.layout-cupertino, .layout-fusion):not(.is-phone)` su
`.mod-right-split` / `.mod-left-split`. Righe: 36, 38, 53, 55. Sono le isole
sidebar galleggianti (margin/radius/outline/shadow che staccano il pannello dai
bordi finestra).

**KEEP.** Su phone le sidebar sono `.workspace-drawer` a schermo intero, non isole
`.mod-*-split` galleggianti. La ricetta island (staccare un pannello dai bordi) è
priva di senso per un drawer full-screen.

## cosmos-tweaks.css — 10 gate → FLIP × 1, KEEP × 9

| Riga | Selettore | Decisione | Motivo |
|---|---|---|---|
| 10 | `.workspace-ribbon.mod-left:not(.is-collapsed)` (padding) | KEEP | Nessuna ribbon su phone (mobile non ha la ribbon UI). |
| 13 | `.workspace-ribbon.mod-left` (align) | KEEP | Ribbon assente su phone. |
| 14 | `.workspace-ribbon.mod-left .side-dock-actions` (align) | KEEP | Idem. |
| 82 | `.workspace-split.mod-sidedock … icon gap 0` | KEEP | Geometria della icon-strip del sidedock desktop; l'header del drawer phone non è una strip sidedock. |
| 93 | `.cosmos-right-island-off … .mod-right-split` | KEEP | Mirror della regola island (island = KEEP): deve restare gated in lockstep, sennò il toggle off diverge dalla regola che annulla. |
| 95 | `.cosmos-left-island-off … .mod-left-split` | KEEP | Mirror della regola island. |
| 102 | `.cosmos-right-island-off … header-container` | KEEP | Mirror della regola island. |
| 104 | `.cosmos-left-island-off … header-container` | KEEP | Mirror della regola island. |
| 115 | `.workspace-split.mod-sidedock .workspace-leaf-resize-handle` | KEEP | Divider tra pannelli impilati nella sidebar; su phone drawer, nessuna maniglia di resize impilata. |
| 138 | `.workspace-tab-header:active { transform: scale(--cosmos-press-scale) }` | **FLIP** | Press feedback. `:active` scatta al tap su touch: è ESATTAMENTE la tattilità Craft del tap. Solo `transform` (composito), zero rischio layout. Il drag nativo usa transform inline → vince comunque, nessun conflitto col riordino tab. Traduzione desktop-press → touch-tap: si de-gata *e* si mantiene semanticamente valido perché `:active` esiste su touch. |

## Ghost settings — SKIP × 4 (nessun consumer Cosmos reale da cablare)

Inventario da `docs/ideation/2026-07-10-mobile-ideation.md`. Regola del task: cablare
un ghost setting SOLO se ha un consumer reale e nominato (una regola CSS che lo
legge); altrimenti documentare perché è skippato. Nessuno dei 4 ha un consumer
*Cosmos* da cablare senza inventare scope.

| Setting | Consumer? | Decisione |
|---|---|---|
| `mobile-sidebar-width-override` | Baseline lo legge già: `body.is-phone .workspace-drawer{width:var(--mobile-sidebar-width-override, var(--mobile-sidebar-width))}` | **SKIP** — già consumato da Baseline; Cosmos non ha un default diverso da iniettare. Cablarlo di nuovo sarebbe un duplicato inerte. |
| tablet sidebar 360/300px | Solo rami `.is-tablet` | **SKIP** — il tier tablet/iPad è stato scartato da Mario (ideation #1: usa solo iPhone Pro Max). Fuori scope. |
| `cards-mobile-width` | Baseline lo legge: `@media(max-width:400pt){body{--cards-min-width:var(--cards-mobile-width)}}` | **SKIP** — già consumato da Baseline; Cosmos non ships un layout cards proprio. |
| `contrast-dark-black-mobile` | Setting Baseline scoped a `layout-minimal`/`layout-cards`; Cosmos ships il proprio dark-remap NON-OLED (`--cosmos-surface-0:#141414`, canvas #141414) | **SKIP** — un toggle Cosmos OLED-black è esplicitamente un item FUTURO (commento in cosmos-tokens.css: "OLED-black: eventuale toggle futuro"). Non invento un consumer non richiesto in questa slice; quando arriverà il toggle avrà un consumer nominato dedicato. |

## Verifica

- `contract.sh` conta 24 gate (era 25) → `mobile_excluding_gates_max: 24`.
- `verify-mobile-spec.json` esteso: asserzione sul token `--cosmos-press-scale`
  (il payload del gate flippato) risolto su phone via class-injection.
- Sign-off finale del tap-scale su iPhone reale (Chromium non triggera `:active` da
  script; la asserzione prova che il token è vivo su phone, il tap va provato a mano).
