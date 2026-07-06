#!/usr/bin/env bash
# Rebuild theme.css = pruned Baseline base + Cosmos source layers.
# The base (everything before the first "COSMOS LAYER" marker) is preserved;
# the three source layers are re-appended fresh. Edit the *.css layer sources,
# then run ./build.sh to regenerate theme.css.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

python3 - <<'PY'
lines = open('theme.css').read().split('\n')
i = next(k for k,l in enumerate(lines) if 'COSMOS LAYER' in l)
cut = i-1                                    # the '/* ===' opener line
while cut>0 and lines[cut-1].strip()=='' : cut-=1   # trim blank lines before it
base = lines[:cut]
parts = base + ['']
for fn in ['cosmos-layer.css','cosmos-islands.css','cosmos-tweaks.css']:
    parts += open(fn).read().split('\n')
open('theme.css','w').write('\n'.join(parts))
o = '\n'.join(parts)
assert o.count('{') == o.count('}'), f"brace mismatch {o.count('{{')} vs {o.count('}}')}"
print(f"theme.css rebuilt — base {cut} lines + 3 layers = {len(parts)} lines, braces balanced")
PY
