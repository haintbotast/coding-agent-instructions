---
name: quality-floor
description: "Use when a project needs a written quality floor (CONSTRAINTS.md: lines a change may never cross) or to check that a diff did not weaken it: new suppression comments, skipped or deleted tests, stubs, secrets. Tightening is silent, loosening is loud. Not for correctness review (code-review-discipline) or writing tests (test-driven-development)."
---

# Quality floor

A floor is the short list of things a change may **never** do, plus the numbers the project refuses to get worse at. It lives in `CONSTRAINTS.md` at the repo root and every row names the **command that produces the verdict**. A dimension with a number and no command is an aspiration, not a constraint.

## Write the floor (once per project, 15 minutes)

1. Read what already gates the repo: pre-commit hook, CI jobs, lint/typecheck/test commands. A repo with no guardrail at all is itself the first finding.
2. Write `CONSTRAINTS.md` with two parts:
   - **Floor** (no numbers, absolute): no new suppression comments (`@ts-ignore`, `eslint-disable`, `# noqa`, `# type: ignore`, `#pragma warning disable`); no unimplemented stubs (`TODO: implement`, `NotImplementedError`, empty handlers); no skipped or deleted tests without a reason in the commit message; no secrets in source; **this file is never weakened to make a change pass**.
   - **Ratchet** (numbers with commands): coverage, type errors, lint warnings, bundle size, p95 latency. Record where the project is today; the rule is "refuse to get worse".
3. Commit it beside the code. Tightening a number is silent; loosening one is a commit that says why, in the message.

## Check a diff against the floor (every review, every handoff)

Run from the project root (`<skill-dir>` = where this skill is installed):

```bash
python3 <skill-dir>/scripts/floor_check.py --base origin/main          # exit 1 on any floor violation in the diff
python3 <skill-dir>/scripts/floor_check.py --base HEAD~1 --json        # machine-readable
python3 <skill-dir>/scripts/floor_check.py --base origin/main --working # include uncommitted changes
```

The script reads `git diff <base>...HEAD` and reports, with `file:line`: added suppression comments, added skip markers (`.skip(`, `xit(`, `@pytest.mark.skip`, `[Ignore]`), deleted test files, added stub markers, and secret-shaped strings. It does not judge style; that is `code-review-discipline`'s job.

## The five loosening moves (say them by name in review)

1. **Threshold moved** — a number in `CONSTRAINTS.md` or a config went down.
2. **Test got easier** — an assertion weakened, a fixture shrunk, a case removed.
3. **Checker silenced** — suppression comment, rule disabled, file excluded.
4. **Work unfinished** — stub, `TODO`, feature flag defaulting the new path off "for now".
5. **Exception appeared** — an allowlist entry, a special case in the gate itself.

Any of these in a diff is reported as a finding even when tests are green. The author may keep it, with the reason written in the commit message; the reviewer never removes the finding to make the review pass.

## Red flags

- "I'll re-enable that check after the release."
- Coverage config edited in the same commit as a feature.
- A skipped test with no linked issue.
- The floor file edited in a feature branch.

## Recovery

| State | Way out |
|---|---|
| `floor_check.py` reports a violation you disagree with | Keep the finding; add the reason to the commit message. Change the rule only in its own commit. |
| Floor never written for an old repo | Run step 1; write only the Floor part first, Ratchet numbers can come later. |
| Script flags a legitimate `# noqa` in vendored code | Add the path to `--exclude` on the command line, not to the script. |

---
*Distilled from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) `constraint-driven-development` (MIT © Addy Osmani) @ bcab6a1 (2026-09-22). The upstream floor-guard sketch (a reference doc there) became a runnable script here, `scripts/floor_check.py`. See SOURCES.md.*
