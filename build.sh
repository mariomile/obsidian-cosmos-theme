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
LAYERS = ['cosmos-tokens.css','cosmos-layer.css','cosmos-islands.css','cosmos-tweaks.css']
used = [fn for fn in LAYERS if os.path.exists(fn)]
for fn in used:
    parts += open(fn).read().split('\n')
open('theme.css','w').write('\n'.join(parts))
o = '\n'.join(parts)
assert o.count('{') == o.count('}'), f"brace mismatch {o.count('{{')} vs {o.count('}}')}"
print(f"theme.css rebuilt — base {len(base)} lines + {len(used)} layers = {len(parts)} lines, braces balanced")
PY

./contract.sh
