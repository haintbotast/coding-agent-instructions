---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed or passing: before committing, opening a PR, or reporting success. Requires fresh verification evidence for every claim. Not for designing tests, that is test-driven-development."
---

# Verification Before Completion

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

Claiming work is complete without verification is dishonesty, not efficiency. If you haven't run the verification command *in this message*, you cannot claim it passes.

## The Gate Function

Before ANY status claim or expression of satisfaction:

1. **IDENTIFY** — what command proves this claim?
2. **RUN** — execute the full command, fresh and complete.
3. **READ** — full output, exit code, failure count.
4. **VERIFY** — does the output confirm the claim? If no: state the actual status with evidence.
5. **ONLY THEN** — make the claim, WITH evidence.

Skip any step = lying, not verifying.

## What Each Claim Requires

| Claim | Requires | Not sufficient |
|-------|----------|----------------|
| Tests pass | Test output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check |
| Build succeeds | Build exit 0 | Linter passing |
| Bug fixed | Original symptom re-tested: passes | Code changed, assumed fixed |
| Regression test works | Red-green verified (revert → fail → restore → pass) | Test passes once |
| Agent/subagent completed | VCS diff shows the changes | Agent's "success" report |
| Requirements met | Line-by-line checklist vs plan | Tests passing |

## Red Flags — STOP

- "Should", "probably", "seems to" in a status statement
- "Great!", "Perfect!", "Done!" before verification
- About to commit/push/PR without running verification
- Trusting a subagent's success report without checking the diff
- Tired and wanting the work to be over — exhaustion is not an excuse

Rule applies to exact phrases, paraphrases, and ANY implication of success.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v6.1.0 @ f268f7c.*
