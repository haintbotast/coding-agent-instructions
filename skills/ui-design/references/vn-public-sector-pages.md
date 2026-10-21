# Public pages of Vietnamese state agencies

Read this when the interface belongs to a Vietnamese state agency, organization or mass association (information portal, public database, public-service page). The starting point comes from
`ui-ux-pro-max-skill` @ `09170ee` (products #13 Government/Public Service,
#177 Government Portal, ui-reasoning #13, styles #8 Accessible & Ethical),
adjusted for how things are actually deployed in Vietnam.

## Mood: trust first, personality second
- Viewers must see immediately **whose page this is**: a band naming the governing agency (full name, no abbreviation on first use) at the top, and a footer stating the governing agency, the managing unit and contact details. Use the logo in its original form, never recolored.
- Serious ≠ dark and gray. "Bright but serious" = light background, straight grid, one interactive accent color, clear bold type, generous whitespace; the brightness comes from a secondary accent color, data illustrations and photos of real people — not from purple-pink gradients, glitter particles or frosted glass.
- Plain language: name the task the citizen needs done (e.g. "Tra cứu hồ sơ", "Look up a record"), not the system (e.g. "Truy vấn CSDL", "Query the database").

## Starting palette (light theme)
From colors #177 (Government Portal), adjusted to the agency's visual identity when one exists:

| Role | Value | Notes |
|---|---|---|
| Primary accent, buttons | `#1E40AF` | white text 8.7 : 1 |
| Secondary accent | `#3B82F6` | graphics/large fills only; black text on it |
| Secondary background | `#EFF6FF` | bands, info boxes |
| Background | `#FFFFFF` | |
| Text | `#0F172A` / secondary `#475569` | |
| Input border | ≥ 3 : 1 against the background, e.g. `#64748B` | do NOT use `#E2E8F0` for inputs |

Upstream's #13 palette (`#0F172A` navy + `#F8FAFC`) is dark-gray in tone and does not fit a "bright" requirement. Flag red and gold star colors: markers only (a stripe, a star), not for buttons or body text. Red is not used for the primary button.

## Common technical constraints
- **Self-host everything**: CSP `script-src 'self'`, no CDN, no Google Fonts
  `@import`. Fonts: download woff2 with the `vietnamese` subset into the project's static folder, declare
  `@font-face` + `unicode-range`. Record the source and license of each library.
- Demo builds with fake data: `noindex` + a "sample data" warning band on every page.
- Maps of Vietnam: always include Hoàng Sa and Trường Sa, labeled by name; do not use a foreign basemap that carries borders or labels.
- Public statistics: small cells (e.g. below 5) must be masked; the numbers on the page come from the same source as the API; numbers not from the database must be labeled "Illustrative figures" (e.g. "Số liệu minh hoạ").

## Accessibility standard
WCAG 2.2 AA is the benchmark (see `pre-delivery-checklist.md`). Before submitting to the agency, check against the current legal documents on accessibility of state-agency websites — the upstream repo does not have them, so look up the official sources yourself.

## Common failures
- A page as long as a dashboard, twenty screens of scrolling: viewers stop at screen 3.
- A hand-drawn 3D object (low-poly) placed next to the agency's logo: looks like a game.
- One architectural landmark carrying an abstract meaning too literally.
- Approving the look-and-feel direction in words and only then building the code: approve it with still images first.
