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
  // Gotcha Obsidian: su pane non-painting le CSSTransition restano "running"
  // congelate al valore di partenza → getComputedStyle riporta il valore
  // animato, non lo steady-state del CSS. Chiudiamo tutte le animazioni
  // prima di misurare (finish() lancia sulle infinite → try/catch).
  document.getAnimations().forEach(a=>{ try{ a.finish(); }catch(e){} });
  // Probe: resolve a custom property to a concrete color (color-mix & var
  // chains resolve only when applied to a real property, not on the raw var).
  const probe = document.createElement("div");
  probe.style.display = "none";
  document.body.appendChild(probe);
  const resolveVar = (v)=>{ probe.style.backgroundColor = "var(" + v + ")"; return getComputedStyle(probe).backgroundColor; };
  const results = spec.map(a=>{
    if(a.skipIfBodyClass && document.body.classList.contains(a.skipIfBodyClass))
      return {name:a.name, status:"SKIP", note:"toggle "+a.skipIfBodyClass+" active"};
    if(a.ruleExists){
      let found=false;
      for(const sheet of document.styleSheets){
        let rules; try{rules=sheet.cssRules}catch(e){continue;}
        // NB: con il CSS nesting ogni CSSStyleRule ha cssRules (vuota ma truthy):
        // testare selectorText SEMPRE, e ricorrere solo se la lista ha elementi.
        const walk=(rs)=>{for(const r of rs){ if(r.selectorText && r.selectorText.includes(a.ruleExists)) found=true; if(r.cssRules && r.cssRules.length) walk(r.cssRules); }};
        walk(rules);
        if(found) break;
      }
      return found ? {name:a.name, status:"PASS"} : {name:a.name, status:"FAIL", expected:"rule "+a.ruleExists, actual:"not found in any stylesheet"};
    }
    if(a.resolveVar){
      const actual = resolveVar(a.resolveVar);
      // Normalize the expected value through the SAME probe: the browser may
      // serialize color-mix results as color(srgb ...) instead of rgb(...).
      probe.style.backgroundColor = "";
      probe.style.backgroundColor = a.expected;
      const expectedNorm = getComputedStyle(probe).backgroundColor;
      const pass = actual === expectedNorm || actual === a.expected ||
        (()=>{ // last resort: numeric compare via color(srgb r g b) / rgb(r,g,b)
          const num = s => (s.match(/[\d.]+/g)||[]).map(Number).map(x=>x<=1?Math.round(x*255):Math.round(x)).slice(0,3).join(",");
          return num(actual) === num(expectedNorm) && num(actual).length>0;
        })();
      return pass
        ? {name:a.name, status:"PASS"}
        : {name:a.name, status:"FAIL", expected:expectedNorm, actual};
    }
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
