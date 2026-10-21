# three.js and GSAP on public pages

Distilled from `ui-ux-pro-max-skill` @ `09170ee` (`data/stacks/threejs.csv`,
`data/motion.csv`), dropping the rows that load libraries via CDN. GSAP has its own license
(not MIT) — read it before packaging.

## three.js
- **One** WebGL context for the whole page; scenes take turns drawing onto the same canvas.
- `renderer.setPixelRatio(Math.min(devicePixelRatio, 2))`; on narrow screens or
  `navigator.connection.saveData`, lower it further (1–1.5).
- Many identical objects (dots, bars) → `InstancedMesh`, not thousands of Meshes.
- If you modify a `BufferAttribute` every frame, set `needsUpdate = true`.
- When leaving a scene or destroying the page: `geometry.dispose()`, `material.dispose()`,
  `texture.dispose()`, `renderer.dispose()`; stop the render loop when the tab is hidden
  (`visibilitychange`) and when the canvas is off-screen (`IntersectionObserver`). Measure CPU in a real browser across visible/off-screen/hidden/paused states.
- Render only when something changes (scroll, hover, a running animation), not a continuous 60 frames when idle.
- Accessibility: `renderer.domElement.setAttribute('role','img')` + `aria-label`;
  provide a static version (pre-rendered image + data table) when WebGL is unavailable, on weak devices, or under reduced-motion.
- Reduced-motion: read `matchMedia('(prefers-reduced-motion: reduce)')` AND listen to
  `change`; when on, stop auto-rotation, particles, and flying cameras.
- Light theme: materials on a light background need stronger ambient light and a soft
  contact shadow so the object does not "float"; avoid high `emissive`, which only looks good on dark backgrounds.

## GSAP / ScrollTrigger
- Wrap every effect in `gsap.matchMedia()` with a
  `(prefers-reduced-motion: reduce)` branch that sets the end state directly.
- Scroll-linked effects (`scrub`) must **not** leave a data value (a counter) stopped
  midway: the counter runs once when it enters the viewport, or it is scroll-linked but the scene is pinned
  long enough for progress to reach 1 before leaving the screen.
- Smooth with a stopping point (snap near the target), not asymptotic interpolation forever.
- Test scroll jumps: End key, dragging the scrollbar, Back to the page — the scene must render at the right position.
- Animate only `transform`/`opacity`/CSS variables; stagger 30–50ms per element.
