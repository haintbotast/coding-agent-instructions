---
name: codebase-design
description: Use when deciding where a seam goes, how deep a module's interface should be, or how to make code more testable and AI-navigable. For naming and shared vocabulary, use domain-modeling.
---

# Codebase Design — deep modules

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. Goal: leverage for callers, locality for maintainers.

## Vocabulary (use these terms exactly)

- **Module** — anything with an interface and an implementation; scale-agnostic (function, class, package). *Avoid: unit, component, service.*
- **Interface** — everything a caller must know: signature + invariants, ordering, error modes, config, performance. *Avoid: API (too narrow).*
- **Depth** — leverage at the interface: behaviour exercised per unit of interface learned. Deep = small interface, lots behind it. Shallow = interface nearly as complex as the implementation.
- **Seam** (Feathers) — where you can alter behaviour without editing in that place; where the interface lives. *Avoid: boundary.*
- **Adapter** — a concrete thing satisfying an interface at a seam (role, not substance).
- **Leverage** — callers' payoff: one implementation pays back across N call sites and M tests.
- **Locality** — maintainers' payoff: change, bugs, and verification concentrate in one place.

## Principles

- **Depth is a property of the interface, not the implementation.** Internals may be small, swappable parts with internal seams — they're just not part of the interface.
- **The deletion test:** imagine deleting the module. Complexity vanishes → it was a pass-through. Complexity reappears across N callers → it earned its keep.
- **The interface is the test surface.** Wanting to test *past* the interface means the module is the wrong shape.
- **One adapter = hypothetical seam. Two adapters = real seam.** Don't introduce a seam unless something actually varies across it.

## Simplicity ladder — stop at the first rung that holds

1. Does this need to exist at all? 2. Already in this codebase? 3. Standard library does it? 4. Native platform feature covers it? 5. An already-installed dependency solves it? 6. Can it be one line? 7. Only then: the minimum code that works. Two stdlib options of the same size → take the one correct on edge cases. Bug fix = root cause, not symptom: grep every caller before editing; one guard in the shared function beats a guard in every caller.

**Mark deliberate shortcuts with a ceiling.** A simplification that cuts a real corner (global lock, O(n²) scan, naive heuristic) gets a `ceiling:` comment naming the ceiling and the upgrade trigger. A ceiling comment with no trigger is the kind that rots; `grep -rn "ceiling:"` is the debt ledger. (Ladder and marker distilled from DietrichGebert/ponytail, MIT.)

## Designing for testability

1. Accept dependencies, don't create them (inject the gateway; don't `new StripeGateway()` inside).
2. Return results, don't produce side effects.
3. Small surface area: fewer methods = fewer tests; fewer params = simpler setup.

When designing an interface ask: fewer methods? simpler params? more complexity hidden inside?

## Periodic architecture review

**Scope before you scan — YAGNI.** Deepening pays off by making *future* changes easier, so weight the parts of the codebase that change often. If the user named a direction (module, subsystem, pain point), take it. Otherwise walk back the commit history (`git log --oneline`) for hot spots — files that keep coming up — and let those pull your attention first; scattered changes with no hot spot → widen the net.

Then scan the scoped area for **deepening opportunities**: shallow modules, concept-understanding that bounces across many files, pure functions extracted "for testability" while bugs hide in how they're called, untestable-through-interface areas. Apply the deletion test to suspects. Present candidates (files, problem, solution, benefits in locality/leverage terms, recommendation strength), let the user pick one, then run `grilling` on the chosen design. Record rejections with load-bearing reasons as ADRs so future reviews don't re-suggest them.

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 9603c1c (2026-07-20). Based on Ousterhout, "A Philosophy of Software Design".*
