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

# 9. Elevazione: UNA sola sede (dynamics-and-depth §A/Contract#1). Le sei
#    superfici flottanti (.menu, .suggestion-container, .prompt, .popover,
#    .modal, .tooltip) prendono il loro gradino di elevazione — cioè
#    `box-shadow: var(--cosmos-pop-shadow)` — da UNA sola regola
#    flavour-agnostica in cosmos-layer.css § ANGLAGE, gated
#    `body:is(.theme-dark, .theme-light):not(.layout-baseline)` (il gate di
#    schema non esclude nulla — ogni body Obsidian ha una delle due classi —
#    serve al PESO di specificità: porta la base a (0,3,1), quanto basta per
#    battere `.modal-container.mod-dim .modal` di app.css senza important).
#    Ogni altra dichiarazione della stessa
#    ombra su una di quelle sei classi è una duplicazione: le flavour
#    possono AGGIUNGERE (surface, backdrop-filter, geometria), non
#    ridichiarare la base. È il difetto misurato del design doc (finding 1):
#    due copie della stessa ricetta con coperture divergenti → .menu senza
#    elevazione sulla flavour attiva.
#    Nota: superfici NON flottanti che usano lo stesso token (mobile-navbar,
#    toolbar, ribbon, pannelli interni) restano libere — la scala è un
#    linguaggio condiviso, il vincolo è solo sulle sei classi.
if contract.get('elevation_anti_dup_check'):
    floating_selectors = {'.menu', '.suggestion-container', '.prompt',
                          '.popover', '.modal', '.tooltip'}
    allowed_file = 'cosmos-layer.css'
    allowed_gate = 'body:is(.theme-dark, .theme-light):not(.layout-baseline)'
    rule_re = re.compile(r'([^{}]+)\{([^{}]*)\}', re.S)
    base_sites = 0
    for f, css in texts.items():
        if css is None: continue
        for sel_block, decl in rule_re.findall(strip_comments(css)):
            if not re.search(r'box-shadow\s*:\s*var\(\s*--cosmos-pop-shadow\s*\)', decl):
                continue
            # Solo il compound RIGHTMOST di ogni comma-branch conta: una
            # regola su `.modal.mod-settings .vertical-tab-header` non sta
            # ridichiarando l'elevazione di `.modal` — sta stilando un
            # discendente diverso. E il match è per TOKEN di classe esatto,
            # non per sottostringa: `.menu-item` non è `.menu`.
            targets = set()
            for branch in sel_block.split(','):
                parts = branch.strip().split()
                if not parts: continue
                targets |= floating_selectors.intersection(
                    re.findall(r'\.[-\w]+', parts[-1]))
            if not targets:
                continue
            if f == allowed_file and allowed_gate in sel_block:
                base_sites += 1
            else:
                failures.append(
                    f"{f}: elevazione base (box-shadow: var(--cosmos-pop-shadow)) ridichiarata per "
                    f"{sorted(targets)} fuori dalla sede unica ({allowed_file}, gate '{allowed_gate}') — "
                    f"le flavour devono aggiungere i propri delta, non ridichiarare la base"
                )
    # UNA regola significa UNA: una seconda copia dentro il file consentito e
    # con lo stesso gate passerebbe il controllo di sede pur ricreando
    # esattamente la duplicazione che questo check esiste per vietare.
    if base_sites != 1:
        failures.append(
            f"elevazione base dichiarata da {base_sites} regole in {allowed_file} (attesa: 1) — "
            f"la scala di elevazione ha UNA sola sede flavour-agnostica"
        )

# 10. Style Settings i18n: il blocco @settings di cosmos-base.css è la UI che
#     l'utente finale vede nel plugin Style Settings — deve restare in
#     inglese (i ~106 commenti CSS interni in italiano altrove nel tema sono
#     fuori scope, per decisione esplicita). Stessa word-list delle
#     i18n-guard del plugin: fallisce se una riga title:/description: dentro
#     il blocco @settings contiene >= 2 parole funzionali italiane (match
#     whole-word, case-insensitive) — soglia 2 per non far scattare falsi
#     positivi su singole parole ambigue tra le due lingue (es. "i" come
#     iniziale, "per" come token isolato in codice).
ITALIAN_FUNCTION_WORDS = {
    'il', 'lo', 'la', 'i', 'gli', 'le', 'un', 'una', 'di', 'del', 'della',
    'dei', 'delle', 'che', 'con', 'per', 'non', 'come', 'anche', 'più',
    'sono', 'sulla', 'nella', 'quando', 'se', 'tra', 'questo', 'questa',
}
base_css = read('cosmos-base.css')
if base_css is not None:
    m = re.search(r'/\*\s*@settings(.*?)\*/', base_css, re.S)
    settings_block = m.group(1) if m else ''
    word_re = re.compile(r"[a-zà-ÿ']+", re.I)
    for lineno, line in enumerate(settings_block.splitlines(), start=1):
        stripped = line.strip()
        if not (stripped.startswith('title:') or stripped.startswith('description:')):
            continue
        words = {w.lower() for w in word_re.findall(stripped)}
        hits = words & ITALIAN_FUNCTION_WORDS
        if len(hits) >= 2:
            failures.append(
                f"cosmos-base.css: @settings line ~{lineno} looks Italian "
                f"(function words: {sorted(hits)}) — {stripped[:100]}"
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
