---
date: 2026-07-24
topic: suite-coherence
status: approved
mode: brainstorm → orchy execution
---

# Coerenza del sistema — design (cantiere 1 del programma design/UX)

Approvato da Mario 2026-07-24. Programma completo: **1) Coerenza** (questo doc) →
2) Dinamica & profondità → 3) Scrittura & lettura (verdetto NC-Tight, di Mario).
Fuori scope per scelta: Home/ingresso, settings screens (in coda, non persi).

## Vincoli di Mario (non negoziabili)

- **Non spaccare nulla**: solo modifiche git-reversibili, commit atomici, un
  plugin per volta, mai big-bang. Revert chirurgico sempre possibile.
- **Mobile paritario**: ogni intervento vale desktop E iPhone (Pro Max, no
  iPad). La coerenza vive su entrambe le piattaforme by design.
- **Cosmos è la lingua**: il riferimento design/UX è il tema Cosmos — il kit
  ESTRAE le sue regole, non ne inventa di nuove.
- Esecuzione via orchy: Fable pianifica/verifica, executor Sonnet/Opus per
  complessità — niente Fable sui task piccoli.

## Scope (3 fronti scelti da Mario)

1. **Icone Huge ovunque** — linguaggio iconografico unico app-wide
2. **Chrome & densità della suite** — i 12+ plugin sembrano UNA app
3. **Empty states & microcopy** — stati vuoti quieti, stessa voce ovunque

## Architettura

### A. Modulo icone core (repo obsidian-portal)
`src/icons/core-icons.ts`: `addIcon()` sui **nomi core Lucide di Obsidian**
(~25-30 curate: search, plus, menu, chevron-*, gear/settings, more/dots, x,
calendar, folder, file, star, trash, copy, link, tag…) → sostituzione app-wide
(menu, toolbar, navbar mobile, settings). Pattern esistente di Mario:
`hi-panel-left` in main.ts — `<g transform="scale(4.166667)">` (viewBox 100/24,
memoria: addIcon forza viewBox 0 0 100), stroke Rounded 1.5, `fill="none"
stroke="currentColor"`.

- **Setting Portal "Huge core icons", default ON**, spegnibile. Nota onesta:
  il revert richiede riavvio app (addIcon non si annulla a runtime) — scritto
  nella descrizione del setting.
- Commit **per batch di icone** con mapping documentato lucide→huge nel file.
- Icone non mappate restano Lucide finché non curate (lista viva, no
  sostituzione cieca).
- Mobile: Portal è mobile-safe → l'override arriva su iPhone via Sync, gratis.

### B. mv-kit — la checklist scritta (questo repo)
`docs/mv-kit.md`, corto e prescrittivo. Ogni voce con **due colonne:
desktop / phone**. Contenuto:
- scala radius e superfici (da cosmos-tokens; i plugin le consumano via
  `var(--cosmos-*, fallback)` inline — pattern theme-independent già in Portal:
  `--portal-motion: var(--cosmos-t-fast, 120ms) var(--mv-lift, …)`)
- taglie type (--font-ui-*) e icone; touch ≥44pt su phone (--cosmos-touch-min)
- token motion + easing (--cosmos-native) con fallback canonici; solo
  transform+opacity; prefers-reduced-motion rispettato
- **pattern empty-state**: micro-label small-caps faint + messaggio "sussurro"
  (la ricetta PROPERTIES/backlinks già shippata in Phone Edition/Craft care)
- **voce microcopy**: sentence-case, EN per superfici product, gergo PM
  standard non tradotto; form language da memoria exo-plugin-form-language
  (.mva-pv label, niente `<select>`, bottoni non mod-cta)

### C. Rollout a ondate (un plugin per volta)
Ordine per frequenza d'uso: **Sonar → Portal → Masonry → TabX** → resto
(Horizon, Glance, Runway, SuperBaseTags, Selection Sidekick, Composer,
AIditor, Exo — Exo per ultimo: superficie più grande).
Ogni ondata: audit vs mv-kit (desktop E phone) → fix → typecheck+lint+test
verdi → commit atomici → push → screenshot verifica (desktop; phone da Mario).

### D. Contract leggero (la coerenza non decade)
Test minimale per repo, stile release-contract già in Masonry/Portal,
introdotto ondata per ondata:
- raw `ms`/hex in styles.css **solo** come fallback dentro `var()` (asserisce
  il pattern theme-independent, non vieta i valori)
- tetto `!important` per file
Mai retro-imposto in blocco su repo non ancora auditati.

## Sicurezza & rollback

- Ogni ondata revertabile da sola (commit atomici + push a fine ondata)
- Icone dietro setting Portal; zero contenuto vault toccato
- Tema: solo test-vault → deploy deliberato (regola attiva); restore-point
  `cosmos-restore-2026-07-22` + `restore.sh` come rete pesante
- Build plugin deployano main.js nel vault (memoria: mai cp di main.js stale);
  Sync porta tutto su iPhone (categorie plugin+temi attive ✓)
- ⛔ mai EmulateMobile (uccide i plugin Node); verifica phone su device reale

## Verifica (definition of done per ondata)

1. typecheck + lint + test del repo verdi (numeri reali nel commit)
2. contract del repo verde (dove introdotto)
3. screenshot desktop; screenshot phone di Mario per il sign-off visivo
4. harness Cosmos resta 7 pass / 0 fail (nessuna regressione tema)

## Non-goals espliciti

- Nessun plugin nuovo; nessun redesign dei layout dei plugin (solo coerenza:
  radius/type/icone/motion/empty-states/microcopy)
- Niente tipografia di contenuto (NC-Tight = cantiere 3, decisione di Mario)
- Niente settings screens (in coda programma)
