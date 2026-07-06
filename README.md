# Cosmos

An opinionated Obsidian theme — a fork of [**Baseline**](https://github.com/aaaaalexis/obsidian-baseline) by Alexis C — with a custom CSS layer and three curated **flavours** switchable from a single dropdown.

Cosmos ships pre-configured to the "Cupertino" look (Apple/macOS-style spacing, floating tabs, a unified dark surface). It is **opinionated / vertical**: Baseline's option lists are intentionally curated (Style Settings machinery is fully preserved).

## Flavours

Switch via **Settings → Style Settings → Cosmos → Cosmos Flavour**:

| Flavour | Workspace layout | Cosmos skin | Right sidebar island |
|---|---|---|---|
| **Cupertino** (default) | `layout-cupertino` | on | yes |
| **Fusion** | `layout-fusion` | on | yes |
| **Border** | `layout-border` | on | no |
| **Standard** | `layout-baseline` | off → clean Baseline | no |

The Cosmos skin (Craft-style compact pill tabs + a darker, uniform dark surface) is scoped `:not(.layout-baseline)`, so **Standard** falls back to a clean Baseline workspace.

**Right sidebar island** — in Cupertino & Fusion the right sidebar becomes a floating "island" matching the editor's native island (radius + hairline outline + shadow, top-aligned).

### Cupertino Light — the "Superfici chiare" toggle

A **class-toggle** in Style Settings (`cosmos-light`, off by default). When on, it disables the Cosmos *darker* surfaces → the theme falls back to Baseline's native (lighter) Cupertino greys. Combine with Cupertino/Fusion to get "Cupertino Light": same craft tabs + island, lighter surfaces. Works in dark and light mode.

## Curated Style Settings (vertical)

Curated option lists:

| Setting | Options kept |
|---|---|
| Cosmos Flavour | Cupertino · Fusion · Border · Standard |
| Dark / Light color scheme | Cupertino only |
| Personality · Status bar · Property style | Cupertino only |
| Editor tab style | Floating · Floating (Center) |
| Callout style | Tactile |
| Code style | Tactile |

The removed color-scheme palettes (Nord, Dracula, Flexoki, …) remain inert in the CSS — re-adding an option is a one-line change in the `@settings` block.

## What's baked in

The `COSMOS LAYER` at the end of `theme.css` is assembled from local `marioverse-*` snippets (historical copies in [`reference/`](reference/)) by `./sync-snippets.sh`, with Cosmos gating applied:

- **Tabs behavior** — min-width + horizontal scroll for the editor tab bar.
- **Craft tabs** — compact centered pill tab-bar (geometry only, no permanent background) + active pill (`#242424` in dark) + soft lift. Editor + sidebars. *Off in Standard.*
- **Darker** — unified, darker, opaque dark surface. *Off in Standard and in Cupertino Light (`cosmos-light`).*
- **Bases skin** — Craft/Notion-style skin for native Bases views + `.mv-*` utilities shared with the marioverse plugin suite (superbasetags). Global.
- **Right sidebar island** — `cosmos-islands.css` (from `marioverse-sidebar-island`), gated on `layout-cupertino`/`layout-fusion`.

## Build & sync

`theme.css` = pruned Baseline base + three layer sources. No compile step.

```bash
./sync-snippets.sh /path/to/vault/.obsidian/snippets
./build.sh                      # rebuild theme.css from the layer sources only
./deploy.sh /path/to/your/vault # copy theme.css + manifest.json into a vault
```

Then: **Settings → Appearance → Themes → Cosmos**. Cosmos needs the **Style Settings** community plugin for the flavour dropdown + Cupertino Light toggle.

## Credits & license

Forked from **Baseline** (Alexis C, MIT). Cosmos is MIT — see [LICENSE](LICENSE). All original Baseline capability and Style Settings are preserved.
