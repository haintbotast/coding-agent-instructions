---
name: code-review-discipline
description: "Use when requesting code review after completing tasks or features, or when receiving review feedback before implementing suggestions. Review early and often; verify feedback before acting on it. Not for checking a diff against a written quality floor, that is quality-floor."
---

# Code Review Discipline

## Requesting Review

**Mandatory:** after each task in subagent-driven work, after major features, before merge.
**Valuable:** when stuck, before refactoring, after a complex bug fix.

Dispatch a reviewer subagent with precisely crafted context — never your session history: description of what you built, the plan/requirements it should meet, and the BASE..HEAD diff. Don't review the diff yourself inline instead — that burns the coordinator context you need to keep driving; the diff and evaluation live in the reviewer's context, only findings come back.

**The reviewer does not dispatch subagents.** Say so in its prompt: it reviews the whole diff itself, never spawning a helper for part of it and never a second reviewer for another opinion. This process already provides every review seat the work gets — a reviewer-spawned reviewer duplicates one at full cost and its verdict counts for nothing. Diff too large for one pass? Review it in passes yourself and say so in the report. The review is also read-only on the checkout: inspect with `git show`/`diff`/`log`, and if a different revision is needed, `git worktree add /tmp/review-<sha>` — never move HEAD.

**Acting on feedback:** fix Critical immediately; fix Important before proceeding; note Minor for later; push back with reasoning if the reviewer is wrong. Never skip review because "it's simple".

**Two-axis review (for branch/PR reviews):** issue both reviewer subagent calls together, in the **foreground** (you aggregate their reports when both return — a background reviewer is a report nobody reads), and report them side by side, never merged or reranked — one axis must not mask the other:
- **Standards** — does the diff follow the repo's documented standards? **Search the repo for every file that documents how code should be written**; when `CODING_STANDARDS.md` or `CONTRIBUTING.md` exists it must be on the list. Plus a smell baseline (Fowler): mysterious name, duplicated code, feature envy, data clumps, primitive obsession, repeated switches, shotgun surgery, divergent change, speculative generality, message chains, middle man, refused bequest. Documented repo standards override the baseline; smells are judgement calls; skip anything tooling already enforces.
- **Spec** — does the diff faithfully implement the originating issue/spec? Report: missing/partial requirements, scope creep (behaviour nobody asked for), requirements implemented wrong. Quote the spec line per finding. No spec findable → the Spec axis reports "no spec available" rather than inventing one.

Pin the fixed point first (`git diff <point>...HEAD`, three-dot) and verify it resolves and the diff is non-empty *before* dispatching. When the base is a branch, use `git merge-base origin/main HEAD` — bare `origin/main` produces phantom deletions. Code can pass one axis and fail the other — that's why they stay separate.

**Two rules for the reviewer prompt:**
- *The spec is a vision document.* A reasonable person's expectation is a requirement; a spec's silence is not permission.
- *Declined to judge.* The reviewer lists every behaviour it set aside instead of silently skipping it; the executor rules on each one.

**Complexity-only pass (optional, on request or before a large merge).** A separate reviewer hunts only over-engineering: reinvented standard library, unneeded dependencies, speculative abstractions, dead flexibility. Format, one line per finding: `L<line>: <tag> <what>. <replacement>.` with tags `delete` / `stdlib` / `native` / `yagni` / `shrink`; end with `net: -<N> lines possible.`, or `Lean already. Ship.` Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, accessibility basics, or anything explicitly requested. (Lens distilled from DietrichGebert/ponytail, MIT.)

## Receiving Review

**Core principle:** verify before implementing. Technical correctness over social comfort.

```
1. READ  the complete feedback without reacting
2. UNDERSTAND  restate the requirement (or ask)
3. VERIFY  check the claim against codebase reality
4. EVALUATE  technically sound for THIS codebase?
5. RESPOND  technical acknowledgment or reasoned pushback
6. IMPLEMENT  one item at a time, test each
```

**Forbidden:** "You're absolutely right!", "Great point!", any performative agreement or gratitude. Instead: restate the requirement, ask, push back, or just fix it — the code shows you heard.

**Unclear items:** STOP — implement nothing until ALL items are clear. Items may be related; partial understanding = wrong implementation. "I understand 1,2,3,6. Need clarification on 4 and 5 first."

**External reviewers — be skeptical, check carefully:** Is it correct for this codebase? Does it break existing functionality? Is there a reason for the current implementation? Does the reviewer have full context? Suggestion to "implement properly" something unused → grep for usage → "Nothing calls this. Remove it (YAGNI)?"

**Push back when:** breaks functionality, reviewer lacks context, violates YAGNI, wrong for this stack, conflicts with owner's architectural decisions. Use technical reasoning; involve the owner if architectural.

**You pushed back and were wrong:** "Verified — you're correct because X. Fixing." No long apology, no defense.

**Implementation order:** clarify everything → blocking issues → simple fixes → complex fixes. Test each individually.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v7.0.0 @ bb92a77 (2026-10-12); two-axis review + Fowler smells from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock) @ f3fc563 (2026-10-08).*
