#!/usr/bin/env bash
# Static design-contract preflight (idea #6a of the pixel-perfect plan).
# Ratchet checks against design-contract.json: metrics may only go down.
# Run standalone or via build.sh (which calls it after rebuilding theme.css).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

python3 - <<'PY'
import json, re, sys

contract = json.load(open('design-contract.json'))
LAYERS = ['cosmos-tokens.css', 'cosmos-layer.css', 'cosmos-islands.css', 'cosmos-tweaks.css', 'cosmos-phone.css']
failures, warnings = [], []

def read(f):
    try:
        return open(f).read()
    except FileNotFoundError:
        return None  # tokens file lands in a later step

def strip_comments(css):
    return re.sub(r'/\*.*?\*/', '', css, flags=re.S)

texts = {f: read(f) for f in LAYERS}

# 1. !important ceiling per file
for f, ceil in contract['important_max'].items():
    css = texts.get(f)
    if css is None: continue
    n = strip_comments(css).count('!important')
    if n > ceil:
        failures.append(f"{f}: !important x{n} > ceiling {ceil}")

# 2. Raw hex ceiling per file (tokens file is exempt: it's where hexes live)
for f, ceil in contract['raw_hex_max'].items():
    if f == 'comment': continue
    css = texts.get(f)
    if css is None: continue
    n = len(re.findall(r'#[0-9a-fA-F]{3,8}\b', strip_comments(css)))
    if n > ceil:
        failures.append(f"{f}: raw hex x{n} > ceiling {ceil}")

# 3. Raw ms durations ceiling per file (tokens file exempt)
for f, ceil in contract['raw_ms_max'].items():
    if f == 'comment': continue
    css = texts.get(f)
    if css is None: continue
    n = len(re.findall(r'\b\d+ms\b', strip_comments(css)))
    if n > ceil:
        failures.append(f"{f}: raw ms durations x{n} > ceiling {ceil}")

# 4. :focus-visible floor (across all layers)
total_focus = sum(strip_comments(c).count(':focus-visible') for c in texts.values() if c)
if total_focus < contract['focus_visible_min']:
    failures.append(f":focus-visible x{total_focus} < floor {contract['focus_visible_min']}")

# 5. New duplicate custom-property definitions (outside allowlist).
#    Scope-aware: scheme/palette ROOT blocks (body.<scheme>.theme-dark{…},
#    body.<palette>.theme-light{…}, …) are BUILT to redefine the same palette
#    tokens per scheme — that's their job, not an accidental dup. Blank those
#    blocks out before counting, so the check still catches genuine accidental
#    dups everywhere else without allowlisting every palette token by hand.
allow = set(contract['duplicate_prop_allowlist'])
all_css = '\n'.join(strip_comments(c) for c in texts.values() if c)
scheme_block = re.compile(
    r'body(?:\.[\w-]+)*\.theme-(?:dark|light)(?:\.[\w-]+)*(?::not\([^)]*\))*\s*\{[^{}]*\}',
    re.S)
counted_css = scheme_block.sub('', all_css)
from collections import Counter
props = Counter(re.findall(r'(--[a-z0-9-]+)\s*:', counted_css))
for p, n in props.items():
    if n > 1 and p not in allow:
        failures.append(f"custom property {p} defined x{n} (not in duplicate allowlist)")

# 6. outline:none must carry a nearby comment (same rule block or preceding comment)
if contract.get('outline_none_requires_comment'):
    for f, css in texts.items():
        if css is None: continue
        for m in re.finditer(r'outline\s*:\s*none', css):
            window = css[max(0, m.start()-600):m.start()]
            # '*/' also counts: the window may start inside a long comment,
            # past its '/*' opener — the closer still proves a comment is near.
            if '/*' not in window and '*/' not in window:
                failures.append(f"{f}: outline:none at offset {m.start()} without a justifying comment nearby")


# 7. Ratchet mobile: gate escludenti (:not(.is-phone)/:not(.is-mobile)) e 100vh
if 'mobile_excluding_gates_max' in contract:
    n=0
    for f,css in texts.items():
        if css is None: continue
        n+=len(re.findall(r':not\(\.is-(?:phone|mobile)\)', strip_comments(css)))
    if n>contract['mobile_excluding_gates_max']:
        failures.append(f"gate mobile escludenti x{n} > ceiling {contract['mobile_excluding_gates_max']} (la polarity deve migliorare, non peggiorare)")
