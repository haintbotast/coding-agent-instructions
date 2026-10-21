---
name: bug-feedback-loop
description: Use when a bug is hard to REPRODUCE. Flaky failure, heisenbug, or performance regression where you need a red/green loop before hypothesising about causes. This is Phase 1 of systematic-debugging. If the bug already reproduces on demand, go straight to systematic-debugging.
---

# Bug Feedback Loop

## Redact first

This skill has you show commands, outputs and captured artifacts. **Redact every secret before showing it** — write `<REDACTED>` in its place. Build loops against env vars so the credential stays in the environment rather than in what you show. Captured artifacts (HAR files, log dumps) carry auth headers: quote only the lines that carry the signal. If the redacted output isn't enough to diagnose the bug, say so and ask the user.

## The loop

**This is the skill — everything after it is mechanical.** With a tight pass/fail signal that goes red on *this* bug, bisection, hypothesis-testing, and instrumentation all just consume it. Without one, no amount of staring at code will save you. If you catch yourself reading code to build a theory before the loop exists — stop; that's the exact failure this prevents.

## Build the loop — try in rough order

1. Failing test at whatever seam reaches the bug (unit → e2e)
2. curl/HTTP script against a dev server
3. CLI invocation with fixture input, diff stdout vs known-good
4. Headless browser script (Playwright) asserting DOM/console/network
5. Replay a captured trace (saved request/payload/event log) through the code path
6. Throwaway harness: minimal subset of the system, mocked deps, one function call
7. Property/fuzz loop: 1000 random inputs, look for the failure mode
8. Bisection harness: automate "boot at state X, check" → `git bisect run`
9. Differential loop: same input through old vs new version, diff outputs
10. Human-in-the-loop script (last resort) — still structured, output feeds back

## Tighten it

Treat the loop as a product: **faster** (cache setup, narrow scope), **sharper** (assert the exact symptom, not "didn't crash"), **more deterministic** (pin time, seed RNG, isolate FS, freeze network). A 2-second deterministic loop is a debugging superpower; a 30-second flaky one barely helps.

**Non-deterministic bugs:** goal is a *higher reproduction rate*, not instant purity. Loop the trigger 100×, parallelise, add stress, inject sleeps. 50% flake is debuggable; 1% is not.

**Genuinely can't build a loop?** Say so explicitly, list what you tried, ask for: repro environment access, a **redacted** captured artifact (HAR/log/core dump/recording), or permission for temporary production instrumentation. Do NOT hypothesise without a loop.

## Completion criteria

One command you have already run at least once (show invocation + output, redacted) that is: **red-capable** (asserts the user's exact symptom), **deterministic** (or pinned high repro rate), **fast** (seconds), **agent-runnable**.

## Then: minimise

Run it red. Confirm it's the failure the *user* described — a nearby different failure = wrong bug = wrong fix. Shrink to the smallest scenario still red: cut inputs/callers/config **one at a time**, re-running after each cut. Done when every remaining element is load-bearing. The minimal repro shrinks the hypothesis space and becomes the regression test.

## Instrumentation hygiene

- 3-5 **ranked, falsifiable** hypotheses before testing any ("if X is the cause, changing Y makes it disappear"). Can't state the prediction → it's a vibe, discard. Show the ranking to the user — they often re-rank instantly.
- One breakpoint beats ten logs; never "log everything and grep".
- **Tag every debug log** with a unique prefix (`[DEBUG-a4f2]`) — cleanup becomes one grep. Untagged logs survive; tagged logs die.
- Performance bugs: measure a baseline first (profiler, timing harness), then bisect. Logs are usually the wrong tool.

## Fix, regression test, cleanup

Regression test **before** the fix — but only at a **correct seam** (one exercising the real bug pattern at its call site). Watch it fail; **if you forced the red by mutating code or a fixture, `diff` against a pristine copy to prove the mutation actually landed before you trust that red** — an unproven red is `BLESSED-REGRESSION` waiting to happen (see `failure-classes`). No correct seam exists? That IS the finding: architecture prevents locking the bug down — flag it for an architecture pass (see `codebase-design`). Before declaring done: original repro green, `grep` your debug prefix returns nothing, throwaway prototypes deleted or moved to a clearly-marked debug location, correct hypothesis stated in the commit/PR message so the next debugger learns.

Use with: `systematic-debugging` (the 4-phase process — this skill IS its Phase 1 muscle), `test-driven-development`.

## Bounded repair loop (when handing the red test to a headless agent)

The test's exit code IS the fitness function — no separate judge. Hard constraints for the repair agent: do not modify the test; do not add dependencies; restrict tools to read/edit/run (`--allowedTools Read,Edit,Bash` or equivalent); cap the budget per attempt; point it only at code you would `git checkout .` afterwards. (Constraints distilled from ruvnet/ruflo `tdd-repair`, MIT; the tool itself was not adopted.)

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 49dd158 (2026-10-12). See SOURCES.md.*
