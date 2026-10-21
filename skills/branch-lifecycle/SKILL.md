---
name: branch-lifecycle
description: "Use when starting feature work that needs isolation from the current workspace, and when implementation is complete and the branch must be merged, PR'd, kept or discarded. Not for commit hygiene, secrets or conflict resolution, that is git-safety."
---

# Branch Lifecycle

## Starting: Isolated Workspace

**Never start implementation on main/master without explicit consent.**

1. **Detect existing isolation first.** Compare `git rev-parse --git-dir` vs `--git-common-dir` (resolved): different (and not a submodule — check `git rev-parse --show-superproject-working-tree`) → already in a linked worktree; skip creation.
2. **Native worktree tools beat manual git.** If the platform has a worktree tool/flag, use it — manual `git worktree add` creates phantom state the harness can't manage.
3. **Manual fallback:** use `.worktrees/` at project root (or existing convention). MUST verify it's git-ignored first (`git check-ignore -q .worktrees`) — if not, add to .gitignore and commit. Then `git worktree add "$path" -b "$branch"`.
4. **Setup + clean baseline:** auto-detect (`npm install` / `cargo build` / `pip install -r` / `go mod download`), then run the test suite. Failures at baseline → report and ask before proceeding.

## Finishing: Verify → Options → Execute → Clean Up

**Step 1 — verify tests pass.** Failing → show failures, stop. No merge/PR with red tests. Capture the worktree path (`git rev-parse --show-toplevel`) now — later steps change directory before cleanup needs it.

**Step 2 — determine base branch:** whatever the work forked from — named in the plan, conversation, or branch upstream. Unsure → ask and confirm; merging into the wrong base is expensive to undo.

**Step 3 — present exactly these options, no extra explanation:**

```
Implementation complete. What would you like to do?
1. Merge back to <base> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
```

(Detached HEAD in an externally managed workspace: options 2-3 only, merge unavailable.) **Discard is never on the menu** — it happens only when the human explicitly asks to throw the work away. The integration decision is theirs; wait for the answer.

**Step 4 — execute:**
- **Merge:** checkout base in the main repo root, pull, merge — verify tests pass on the merged result BEFORE removing anything. Tests fail on the merge → stop, leave worktree and branch in place, investigate (nothing pushed; it's local and recoverable). Green → clean up worktree, delete branch.
- **PR:** push branch, create the PR with the forge's tooling (its CLI, or the creation URL printed on push), following the repo's PR template/conventions; report the URL. Keep the worktree — it's needed to iterate on PR feedback.
- **Keep:** report branch name and location; done.
- **Discard (only on explicit request):** confirm explicitly ("this permanently deletes X commits — type 'discard' to confirm") before `git worktree remove --force` + `git branch -D`.

Order matters: merge first, verify, only then delete. Never destroy work before its replacement is confirmed. Cleanup only removes worktrees under `.worktrees/`/`worktrees/` (ours); externally managed workspaces stay in place.

**Removal refused** (`contains modified or untracked files`): the worktree holds files that exist nowhere else — uncommitted plans, notes, scratch work. **Never `--force` on your own initiative.** Run `git -C "$WORKTREE_PATH" status --porcelain -uall`, show the user the file list, and offer three choices: (1) commit them to the branch before cleanup, (2) move them into the main repo root, (3) delete them (unrecoverable). Carry out the choice, then remove the worktree. "Removal refused, so `--force` just finishes the cleanup" is exactly backwards — the refusal *is* the signal that files would be destroyed permanently.

---
*Distilled from [obra/superpowers](https://github.com/obra/superpowers) (MIT © Jesse Vincent / Prime Radiant), v6.3.0 @ b36e082.*
