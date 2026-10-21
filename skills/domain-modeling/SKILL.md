---
name: domain-modeling
description: Use when writing or editing a GLOSSARY.md (older repos CONTEXT.md) or an ADR, or when design conversations keep using vague or conflicting terms. Settles the project's shared vocabulary. For where a module seam goes or how deep an interface should be, use codebase-design.
---

# Domain Modeling — shared language

A shared language between you, the user, and the codebase pays off every session: fewer tokens on explanation, consistent naming of variables/files, easier navigation. "There's a problem with the materialization cascade" beats three sentences of description.

## Files

- `GLOSSARY.md` at repo root — the glossary (mattpocock/skills v1.3 renamed it from `CONTEXT.md`). A repo that already has `CONTEXT.md` keeps it: read and update that file, never rename it without asking. Create **lazily**, when the first term is resolved.
- `docs/adr/NNNN-<slug>.md` — decisions. Create when the first ADR is needed.
- Multi-context repos: `GLOSSARY-MAP.md` (or the repo's existing `CONTEXT-MAP.md`) at root points to per-context glossary files.

**Habit for ALL skills:** before exploring a codebase, read `GLOSSARY.md` (or `CONTEXT.md`) if it exists, and respect ADRs in the area you're touching.

## Glossary format (`GLOSSARY.md` / `CONTEXT.md`)

```md
# {Context Name}
{1-2 sentences: what this context is and why it exists.}

## Language
**Order**: A customer's request to purchase, from placement to fulfillment.
_Avoid_: Purchase, transaction
```

Rules: be **opinionated** (pick one term, list the rest under _Avoid_); definitions 1-2 sentences, what it IS not what it does; **only project-specific concepts** — general programming ideas don't belong; glossary only, zero implementation details.

## During design sessions (the active discipline)

- **Challenge against the glossary:** user's term conflicts with the glossary? Call it out immediately.
- **Sharpen fuzzy language:** "You said 'account' — Customer or User? Those differ."
- **Stress-test with concrete scenarios** that probe boundaries between concepts.
- **Cross-reference with code:** "Your code cancels entire Orders, but you said partial cancellation exists — which is right?"
- **Update the glossary inline** the moment a term is resolved. Don't batch.

## ADRs — offer sparingly

Only when ALL three hold: (1) hard to reverse, (2) surprising without context — future reader would ask "why this way?", (3) result of a real trade-off. Missing any → skip the ADR. Format: Status / Context / Decision / Consequences, one page max.

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 068b6e0 (2026-08-17). See SOURCES.md.*
