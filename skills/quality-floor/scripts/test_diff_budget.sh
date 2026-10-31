#!/usr/bin/env bash
# test_diff_budget.sh — exercise diff_budget.py on a throwaway repo: must go RED when over, GREEN when within budget.
# Run: bash test_diff_budget.sh   (exit 0 = every case right)
set -uo pipefail
S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/diff_budget.py"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q; git config user.email t@t; git config user.name t
echo "x = 1" > app.py; mkdir -p tests; echo "def test_x(): pass" > tests/test_app.py; git add .; git commit -qm init; git branch -q base
fail=0
case_() { # case_ <name> <expected-exit> <command...>
  local name="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" = "$want" ]; then echo "ok    $name"; else echo "FAIL  $name (want $want, got $got)"; fail=1; fi
}
lines() { python3 -c "import sys; print('\n'.join(f'{sys.argv[1]}{i} = {i}' for i in range(int(sys.argv[2]))))" "$1" "$2"; }

lines y 60 >> app.py
case_ "60 logic lines -> over" 1 python3 "$S"
git checkout -q -- app.py
lines y 40 >> app.py; lines t 300 >> tests/test_app.py
case_ "40 logic + 300 test -> ok (tests not counted)" 0 python3 "$S"
git checkout -q -- .
echo '{"lockfileVersion": 3}' > package-lock.json; lines '"k' 2000 | sed 's/ = /": /' >> package-lock.json
lines z 10 >> app.py
git add package-lock.json
case_ "2000-line lockfile (added) + 10 logic -> ok" 0 python3 "$S"
git reset -q package-lock.json; rm -f package-lock.json; git checkout -q -- .
lines t 60 > test_check.sh
case_ "new test script test_*.sh, 60 lines -> ok (it is a test)" 0 python3 "$S"
rm -f test_check.sh
lines n 60 > new.py
case_ "new UNTRACKED logic file, 60 lines -> over" 1 python3 "$S"
rm -f new.py
lines a 49 >> app.py; git add .; git commit -qm b1
lines b 49 >> app.py; git add .; git commit -qm b2
case_ "last commit 49 lines -> ok" 0 python3 "$S" --base HEAD~1
case_ "step budget 40 -> over" 1 python3 "$S" --base HEAD~1 --step 40
for i in 1 2 3 4 5 6 7 8 9; do lines "c$i" 49 >> app.py; git add .; git commit -qm "c$i"; done
case_ "PR ~540 lines vs base -> over 400" 1 python3 "$S" --pr base
case_ "PR with budget 600 -> ok" 0 python3 "$S" --pr base --pr-budget 600
git mv app.py core.py; git commit -qm rename
case_ "rename without content change -> ok" 0 python3 "$S" --base HEAD~1
case_ "bad ref -> usage error (exit 2)" 2 python3 "$S" --base no-such-ref
exit $fail
