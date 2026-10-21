---
name: systematic-debugging
description: "Use when a bug, test failure or unexpected behavior appears AND you can already reproduce it on demand. Four-phase root-cause process; symptom fixes are failure. If you cannot reliably reproduce it yet (flaky, heisenbug, performance regression), run bug-feedback-loop first."
---

# Systematic Debugging

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Use for ANY technical issue — and ESPECIALLY under time pressure, when "one quick fix" seems obvious, or when previous fixes didn't work. Systematic is faster than thrashing (upstream reports 15-30 min vs 2-3 h, first-fix rate 95% vs 40%).

## Phase 1 — Root Cause Investigation

**For hard/flaky bugs: build a red-capable feedback loop FIRST** — see the `bug-feedback-loop` skill. A tight loop (fast, deterministic, asserts the exact symptom) makes every later phase mechanical.

1. **Read error messages completely.** Stack traces, line numbers, codes — they often contain the solution.
2. **Reproduce consistently.** Not reproducible → gather more data, don't guess.
3. **Check recent changes.** git diff, new deps, config, environment.
4. **Multi-component systems: instrument before theorizing.** Log data entering/exiting each component boundary; run once; the evidence shows WHERE it breaks. Then investigate that component.
5. **Trace backward to the source.** Bug manifests deep in the stack? Ask "what called this with the bad value?" repeatedly until you find the original trigger. Fix at the source, not where the error appears.

## Phase 2 — Pattern Analysis

Find similar *working* code in the codebase. Read reference implementations COMPLETELY (no skimming). List every difference between working and broken — don't assume "that can't matter".

## Phase 3 — Hypothesis and Testing

State one specific hypothesis: "I think X is the root cause because Y." Test with the SMALLEST possible change, one variable at a time. Didn't work → new hypothesis; do NOT stack more fixes on top. Don't understand? Say so and research — don't pretend.

## Phase 4 — Implementation

1. Create a failing test reproducing the bug (use `test-driven-development`).
2. Implement ONE fix addressing the root cause. No "while I'm here" changes.
3. Verify: test passes, no other tests broken. Run `verification-before-completion` before claiming success.
4. Fix didn't work? Count attempts. **< 3:** back to Phase 1 with new info. **≥ 3: STOP — the architecture is in question**, not the hypothesis. Each fix revealing a new problem elsewhere = wrong pattern. Discuss fundamentals with the human before any 4th attempt.

## Hardening After the Fix (defense in depth)

Validate at EVERY layer the bad data passes through, so the bug becomes structurally impossible: entry-point validation → business-logic checks → environment guards → debug logging.

## Flaky Tests: Condition-Based Waiting

Never guess at timing with `sleep`/`setTimeout`. Poll for the actual condition you care about (event fired, file exists, state set). Arbitrary timeouts are only acceptable when testing timing behavior itself — and then document WHY.

## Red Flags — STOP, return to Phase 1

- "Quick fix for now, investigate later" / "Just try changing X"
- Multiple changes at once; proposing fixes before tracing data flow
- "It's probably X" / "I don't fully understand but this might work"
- "One more fix attempt" after 2+ failures

Human says "stop guessing" / "is that not happening?" → you skipped investigation. Return to Phase 1.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v6.2.0 @ 3dcbd5c.*
