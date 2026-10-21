---
name: handoff
description: "Use when the current session is ending or its context is full and another agent or session must continue the work: compacts the conversation into a restartable handoff document. Not for durable project documentation, which belongs in the repo."
---

# Handoff

Write a handoff document summarising the current conversation so a fresh agent can continue. Save to the OS temp directory (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) — NOT the workspace (it would pollute the repo). Resolve it the same way every run and report the path.

## Rules

- Include a **"suggested skills"** section naming the skills the next agent should invoke.
- **Do not duplicate** content already captured in artifacts (specs, plans, ADRs, issues, commits, diffs) — reference them by path/URL instead.
- **Redact** secrets: API keys, passwords, PII.
- If the user says what the next session will focus on, tailor the doc to that.
- Structure: current state → what was decided and why → what remains → gotchas discovered → suggested skills → artifact references.
- **Restartable boundary:** the doc must let a fresh session resume without the transcript — goal in one line, done-criteria, branch + commit, the exact commands that verify current state, open decisions with the options still on the table. If any of these is missing, the handoff is not restartable. (From addyosmani/agent-skills `context-engineering`, MIT.)

---
*Distilled from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © Matt Pocock), snapshot 49dd158 (2026-10-12). See SOURCES.md.*
