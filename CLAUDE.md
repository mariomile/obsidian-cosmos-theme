# CLAUDE.md — Cosmos

Regole che cambiano il comportamento, non documentazione. Il resto sta nei commenti dei layer, che sono la vera spiegazione.

## ⛔ Colori delle superfici: Scoped Token Override, mai dipingere

**Per cambiare il colore di una ZONA, non dipingere gli elementi che la compongono. Ridefinisci la variabile nello scope del contenitore.**

Tecnica completa: `Atlas/Concepts/Tools/Scoped Token Override.md` nel vault di Mario — scritta dopo un giorno intero passato sull'approccio sbagliato. **Leggila prima di toccare i colori.**

```css
body.<palette> { --cosmos-surface-0: <colore CORNICE>; }   /* 1 */
body.<palette> .workspace-split.mod-root {
  --background-primary:     <colore PANNELLO>;             /* 2 */
  --file-header-background: <colore PANNELLO>;             /* derivato */
}
```

1. Il globale porta il valore della **cornice**, non dell'editor. Ribbon, tab bar, sidebar, fondo e view dei plugin diventano scuri **gratis**, senza toccare un elemento.
2. Solo il pannello centrale torna chiaro. La geometria (border-radius + overflow hidden già presenti) ritaglia da sola la forma giusta — la stessa geometria che nell'approccio "dipingi" è un ostacolo da combattere.

**Il fallimento caratteristico:** il 2026-08-04 si è provato a dipingere `.workspace-split:is(.mod-left-split, .mod-right-split)`. Ribbon e tab bar sono rimasti fuori perché **non stanno dentro quel contenitore**. Ogni correzione ne genera un'altra; il segnale d'allarme è quando la correzione N ripara la N-1.

**Trappola obbligatoria:** i token derivati si risolvono dove sono **dichiarati**. `--file-header-background: var(--background-secondary)` sul `body` si risolve lì come valore letterale, e la ridefinizione di scope non lo raggiunge → va ridichiarato dentro lo scope. Sintomo: una sottozona resta del colore vecchio dentro un'area per il resto corretta.

Implementazioni di riferimento in `cosmos-tokens.css`: `linear-darker` (che ha generato la tecnica) e `realcraft`.

## Verifica: pixel, non token

**Un token corretto non garantisce un pixel corretto.** Dopo ogni modifica ai colori, campiona i pixel resi da uno screenshot — ribbon, tab bar, sidebar, pannello centrale — e confrontali col riferimento.

Due sorgenti di misure false, entrambe incontrate davvero:
- **Screenshot stantio**: catturato prima del ridisegno. Se pixel e `getComputedStyle` sono in disaccordo, ricattura con più margine prima di concludere.
- **rAF che non scatta**: con la finestra non a fuoco `requestAnimationFrame` non viene servito, quindi qualunque misura che ci si appoggia raccoglie zero campioni. Usa `PerformanceObserver` con `longtask`.

## Contratti che si rompono in silenzio

- `./build.sh` esegue `contract.sh`: hex e ms raw **solo** in `cosmos-tokens.css`, `!important` a soglia per file (scendono soltanto), floor di `:focus-visible`, ban dei custom-prop duplicati fuori dall'allowlist. I blocchi scoped con selettore discendente **non** sono esentati dal blanking → il duplicato va messo in `duplicate_prop_allowlist` **con la motivazione** nel campo `_comment`.
- Un `*/` orfano in un commento uccide in silenzio la regola successiva: il CSS resta nel file, sparisce dal CSSOM, e le graffe restano bilanciate. `build.sh` conta aperture e chiusure **per file** apposta. Non scrivere mai un glob di token seguito da slash dentro un commento.
- Il blocco `@settings` è **YAML**: una `description` che contiene `due punti + spazio` rompe il parsing dell'intero controllo, che sparisce dalle impostazioni senza errori.

## Style Settings: lo stato si perde

Modificare il blocco `@settings` mentre Obsidian gira fa **perdere la classe applicata** — è successo a `input-cupertino`, portandosi via l'intera scala di superfici. Dopo ogni cambio di schema: rileggere `data.json` sul disco e correggere via `settingsManager.setSetting(sezione, id, valore)` (tre argomenti). Scrivere `data.json` a mano con l'app aperta non funziona: viene riscritto all'unload.

## ⛔ `sync-snippets.sh` è ritirato

Il repo è la sorgente di verità dal 2026-07-10. Lo script esce 1 e spiega perché: rieseguirlo reintrodurrebbe hex e ms raw sopra soglia e cancellerebbe `§ ANGLAGE`, cioè l'unica dichiarazione di `--cosmos-pop-shadow` che il contract pretende esista.

## ⛔ `@layer` per la base: ritirato

`app.css` è unlayered e precede il tema → unlayered batte layered → app.css vincerebbe su tutta la base. Un tema Obsidian **deve** restare unlayered. Gli override si vincono con specificità, o con `!important` mirati e commentati (`/* beats: … */`).

## Flusso

```bash
./build.sh                       # concatena i layer + contract
pnpm check:reproducible          # due build, byte-identiche
./deploy.sh <vault>              # copia theme.css + manifest
./restore.sh <vault> [tag]       # revert totale a un tag cosmos-restore-*
```

Sviluppo in `test-vault/`; il vault reale si tocca solo al confine di una milestone.
