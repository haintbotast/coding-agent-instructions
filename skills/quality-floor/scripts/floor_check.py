#!/usr/bin/env python3
"""Check whether a git diff weakens the quality floor (quality-floor skill).

Usage: python3 floor_check.py --base origin/main [--exclude vendor/ --exclude third_party/] [--json]
Reads `git diff <base>...HEAD --unified=0` and reports by file:line:
  - ADDED lines with a check-suppression comment (ts-ignore, eslint-disable, noqa, type: ignore, pragma warning disable)
  - ADDED lines that skip a test (.skip(, xit(, xdescribe(, @pytest.mark.skip, [Ignore], @Ignore, t.Skip()
  - ADDED lines marking unfinished work (TODO: implement, NotImplementedError, raise NotImplemented, throw new Error("not implemented"))
  - ADDED lines that look like a secret (AKIA…, ghp_…, -----BEGIN … PRIVATE KEY-----, api_key = "…")
  - DELETED TEST FILES
Exit 0 when clean, 1 on violations, 2 on a git execution error. Standard library only.
"""
import argparse
import json
import re
import subprocess
import sys

SUPPRESS = re.compile(r"@ts-ignore|@ts-expect-error|eslint-disable|#\s*noqa|#\s*type:\s*ignore|#pragma\s+warning\s+disable|// nolint|@SuppressWarnings", re.I)
SKIP = re.compile(r"\.skip\(|\bxit\(|\bxdescribe\(|@pytest\.mark\.skip|\[Ignore\]|@Ignore\b|\bt\.Skip\(|\.only\(", re.I)
STUB = re.compile(r"TODO:?\s*implement|NotImplementedError|raise NotImplemented\b|not implemented\"|not implemented'", re.I)
SECRET = re.compile(r"AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|secret|token|password)\s*[:=]\s*[\"'][^\"'$]{12,}[\"']", re.I)
TEST_FILE = re.compile(r"(^|/)(test|tests|__tests__|spec)(/|$)|\.(test|spec)\.[a-z]+$|_test\.(go|py|rb)$|^test_.*\.py$", re.I)


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stderr)
        sys.exit(2)
    return r.stdout


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", default="origin/main", help="comparison base (three-dot with HEAD)")
    ap.add_argument("--exclude", action="append", default=[], help="path prefix to skip (repeatable)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--working", action="store_true",
                    help="also include uncommitted changes to tracked files (diff from the merge-base to the working tree)")
    a = ap.parse_args()
    rng = [run(["git", "merge-base", a.base, "HEAD"]).strip()] if a.working else [f"{a.base}...HEAD"]

    findings = []
    for line in run(["git", "diff", *rng, "--name-status", "-M"]).splitlines():
        parts = line.split("\t")
        if parts[0].startswith("D") and TEST_FILE.search(parts[-1]) and not any(parts[-1].startswith(x) for x in a.exclude):
            findings.append({"file": parts[-1], "line": 0, "kind": "test-deleted", "text": ""})

    diff = run(["git", "diff", *rng, "--unified=0", "--no-color"])
    cur, ln = None, 0
    for raw in diff.splitlines():
        if raw.startswith("+++ "):
            cur = raw[6:] if raw.startswith("+++ b/") else None
            continue
        if raw.startswith("@@"):
            m = re.search(r"\+(\d+)", raw)
            ln = int(m.group(1)) if m else 0
            continue
        if cur is None or raw.startswith("---") or raw.startswith("-"):
            continue
        if raw.startswith("+"):
            text = raw[1:]
            if not any(cur.startswith(x) for x in a.exclude):
                for kind, rx in (("suppression", SUPPRESS), ("test-skipped", SKIP), ("stub", STUB), ("secret", SECRET)):
                    if rx.search(text):
                        findings.append({"file": cur, "line": ln, "kind": kind, "text": text.strip()[:120]})
            ln += 1

    if a.json:
        print(json.dumps({"base": a.base, "findings": findings}, ensure_ascii=False, indent=1))
    else:
        for f in findings:
            loc = f"{f['file']}:{f['line']}" if f["line"] else f["file"]
            print(f"  ERROR  {loc}: {f['kind']}  {f['text']}")
        print(f"  {'ok   ' if not findings else ''}{len(findings)} floor violation(s) vs {a.base}")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
