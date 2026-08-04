#!/usr/bin/env bash
# Rebuild theme.css = pinned Baseline source + Cosmos source layers.
# Every input is explicit, so a clean checkout can reproduce theme.css without
# using a previous generated theme.css as an implicit source.
# After the rebuild, contract.sh runs the static design-contract preflight
# (ratchet on !important / raw hex / raw ms / focus-visible floor / dup props).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

python3 - <<'PY'
import os, re

# --- Sfrondatura delle personalità inutilizzate (2026-08-04) ----------------
# Baseline spedisce sei "Personality" (cupertino, material, fluent, adwaita,
# tactile, baseline). Cosmos ne usa UNA: input-cupertino è il default e la sola
# su cui è tarata l'identità New Craft. Le altre restano nel foglio e ogni loro
# regola va comunque confrontata con ogni elemento a ogni ricalcolo di stile.
#
# Misurato il 2026-08-04, apertura di una nota (long task, PerformanceObserver):
#   nessun tema        1 task,  60-77ms
#   base completa      2-5 task, 230-347ms
#   base sfrondata     1 task,  105-132ms
# 228 regole in meno — l'8% dei byte — dimezzano abbondantemente il costo.
#
# La sfrondatura avviene QUI, a build time: cosmos-base.css resta il fork
# pinnato e intatto, quindi ri-sincronizzare Baseline resta possibile e questa
# scelta si annulla svuotando la lista.
DROP_PERSONALITIES = ()

def trim_personalities(css: str) -> tuple[str, int]:
    kept, dropped, i, n = [], 0, 0, len(css)
    while i < n:
        j = css.find('{', i)
        if j == -1:
            kept.append(css[i:]); break
        sel = css[i:j]
        depth, k = 1, j + 1
        while k < n and depth:
            if css[k] == '{': depth += 1
            elif css[k] == '}': depth -= 1
            k += 1
        if not sel.lstrip().startswith('@') and any(d in sel for d in DROP_PERSONALITIES):
            dropped += 1
        else:
            kept.append(css[i:k])
        i = k
    return ''.join(kept), dropped

raw = open('cosmos-base.css').read().rstrip('\n')
if DROP_PERSONALITIES:
    # Il blocco @settings è un commento: si estrae, si sfronda il solo CSS, si
    # rimette. Altrimenti il conteggio graffe della sfronda leggerebbe le
    # parentesi dentro la prosa delle description.
    comments = []
    def _stash(m):
        comments.append(m.group(0)); return f'/*__C{len(comments)-1}__*/'
    stashed = re.sub(r'/\*.*?\*/', _stash, raw, flags=re.S)
    trimmed, n_dropped = trim_personalities(stashed)
    raw = re.sub(r'/\*__C(\d+)__\*/', lambda m: comments[int(m.group(1))], trimmed)
    print(f'sfrondate {n_dropped} regole delle personalità non usate')

base = raw.split('\n')
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
