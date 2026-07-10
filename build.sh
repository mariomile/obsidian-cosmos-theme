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
# --- @layer wrap (2026-07-10, idea #7) --------------------------------------
# The minified Baseline base (line 1) is wrapped in `@layer baseline { ... }`.
# The Cosmos layers stay UNLAYERED: unlayered author styles beat layered ones
# regardless of selector specificity, so Cosmos declarations win without
# !important. (Checked: none of the base's own 81 !important collide with
# Cosmos fights.) User snippets — also unlayered, loaded later — beat both.
# Idempotente: prima UNWRAP di un eventuale wrap precedente, poi re-wrap.
# GOTCHA (scoperto live 2026-07-10): la base minificata termina con un
# commento PENDENTE (`/*!`). Senza chiuderlo, la `}` del layer viene
# inghiottita dal commento → il blocco @layer resta aperto → TUTTI i layer
# Cosmos finiscono layered dentro `baseline` e perdono la cascade war.
line = base[0]
if line.startswith('@layer baseline{'):
    line = line[len('@layer baseline{'):]
    if line.endswith('}'):  line = line[:-1]
    if line.endswith('*/'): line = line[:-2]
if line.count('/*') > line.count('*/'):
    line += '*/'                          # chiude il commento pendente
base[0] = '@layer baseline{' + line + '}'
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
