---
name: research
description: "Use when a question needs investigating against primary sources AND the findings must be kept as a cited file in the repo. Not for a quick answer that need not be filed: just answer in the conversation."
---

# Research

Delegate the reading to a **background subagent** so the main thread keeps working.

The agent's job:

1. **Primary sources only** — official docs, source code, specs, first-party APIs; never a secondary write-up of them. Follow every claim back to the source that owns it.
2. **One Markdown file, every claim cited.**
3. **Save where the repo already keeps such notes** — match the existing convention; if there is none, pick a sensible place and say where.

Research feeds the thinking, it doesn't replace it: take the resulting file into `grilling` / `domain-modeling` or the planning pipeline — it's input, not a decision.

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 66f92b6 (2026-07-05). See SOURCES.md.*
