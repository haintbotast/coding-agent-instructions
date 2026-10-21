# Checks before delivering a web interface

Distilled from `nextlevelbuilder/ui-ux-pro-max-skill` @ `09170ee` (MIT), sections
`references/quick-reference.md` §1, §5–§8, `data/ux-guidelines.csv`, with the
places where upstream is wrong or self-contradictory CORRECTED (listed at the end).
Benchmark: **WCAG 2.2 AA**.
Anything a machine can check: run `scripts/contrast_check.py`, do not estimate.

## 1. Contrast (run the script, do not eyeball)

| Pair | AA threshold | Notes |
|---|---|---|
| Regular text on its background | 4.5 : 1 | including text in buttons, labels, placeholders |
| Large text (≥ 24px, or ≥ 18.66px bold) | 3 : 1 | |
| Non-text components: input borders, secondary button borders, focus rings, meaningful icons, data lines | 3 : 1 | **a faint "decorative" border like #E2E8F0 on white is 1.2 : 1 — using it as an input border fails 1.4.11** |
| Error and success states | 4.5 : 1 for text | always paired with an icon or text, never color alone |

AAA (7 : 1) is a goal for body text when achievable, not a requirement for the whole page.

## 2. Keyboard, focus, screen readers
- A visible focus ring on EVERY clickable element, 2–4px thick, 3 : 1 contrast against the background; never a bare `outline: none`.
- Sticky elements (sticky header, banner) must not cover the focused element (2.4.11).
- A "Skip to content" link is the first focusable element.
- Tab order follows reading order; headings h1 → h6 do not skip levels.
- Icon-only buttons must have a readable name (`aria-label`); decorative icons get `aria-hidden`.
- WebGL canvas: `role="img"` + an `aria-label` describing what it shows, and a text version (data table) of the same content.
- Numbers that change on interaction: one `aria-live="polite"` region, a full sentence with context, no focus shift.

## 3. Touch, pointer
- Web: minimum target size **24×24 CSS px** (2.5.8 AA); prefer 44×44 for primary buttons on phones. 44pt/48dp are native-app numbers and do not replace px.
- Spacing between two targets ≥ 8px.
- No action may be hover-only; drag-and-drop must have a click and keyboard alternative (2.5.7).

## 4. Layout, type
- `width=device-width, initial-scale=1`, do not block zoom.
- No horizontal scroll at 375px. Check 375 / 768 / 1024 / 1440.
- Body text ≥ 16px on phones, line height 1.5–1.75; line length 60–75 characters on desktop, 35–60 on phones.
- Use `svh`/`dvh` for phone screen height, not `vh`.
- Numbers in tables and counters: `font-variant-numeric: tabular-nums`.
- **Vietnamese: the font must have the `vietnamese` subset** (check on the font's page). Atkinson Hyperlegible and many other "readable" fonts do NOT — diacritics fall back to a fallback font and break the rhythm. Be Vietnam Pro, Inter, Noto Sans have it.
- URLs, long codes: `overflow-wrap: anywhere`; no `word-break: break-all` for prose.

## 5. Motion
- Respect `prefers-reduced-motion`, and also listen to the `matchMedia` `change` event (the user may turn it on mid-session).
- **Every animation has a defined end state and always reaches it.** A number stopping midway ("0", "39" instead of 40) when the viewer stops scrolling is a data error, not an aesthetic one. Test at three scroll speeds: slow, normal, fast flick.
- Animate only `transform`, `opacity`; not `width/height/top/left`.
- 1–2 main animations per screen; motion must tell cause and effect, not decorate.
- Exit faster than enter (~60–70% of the enter duration); do not block interaction while running; make it interruptible.
- No flashing more than 3 times per second; an auto-playing carousel needs a pause button and pauses on focus.
- Do not leave elements hanging at `opacity` below .2.

## 6. Forms
- A visible label for each field (not just a placeholder); the error sits directly under the field, linked with `aria-describedby`.
- Failed submit: a focusable error summary block at the top, each error a link to its field; keep the per-field errors too.
- Errors state the cause + how to fix. Never erase what the user typed.
- Correct `type`/`autocomplete` so phones show the right keyboard and autofill.

## 7. Performance
- WebP/AVIF images, declare `width`/`height` or `aspect-ratio` (avoids layout shift), `loading="lazy"` below the first screen.
- Fonts with `font-display: swap`, preload only fonts actually needed on the first screen.
- Per-frame work < 16ms; scroll/resize events must be throttled.

## 8. Charts
- Data lines/bars ≥ 3 : 1 against the background, number labels ≥ 4.5 : 1; always provide an alternative data table; no more than 5 slices in a pie chart.

## Where upstream is wrong or contradictory — corrected above
1. Says "WCAG AAA mandatory" for government pages, yet its own accompanying palette is below 7 : 1; W3C does not recommend AAA for a whole page → AA is used as the standard.
2. The priority table says a 44×44px touch target is mandatory on every platform, contradicting its own 24px web item → split into web / native.
3. 173/173 `Border` tokens are below 3 : 1 against the background → warning in §1.
4. Treats "Motion effects" as an anti-pattern for government pages → wrong in principle; the right rule is purposeful motion + reduced-motion.
5. 74/74 font rows use `@import fonts.googleapis.com`, 4 three.js rows use a CDN → conflicts with self-hosted CSP; see `vn-public-sector-pages.md`.
6. The 300ms `tap-delay` is obsolete in modern browsers → dropped.
