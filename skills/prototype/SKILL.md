---
name: prototype
description: Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like, before committing to a real implementation. NOT for building the real thing, that is writing-plans then test-driven-development.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape:

- **"Does this logic/state model feel right?"** → a **single shareable HTML file** — free-play buttons plus tabbed guided walkthroughs — that pushes the state machine through cases hard to reason about on paper, and that a non-developer can drive.
- **"What should this look like?"** → several radically different UI variations on one route, switchable via URL param.

Ambiguous and user unreachable? Default by surrounding code (backend module → logic; page/component → UI) and state the assumption at the top.

## Rules

1. **Throwaway from day one, clearly marked.** Place near where it'll be used, named so a casual reader sees it's a prototype. Follow existing routing conventions for UI routes.
2. **Trivial to run.** A UI prototype starts from one command in the project's existing task runner; a logic demo is a single HTML file the user double-clicks. Either way, no thinking required to start it.
3. **No persistence by default** — state in memory. If the question IS persistence, use a scratch DB/file named "PROTOTYPE — wipe me".
4. **Skip the polish.** No tests, no error handling beyond runnable, no abstractions.
5. **Surface the state** after every action / variant switch so the user sees what changed.
6. **Capture when done.** Fold the validated decision into real code — main keeps only that. Then commit the prototype itself to a **throwaway branch** (out of main) as a primary source, with a pointer to the branch from the implementation issue/commit. Capture the answer too — verdict + the question it settled — durably (issue, commit message, ADR). For UI variants: the winner folds into the real page/route; the full variant set + switcher ride the throwaway branch, never main.

## Recovery

| State | Way out |
|---|---|
| Prototype code leaked into main | It was never meant to ship: `git revert` the commit that brought it, then put it on the throwaway branch where rule 6 says it belongs. Check the routing config too — a prototype route left registered is the part that survives a partial revert. |
| Scratch DB/file from rule 3 still around | Delete it. It is named "PROTOTYPE — wipe me" precisely so this is a one-line decision, not an investigation. |
| Throwaway branch deleted before the answer was captured | The verdict matters, the code does not. If the answer was never written to an issue/commit/ADR, it is gone — re-run the prototype rather than reconstruct it from memory. Capture first next time; that is what rule 6 is for. |
| Prototype grew tests, error handling, abstractions | It stopped being a prototype and became unreviewed production code. Stop. Either throw it away and implement properly, or put it through the normal pipeline from `writing-plans` onward. Do not merge it because it "already works". |
| Cannot tell whether the prototype answered the question | It did not. An inconclusive prototype is a cheap failure — say so, name what stayed ambiguous, and either sharpen the question or move to a real spike. Do not report a guess as a finding. |

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 068b6e0 (2026-08-17). See SOURCES.md.*
