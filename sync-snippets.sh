#!/usr/bin/env bash
# ⛔ RITIRATO — NON ESEGUIRE. Vedi il blocco di guardia sotto.
#
# Re-sync Cosmos layers from local marioverse-* snippets,
# applying Cosmos gating transforms, then rebuild theme.css.
#   craft/darker → :not(.layout-baseline)  (off in Standard flavour)
#   darker       → :not(.cosmos-light)      (off in "Superfici chiare" / Cupertino Light)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# --- Guardia (2026-08-03) ---------------------------------------------------
# cosmos-layer.css e cosmos-islands.css hanno SUPERATO gli snippet del vault
# con la tokenizzazione del 2026-07-10. Da allora il repo è la sorgente di
# verità e questo script è una regressione, non una sincronizzazione.
#
# Misurato il 2026-08-03, rieseguendo la trasformazione sugli snippet di oggi:
#   · reintroduce 3 durate ms raw   (ceiling: 0)  → contract.sh fallisce
#   · reintroduce 4 hex raw          (ceiling: 0)  → contract.sh fallisce
#   · porta gli !important da 10 a 12 (ceiling: 10) → contract.sh fallisce
#   · CANCELLA § ANGLAGE, cioè l'unica dichiarazione di --cosmos-pop-shadow
#     che il check #9 pretende esista → elevazione delle superfici flottanti
#     persa, e il check fallisce con base_sites=0
#   · CANCELLA il bridge .graph-view.color-*
#   · CANCELLA il contratto di elevazione delle card (--mv-card-rest sulla
#     .bases-cards-item), landato in questa stessa data
#
# Inoltre gli snippet NON girano: appearance.json abilita solo mv-icons-boot,
# quindi i marioverse-* sono artefatti storici congelati, non una sorgente viva.
# reference/marioverse-{bases,craft,tabs}.css divergono già dalle copie del vault.
#
# Per modificare i layer: si editano DIRETTAMENTE nel repo, poi ./build.sh.
echo "⛔ sync-snippets.sh è ritirato: il repo è la sorgente di verità dal 2026-07-10." >&2
echo "   Rieseguirlo romperebbe il design contract e cancellerebbe § ANGLAGE." >&2
echo "   Per modificare i layer: editali nel repo, poi ./build.sh." >&2
exit 1
SNIP="${1:-${OBSIDIAN_SNIPPETS_DIR:-}}"
if [[ -z "$SNIP" || ! -d "$SNIP" ]]; then
  echo "Usage: ./sync-snippets.sh /path/to/vault/.obsidian/snippets" >&2
  echo "Or set OBSIDIAN_SNIPPETS_DIR." >&2
  exit 1
fi

cp "$SNIP"/marioverse-*.css reference/

python3 - "$SNIP" <<'PY'
import sys, re
SNIP=sys.argv[1]
def read(n): return open(f"{SNIP}/marioverse-{n}.css").read()

craft  = read("craft").replace(":not(.is-phone)", ":not(.is-phone):not(.layout-baseline)")
darker = read("darker").replace("body.theme-dark.cupertino-dark",
                                "body.theme-dark.cupertino-dark:not(.layout-baseline):not(.cosmos-light)")
tabs, bases = read("tabs"), read("bases")
# Il §0 dello snippet bases ridefinisce --mv-* su body{}: utile stand-alone
# (senza Cosmos), ma nel bake i token vivono in cosmos-tokens.css (layer zero).
# Strippa quel body{} per non reintrodurre la duplicazione — arrivando dopo
# tokens per source-order, scavalcherebbe i valori flavour-aware (es. i radii
# di Notion). I nomi --mv-* restano consumati; qui rimuoviamo solo la ri-def.
bases = re.sub(r"\nbody \{[^}]*\}\n", "\n", bases, count=1, flags=re.S)

header = """
/* ==========================================================================
   ███  COSMOS LAYER  ███
   Baked-in sopra la base Baseline (fork). Assemblato dagli snippet marioverse-*
   del vault (copie in reference/) via ./sync-snippets.sh, con gating Cosmos:
     • craft/darker → :not(.layout-baseline)  (spenti nel flavour Standard)
     • darker       → :not(.cosmos-light)      (spento in "Superfici chiare" = Cupertino Light)
   Ordine: tabs (behavior) · craft (tab UI) · darker (dark surfaces) · bases (Bases skin).
   ========================================================================== */
"""
out = (header
    + "\n\n/* ===== TABS BEHAVIOR ===== */\n" + tabs
    + "\n\n/* ===== CRAFT TABS (gated :not(.layout-baseline)) ===== */\n" + craft
    + "\n\n/* ===== DARKER (gated :not(.layout-baseline):not(.cosmos-light)) ===== */\n" + darker
    + "\n\n/* ===== BASES SKIN ===== */\n" + bases)
open("cosmos-layer.css","w").write(out)
open("cosmos-islands.css","w").write(read("sidebar-island"))
print("layers re-synced from snippets")
PY

./build.sh
echo "Done. Deploy with: ./deploy.sh <vault>"
