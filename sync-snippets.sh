#!/usr/bin/env bash
# Re-sync Cosmos layers from local marioverse-* snippets,
# applying Cosmos gating transforms, then rebuild theme.css.
#   craft/darker → :not(.layout-baseline)  (off in Standard flavour)
#   darker       → :not(.cosmos-light)      (off in "Superfici chiare" / Cupertino Light)
# Run after editing the snippets in the vault. Read-only on the vault.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
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
