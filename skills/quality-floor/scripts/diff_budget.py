#!/usr/bin/env python3
"""Measure one change against the small-step budget (quality-floor skill).

Two budgets:
  - Step (one commit, or the uncommitted work): <= 50 added LOGIC lines. Logic = non-test source files.
    Not counted: tests, docs, config, generated code, lockfiles, data, deleted lines, renames.
  - PR (whole branch vs its base): <= 400 changed lines (added + deleted) in every file except
    generated code, lockfiles and binaries.
Where the numbers come from: Google eng-practices "Small CLs" (~100 lines is usually reasonable,
~1000 usually too large); SmartBear/Cisco: defect finding drops when one review goes past 200-400 lines.

Usage (inside a git repo):
  python3 diff_budget.py                      # staged + unstaged + new untracked files vs HEAD (the step about to be committed)
  python3 diff_budget.py --base HEAD~1        # the commit just made
  python3 diff_budget.py --pr origin/main     # whole branch, PR budget
  python3 diff_budget.py --step 80 --json     # other step budget, JSON output
Exit 0 = within budget; 1 = over (split the step, or give the reason in the commit message); 2 = usage or git error.
It warns, it does not block: the rule has fair exceptions (mass rename, migration, a new tool), so state the reason.
Standard library only.
"""
import argparse, json, re, subprocess, sys

TEST = re.compile(r"(^|/)(tests?|__tests__|spec|e2e|test-unit)/|(\.|_)(test|spec)\.[a-z0-9]+$|(^|/)test_[^/]+\.(py|sh)$|_test\.(go|py|rs)$")
DOCS = re.compile(r"\.(md|mdx|txt|rst|adoc)$|(^|/)docs?/")
GENERATED = re.compile(r"(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Pipfile\.lock|go\.sum|Cargo\.lock|composer\.lock|Gemfile\.lock)$"
                       r"|\.min\.(js|css)$|\.snap$|(^|/)(dist|build|vendor|node_modules|generated|\.next)/|\.(pb|g|gen)\.[a-z]+$")
CONFIG = re.compile(r"\.(json|ya?ml|toml|ini|cfg|conf|env\.example|xml|plist|properties)$|(^|/)(Dockerfile|Makefile|\.gitignore|Caddyfile)$")
LOGIC = re.compile(r"\.(py|ts|tsx|js|jsx|mjs|cjs|go|java|kt|cs|php|rb|rs|swift|c|cc|cpp|h|hpp|sql|sh|bash|zsh|ps1|lua|dart|scala|vue|svelte)$")

def kind(path):
    if GENERATED.search(path): return "generated"
    if TEST.search(path): return "test"
    if DOCS.search(path): return "docs"
    if CONFIG.search(path): return "config"
    if LOGIC.search(path): return "logic"
    return "other"

def numstat(args):
    r = subprocess.run(["git", "diff", "--numstat", "-M"] + args, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"git diff failed: {r.stderr.strip()}", file=sys.stderr); sys.exit(2)
    out = []
    for line in r.stdout.splitlines():
        added, deleted, path = line.split("\t", 2)
        if added == "-":                       # binary
            continue
        if "=>" in path:                       # rename: keep the new name
            path = re.sub(r"\{([^}]*) => ([^}]*)\}", r"\2", path).split(" => ")[-1]
        out.append((int(added), int(deleted), path))
    return out

def untracked():
    """New files not yet `git add`-ed: git diff does not see them, so count their lines (skip binaries)."""
    r = subprocess.run(["git", "ls-files", "--others", "--exclude-standard", "-z"], capture_output=True, text=True)
    out = []
    for path in filter(None, r.stdout.split("\0")):
        try:
            with open(path, "rb") as f:
                b = f.read()
        except OSError:
            continue
        if b"\0" in b[:8000]:
            continue
        out.append((b.count(b"\n") + (0 if b.endswith(b"\n") or not b else 1), 0, path))
    return out

def main():
    ap = argparse.ArgumentParser(description="Measure a change against the small-step budget.")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--base", help="compare with this ref (default: HEAD, staged + unstaged + untracked)")
    g.add_argument("--pr", metavar="BASE_BRANCH", help="measure the whole branch against its base, PR budget")
    ap.add_argument("--step", type=int, default=50, help="added logic lines per step (default 50)")
    ap.add_argument("--pr-budget", type=int, default=400, help="changed lines per PR (default 400)")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    if a.pr:
        rows = numstat([f"{a.pr}...HEAD"])
    else:
        rows = numstat([a.base or "HEAD"])
        if not a.base:
            rows += untracked()
    by = {}
    for added, deleted, path in rows:
        t = by.setdefault(kind(path), {"added": 0, "deleted": 0, "files": []})
        t["added"] += added; t["deleted"] += deleted; t["files"].append(path)

    if a.pr:
        measured = sum(v["added"] + v["deleted"] for k, v in by.items() if k != "generated")
        limit, label = a.pr_budget, "PR: changed lines (added + deleted, excluding generated code and lockfiles)"
    else:
        measured = by.get("logic", {}).get("added", 0)
        limit, label = a.step, "Step: added logic lines (excluding tests, docs, config, generated code)"
    over = measured > limit
    res = {"measured": measured, "limit": limit, "over": over,
           "kinds": {k: {"added": v["added"], "deleted": v["deleted"], "files": len(v["files"])} for k, v in by.items()}}
    if a.json:
        print(json.dumps(res))
    else:
        print(f"{label}: {measured} / {limit} -> {'OVER' if over else 'OK'}")
        for k, v in sorted(by.items()):
            print(f"  {k:9} +{v['added']:<5} -{v['deleted']:<5} {len(v['files'])} files")
        if over:
            print("Split into smaller steps (one test + the code that turns it green). If it cannot be split, give the reason in the commit message.")
    sys.exit(1 if over else 0)

if __name__ == "__main__":
    main()
