#!/usr/bin/env bash
# Mobile verification harness (ideazione mobile #4, 2026-07-10 — v2 class-injection).
#
# SCOPERTA (v1, ritirata): sotto EmulateMobile muore anche il dev-bridge di
# obsidian-cli (è un plugin Node) → `eval` non esiste dentro l'emulazione, e
# quindi non si può misurare nulla da script. L'emulazione resta utile solo
# per l'eyeball manuale.
#
# v2: CLASS-INJECTION. Iniettiamo `is-mobile is-phone` sul body, misuriamo i
# computed style (i gate CSS del tema si attivano — è esattamente ciò che va
# testato), poi rimuoviamo le classi nello stesso eval. EmulateMobile non
# viene MAI toccato → il footgun "plugin Node morti al boot" è impossibile
# by design, non per disciplina.
#
# Limiti onesti: (1) non testa il vero UI-tree mobile di Obsidian (chrome,
# toolbar) — solo i gate CSS; (2) engine Chromium: i bug WebKit-only
# (aspect-ratio drift, 100vh, backdrop-filter perf) NON compaiono → sign-off
# finale su iPhone reale.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

BIN="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"
[ -x "$BIN" ] || { echo "obsidian-cli non trovato"; exit 2; }

SPEC=$(jq -c '.assertions' verify-mobile-spec.json)

JS=$(cat <<JS
(()=>{
  const spec = ${SPEC};
  document.getAnimations().forEach(a=>{ try{ a.finish(); }catch(e){} });
  // Inietta le classi phone (i gate CSS del tema si attivano), misura, pulisci.
  const added=[];
  for(const c of ["is-mobile","is-phone"]) if(!document.body.classList.contains(c)){ document.body.classList.add(c); added.push(c); }
  let out;
  try{
    const probe = document.createElement("div");
    probe.style.display = "none";
    document.body.appendChild(probe);
    const resolveVar = (v)=>{ probe.style.backgroundColor = "var(" + v + ")"; return getComputedStyle(probe).backgroundColor; };
    const results = spec.map(a=>{
      if(a.bodyClass){
        const has=document.body.classList.contains(a.bodyClass);
        return has===(a.expected!==false) ? {name:a.name,status:"PASS"} : {name:a.name,status:"FAIL",expected:"body."+a.bodyClass+"="+(a.expected!==false),actual:String(has)};
      }
      if(a.resolveVar){
        const actual = resolveVar(a.resolveVar);
        probe.style.backgroundColor=""; probe.style.backgroundColor=a.expected;
        const norm=getComputedStyle(probe).backgroundColor;
        const num=s=>(s.match(/[\\d.]+/g)||[]).map(Number).map(x=>x<=1?Math.round(x*255):Math.round(x)).slice(0,3).join(",");
        const pass = actual===norm || actual===a.expected || (num(actual)===num(norm)&&num(actual).length>0);
        return pass?{name:a.name,status:"PASS"}:{name:a.name,status:"FAIL",expected:norm,actual};
      }
      const el=document.querySelector(a.selector);
      if(!el) return {name:a.name,status:"SKIP",note:"selector not in DOM"};
      const cs=getComputedStyle(el);
      const actual=cs.getPropertyValue(a.property).trim();
      return actual===a.expected?{name:a.name,status:"PASS"}:{name:a.name,status:"FAIL",expected:a.expected,actual};
    });
    probe.remove();
    out={injected:added, results};
  } finally {
    for(const c of added) document.body.classList.remove(c);
  }
  return JSON.stringify(out);
})()
JS
)

RAW=$("$BIN" eval code="$JS" 2>&1 | sed 's/^=> //' | tail -1)

python3 - "$RAW" <<'PY'
import json,sys
try: data=json.loads(sys.argv[1])
except Exception:
    print("verify-mobile: output non parsabile — Obsidian attivo?"); print(sys.argv[1][:300]); sys.exit(2)
p=f=s=0
for r in data["results"]:
    st=r["status"]
    if st=="PASS": p+=1; print(f"  ✓ {r['name']}")
    elif st=="SKIP": s+=1; print(f"  ○ {r['name']} ({r['note']})")
    else: f+=1; print(f"  ✗ {r['name']}: expected {r['expected']!r}, got {r['actual']!r}")
print(f"\nverify-mobile: {p} pass, {f} fail, {s} skip  (class-injection su Chromium — sign-off WebKit su iPhone reale)")
sys.exit(1 if f else 0)
PY
