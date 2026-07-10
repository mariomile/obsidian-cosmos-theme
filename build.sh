#!/usr/bin/env bash
# Rebuild theme.css = pruned Baseline base + Cosmos source layers.
# The base (everything before the first "COSMOS LAYER" marker) is preserved;
# the source layers are re-appended fresh (tokens first — the other layers
# consume them). Edit the *.css layer sources, then run ./build.sh.
# After the rebuild, contract.sh runs the static design-contract preflight
# (ratchet on !important / raw hex / raw ms / focus-visible floor / dup props).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

python3 - <<'PY'
import os
lines = open('theme.css').read().split('\n')
# Cut at the FIRST Cosmos marker: tokens (when present) precede the layer.
i = next(k for k,l in enumerate(lines) if 'COSMOS TOKENS' in l or 'COSMOS LAYER' in l)
cut = i-1                                    # the '/* ===' opener line
while cut>0 and lines[cut-1].strip()=='' : cut-=1   # trim blank lines before it
base = lines[:cut]
# --- @layer wrap: TENTATO E RITIRATO (2026-07-10) ----------------------------
# L'idea era wrappare la base in `@layer baseline{}` così i layer Cosmos
# (unlayered) vincono senza !important. NON FUNZIONA: app.css di Obsidian è
# unlayered e viene prima → unlayered batte layered → app.css vincerebbe su
# TUTTA la base layerata (radius dimezzati, bottoni nativi del file explorer
# riapparsi, divider fra le tab, ecc. — regressioni viste live). Un tema
# Obsidian DEVE restare unlayered per battere app.css. Gli override Cosmos
# contro la base tornano a vincere con !important mirati (documentati inline).
# Qui facciamo solo UNWRAP di un eventuale wrap residuo di quel tentativo.
line = base[0]
if line.startswith('@layer baseline{'):
    line = line[len('@layer baseline{'):]
    if line.endswith('}'):  line = line[:-1]
    if line.endswith('*/'): line = line[:-2]
base[0] = line
rest = base[1:]
while rest and rest[0].strip() == '@layer baseline{' : rest = rest[1:]
while rest and rest[-1].strip() == '} /* end @layer baseline */' : rest = rest[:-1]
base = [base[0]] + rest
parts = base + ['']
LAYERS = ['cosmos-tokens.css','cosmos-layer.css','cosmos-islands.css','cosmos-tweaks.css']
used = [fn for fn in LAYERS if os.path.exists(fn)]
for fn in used:
    parts += open(fn).read().split('\n')
open('theme.css','w').write('\n'.join(parts))
o = '\n'.join(parts)
assert o.count('{') == o.count('}'), f"brace mismatch {o.count('{{')} vs {o.count('}}')}"
print(f"theme.css rebuilt — base {cut} lines + {len(used)} layers = {len(parts)} lines, braces balanced")
PY

./contract.sh
