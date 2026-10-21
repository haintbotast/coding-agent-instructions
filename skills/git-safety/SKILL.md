---
name: git-safety
description: "Use when committing, pushing, creating or publishing a repository, opening a PR, changing dependencies, or resolving an in-progress merge or rebase conflict: no leaked secrets, no rewritten shared history, every step reversible. Not for deciding how a finished branch ends (merge, PR, keep), that is branch-lifecycle."
---

# Git safety

Goal: repo operations that are boringly safe — no surprises, no leaks, reversible.

## Hard rules

1. **Never commit secrets.** Scan staged changes before every commit. Found one: unstage, add to `.gitignore`, redo.
2. **Never force-push or rewrite shared history** (`push --force`, rebasing pushed commits, deleting branches) without explicit confirmation. If truly needed and confirmed, `--force-with-lease`, never bare `--force`.
3. **Confirm remote and account** before pushing: `git remote -v`, and the authenticated account (`gh auth status` or equivalent) match what the user intends.
4. **Small, clear commits.** Imperative subject ≤ 72 chars; the body explains *why* when not obvious. Follow the repo's commit convention if it has one; otherwise `feat` / `fix` / `docs` / `chore` / `refactor` / `security`.
5. **Publishing (private → public) is irreversible in practice:** forks, caches and clones keep what was public. Before the first public push scan the WHOLE tree and history, not just the last diff, for secrets AND for internal material (hostnames, internal IPs, customer names, runbooks, personal paths). Secret scanners skip prose; a human-style read of Markdown is still required.

**Dependency discipline.** One dependency change per commit. Review the lockfile diff, not just the manifest; never hand-edit a lockfile. Audit a new dependency with install scripts disabled first (`npm ci --ignore-scripts`, `pip download` then inspect) and pin its version.

## Pre-commit secret scan

Run from the project root; `<skill-dir>` is where this skill is installed (e.g. `~/.agents/skills/git-safety`):

```bash
bash <skill-dir>/scripts/secret-scan.sh            # staged changes (default)
bash <skill-dir>/scripts/secret-scan.sh --working  # all uncommitted changes
bash <skill-dir>/scripts/secret-scan.sh --file X   # one file
bash <skill-dir>/scripts/secret-scan.sh --test     # self-test, run after changing the patterns
```

Exit 0 = clean, 1 = review before committing; hits print with the value masked. Run the script; do not retype the pattern by hand — a hand-typed scan that misses looks exactly like one that passed. Two layers keep it worth reading: credential *shapes* (PAT, AWS key, PEM, JWT, Bearer) always flag; keyword-plus-assignment flags only with a real value attached, so prose about secrets does not. Prefer a dedicated scanner (gitleaks, trufflehog) for whole-history scans when available.

## Standard flow

```bash
git status
git add -A                       # or the specific paths
bash <skill-dir>/scripts/secret-scan.sh || exit 1
git commit -m "type: concise imperative subject"
git switch -c feat/short-name    # work on a branch, not main
git push -u origin feat/short-name
```

## Before any push

- [ ] `git remote -v` and the authenticated account are the intended ones.
- [ ] Secret scan clean.
- [ ] On a purpose-named branch (or `main` intentionally).
- [ ] No force-push unless explicitly confirmed.

## Merge or rebase conflict in progress

1. **See the state:** `git status`, the history of both sides, the conflicting files.
2. **Find the primary sources** for each conflict — commit messages, PRs, issues — and understand why each change was made.
3. **Resolve each hunk.** Preserve both intents where possible; where incompatible, pick the one matching the merge's stated goal and note the trade-off. Do not invent new behaviour. Do not give up on a resolvable conflict with `--abort`.
4. **Run the project's checks** (typecheck, tests, format). Fix what the merge broke.
5. **Finish:** stage and commit; if rebasing, continue until every commit is rebased. Then the pre-push checklist.

## Recovery — when it already went wrong

| State | Way out |
|---|---|
| Wrong content committed, **not pushed** | `git reset --soft HEAD~1` keeps changes staged, drops the commit. Fix, re-scan, re-commit. |
| Wrong message, **not pushed** | `git commit --amend -m "…"`. Never amend a commit already on the remote. |
| Staged something that should not be there | `git restore --staged <path>`; add to `.gitignore` if it will recur. |
| Pushed a commit that should be undone | `git revert <sha>` and push the revert. Not `reset` + force-push. |
| **Secret already pushed** | Stop touching git. The credential is compromised the moment it left the machine: rotate/revoke first, then decide about history. Removing it from history does not un-leak it. Tell the user before doing either. |
| Resolution going wrong, nothing committed | `git merge --abort` / `git rebase --abort` restores the pre-merge state — the one right use of abort. |
| Lost track of what each side said | `git show :2:<path>` ours, `:3:<path>` theirs, `:1:<path>` ancestor — until the merge is committed or aborted. |
| Committed the merge, resolution wrong | Not pushed: `git reset --hard ORIG_HEAD`. Pushed: `git revert -m 1 <merge-sha>`, redo the merge. |
| Rebase went sideways | `git reflog` lists every position; `git reset --hard <sha>` returns to any of them. |
| Checks fail after resolving | The merge is not done. Fix, or abort and restart; never commit to "finish it". |
| Pushed to the wrong remote/account | Deleting it is a history rewrite on someone else's repo. Tell the user which remote and commits; let them decide. |

Everything above except the secret case is local and reversible — that is why the order is scan, then commit, then push: each step is harder to undo than the last.

---
*Original rules by the repository author. Conflict procedure from [mattpocock/skills](https://github.com/mattpocock/skills) `resolving-merge-conflicts` (MIT © Matt Pocock, snapshot 7a83a3a); dependency discipline from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT). See SOURCES.md.*
