---
name: subagent-driven-dev
description: "Use when executing an implementation plan with independent tasks, or when facing 2+ independent problems that can be worked in parallel. Fresh subagent per task with two-stage review and a ruling ledger. Not for writing the plan, that is writing-plans."
---

# Subagent-Driven Development

**Core principle:** Fresh subagent per task + review after each (spec compliance AND code quality) + broad final review = high quality, fast iteration.

Subagents never inherit your session history — you construct exactly the context they need. This keeps them focused and preserves your context for coordination.

## Rulings, Not Stalls

**A running plan does not wait on a human.** Conflicts, ambiguities, plan defects, a cap you would have asked to exceed — decide them. The **spec is the binding authority**, the plan is its argument, and your judgement settles what neither answers. Record every decision in the ledger as `Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep going. A wrong ruling costs rework the user can see and undo; a session parked on a question costs their whole day and buys nothing.

**Four things stop you, and only these:** an irreversible or destructive operation; a security-sensitive action; a side effect outside this worktree that norms say you ask about first (a merge, a push to a shared branch, a publish); a plan so broken that every path forward is a guess.

## Per-Task Loop

1. Read plan; note global constraints; create todos. **If the plan names a Spec, read it too** — conflicts inside the plan resolve against it. No reachable spec → ledger note saying so; rulings made without one are provisional.

**Preflight scan before Task 1 — output is a table, not a verdict.** One row per pair of tasks sharing a file or interface (what one produces vs what the other consumes, what you found); one row per task (does its own text agree with itself — tests vs code specified, files created vs files later touched). "The scan is clean" without those rows is not a scan you ran. Also flag anything the plan mandates that the review rubric treats as a defect (a test asserting nothing, verbatim duplication of a logic block). Write the table to the ledger, **rule on every finding** beside its row, then dispatch Task 1. Clean scan → proceed without comment. The review loop remains the net for conflicts that only emerge from implementation.

**Batch small same-shape work.** Several plan tasks that are each a small independent edit of the same kind (the same one-line fix, constant change, or field addition across files) → ONE dispatch brief listing every file and its change, one subagent, one diff reviewed as a unit. Reserve one-dispatch-per-task for work needing its own judgement, tests, or review surface.
2. **Dispatch implementer** with: one line of where the task fits; the task's full text (as a file path, not pasted); interfaces/decisions from earlier tasks; your resolution of any ambiguity; the report-file path + report contract (implementer writes the full report to a file, returns only status/commits/test summary/concerns). Exact values live in the brief only. Record BASE (`git rev-parse HEAD`) and the implementer's agent identity before dispatching. **Carry the no-subagents contract:** the implementer never dispatches subagents — not helpers, and never a reviewer. Review arrives from you, after the report. In real sessions every reviewer a worker spawned duplicated the task review the controller dispatched anyway — a full extra review seat per task. If an earlier task parked a finding in the area this task touches, carry a pointer to that ledger entry.
3. Implementer asks questions? Answer completely before letting it proceed. **While waiting:** never poll with short timeouts, and never sit in one silent open-ended wait. Have local work (ledger updates, packaging the next review, reading reports)? Keep working — child results arrive on their own. Genuinely idle → wait in bounded stretches (5-10 min where the platform allows), and between stretches post one line of status and reconcile live children: list them, chase any that finished without reporting. Bounded stretches keep nearly all of a long wait's efficiency while catching a stuck or lost child in minutes, not at session end.
4. Implementer implements, tests, commits, self-reviews, reports status.
5. **Dispatch task reviewer** with the diff as a file (BASE..HEAD; never `HEAD~1` — it drops multi-commit work), the brief, the report file, and global constraints copied verbatim.
6. Critical/Important findings, spec ❌, or a ⚠️ "cannot verify from diff" item you confirmed as a real gap → **fix loop** (below). Minor findings never enter the loop — record them in the ledger as deferred.
7. Mark complete in todos AND the ledger. Conversation memory doesn't survive compaction — after compaction, trust the ledger and `git log`, never re-dispatch completed tasks.
8. All tasks done → **final whole-branch review** (most capable model) with the full branch diff + the ledger's deferred/parked lines → if findings: ONE fix subagent with the complete list + ONE scoped re-review, no second wave — residual load-bearing findings surface to the human → `branch-lifecycle` to finish.

## Plan-Scoped Ledger

One ledger file per plan (e.g. `.sdd/<plan-basename>/progress.md`, git-ignored), first line naming the plan file: `# SDD ledger — plan: <path>`. Tasks with a `Task N: complete` line are DONE — resume at the first task without one; a task whose last line is a fix round resumes mid-loop. A ledger whose first line names a *different* plan is not yours: leave it, start fresh. After the final review is clean, delete the plan's workspace — git history is the record.

## Fix Loop (max 5 rounds per task)

A round = one fix dispatch + one scoped re-review.

