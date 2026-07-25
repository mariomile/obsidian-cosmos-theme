---
date: 2026-07-25
topic: dynamics-and-depth
status: approved
mode: grounded-audit → orchy execution
---

# Dinamica & profondità — design (cantiere 2 del programma design/UX)

Approvato da Mario 2026-07-25. Programma: 1) Coerenza ✅ CHIUSA (12/12 plugin,
`docs/2026-07-24-suite-coherence-design.md`) → **2) Dinamica & profondità**
(questo doc) → 3) Scrittura & lettura (verdetto NC-Tight, decisione di Mario).

## Findings verificati (misurati, non ipotizzati)

Misurazioni fatte via `obsidian-cli eval` sull'istanza reale di Mario
(flavour attiva: `cupertino-dark` + `perplexity` + `layout-cupertino`) e via
CSSOM, non per grep — la prima ipotesi ("elevazione assente ovunque") era
SBAGLIATA ed è stata corretta dai dati.

1. **L'elevazione è duplicata per-flavour e la copertura è andata alla
   deriva.** La stessa ricetta è scritta due volte con coperture diverse:
   - `body.theme-dark.cupertino-dark …` → `.modal`, `.prompt`,
     `.suggestion-container`, `.popover.hover-popover`, `.tooltip`
   - `body.layout-cosmos-fusion-glass …` → `.menu`, `.suggestion-container`,
     `.prompt`, `.popover`, `.modal:not(.mod-settings)`

   **Conseguenza misurata:** sulla flavour attiva di Mario i **menu
   contestuali non ricevono elevazione Cosmos** — `.menu` esiste solo nella
   regola fusion-glass. È la stessa classe di difetto del bug Sonar: una
   regola che *sembra* coprire e invece no.

2. **Il tab pill non ha motion.** Zero `transition`/`transform` sulle regole
   `.workspace-tab-header` in `cosmos-layer.css`: la firma desktop del tema
   (pill Craft-card) si attiva di scatto.

3. **Progressive disclosure quasi assente nel tema**: 1 sola occorrenza di
   `opacity: 0` nei layer (mentre `obsidian-portal` la usa bene nel rail —
   `.portal-section-action` 0 → 1 su hover/focus-visible).

## Scope (3 workstream scelti da Mario, in ordine di dipendenza)

### A. Elevation ladder unificata — fondamento
Un layer di elevazione **flavour-agnostico** che sostituisce la duplicazione:
ogni superficie flottante prende la profondità giusta in OGNI flavour.

- **Scala** (token già esistenti in `cosmos-tokens.css`, nessuno nuovo se
  evitabile): canvas → pannello elevato (`--cosmos-island-shadow`) →
  superficie flottante (`--cosmos-pop-shadow`) → overlay/modal.
- **Regola base unica** per l'insieme delle superfici flottanti
  (`.menu`, `.suggestion-container`, `.prompt`, `.popover`, `.tooltip`,
  `.modal`), applicata a prescindere dalla flavour.
- **Le flavour restano libere di SOVRASCRIVERE** (fusion-glass aggiunge
  blur/glass; cupertino-dark può rifinire): si rimuove la *duplicazione della
  base*, non la personalità delle flavour.
- **Effetto visibile atteso:** i menu contestuali guadagnano l'ombra Cosmos su
  cupertino-dark. Cambio voluto, reversibile (git + `restore.sh`).
- **Non-goal:** non toccare le superfici che una flavour rende
  deliberatamente piatte; nessun ridisegno di geometria.

### B. Motion strutturale
- **Tab pill**: transizione sull'attivazione (solo `transform`/`opacity`,
  durate/easing dai token `--cosmos-t-*` + `--cosmos-native`); il drag nativo
  usa transform inline → verificare che non ci sia conflitto (stessa cautela
  già applicata al press-scale del tab, slice 3 mobile).
- **Pannelli**: rifinitura del movimento esistente senza reintrodurre il
  gotcha `display:none` già documentato in `cosmos-native-sidebar-motion`.
- **Reduced-motion**: gratis se si consumano i token (Cosmos li azzera a
  livello token sotto la media query) — verificarlo, non assumerlo.

### C. Progressive disclosure
Pattern sistematico per le azioni secondarie: nascoste a riposo, rivelate su
hover **e** su `:focus-visible` (accessibilità da tastiera), sul modello già
shippato in Portal.

- **⛔ Vincolo di correttezza non negoziabile:** su touch l'hover NON esiste.
  Ogni regola di disclosure va gated `@media (hover: hover) and (pointer:
  fine)`. Su phone le azioni restano **sempre raggiungibili** — mai nascoste
  dietro uno stato che il dito non può produrre. Questo è il criterio di
  parità mobile per questo cantiere.

## Contract (la coerenza non decade — estensione del ratchet)

Aggiungere a `contract.sh` / `design-contract.json`:
1. **Anti-duplicazione elevazione**: le superfici flottanti ricevono la loro
   ombra base da UNA regola flavour-agnostica; una seconda definizione
   flavour-scoped della stessa base è una violazione (le flavour possono
   aggiungere, non ri-dichiarare la base). Codifica il difetto trovato oggi.
2. **Disclosure mai su touch**: ogni `opacity: 0` usato per progressive
   disclosure vive dentro un blocco `hover: hover`/`pointer: fine`.

## Verifica (definition of done)

1. `./build.sh` verde (contract incluso, nuovi check compresi)
2. `./verify-mobile.sh` senza regressioni (oggi 7 pass / 0 fail / 3 skip)
3. Misura live via `obsidian-cli eval`: `.menu` ha `--cosmos-pop-shadow` sulla
   flavour attiva (oggi NON ce l'ha) — prova empirica, non solo test statico
4. Nessuna regressione desktop sulle altre flavour: campionare almeno
   `layout-baseline` (che deve restare piatta) e `fusion-glass` (glass intatto)
5. Sign-off visivo di Mario su desktop; phone via Sync

## Vincoli ereditati dal programma

- Commit atomici reversibili, push a fine ondata, no PR
- **Mobile paritario** (qui: vincolo C sopra)
- Cosmos = lingua; contract Cosmos: **mai `!important`**, si vince per
  specificità/source-order; no hex/ms raw fuori da `cosmos-tokens.css`
- Sviluppo in `test-vault`, deploy nel vault reale solo deliberato
- ⛔ mai `EmulateMobile`; ⛔ mai un glob di token seguito da slash nei commenti
