---
name: writing-plans
description: "Use when you have an approved spec or requirements for a multi-step task, before touching code. Produces bite-sized, zero-context implementation plans a cheaper model can execute. Not for executing a written plan, that is subagent-driven-dev."
---

# Writing Plans

## Overview

Write plans assuming the engineer has **zero context for the codebase and questionable taste**: skilled developer, knows nothing about our toolset or domain, doesn't know good test design. Document everything: files to touch, complete code, exact commands, how to test.

Save to: `docs/plans/YYYY-MM-DD-<feature>.md`. DRY. YAGNI. TDD. Frequent commits.

## Before Tasks: File Structure

Map which files get created/modified and each one's single responsibility. Clear boundaries, focused files. Follow existing codebase patterns.

## Step Granularity

Each step is ONE action with a checkable result: write failing test → run it, confirm it fails → minimal implementation → run tests, confirm pass → commit. A commit adds **≤50 logic lines** (tests, docs, config, generated code excluded; `quality-floor`'s `scripts/diff_budget.py`); a task that needs more is split further. A task = smallest unit with its own test cycle, ending in an independently testable deliverable. The reader writes idiomatic code once given the exact interface and the exact test; what they lack is context about this codebase, so the plan supplies it.

## Plan Header (mandatory)

```markdown
# [Feature] Implementation Plan

> **For agentic workers:** execute task-by-task via subagent-driven-dev (recommended) or inline. Steps use checkbox syntax.

**Goal:** [one sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [key technologies]
**Spec:** [path to the spec/design doc this plan implements — the plan argues from the spec, so the spec travels with it; executors read both]

## Global Constraints
[Project-wide requirements copied VERBATIM from the spec — versions, naming, limits. Every task implicitly includes these.]
```

## Task Structure

```markdown
### Task N: [Component]
**Files:** Create/Modify/Test — exact paths (with line ranges for modifications)
**Interfaces:**
- Consumes: [exact signatures from earlier tasks]
- Produces: [exact names/types later tasks rely on — implementers see only their own task]

- [ ] Step 1: Write the failing test   [actual test code block]
- [ ] Step 2: Run it — expected: FAIL with "..."   [exact command]
- [ ] Step 3: Minimal implementation   [actual code block]
- [ ] Step 4: Run it — expected: PASS   [exact command]
- [ ] Step 5: Commit   [exact git command]
```

## Review Focus (section of the plan header)

List up to five spec-implied inputs or failure modes that no task tests yet; pin each to a test in the task that owns it. Empty list is a finding, not a default.

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing from it. A code step names the exact signature, the file, and the spec values; a **body appears only for an algorithm the signature and tests do not determine**. A plan longer than the code it describes has written the code instead of planning it.

Plan failures, never write them: "TBD" / "TODO" / "add appropriate error handling" / "write tests for the above" (without test code) / "similar to Task N" (repeat the code) / steps describing *what* without *how* / references to types not defined in any task.

## Self-Review (run yourself, fix inline)

1. **Spec coverage:** every spec requirement maps to a task.
2. **Placeholder scan:** none of the patterns above.
3. **Type consistency:** names/signatures in later tasks match earlier definitions.
4. **Review Focus filled:** every listed input/failure mode is pinned to a test.
5. **Proportion:** a plan several times longer than its spec is a transcript, not a plan — cut bodies the signature and tests already determine.

## Execution Handoff

Offer two options with a plan-specific recommendation: **1. Subagent-driven** (fresh subagent per task, review between tasks; use `subagent-driven-dev`) or **2. Native** (execute in-session as the implementer yourself). The human reviews the saved plan before anything runs.

**Native execution rules:** ensure an isolated workspace first (`branch-lifecycle`); review plan critically; raise concerns before starting; follow steps exactly; don't skip verifications; STOP and ask when blocked (missing dep, unclear instruction, repeated verification failure) — never guess; never start on main/master without explicit consent.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v7.0.0 @ bb92a77 (2026-10-12).*
