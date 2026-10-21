---
name: brainstorming-design
description: "Use when the idea is still ROUGH and no design exists yet. Turns a vague feature request into an approved design through questions, before any implementation. If a plan or design already exists and needs stress-testing, use grilling instead."
---

# Brainstorming Ideas Into Designs

<HARD-GATE>
Do NOT write code, scaffold a project, or take any implementation action until you have told the user what you intend and they approved it. This applies to EVERY task on EVERY path below — **the ceremony scales with the task; the approval gate never does.**
</HARD-GATE>

"Simple" projects are where unexamined assumptions cause the most wasted work. The design can be two sentences in chat — but you MUST present it and get approval. What scales with simplicity is the artifact, never the approval.

## Three paths — classify first, say it out loud

Before your first question, classify the request and announce the classification ("this looks bounded, so I'll present a short design here rather than write a spec") so the user can override it.

| Path | What it is | Process |
|---|---|---|
| **Spike** | A feasibility question ("can we…", "is it possible…", "quick and dirty is fine") whose output is an *answer*, not code you keep. | Present the question + what you'll try in 2-3 sentences → get a nod → find out as cheaply as correctness allows → report a recommendation. Anything built stays labelled throwaway. No design doc, no spec. |
| **Bounded** | A well-scoped change to code **that already exists in this repo** — a new flag, a small endpoint, a one-file fix. Bounded means the flow you're changing is here to read; no existing flow → not bounded. | Ask the clarifying questions that matter → present a short design **in chat** (a few sentences to a few short paragraphs: approach, files touched, testing) → **STOP** and wait for an explicit yes → implement via the normal workflow (TDD applies). No spec file, no plan document. |
| **Architectural** | New projects, new subsystems, changes that restructure how components fit together or alter interfaces others depend on. | The full checklist below → written spec → `writing-plans`. |

**When in doubt between two paths, take the heavier one.** The ratchet is one-way: hidden complexity discovered mid-task upgrades the path — stop, say so, step up. Nothing downgrades mid-task.

**Terminal states are path-bound.** Architectural → `writing-plans`, never an implementation skill. Bounded → implementation directly, no plan document. Spike → a reported recommendation.

## Shared understanding before the first design question

- **Know what you know first.** If everything that matters is already in the request ("make the icon cornflower blue"), it is a quick, clear task: do it and say what you did. If something non-trivial is missing, start the conversation.
- **First message = two things, in order:** (1) one line saying they can skip the questions and have you just start (if they do, state any significant how-it-gets-made choice — platform, language, medium — in one plain line and continue through the normal workflow; the gate below no longer applies); (2) ONE open question that gets them describing a real moment or concrete picture, not a menu.
- **Discover intent first.** Ask the purpose before proposing features or an approach. Each message ends with exactly one question (one sentence, no list of example answers). Open questions before options; offer a short menu only when they are stuck, and when they say "just guess" propose something concrete. Match their vocabulary, no process jargon.
- **Find out who decides the how** (medium, tools, language, existing assets): build on what the repo already uses; any choice you make goes in the design as YOUR call, never as something they agreed to.
- **Play back in chunks.** As soon as one part is clear enough, describe it back in ~200-300 words in your own words, mark guesses as guesses (only what they said goes in as theirs), end by asking what is wrong or missing, then return to questions about the next part. Playback and questions alternate.
- **Offer recon** (codebase, files, web) once there is grounding; say what you would look for; they decide. Think wide privately (several ideas, drop the weak ones) and show the comparison only when it helps them decide.
- **A reply approves the stage actually presented, nothing beyond it.** Approval of an idea or a feature scope does not approve artifacts that do not exist yet: conversational design approval only permits writing the spec; written-spec approval only permits invoking `writing-plans`. Read-only exploration of the repo is allowed before approval; writing is not.
- A "simple todo app" from scratch is a new project -> architectural, not two sentences in chat.

## Red flags

| Thought | Reality |
|---|---|
| "Too simple to need a design" | Simple means a *short* design, not none. Two sentences, then approval. |
| "I'll call it bounded and skip the spec" | Reaching for a label to skip work IS the doubt — take the heavier path. |
| "It's bounded and obvious — I'll start while they read it" | The gate is the approval, not the design's length. Present, then stop until you hear yes. |
| "I understand this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. A new project has no existing flow — it's architectural. |
| "I'll fill in sensible defaults silently" | Say them out loud. A default they never heard is one they could not reject. |
| "The spike works, so I'll keep the code" | A spike's output is an answer. Keeping the code is a new request — classify it. |
| "It grew, but I'm almost done — no need to re-classify" | Hidden complexity upgrades the path mid-task. Stop and say so. |
| "They approved the spike, so the follow-up is approved too" | Each task gets its own classification and its own approval. |

## Checklist — architectural path (create a todo per item)

1. **Explore project context** — files, docs, recent commits. Follow existing patterns.
2. **Scope check** — request spans multiple independent subsystems? Decompose into sub-projects first; each gets its own spec → plan → implementation cycle.
3. **Ask clarifying questions — ONE at a time.** Multiple choice preferred. Focus: purpose, constraints, success criteria.
4. **Propose 2-3 approaches** with trade-offs; lead with your recommendation and reasoning.
5. **Present the design in sections** scaled to complexity; get approval after each section. Cover: architecture, components, data flow, error handling, testing.
6. **Write the design doc** to `docs/specs/YYYY-MM-DD-<topic>-design.md` and commit. (User preference overrides location.)
7. **Builder check** — dispatch a fresh subagent as "a talented <domain> builder who cannot talk to the author": read the spec, report ONLY the questions whose wrong guess would matter, ranked, each with why it changes the plan ("nothing important left" if none). Sort into: answered already (put it in the spec) / minor (settle it, mark as your call) / theirs (only the user can answer and it changes what gets built). Bring "theirs" in ONE message, update the spec, hand it over with the list of your calls. One round only. No subagent tool -> read it as that builder yourself.
8. **User reviews the written spec** — wait for approval before proceeding.
9. **Transition** — invoke `writing-plans`. That is the ONLY next skill.

## Design Principles

- **YAGNI ruthlessly** — cut unnecessary features from every design.
- **Design for isolation:** each unit has one clear purpose, a well-defined interface, and can be understood and tested independently. Can someone use it without reading its internals? Can you change internals without breaking consumers? If not, boundaries need work.
- Existing code with problems that affect the work → include targeted improvements. Don't propose unrelated refactoring.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v7.0.0 @ bb92a77 (2026-10-12).*
