#!/usr/bin/env bash
# Live pixel contract (idea #6b of the pixel-perfect plan).
# Runs the assertions in verify-spec.json against the RUNNING Obsidian vault
# via `obsidian-cli eval` — the theme's live-DOM oracle. Selectors not in the
# DOM (closed modals, collapsed panes) report SKIP, not FAIL.
# Usage: ./verify.sh          (after build.sh + deploy.sh + theme reload)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

BIN="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"
[ -x "$BIN" ] || { echo "obsidian-cli not found at $BIN"; exit 2; }

SPEC=$(jq -c '.assertions' verify-spec.json)

JS=$(cat <<JS
(()=>{
  const spec = ${SPEC};
  const results = spec.map(a=>{
    if(a.skipIfBodyClass && document.body.classList.contains(a.skipIfBodyClass))
      return {name:a.name, status:"SKIP", note:"toggle "+a.skipIfBodyClass+" active"};
    const el = document.querySelector(a.selector);
    if(!el) return {name:a.name, status:"SKIP", note:"selector not in DOM"};
    const cs = getComputedStyle(el);
    const actual = a.property.startsWith("--")
      ? cs.getPropertyValue(a.property).trim()
      : cs.getPropertyValue(a.property).trim();
    return actual === a.expected
      ? {name:a.name, status:"PASS"}
      : {name:a.name, status:"FAIL", expected:a.expected, actual};
  });
  return JSON.stringify({theme: app.customCss.theme, results});
})()
JS
)

RAW=$("$BIN" eval code="$JS" 2>&1 | sed 's/^=> //' | tail -1)

python3 - "$RAW" <<'PY'
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("verify: could not parse obsidian-cli output — is Obsidian running with the vault focused?")
    print(sys.argv[1][:300]); sys.exit(2)
if data.get("theme") != "Cosmos":
    print(f"verify: active theme is {data.get('theme')!r}, not Cosmos — assertions assume Cosmos. Aborting.")
    sys.exit(2)
p = f = s = 0
for r in data["results"]:
    st = r["status"]
    if st == "PASS": p += 1; print(f"  ✓ {r['name']}")
    elif st == "SKIP": s += 1; print(f"  ○ {r['name']} (skipped: {r['note']})")
    else: f += 1; print(f"  ✗ {r['name']}: expected {r['expected']!r}, got {r['actual']!r}")
print(f"\nverify: {p} pass, {f} fail, {s} skip")
sys.exit(1 if f else 0)
PY