- **Rounds 1–3: resume the original implementer** with the open findings verbatim — its context is intact. Can't resume? Fresh implementer with brief + report file + findings (the report file is the persistent memory).
- **Rounds 4–5: fresh implementer, one model tier above the stuck one**, framed: "a prior implementer attempted this N times; read the report file for what was tried." Three failed resumes usually means it can't see its own problem.
- Every round: fixer re-runs the covering tests (named in the fix message — a one-line fix doesn't need the whole suite), appends to the report file. Confirm tests + command + output present before re-review.
- **Scoped re-review** (cheap-to-mid model): verdicts each finding ADDRESSED/NOT ADDRESSED; flags new breakage in the fix diff only — new Critical/Important there joins the list; out-of-scope observations go to the ledger as deferred minors, never extend the loop.
- Ledger after each round: `Task N: fix round R/5 (X addressed, Y open; commits a..b)`.
- **Never fix findings yourself in the controller session** — pollutes coordination context and skips review.

**Breaker — round 5 still has open findings:** stop dispatching, adjudicate each yourself (you hold the plan and cross-task context). Reviewer wrong/contestable, or real but nothing builds on it → park with a ruling in the ledger (`Task N: parked — <finding> — Ruling: <why the code stands>`). Real and **load-bearing** (later task builds on it, or reveals a plan defect) → **rule on the smallest change that unblocks the dependent work**, ledger it, and carry it into the next task's dispatch. Parking a structural failure silently lets every dependent task build on it. Stop only when the defect leaves every path forward a guess. Adjudicate ONLY at the cap — earlier is pre-judging. Every ruling is a ledger entry; silent discards forbidden.

## Implementer Statuses

- **DONE** → generate diff, dispatch reviewer.
- **DONE_WITH_CONCERNS** → read concerns; correctness/scope concerns get addressed before review.
- **NEEDS_CONTEXT** → provide it, re-dispatch.
- **BLOCKED** → context problem: add context; reasoning problem: stronger model; too large: split; **plan wrong: rule on the correction, ledger it, re-dispatch with the ruling carried in the brief.** Never force a retry unchanged, never ignore an escalation.

## Reviewer Rules

- Never tell a reviewer what NOT to flag or pre-rate severity ("treat as Minor") — that's pre-judging to spare yourself a loop. Let it flag; adjudicate after.
- Don't ask reviewers to re-run tests the implementer already ran on the same code.
- A finding that conflicts with what the plan mandates is **yours to rule on**: weigh finding against plan text, decide with the spec as binding authority, ledger the ruling before acting on it. Don't dismiss the finding because the plan mandates it; don't dispatch a fix contradicting the plan without a recorded ruling.
- **Reviewers don't dispatch subagents either** — a reviewer-spawned reviewer duplicates a seat at full cost. If a worker spawned one, that's a defect to flag, not extra rigour.
- Every fix dispatch: fixer re-runs the covering tests and reports command + output. Confirm all three before re-review.
- **Hand the reviewer the artifact and the contract, never your claim.** Passing your conclusion ("this is correct because…") biases the reviewer toward agreement. An adversarial review runs at most 3 cycles; after that escalate to the human instead of grinding a fourth alone. (From addyosmani/agent-skills `doubt-driven-development`, MIT.)

## Parallel Dispatch (independent problems)

2+ failures in unrelated subsystems → one agent per problem domain, dispatched in the SAME response (= parallel). Each prompt: focused scope, self-contained context (paste the errors), constraints ("fix tests only"), specified output ("return root cause + changes"). Don't parallelize: related failures, shared state, exploratory debugging, or multiple *implementation* subagents (conflicts).

Integration after return: read each summary, check for conflicting edits, run the full suite.

Parallel implementers on one feature, each on a branch off an integration branch: before reporting done, each merges the integration branch's current head into its own branch and re-runs its tests. Merging back is then a fast-forward and conflicts surface in the implementer's context, not yours (mattpocock `implement-spec` @d81f3a1).

## Red Flags — never

- Start on main/master without explicit consent
- Skip task review or accept a report missing either verdict
- Proceed with unfixed Critical/Important issues
- Accept "close enough" on spec compliance
- Paste session history into dispatch prompts (task brief + interfaces + constraints only)
- Trust "success" reports — verify the diff (`verification-before-completion`)
- Pause between tasks to ask "should I continue?" — execute the plan; rule and keep going, stop only for the four cases above or completion
- Let an implementer spawn its own reviewer — a duplicate seat on the same diff; the task review is the gate

## Finish — surface every ruling

Before deleting anything, collect **every** ledger line containing `Ruling:` — preflight rulings, parked findings, breaker adjudications, all of them — into your final message under **"Rulings I made"**, in the order you made them, each with what it costs if wrong. The list is exhaustive: if the ledger holds a ruling, the list holds it. That list is the only place decisions you took on the user's behalf reach them — they read it and rework whatever you got wrong. **A ruling that dies with the workspace was a decision made in secret.** Then delete the plan's workspace and hand off to `branch-lifecycle`.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v6.3.0 @ b36e082; reviewer-input rule from addyosmani/agent-skills `doubt-driven-development` (MIT). See SOURCES.md.*
