#!/usr/bin/env bash
# Rebuild theme.css = pinned Baseline source + Cosmos source layers.
# Every input is explicit, so a clean checkout can reproduce theme.css without
# using a previous generated theme.css as an implicit source.
# After the rebuild, contract.sh runs the static design-contract preflight
# (ratchet on !important / raw hex / raw ms / focus-visible floor / dup props).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

python3 - <<'PY'
import os
base = open('cosmos-base.css').read().rstrip('\n').split('\n')
parts = base + ['']
LAYERS = ['cosmos-tokens.css','cosmos-layer.css','cosmos-islands.css','cosmos-tweaks.css','cosmos-phone.css']
used = [fn for fn in LAYERS if os.path.exists(fn)]
for fn in used:
    parts += open(fn).read().split('\n')

# Commenti bilanciati, PER FILE. Un `*/` di troppo (tipico: si estende un
# commento incollando il testo DOPO la sua riga di chiusura) lascia testo nudo
# fuori da ogni commento: il parser CSS scarta fino al punto di recupero e si
# mangia silenziosamente la regola successiva. Le graffe restano bilanciate,
# quindi il check qui sotto non lo vede — e il CSS morto arriva a schermo.
# Misurato il 2026-08-02 su § CHROME DISTINTO: regola live nel <style>,
# selettore che matcha, ma assente dal CSSOM.
for fn in used:
    src = open(fn).read()
    o_, c_ = src.count('/*'), src.count('*/')
    assert o_ == c_, f"{fn}: commenti sbilanciati — {o_} aperture '/*' vs {c_} chiusure '*/' (un '*/' orfano uccide la regola che segue)"

open('theme.css','w').write('\n'.join(parts))
o = '\n'.join(parts)
assert o.count('{') == o.count('}'), f"brace mismatch {o.count('{{')} vs {o.count('}}')}"
print(f"theme.css rebuilt — base {len(base)} lines + {len(used)} layers = {len(parts)} lines, braces + comments balanced")
PY

./contract.sh
