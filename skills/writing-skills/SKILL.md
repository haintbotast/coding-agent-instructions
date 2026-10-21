---
name: writing-skills
description: "Use when creating, editing or verifying an agent skill (SKILL.md) before deployment. Skill writing is test-driven development applied to process documentation. Not for deciding which existing skill to invoke, that is using-skills."
---

# Writing Skills

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

TDD mapping: pressure scenario = test case; SKILL.md = production code; agent violates rule without skill = RED (document the exact rationalizations it used); agent complies with skill = GREEN; closing loopholes = REFACTOR.

## When to Create

- Technique wasn't intuitively obvious; you'd reference it across projects; applies broadly; others benefit.

**Don't create for:** one-off solutions, standard practices documented elsewhere, project-specific conventions (→ the project's AGENTS.md / CLAUDE.md), mechanically enforceable constraints (→ automate instead).

## Structure

```
skills/skill-name/SKILL.md    # required; separate files only for heavy reference (100+ lines) or reusable scripts
```

```markdown
---
name: skill-name-with-hyphens
description: Use when [triggering conditions and symptoms] — NOT a summary of the process
---
# Name
## Overview — core principle in 1-2 sentences
## When to Use — symptoms, use cases, when NOT
## Core Pattern — before/after comparison
## Quick Reference — scannable table
## Common Mistakes — what goes wrong + fixes
```

## Description Field = Discovery

The agent reads only the description to decide whether to load the skill. It must answer "should I read this NOW?":
- Start with "Use when..." — triggering conditions, specific symptoms and contexts
- End with a negative clause naming the sibling skill that owns the neighbouring case ("Not for X, that is other-skill") so two skills never compete for one trigger
- Third person; max ~500 chars (Agent Skills spec hard limit: 1024); NEVER summarize the workflow (agents will follow the summary instead of reading the skill)
- `name`: lowercase letters, digits and single hyphens, ≤ 64 chars, equal to the folder name. Keep frontmatter to `name` + `description` (optionally `license`, `metadata`): some tools reject unknown keys

## Writing Rules

- Skills are reusable techniques, NOT narratives about how you once solved something
- Never make a skill fetch its procedure from a live URL at run time; copy what it needs into `references/` with the source SHA (failure class `REMOTE-INSTRUCTIONS-AT-RUNTIME`)
- A rule a machine can check becomes a script in `scripts/`, not a sentence
- One excellent way per problem, not many options
- Address the reader as "you"; imperative mood
- Rationalization tables and "Red Flags — STOP" sections close loopholes for rules agents are tempted to break under pressure
- For discipline skills, state an Iron Law and make violations concrete: "Delete it. Start over."
- Invoke bundled scripts through their interpreter in the prose (`bash scripts/tool.sh`, `python3 scripts/tool.py`), never by bare path: some plugin packagers strip executable bits.

## Testing

Run the pressure scenario with a fresh subagent WITHOUT the skill (baseline RED — record its excuses), then WITH the skill (GREEN). New rationalizations → plug them → re-verify.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v6.1.0 @ f268f7c; script-invocation rule from v6.4.2 @ 8ca22db; unchanged at v7.0.0 @ bb92a77 (2026-10-12).*
