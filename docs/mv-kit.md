# mv-kit — Marioverse suite coherence checklist

Normative audit gate for the suite-coherence rollout (see
`docs/2026-07-24-suite-coherence-design.md`, section B). Every rule here is
checkable yes/no against a plugin. Nothing in this file is invented: every
token and value is extracted verbatim from `cosmos-tokens.css` /
`cosmos-phone.css` in this repo. If a rule can't be checked yes/no, it
doesn't belong here.

**Golden rule:** plugins are theme-independent. They never define
`--mv-*` / `--cosmos-*` at `:root`. They **consume** Cosmos tokens with an
inline fallback so the plugin still looks correct with Cosmos absent:

```css
/* Shipped example — obsidian-portal, portal/styles.css */
.portal-rail {
  --portal-motion: var(--cosmos-t-fast, 120ms) var(--mv-lift, cubic-bezier(0.22, 1, 0.36, 1));
}
```

> MUST: every `var(--cosmos-*)` / `var(--mv-*)` consumed by a plugin has a
> literal fallback value in the same declaration.
> MUST NOT: a plugin stylesheet redefines `--mv-*` or `--cosmos-*` on
> `:root` / `body`.

> ⚠️ **MUST NOT: write a token glob immediately followed by a slash inside a
> CSS comment.** That character pair closes the comment early; everything
> after it parses as garbage and the browser **silently drops the enclosing
> rule**. This is invisible to eslint, tsc and to the raw-value scan — it cost
> Sonar its `.sonar-modal { width: 880px }` in the 2026-07 audit wave (the
> modal collapsed to Obsidian's 560px default and the filter row clipped).
> In prose write "the `--cosmos-` and `--mv-` tokens", never the glob-slash
> pair. Guarded by the `no CSS comment terminates early` assertion in each
> repo's style contract — port it when adding a contract to a new repo.

---

## 1. Radius + surfaces scale

Source: `cosmos-tokens.css`.

| Token | Canonical value | Desktop use | Phone use |
|---|---|---|---|
| `--cosmos-r-pill` | `var(--cosmos-tab-radius, var(--tab-radius, 8px))` | Tab pill radius | Same — pill geometry doesn't change on phone |
| `--cosmos-r-tabbar` | `calc(var(--cosmos-r-pill) + var(--cosmos-tab-inset))` | Tab bar container radius (concentric with pill, never a standalone number) | Same |
| `--cosmos-r-fusion-tab` | `999px` | Fusion-flavour tab (full pill) | Same |
| `--cosmos-r-fusion-tabbar` | `calc(var(--cosmos-r-fusion-tab) + var(--cosmos-tab-inset))` | Fusion tab bar container | Same |
| `--cosmos-r-floating-surface` | `var(--radius-m)` | Menus, popovers, floating panels | Same base; phone bottom-sheets additionally round only the top corners with `--radius-xl` (see `cosmos-phone.css` `.menu` rule) |
| `--mv-r1` | `6px` | Chip / toolbar radius (suite-wide contract, shared with exo `--mva-r1`) | Same |
| `--mv-r-card` | `11px` | Card radius (= masonry `--masonry-radius`) | Same |
| `--mv-r-chip` | `5px` | Tag chip radius (= `.masonry-tag-chip`) | Same |
| `--cosmos-glass-surface` | `color-mix(in srgb, var(--background-primary) 78%, transparent)` | Fusion glass surface (editor/settings/ribbon/drawer) | Same |
| `--cosmos-glass-surface-strong` | `color-mix(in srgb, var(--background-secondary) 86%, transparent)` | Stronger glass variant | Same |
| `--cosmos-glass-outline` | `1px solid color-mix(in srgb, var(--text-muted) 16%, transparent)` | Glass surface outline | Same |
| `--cosmos-island-shadow` | 2-layer shadow (dark: `rgba(0,0,0,.16) 0 24px 48px, rgba(0,0,0,.12) 0 4px 16px`) | Sidebar island elevation | Same recipe |
| `--cosmos-pop-shadow` | 2-layer shadow (dark: `rgba(0,0,0,.28) 0 12px 32px, rgba(0,0,0,.16) 0 2px 8px`) | Floating surface elevation (menu/tooltip/popover/prompt) | Also used for the phone navbar pill and bottom-sheet menu elevation |

> MUST: any plugin-defined radius that visually matches "pill", "card", or
> "chip" consumes the matching `--mv-r*` / `--cosmos-r-*` token with its
> canonical fallback above — not a hand-picked pixel value.
> MUST: plugins never hardcode elevation shadows for floating surfaces —
> consume `--cosmos-pop-shadow` (or fall back to its literal value) instead.

---

## 2. Type sizes, icon sizes, touch targets

| Token | Canonical value | Desktop | Phone |
|---|---|---|---|
| `--font-ui-smaller` (native, consumed by Cosmos) | `calc(12px + var(--font-ui-modifier))` | Micro-label / eyebrow text | Same — used verbatim in `cosmos-phone.css` for the Properties micro-label and the backlinks empty-state |
| Icon sizing | native `--icon-size-*` / `--icon-*-stroke-width` (Cosmos defines no separate icon-size scale) | Icons follow Obsidian's native icon-size tokens | Same tokens; no phone-specific icon scale exists |
| `--cosmos-touch-min` | `44px` | N/A (no minimum enforced) | **MUST**: every tappable target (`.view-header .view-action`, `.clickable-icon`, toolbar options) has `min-width`/`min-height: var(--cosmos-touch-min, 44px)` |

> MUST: on phone, no interactive element has a computed hit area below
> `--cosmos-touch-min` (44px). Checkable via `min-width`/`min-height` in the
> phone-scoped stylesheet.
> MUST NOT: a plugin ships a bespoke micro-label font size on phone instead
> of `var(--font-ui-smaller, 12px)`.

---

## 3. Motion

Source: `cosmos-tokens.css` (durations, easings) + `cosmos-phone.css`
(animation recipes).

| Token | Canonical value | Desktop | Phone |
|---|---|---|---|
| `--cosmos-t-fast` | `140ms` | Micro feedback (hover wash, colour, press-scale) | Same — also drives `cosmos-fade-in` |
| `--cosmos-t-base` | `180ms` | Physical lift (card shadow, pill), popover pop-in | Same — also drives `cosmos-pop-in` |
| `--cosmos-t-slow` | `260ms` | Progress / extensions | Same, no phone-only usage |
| `--cosmos-t-panel` | `300ms` | Structural panel movement (sidebar open/close, ribbon peek) | Same — also drives `cosmos-sheet-rise` (modal/bottom-sheet entrance) |
| `--cosmos-native` | `cubic-bezier(0.32, 0.72, 0, 1)` | Default easing for panels/structural motion — no overshoot | Same — the easing for all three phone entrance keyframes |
| `--cosmos-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Confirmation micro-moments ONLY (press-release of a tab, checkbox tap) — never on hover/reveal | Same rule; no phone-only carve-out |
| `--mv-lift` | `cubic-bezier(0.22, 1, 0.36, 1)` | Physical hover/reveal easing (suite-wide, = exo `--mva-ease-out`) | Same — hover is rare on touch but the token still applies to press/reveal transitions |
| `--mv-wash` | `cubic-bezier(0.25, 1, 0.5, 1)` | Colour/background wash easing (= masonry `--masonry-ease`) | Same |
| `--mv-t` | `var(--cosmos-t-fast)` (0.14s) | Bridge alias consumed by exo (`--mva-t`) | Same |
| `--cosmos-press-scale` | `0.98` | N/A (no press-scale defined for pointer/desktop) | **MUST**: tap targets apply `transform: scale(var(--cosmos-press-scale, 0.98))` on active/press |

Phone animation recipes (`cosmos-phone.css`, keyframes `cosmos-pop-in`,
`cosmos-sheet-rise`, `cosmos-fade-in`) — desktop has no equivalent
chrome-entrance requirement, these are phone-only:

| Recipe | Duration + easing | Property | Desktop | Phone |
|---|---|---|---|---|
| `cosmos-pop-in` | `var(--cosmos-t-base) var(--cosmos-native)` | `opacity` + `transform: translateY(4px) → none` | N/A — no entrance-animation requirement | **MUST** on popover/menu chrome entrance |
| `cosmos-sheet-rise` | `var(--cosmos-t-panel) var(--cosmos-native)` | `opacity` + `transform: translateY(12px) → none` | N/A | **MUST** on modal/bottom-sheet entrance |
| `cosmos-fade-in` | `var(--cosmos-t-fast) var(--cosmos-native)` | `opacity` only | N/A | **MUST** on lightweight chrome entrance (tooltips, small overlays) |

> MUST: animate only `transform` and `opacity` (composited properties) —
> never `width`/`height`/`top`/`left`/layout-triggering properties.
> MUST: durations/easings come from the `--cosmos-t-*` / `--cosmos-native` /
> `--cosmos-spring` / `--mv-lift` / `--mv-wash` tokens (with literal
> fallback), never a raw `ms` value or bezier hardcoded outside a `var()`
> fallback.
> MUST: `--cosmos-spring` (overshoot) is reserved for confirmation
> micro-moments only — never hover or reveal. No desktop/phone distinction.
> MUST: `prefers-reduced-motion: reduce` is respected on both desktop and
> phone. Cosmos zeroes all `--cosmos-t-*` tokens (and
> `--anim-speed-modifier`) at the token level under that media query — a
> plugin that consumes the duration tokens (rather than hardcoding `ms`)
> inherits this automatically on every surface, desktop and phone alike.
> Audit rule: grep the plugin's stylesheet for raw `ms` durations outside a
> `var()` fallback; any hit is a reduced-motion violation.

---

## 4. Empty-state pattern

Source: `cosmos-phone.css`, already-shipped recipes (Properties heading,
backlinks/mentions heading, "No backlinks found").

**Micro-label (section eyebrow), verbatim recipe:**

```css
font-size: var(--font-ui-smaller);
font-weight: var(--font-medium);
color: var(--text-faint);
text-transform: uppercase;
letter-spacing: 0.06em;
```

**Whisper empty message, verbatim recipe** (`.search-empty-state` /
"No backlinks found"):

```css
color: var(--text-faint);
font-size: var(--font-ui-smaller);
```

| | Desktop | Phone |
|---|---|---|
| Section label (e.g. "Properties", "Linked/Unlinked mentions") | Same micro-label recipe applies wherever the plugin has an equivalent section heading | Shipped verbatim in `cosmos-phone.css` for `.metadata-properties-heading .metadata-properties-title` and `.embedded-backlinks .backlink-pane > .tree-item-self .tree-item-inner` |
| Empty message (e.g. "No X found") | Same whisper recipe | Shipped verbatim for `.embedded-backlinks .search-empty-state` |

> MUST: a plugin's empty-state message uses `color: var(--text-faint)` and
> `font-size: var(--font-ui-smaller)` — never `--text-normal` or a larger
> size (an empty state is not a call to action).
> MUST: any section eyebrow/label a plugin renders (e.g. "RESULTS",
> "RECENT") uses the micro-label recipe above verbatim, not a bespoke
> uppercase treatment.
> MUST NOT: an empty state reads as a title (no bold, no `--text-normal`,
> no sentence punctuation implying urgency).

---

## 5. Microcopy voice

Source: `.claude/rules/exo-plugin-form-language` memory (already the
suite's form-language convention) + vault language rules.

| Rule | Desktop | Phone |
|---|---|---|
| Labels | Sentence case, `.mva-pv`-style class convention | Same |
| Language | English for product/tech surfaces (labels, buttons, settings) | Same |
| PM jargon | Standard English PM terms left untranslated (never forced into Italian) | Same |
| Pickers | Chip + popover pattern (`.mva-sel`) — never a native `<select>` | Same |
| Buttons | `.mva-btn` convention — never `mod-cta` | Same |
| Inputs | `.mva-pv-input` convention | Same |

> MUST: no plugin form uses a native `<select>` element — chip+popover only.
> MUST: no plugin button carries the `mod-cta` class.
> MUST: all labels are sentence-case, not Title Case or ALL CAPS (labels;
> micro-labels are the sole uppercase exception, see §4).
> MUST: product-surface copy is English; standard PM jargon (e.g. "churn",
> "onboarding", "activation") stays untranslated even in an Italian-language
> context.

---

## Audit procedure (per rollout wave)

1. Grep the plugin's stylesheet for raw `ms` / hex values outside a
   `var(--cosmos-*, fallback)` or `var(--mv-*, fallback)` pattern.
2. Walk each of the 5 sections above against the plugin's surfaces —
   desktop first, then phone (iPhone Pro Max; no iPad).
3. Every unchecked box is a fix, not a note — this file is the gate, not a
   suggestion list.
4. Cosmos verify harness must stay green (7 pass / 0 fail) after any
   plugin-side fix — this file does not change harness behavior.
