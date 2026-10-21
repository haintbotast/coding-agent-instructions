---
name: ui-design
description: "Use when building new UI or reshaping existing UI: distinctive visual direction, typography, layout and copy that do not read as templated AI defaults, plus a WCAG 2.2 AA pre-delivery checklist, a contrast-check script and a static lint for AI-default tells. Not for charts, dashboards or diagrams."
---

# UI Design

Approach this as the design lead at a studio known for giving every client a visual identity that could not be mistaken for anyone else's. The client rejects clichéd, templated proposals. Make deliberate, opinionated choices about palette, typography, and layout specific to THIS brief, and take aesthetic risk where you can justify it.

## Ground it in the subject

Brief doesn't pin down the subject? Pin it yourself and confirm with the client: one concrete subject, its audience, the design's primary job — proposed, not assumed. The subject's own world (industry, materials, vernacular) is where distinctive choices come from; a toy for girls aged 8–11 and a dashboard for financial analysts should not look alike. Use any memory of the user's preferences and past designs as hints.

## Known AI-default looks — don't spend freedom on them

1. Warm cream background (~#F4F1EA) + high-contrast serif display + terracotta/warm-clay accent (often ~#D97757 — Anthropic's own Claude accent, so on a user's brief it reads as a tell).
2. Near-black background + one bright acid-green or vermilion accent.
3. Broadsheet layout: hairline rules, zero border-radius, dense newspaper columns.
4. **SaaS-card kit:** content chopped into identical rounded cards, one border-radius on everything regardless of hierarchy, the same soft grey shadow (`rgba(0,0,0,.1)`) under each, gradient washes as decoration.
5. **Template chrome that appears whatever the subject:** tracked-out ALL-CAPS eyebrow above every heading; meta strings joined with middle dots (`A · B · C`); labels built as `WORD — fragment` with a spaced em dash; tinted near-black (#0B0B0B, #111) standing in for black; monospace for small data labels; `→` appended to link and button text.

All are legitimate for some briefs, but they are defaults rather than choices, and they appear regardless of subject. The brief's own words always win — including when it asks for one of these looks. Where an axis is free, don't spend that freedom on a default.

## Principles

- **The hero is the first thing seen.** Open with the most characteristic thing in the subject's world, in whatever form fits: headline, image, animation, live demo. "Big number + small label + supporting stats + gradient accent" is the default treatment — use it only if it is truly best.
- **Typography carries personality.** One family, or two clearly distinct ones — display and body need not differ. Choose deliberately, not the defaults you'd reach for on any project; set a real type scale (Elements of Typographic Style as baseline) with intentional weights, widths, spacing. Where type is a headline or visual element, make the treatment itself part of the design.
- **Type defaults to avoid** — the commonest generated-page tells: accenting a single word in a headline (one word italic/bold/colored); ALL CAPS for labels; typographic labels added above content for no reason.
- **Line length under ~80 characters.** Serif can run slightly longer, and wants slightly more line-height than sans.
- **Structure is information.** Outlines, borders, numbering, eyebrows, dividers must encode something true (01/02/03 only if the content really is a sequence), never decorate.
- **Motion answers actions.** Use non-user-triggered motion sparingly and only to draw attention; one orchestrated moment beats scattered effects. Fade-and-slide-up on every section and hover transitions on every card are the generic default and read as AI-generated. Motion that responds to a person opening, expanding, or confirming something is welcome — it shows what changed.
- **Copy is design content.** Placeholder copy can make a design feel as templated as the layout; see Writing below.

## Process — two passes

**Pass 1, plan:** a compact token system —

- **Color:** core base palette as 4–6 named hex values.
- **Type:** the typefaces and their roles.
- **Layout:** one-sentence concept + ASCII wireframe to compare options; state alignment (left / centered / justified).
- **Principles:** the high-level guidance for what makes this page unique.

**Pass 2, review the plan against the brief before building:** would you produce this same plan working through any similar prompt? If any part reads generic — revise it and say what changed and why. Only then write code, following the revised plan.

Coding note: watch CSS selector specificity — a type-based selector (`.section`) and an element-based one (`.cta`) cancelling each other's padding/margin between sections is a classic self-inflicted bug.

## Restraint and self-critique

Spend your boldness in ONE place — let one element be the memorable thing, keep everything around it quiet, cut decoration that doesn't serve the brief. Chanel's rule: before leaving the house, remove one accessory. Quality floor without announcing it: responsive to mobile, visible keyboard focus, `prefers-reduced-motion` respected, visually accessible, harmonious palette. Critique your own work while building; screenshot if the environment allows — a picture is worth 1000 tokens. Jot notes on what you've tried; memory is how human designers avoid repeating themselves.

## Writing in design

Copy exists to make the design easier to understand and use. Same intentionality and minimalism as spacing and color.

- Write from the user's side of the screen: name things in language they recognize, not how the system is built — "manage notifications", not "webhook config". Specific and legible beats clever.
- Active voice; a CTA says exactly what happens: "Save changes", not "Submit". An action keeps its name through the flow ("Publish" → toast "Published"). Consistent vocabulary is how people learn their way around.
- Errors: what went wrong + how to fix, in the interface's voice — never vague, never apologizing. Empty states are invitations to act.
- Sentence case, plain verbs, no filler; each element does exactly one job.

## Look-ups and checks (load only what the task needs)

- `references/pre-delivery-checklist.md` — pre-delivery checklist for any web UI: WCAG 2.2 AA numbers (text 4.5:1, non-text incl. input borders 3:1, web targets 24 CSS px), focus, forms, motion end-states, font subset for the page's language, performance. Run it before calling a page done.
- `references/vn-public-sector-pages.md` — public pages of a Vietnamese state agency or mass organisation: trust cues, "bright but serious" starting palette, self-hosting under CSP, demo-data banners, map rules (Hoàng Sa, Trường Sa).
- `references/threejs-gsap.md` — three.js / GSAP performance and accessibility (one WebGL context, pixel-ratio cap, dispose, reduced-motion via `gsap.matchMedia`, data values never frozen mid-animation).
- `python3 scripts/contrast_check.py "#fg:#bg[:ratio]" …` — WCAG contrast; exit 1 on any failing pair. Use it for every colour pair you introduce instead of estimating.
- `references/anti-patterns.md` — 31 coded "generated-UI" tells (side-tab, gradient text, purple gradients, colored zero-offset glow, icon-tile stack, hero eyebrow chip…) and craft floors (tracking, scale step, elevation), each with its fix; the brief's explicit wish beats any code.
- `python3 scripts/check_ui.py <file.html|.css>` — static lint for 18 of those codes, stdlib only, exit 2 on findings; `--self-test` proves every rule still fires. Rendered-page checks (overflow, occlusion, contrast over images) still need chrome-devtools or playwright MCP.

Checklist and references distilled from `nextlevelbuilder/ui-ux-pro-max-skill` @ `09170ee` (MIT); anti-pattern codes from `pbakaus/impeccable` @ `e103efe` (Apache-2.0) — see SOURCES.md. Its BM25 `--design-system` generator was deliberately NOT carried over: for Vietnamese public-sector queries it picks a font without a Vietnamese subset and a dark slate palette.

---
*Adapted (condensed) from Anthropic's `frontend-design` skill, [anthropics/skills](https://github.com/anthropics/skills) @ dbd4588 — Apache License 2.0, see LICENSE.txt in this directory. Changes: condensed, restructured, merged claude-code plugin notes.*
