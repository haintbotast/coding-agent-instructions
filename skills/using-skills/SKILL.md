---
name: using-skills
description: "Use at the start of any development conversation or task: check which skill applies BEFORE responding or acting, and follow the standard pipeline from idea to merged code. Not for writing or editing a skill, that is writing-skills."
---

# Using Skills (skills-first workflow)

## The Rule

**If there is even a 1% chance a skill applies to what you are doing, invoke it BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

Announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

**How to invoke a skill:** if your tool loads skills natively (a Skill tool, `/skill-name`, automatic loading), use that. Otherwise open `<skills-dir>/<name>/SKILL.md` with your file-read tool and follow it; paths inside a skill (`scripts/`, `references/`) are relative to that skill's folder; run its scripts from the project root by full path (`<skill-dir>/scripts/...`).

## Skill Priority

Process skills come first — they set the approach; implementation skills carry it out.

- "Let's build X" → `brainstorming-design` first, then implementation.
- "Fix this bug" → `systematic-debugging` first, then domain skills.

User instructions (direct requests, then the project's AGENTS.md / CLAUDE.md / rules files) take precedence over skills, which override default behavior.

## The Standard Pipeline

1. **brainstorming-design** — refine idea into an approved design/spec. No code before approval.
2. **branch-lifecycle** — isolated workspace (worktree/branch), clean test baseline.
3. **writing-plans** — bite-sized tasks (2-5 min each) with exact paths, code, and verification.
4. **subagent-driven-dev** — fresh subagent per task with two-stage review; or inline execution with checkpoints.
5. **test-driven-development** — RED-GREEN-REFACTOR inside every task.
6. **code-review-discipline** — review between tasks; critical issues block progress.
7. **verification-before-completion** — evidence before any success claim.
8. **branch-lifecycle** (finish) — verify tests, present merge/PR/keep/discard options.

These are mandatory workflows, not suggestions.

## Red Flags — you are rationalizing

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I remember this skill" | Skills evolve. Read the current version. |

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), `using-superpowers` v6.1.0 @ f268f7c. See SOURCES.md.*
