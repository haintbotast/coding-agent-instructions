#!/usr/bin/env bash
# vet_clone.sh — fetch a repo for vetting WITHOUT a working tree, then scan the risk surface on HEAD.
#
#   bash vet_clone.sh <owner>/<repo> [ref]
#
# No files on disk besides .git ⇒ the repo's scripts cannot be run by accident (failure class READONLY-BY-PROSE:
# in a real incident a sub-agent told "read-only" only in prose still ran evals/measure.py). This guard blocks ACCIDENTAL runs,
# not deliberate ones (`git show … | python3` still works) — for a suspicious repo, vet inside a throwaway VM.
# Read:  git -C <dir> show HEAD:<path>   ·   git -C <dir> grep -n <pattern> HEAD   ·   git -C <dir> ls-tree -r --name-only HEAD
# Exit codes: 0 done · 2 bad arguments · 3 repo does not exist/is not accessible (check the name for typo-squatting) · 1 clone failed.
set -uo pipefail
R="${1:-}"; REF="${2:-}"
case "$R" in */*) ;; *) echo "usage: vet_clone.sh <owner>/<repo> [ref]" >&2; exit 2;; esac

META=$(curl -fsS -m 20 "https://api.github.com/repos/$R" 2>/dev/null) || {
  echo "DOES NOT EXIST or not accessible: $R — check the name for typo-squatting"; exit 3; }
printf '%s' "$META" | python3 -c 'import sys,json
d=json.load(sys.stdin)
print("repo: %s | stars: %s | license: %s | push: %s | fork: %s%s" % (d["full_name"], d["stargazers_count"],
      (d.get("license") or {}).get("spdx_id"), d["pushed_at"][:10], d.get("fork"),
      (" <- " + d["parent"]["full_name"]) if d.get("fork") else ""))'

D=$(mktemp -d "${TMPDIR:-/tmp}/vet-XXXX")
if [ -n "$REF" ]; then
  git clone -q --depth 1 --no-checkout --branch "$REF" "https://github.com/$R.git" "$D/r" || { echo "clone failed" >&2; exit 1; }
else
  git clone -q --depth 1 --no-checkout "https://github.com/$R.git" "$D/r" || { echo "clone failed" >&2; exit 1; }
fi
G=(git -C "$D/r")
ON_DISK=$(find "$D/r" -mindepth 1 -not -path "$D/r/.git*" | wc -l | tr -d ' ')
echo "dir: $D/r | HEAD: $("${G[@]}" rev-parse --short HEAD) | files in tree: $("${G[@]}" ls-tree -r --name-only HEAD | wc -l | tr -d ' ') | files on disk outside .git: $ON_DISK"
[ "$ON_DISK" = 0 ] || echo "WARNING: files exist on disk — the guard is gone"

sec() { echo "== $1 =="; }
LS=$("${G[@]}" ls-tree -r --name-only HEAD)
sec "hook / settings / plugin"
printf '%s\n' "$LS" | grep -E '(^|/)(hooks?/[^/]+$|\.claude/settings[^/]*\.json$|hooks\.json$|plugin\.json$|\.mcp\.json$)' | head -15
sec "installer / postinstall"
printf '%s\n' "$LS" | grep -E '(^|/)install[^/]*\.(sh|ps1|js|mjs|py)$' | head -10
"${G[@]}" grep -nE '"(pre|post)install"' HEAD -- '*package.json' | head -5
sec "npx -y / @latest / curl|sh"
"${G[@]}" grep -nE 'npx (-y|--yes)|@latest|(curl|wget)[^|]*\|[[:space:]]*(ba|z)?sh' HEAD -- ':!*.md' ':!.github/*' ':!*test*' ':!*fixture*' | head -15
sec "network calls in shipped code (files; excluding .github/, test, fixture)"
"${G[@]}" grep -lE 'fetch\(|requests\.(get|post)|urllib\.request|http\.client|axios|ureq::|reqwest|curl |wget ' HEAD -- ':!*.md' ':!.github/*' ':!*test*' ':!*fixture*' | head -20
sec "telemetry / analytics"
"${G[@]}" grep -liE 'telemetry|posthog|segment\.io|supabase|mixpanel|amplitude' HEAD -- ':!*.md' ':!.github/*' ':!*test*' ':!*fixture*' ':!*schema*' | head -12
sec "text coaxing for permissions (ask for permission / approve / elevated)"
"${G[@]}" grep -liE '(ask|request|rerun).{0,60}(permission|approv|elevat|escalat|network-enabled)|approver must|escalated command|dangerously|--no-sandbox' HEAD -- ':!*.md' ':!.github/*' ':!*test*' ':!*fixture*' | head -10
echo
echo "Read further: git -C $D/r show HEAD:<path> | git -C $D/r grep -n <pattern> HEAD.  Clean up: rm -r $D"
