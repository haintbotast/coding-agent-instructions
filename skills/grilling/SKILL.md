---
name: grilling
description: Use when a plan, decision, or idea ALREADY EXISTS and needs stress-testing before acting, when alignment on requirements feels shaky, or when opening an ambiguous coding task (one bounded round). If there is no design yet, use brainstorming-design first.
---

# Grilling

Interview the user **relentlessly** about every aspect of the plan, decision, or idea until you reach shared understanding. The most common failure mode is misalignment — you think you understood, then you build the wrong thing. Grilling closes the gap before you act.

## The design tree, worked in rounds

Map the subject as a **design tree**: every decision branches into the decisions hanging off it. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you haven't heard yet.

**Ask the whole frontier in one round**, then wait for the user's answers before the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one. Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock what depended on them. Recompute, ask the next round.

Format a round — separate consecutive questions with a `---` rule:

```
❓ **Q1** - **<question title>**: <body, may be several paragraphs, may offer multiple choice>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <body...>

➡️ <your recommended answer>
```

Always give your recommended answer — the user reacts faster to a concrete proposal than a blank prompt. **Word each question so a plain "yes" accepts your recommendation.** Prefer multiple choice when the option space is small.

**Finding facts is your job, never the user's.** A frontier question needing a fact from the environment (codebase, filesystem, tools) → dispatch a sub-agent to find it. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait — ask the rest of the frontier now. **Decisions belong to the user**: put each to them and wait.

## Opening a coding task (bounded mode)

Before code on a task that is ambiguous or expensive to redo, run ONE round only: **at most 5 questions**, each with your recommended answer, and only questions whose answer changes what gets built. Then grill your own plan without the user: write **at least 3 ways it could be wrong** and the command or check that would catch each. Ask at the start, never mid-way. User away, unattended run, or "just do it all" → take your recommendations, write them down as assumptions, proceed. Full relentless rounds above are for plans and decisions the user explicitly wants stress-tested.

## With docs (grill-with-docs mode)

When the project keeps a domain glossary, run the `domain-modeling` skill during the session: challenge terms against `GLOSSARY.md` (or `CONTEXT.md`), sharpen fuzzy language, capture resolved terms and ADR-worthy decisions **as they crystallise**, not at the end.

## When to stop

**The session is done when the frontier is empty** — every branch of the design tree visited, nothing left silently assumed. Then summarise the agreed design and hand off to the normal pipeline (`brainstorming-design` → `writing-plans`), or straight to implementation for small changes.

**Gate:** do not act on it until the user confirms shared understanding — a summary is not agreement.

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 49dd158 (2026-10-12). See SOURCES.md.*
