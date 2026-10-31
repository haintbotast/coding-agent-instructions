---
name: test-driven-development
description: "Use when implementing any feature or bugfix, before writing implementation code. Enforces RED-GREEN-REFACTOR with mandatory failure verification, tests at agreed seams, and the testing anti-pattern laws. Not for hunting a bug's root cause, that is systematic-debugging."
---

# Test-Driven Development

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? **Delete it. Start over.** Don't keep it as "reference", don't "adapt" it while writing tests. Delete means delete.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## When

Always: new features, bug fixes, refactoring, behavior changes — any code with logic (business rules, permission checks, calculations, parsing, data transforms).
Exceptions (no need to ask; **name the exception in the report**): config, docs, purely presentational UI, generated code, throwaway prototypes, one-off scripts. Infrastructure changes are verified by real behaviour (`ops-safety`), not unit tests.

**Not "the whole test suite first".** A request like "write full-coverage unit tests before generating any logic" is met by this skill's vertical slices, not by a test-suite-up-front pass: all-tests-first verifies imagined behaviour (law 5 below). What the human can approve up front is the **list of seams and cases**, one line each — not the test bodies.

**Coverage ratchet.** Where the project measures coverage, new lines stay ≥80%; never lower the threshold to make a change pass (`quality-floor`).

**Small steps.** One cycle = one test + the code that turns it green + one commit, at most **50 added logic lines** (tests, docs, config, generated code, lockfiles, deletions and renames excluded). Measure with `quality-floor`'s `scripts/diff_budget.py`. Over budget → split; can't split → reason in the commit message.

## Red-Green-Refactor

**RED — write one minimal failing test.** One behavior, clear name, real code (mocks only if unavoidable). Demonstrates the desired API.

**Verify RED — run it, watch it fail. MANDATORY.** Confirm it *fails* (not errors) for the expected reason: feature missing, not a typo. Test passes immediately? You're testing existing behavior — fix the test.

**GREEN — write the simplest code that passes.** No extra options, no features beyond the test. YAGNI.

**Verify GREEN — run it, watch it pass. MANDATORY.** All other tests still green, output pristine (no warnings). Test fails? Fix the code, not the test.

**REFACTOR — only after green.** Remove duplication, improve names, extract helpers. No new behavior. Stay green.

Repeat with the next failing test.

## Bug Fixes

Never fix a bug without a failing test reproducing it first. The test proves the fix and prevents regression. Red-green verify regression tests: pass → revert fix → MUST fail → restore → pass.

## Rationalizations (all false)

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after answer "what does this do?"; tests-first "what *should* this do?" — after-tests are biased by the code you wrote, verifying remembered cases, not discovered ones. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Unverified code is debt. |
| "TDD will slow me down" | TDD is faster than debugging after. |
| "Test hard = skip it" | Hard to test = hard to use. Listen to the test; simplify the design. |

## Seams — where tests go

A **seam** is the public boundary you test at. Tests live at seams, never against internals — code can change entirely; tests shouldn't. A good test reads like a specification ("user can checkout with valid cart") and survives refactors. **Test only at pre-agreed seams:** before writing tests, ask "what's the public interface, and which seams should we test?" — confirm with the user so effort lands on critical paths, not every edge case. Give each proposed seam a one-line note on what it **catches** and what it **misses** — the user is choosing coverage, not nodding at a list. Read `GLOSSARY.md` (or `CONTEXT.md`) (if it exists) so test names match the project's domain language. When the *shape* of that interface is itself in question — how deep the module is, where the seam belongs, what the interface should expose — consult `codebase-design` for the vocabulary (module, interface, depth, seam, adapter, leverage, locality). It's a reference to look things up in, not a session to run.

## Testing Anti-Patterns — the five laws

1. **NEVER test mock behavior.** Assert on real behavior, not that a mock rendered/was called. Ask: "Am I testing the component or the mock's existence?"
2. **NEVER add test-only methods to production classes.** Test needs a hook? Fix the design or keep helpers in test code.
3. **NEVER mock without understanding the dependency.** Mocks are for isolation, not the thing being tested.
4. **NEVER write tautological tests** — assertions that recompute the expected value the way the code does (`expect(add(a,b)).toBe(a+b)`) pass by construction. Expected values come from an independent source: a known-good literal, a worked example, the spec.
5. **NEVER slice horizontally** — all tests first, then all implementation, verifies *imagined* behavior. Work in vertical slices: one test → one implementation → repeat, each test a tracer bullet informed by the last cycle.

## Name the Break — gate before every test body

**Before writing a test, name the production change that would make it fail — and is that change a bug or a decision?** Can't name one → redesign around observable behavior.

- **No change detectors.** If only intentional decisions can fail a test (a constant's value, exact message wording, private structure), it fires on redesign and sleeps through bugs. Test the behavior that *depends on* the decision: not `expect(MAX_RETRIES).toBe(5)` but "a failing call retries 5 times, the 6th never happens."
- **Behavior, not text.** Asserting a script/config contains an exact line proves only the source is the source. Run it against controlled inputs; assert outputs, side effects, exit codes.
- **Your code, not the framework.** Test the contract your code makes at its boundaries (route registered, query emitted, payload produced) — upstream mechanics are the framework maintainers' tests. Upstream behavior genuinely surprised you → one narrow characterization test naming the assumption. Constructors/getters/trivial forwarding earn tests only when they validate, normalize, default, derive, or cause side effects.

## Checklist before claiming done

- [ ] Every new function has a test that I watched fail for the right reason
- [ ] Minimal code to pass each test; all tests pass; output pristine
- [ ] Tests use real code; edge cases and errors covered

Can't check all boxes → you skipped TDD → start over.

**"Other tests" means the project's suite, not just your file.** A scope statement in your task bounds the deliverable, not your verification. Any failure that run shows — including one you did not cause — goes in your report by name; a red test you watched scroll past and did not mention is a report falsified by omission.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write the wished-for API; write the assertion first. |
| Test too complicated | Design too complicated. Simplify the interface. |
| Must mock everything | Code too coupled. Dependency injection. |

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v7.0.0 @ bb92a77 (2026-10-12); seams + tautological/horizontal anti-patterns from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock) @ f3fc563 (2026-10-08).*
