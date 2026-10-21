#!/usr/bin/env bash
# secret-scan.sh — scan for secrets before committing. Exits 0 if clean, 1 if suspicious.
#
#   bash skills/git-safety/scripts/secret-scan.sh            # scan the staged area (default)
#   bash skills/git-safety/scripts/secret-scan.sh --working  # also scan unstaged changes
#   bash skills/git-safety/scripts/secret-scan.sh --file X   # scan one specific file
#
# Exits 1 when any line matches. Hits print as `line-number: <masked text>` (values redacted); read them and decide:
# unstage, add to .gitignore, or confirm it is a false positive.
set -uo pipefail

MODE="staged"; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --working) MODE="working"; shift ;;
    --file) MODE="file"; TARGET="${2:-}"; shift 2 ;;
    --test) MODE="test"; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1 (see --help)"; exit 2 ;;
  esac
done

# Two layers. Scanning for bare keywords ("secret", "token") also catches prose ABOUT
# secrets — it would fire on every run, and a scanner that cries wolf gets ignored within a week.
# Layer 1: the shape of a real credential, no context needed.
HIGH='(-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|glpat-[A-Za-z0-9_-]{15,}|AIza[A-Za-z0-9_-]{30,}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})'
# Layer 2: keyword + assignment + a long enough value. "our secret sauce" does not match;
# API_KEY="ab12cd34ef56" does. Split into key part (kept when masking) and value part (redacted).
ASSIGN_KEY='(api[_-]?key|secret[_-]?(key|token)?|token|password|passwd|passphrase|access[_-]?key|private[_-]?key|client[_-]?secret)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?'
ASSIGN_VAL='[A-Za-z0-9/+_.=-]{12,}'
ASSIGN="$ASSIGN_KEY$ASSIGN_VAL"
# Layer 2b: Authorization header.
BEARER='[Bb]earer[[:space:]]+[A-Za-z0-9._-]{20,}'
PAT="($HIGH|$ASSIGN|$BEARER)"

# redact: stdin = `grep -n` output (N:line). Prints `N: <first 60 chars of the line>` with every
# matched credential-shaped or assigned value replaced by ***REDACTED***. Masking happens BEFORE
# truncation so a cut never leaves a partial secret. Fails closed: if anything still matches $PAT
# after masking (or sed produced nothing), the line text is withheld entirely.
redact() {
  local l n t m
  while IFS= read -r l; do
    n="${l%%:*}"; t="${l#*:}"
    m="$(printf '%s\n' "$t" | sed -E \
      -e "s#$HIGH#***REDACTED***#gI" \
      -e "s#$BEARER#***REDACTED***#gI" \
      -e "s#($ASSIGN_KEY)$ASSIGN_VAL#"'\1'"***REDACTED***#gI" 2>/dev/null | cut -c1-60)"
    if [ -z "$m" ] || printf '%s\n' "$m" | grep -qEi "$PAT"; then m="***REDACTED*** (line withheld)"; fi
    printf '%s: %s\n' "$n" "$m"
  done
}

if [ "$MODE" = "test" ]; then
  RC=0
  chk() { # chk <expected 0|1> <label> <content>
    printf '%s\n' "$3" | grep -qEi "$PAT" && G=1 || G=0
    if [ "$G" = "$1" ]; then printf '  ok   %s\n' "$2"
    else printf '  MISMATCH %s (expected %s, got %s)\n' "$2" "$1" "$G"; RC=1; fi
  }
  chk 0 'prose about secret/token/password'     'Our secret sauce is the token pipeline; set a password in the UI.'
  chk 0 'bare variable name without a value'    'read API_KEY from the environment'
  chk 1 'GitHub PAT'                            'ghp_abcdefghijklmnopqrstuvwxyz01'
  chk 1 'AWS access key id'                     'AKIAIOSFODNN7EXAMPLE'
  chk 1 'assignment with a long value'          'API_KEY="ab12cd34ef56gh78"'
  chk 1 'YAML-style client_secret'              'client_secret: 9f8e7d6c5b4a3210'
  chk 1 'Authorization Bearer'                  'Authorization: Bearer abcdefghij0123456789xyz'
  chk 1 'PEM private key'                       '-----BEGIN RSA PRIVATE KEY-----'
  OUT="$(printf '%s\n' 'API_KEY="ab12cd34ef56gh78"' | grep -nEi "$PAT" | redact)"
  if [ -n "$OUT" ] && ! printf '%s' "$OUT" | grep -q 'ab12cd34ef56gh78' && printf '%s' "$OUT" | grep -q 'REDACTED'; then
    printf '  ok   %s\n' 'printed hit does not contain the secret value'
  else
    printf '  MISMATCH %s (output: %s)\n' 'printed hit leaks the secret value' "$OUT"; RC=1
  fi
  [ "$RC" = 0 ] && echo "PASS" || echo "FAIL"
  exit "$RC"
fi

# A scan that could not read its input must never report "clean" (failure class GUARD-NEVER-RAN).
if [ "$MODE" != file ]; then
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not inside a git work tree: nothing was scanned (use --file)"; exit 2; }
fi
untracked() { # contents of untracked, non-ignored files, as added lines
  git ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do
    [ -f "$f" ] && sed 's/^/+/' "$f"
  done
}
case "$MODE" in
  staged)  SRC="$(git diff --cached)" || { echo "git diff failed: nothing was scanned"; exit 2; }
           WHAT="the staged area" ;;
  working) if git rev-parse --verify -q HEAD >/dev/null; then
             SRC="$(git diff HEAD)" || { echo "git diff failed: nothing was scanned"; exit 2; }
           else
             SRC="$(git diff --cached; git diff)" || { echo "git diff failed: nothing was scanned"; exit 2; }
           fi
           SRC="$SRC
$(untracked)"
           WHAT="all uncommitted changes, including untracked files" ;;
  file)    [ -f "$TARGET" ] || { echo "no such file: $TARGET"; exit 2; }
           SRC="$(cat "$TARGET")";     WHAT="file $TARGET" ;;
esac

if [ -z "$SRC" ]; then
  echo "nothing to scan ($WHAT is empty)"
  exit 0
fi

# Skip removed lines (-) when scanning a diff: a secret being removed is not a new problem.
HITS="$(printf '%s\n' "$SRC" | grep -vE '^-[^-]' | grep -nEi "$PAT" || true)"

if [ -n "$HITS" ]; then
  echo "⛔ suspected secret in $WHAT (values redacted):"
  printf '%s\n' "$HITS" | head -40 | redact
  N="$(printf '%s\n' "$HITS" | wc -l | tr -d ' ')"
  [ "$N" -gt 40 ] && echo "… $((N-40)) more line(s)"
  echo
  echo "What to do: unstage it (git restore --staged <file>), add it to .gitignore,"
  echo "or confirm it is a false positive and commit manually. Do NOT just ignore it."
  exit 1
fi

echo "✅ clean ($WHAT)"
exit 0