if 'raw_100vh_max' in contract:
    n=sum(len(re.findall(r'\b100vh\b', strip_comments(css))) for css in texts.values() if css)
    if n>contract['raw_100vh_max']:
        failures.append(f"100vh x{n} > ceiling {contract['raw_100vh_max']} (usare dvh: 100vh e' rotto su iOS)")

# 8. Toggle Style Settings nel PRIMO blocco @settings del theme.css buildato.
#    Style Settings ignora i blocchi successivi: un toggle fuori dal primo
#    blocco non si registra mai → feature silenziosamente inerte (2026-07-23).
if 'style_settings_first_block_required_ids' in contract:
    theme = read('theme.css') or ''
    m = re.search(r'/\*\s*@settings(.*?)\*/', theme, re.S)
    first = m.group(1) if m else ''
    for rid in contract['style_settings_first_block_required_ids']:
        if not re.search(r'^\s*id:\s*' + re.escape(rid) + r'\s*$', first, re.M):
            failures.append(f"Style Settings: id '{rid}' assente dal PRIMO blocco @settings di theme.css (i blocchi successivi sono ignorati dal plugin)")

# 9. Anti-duplicazione elevazione (dynamics-and-depth §A/Contract#1). Le
#    superfici flottanti (.menu, .suggestion-container, .prompt, .popover,
#    .modal, .tooltip) ricevono la loro ombra BASE (background-color +
#    box-shadow: var(--cosmos-pop-shadow) nello stesso blocco di regola) da
#    UNA sola sede flavour-agnostica: cosmos-layer.css § ANGLAGE
#    (gate `body.theme-dark.cupertino-dark:not(.layout-baseline):not(.cosmos-light)`,
#    che è il gate "qualunque flavour scuro Cosmos non-Baseline/non-Light" —
#    l'unico consentito a dichiarare la base). Qualsiasi ALTRO blocco che
#    ridichiari ENTRAMBE le proprietà sullo stesso selettore flottante è una
#    duplicazione: le flavour possono SOVRASCRIVERE proprietà additive (es.
#    backdrop-filter) ma non re-includere box-shadow insieme a un
#    background sullo stesso selettore — quello è il pattern che ha causato
#    la deriva di copertura misurata (finding 1).
if contract.get('elevation_anti_dup_check'):
    floating_selectors = ['.menu', '.suggestion-container', '.prompt',
                           '.popover', '.modal', '.tooltip']
    allowed_file = 'cosmos-layer.css'
    allowed_gate = 'body.theme-dark.cupertino-dark:not(.layout-baseline):not(.cosmos-light)'
    rule_re = re.compile(r'([^{}]+)\{([^{}]*)\}', re.S)
    for f, css in texts.items():
        if css is None: continue
        for sel_block, decl in rule_re.findall(strip_comments(css)):
            has_bg = re.search(r'\bbackground(?:-color)?\s*:', decl)
            has_pop_shadow = re.search(r'box-shadow\s*:\s*var\(--cosmos-pop-shadow\)', decl)
            if not (has_bg and has_pop_shadow):
                continue
            # Solo il selettore RIGHTMOST di ogni comma-branch conta: una
            # regola su `.modal.mod-settings .vertical-tab-header` non sta
            # ridichiarando l'elevazione di `.modal` — sta stilando un
            # discendente più specifico e diverso. Guardiamo solo l'ultimo
            # simple-selector di ogni branch (dopo l'ultimo combinatore).
            branches = sel_block.split(',')
            rightmost = [b.strip().split()[-1] if b.strip().split() else '' for b in branches]
            targets = sorted({s for s in floating_selectors
                               for r in rightmost if s in r})
            if not targets:
                continue
            is_allowed_site = (f == allowed_file and allowed_gate in sel_block)
            if not is_allowed_site:
                failures.append(
                    f"{f}: elevazione base (background+--cosmos-pop-shadow) ridichiarata per {targets} "
                    f"fuori dalla sede unica ({allowed_file}, gate '{allowed_gate}') — le flavour devono "
                    f"sovrascrivere/aggiungere, non ridichiarare la base"
                )

if warnings:
    print("contract warnings:")
    for w in warnings: print(f"  ⚠ {w}")
if failures:
    print("DESIGN CONTRACT VIOLATIONS:")
    for f in failures: print(f"  ✗ {f}")
    sys.exit(1)
print(f"design contract OK ({total_focus} :focus-visible, ceilings respected)")
PY
