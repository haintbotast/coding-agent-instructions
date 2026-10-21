#!/usr/bin/env bash
# test-install.sh — behavioural test of install.sh in a throwaway HOME and project. Exit 0 = all pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/cai-test-XXXX")"
FAIL=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; FAIL=1; }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
NSK=$(ls -d "$REPO"/skills/*/ | wc -l | tr -d ' ')
B='<!-- coding-agent-instructions:begin -->'

# ---- user scope ----
H="$T/home"; mkdir -p "$H/.claude/skills/my-own-skill" "$H/.codex"
printf '# My rules\nkeep me\n' > "$H/.claude/CLAUDE.md"; cp "$H/.claude/CLAUDE.md" "$T/claude.orig"
echo "mine" > "$H/.claude/skills/my-own-skill/SKILL.md"
mkdir -p "$H/.agents/skills/test-driven-development"; echo "user's own copy" > "$H/.agents/skills/test-driven-development/SKILL.md"
HOME="$H" bash "$REPO/scripts/install.sh" >/dev/null 2>&1; chk "user install exits 0" '[ $? = 0 ]'
chk "canonical rules written" 'grep -qF "$B" "$H/.agents/AGENTS.md"'
chk "skills path rewritten to ~/.agents/skills" 'grep -qF "$H/.agents/skills/<name>/SKILL.md" "$H/.agents/AGENTS.md"'
chk "CLAUDE.md keeps user content" 'grep -q "keep me" "$H/.claude/CLAUDE.md"'
chk "CLAUDE.md imports canonical file" 'grep -qxF "@$H/.agents/AGENTS.md" "$H/.claude/CLAUDE.md"'
chk "backup of CLAUDE.md made outside rules folders" '[ -n "$(find "$H/.local/state/coding-agent-instructions/backups" -name CLAUDE.md)" ] && [ -z "$(find "$H" -name "*.bak-*")" ]'
chk "windsurf global rules stay within 6000 bytes" '[ $(wc -c < "$H/.codeium/windsurf/memories/global_rules.md") -le 6000 ]'
chk "codex AGENTS.md has full rules" 'grep -q "## Failure classes" "$H/.codex/AGENTS.md"'
for f in .copilot/copilot-instructions.md .gemini/GEMINI.md .codeium/windsurf/memories/global_rules.md \
         .roo/rules/coding-agent-instructions.md .kiro/steering/coding-agent-instructions.md .junie/AGENTS.md \
         .config/amp/AGENTS.md .config/opencode/AGENTS.md; do
  chk "rules block in ~/$f" 'grep -qF "$B" "$H/$f"'
done
chk "kiro steering has inclusion: always first" '[ "$(sed -n 2p "$H/.kiro/steering/coding-agent-instructions.md")" = "inclusion: always" ]'
chk "all skills in ~/.claude/skills" '[ $(ls "$H/.claude/skills" | grep -vc my-own-skill) = $NSK ]'
chk "pre-existing unmarked skill NOT overwritten" 'grep -q "user'"'"'s own copy" "$H/.agents/skills/test-driven-development/SKILL.md"'
chk "user's own skill untouched" '[ "$(cat "$H/.claude/skills/my-own-skill/SKILL.md")" = mine ]'
cp "$H/.claude/CLAUDE.md" "$T/claude.after1"
HOME="$H" bash "$REPO/scripts/install.sh" >/dev/null 2>&1
chk "re-run is idempotent (one block)" '[ $(grep -cF "$B" "$H/.claude/CLAUDE.md") = 1 ] && cmp -s "$T/claude.after1" "$H/.claude/CLAUDE.md"'
HOME="$H" bash "$REPO/scripts/install.sh" --uninstall >/dev/null 2>&1
chk "uninstall restores CLAUDE.md content" 'diff <(grep -v "^$" "$T/claude.orig") <(grep -v "^$" "$H/.claude/CLAUDE.md") >/dev/null'
chk "uninstall removes our-only files" '[ ! -e "$H/.codex/AGENTS.md" ] && [ ! -e "$H/.agents/AGENTS.md" ] && [ ! -e "$H/.kiro/steering/coding-agent-instructions.md" ]'
chk "uninstall leaves no backup copies in rules folders" '[ -z "$(find "$H/.roo" "$H/.kiro" "$H/.codeium" -type f 2>/dev/null)" ]'
chk "uninstall removes marked skills only" '[ ! -e "$H/.claude/skills/systematic-debugging" ] && [ -e "$H/.claude/skills/my-own-skill" ] && [ -e "$H/.agents/skills/test-driven-development" ]'

# ---- user scope, --link ----
H2="$T/home2"; mkdir -p "$H2"
HOME="$H2" bash "$REPO/scripts/install.sh" --link --tools claude,codex >/dev/null 2>&1
chk "--link makes symlinks into the clone" '[ -L "$H2/.agents/skills/ops-safety" ] && [ -f "$H2/.agents/skills/ops-safety/SKILL.md" ]'
chk "--tools limits targets" '[ -e "$H2/.codex/AGENTS.md" ] && [ ! -e "$H2/.gemini/GEMINI.md" ]'
HOME="$H2" bash "$REPO/scripts/install.sh" --uninstall >/dev/null 2>&1
chk "unlink removes links, clone intact" '[ ! -e "$H2/.agents/skills/ops-safety" ] && [ -f "$REPO/skills/ops-safety/SKILL.md" ]'

# ---- project scope ----
P="$T/proj"; mkdir -p "$P"; printf '# Project rules\nuse pnpm\n' > "$P/AGENTS.md"
HOME="$T/home3" bash "$REPO/scripts/install.sh" --project "$P" >/dev/null 2>&1; chk "project install exits 0" '[ $? = 0 ]'
chk "project AGENTS.md keeps own rules + block" 'grep -q "use pnpm" "$P/AGENTS.md" && grep -qF "$B" "$P/AGENTS.md"'
chk "project skills path is .agents/skills" 'grep -qF "\`.agents/skills/<name>/SKILL.md\`" "$P/AGENTS.md"'
chk "project CLAUDE.md imports AGENTS.md" 'grep -qxF "@AGENTS.md" "$P/CLAUDE.md"'
chk "project GEMINI.md imports AGENTS.md" 'grep -qxF "@AGENTS.md" "$P/GEMINI.md"'
chk "project .agents/.claude/.kiro skills" '[ $(ls "$P/.agents/skills" | wc -l) = $NSK ] && [ -d "$P/.claude/skills/ops-safety" ] && [ -d "$P/.kiro/skills/ops-safety" ]'
chk "project mode writes to HOME only backups" '[ -z "$(find "$T/home3" -type f ! -path "*/coding-agent-instructions/backups/*" 2>/dev/null)" ]'
HOME="$T/home3" bash "$REPO/scripts/install.sh" --project "$P" --uninstall >/dev/null 2>&1
chk "project uninstall leaves only original AGENTS.md" '[ "$(grep -v "^$" "$P/AGENTS.md")" = "$(printf "# Project rules\nuse pnpm")" ] && [ ! -e "$P/CLAUDE.md" ] && [ ! -e "$P/.agents/skills/ops-safety" ]'

# ---- dry-run and bad input ----
H4="$T/home4"; mkdir -p "$H4"
HOME="$H4" bash "$REPO/scripts/install.sh" --dry-run >/dev/null 2>&1
chk "dry-run writes nothing" '[ -z "$(find "$H4" -mindepth 1 -print -quit)" ]'
HOME="$H4" bash "$REPO/scripts/install.sh" --tools claude,nosuchtool >/dev/null 2>&1; rc=$?
chk "unknown tool fails closed (exit 2, nothing written)" '[ $rc = 2 ] && [ -z "$(find "$H4" -mindepth 1 -print -quit)" ]'

rm -rf "$T"
[ "$FAIL" = 0 ] && echo "test-install: PASS" || echo "test-install: FAIL"
exit "$FAIL"
