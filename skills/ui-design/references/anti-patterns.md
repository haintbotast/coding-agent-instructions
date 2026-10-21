# Signs of an "AI-default interface" — lookup table

Read this when reviewing a freshly built interface, or when `scripts/check_ui.py` reports a code. The **Static** column = `check_ui.py` catches it by scanning HTML/CSS; the remaining codes must be judged on the rendered page (screenshot, chrome-devtools/playwright MCP).

Each code is a **default**, not an absolute ban: if the brief explicitly asks for that style, do it. The mistake is using it when nobody chose it.

## "Slop" group — looks auto-generated

| Code | Sign | Fix | Static |
|---|---|---|---|
| `side-tab` | Thick colored border (≥3px) on one side of a card — the easiest tell | Remove it, or use a lighter accent | ✓ |
| `gradient-text` | Gradient-filled text (`background-clip: text`), common on headings and numbers | Solid color | ✓ |
| `ai-color-palette` | Purple/violet gradients; neon cyan text on a dark background | Pick colors from the topic's own world | ✓ (purple gradient) |
| `dark-glow` | Non-offset colored shadow/halo (`0 0 Npx <color>`), or a blurred colored shadow on a dark background | Neutral shadow with an offset | ✓ |
| `radial-halo` | Saturated radial-gradient blob in the middle, fading to the edges, making a dark background "glow" | Flat background or a real material | — |
| `overused-font` | Primary font is Inter, Roboto, Fraunces, Geist, Plus Jakarta Sans, Space Grotesk | Choose a font with its own reason from the brief | ✓ |
| `italic-serif-display` | Large italic serif hero heading (Fraunces, Recoleta, Playfair) | Set it roman, or use a sans display face | — |
| `hero-eyebrow-chip` | Small uppercase letter-spaced label (or chip) right above the hero heading | Remove it, or merge it into the heading | — |
| `icon-tile-stack` | Rounded square holding an icon above a feature card's title | Icon beside the title, or inline in the text | — |
| `nested-cards` | Card inside a card | Use whitespace, text, rules instead of nested frames | — |
| `gpt-thin-border-wide-shadow` | 1px border plus a wide soft shadow at the same time | Pick one: a clear edge OR soft elevation | ✓ |
| `codex-grid-background` | Thin repeating pixel-grid background used as decoration | Use grids only for real canvases/maps/drawings | — |
| `repeating-stripes-gradient` | `repeating-*-gradient` stripes as surface decoration | A deliberate material, or leave it plain | ✓ |
| `image-hover-transform` | Zoom/rotate image on hover | Leave the image still, or make the interaction purposeful | ✓ |
| `bounce-easing` | Bouncy/elastic easing (`cubic-bezier` with y outside [0,1]) | Smooth deceleration: ease-out quart/quint/expo | ✓ |
| `pulsing-dot` | Blinking dot faking "liveness" | Pulse only when real data is changing; otherwise use a labeled static indicator | — |
| `marketing-buzzword` | streamline, empower, supercharge, world-class, enterprise-grade, next-generation, cutting-edge, seamless | One verb + a concrete noun saying what the product does | ✓ (English) |
| `em-dash-overuse` | Text dense with em dashes (≥8, about 1 per 500 characters) | Short sentences | — |

## "Quality" group — measurable, affects readers

| Code | Threshold | Static |
|---|---|---|
| `low-contrast` | Body text ≥ 4.5:1, large text ≥ 3:1 (WCAG AA) | ✓ when both colors are written directly in the CSS |
| `gray-on-color` | Gray text on a colored background looks washed out: use a darker shade of the background's own hue, or white | — |
| `flat-type-hierarchy` | Two adjacent type roles (heading/body) differ by < 1.25× at every step → flat | — |
| `tight-leading` | line-height < 1.3; body text should be 1.5–1.7 | ✓ (body selector) |
| `tiny-text` | Text < 12px; body ≥ 14px, ideally 16px | ✓ |
| `line-length` | Lines > ~80 characters are hard to read; body 65–75ch | — |
| `extreme-negative-tracking` | letter-spacing tighter than −0.04em | ✓ |
| `wide-tracking` | letter-spacing > 0.05em only for short uppercase labels, never body text | — |
| `all-caps-body` | Long paragraphs in all caps | — |
| `justified-text` | Justified text without `hyphens: auto` → "rivers of white" | ✓ |
| `skipped-heading` | Skipping heading levels (h1 → h3) breaks the outline for screen readers | ✓ |
| `layout-transition` | Animating width/height/padding/margin → jank; use transform/opacity (for height: grid-template-rows) | ✓ |
| `broken-image` | `<img>` missing `src` | ✓ |

## Craft thresholds (supplement to `pre-delivery-checklist.md`; the WCAG numbers there are not repeated)

- Largest display text ≤ 6rem; body 65–75ch.
- Tracking no tighter than −0.04em (best −0.02 to −0.03em); > 0.05em only for short uppercase labels.
- Two adjacent type roles differ by ≥ 1.25×; whitespace above a large heading is bigger than below it.
- Declare elevation once: border OR shadow. Shadows have an offset and a soft blur; card corner radius 12–16px, pills only for small controls.
- No hard `4px 4px 0` shadows unless the whole interface is genuinely neobrutalist.
- Animate only `transform`/`opacity`; smooth deceleration easing (ease-out quart/quint/expo), no bounce/elastic.

---
*Codes and descriptions paraphrased from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) @e103efe `crates/live/assets/antipatterns.json` (61 codes, Apache License 2.0 — see `LICENSE.txt` in this skill's directory), 31 codes selected; numeric thresholds cross-checked against `skill/reference/craft-floor.md` at the same commit. Only the data was taken; impeccable's hooks, binary-downloading launcher and "seed" text were NOT taken — see SOURCES.md at the repo root.*
