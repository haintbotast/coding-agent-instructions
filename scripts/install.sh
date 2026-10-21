#!/usr/bin/env bash
# install.sh — install AGENTS.md rules + skills into one or more AI coding tools.
#
#   bash scripts/install.sh [--tools LIST] [--project DIR] [--link] [--dry-run] [--uninstall]
#
#   --tools LIST   comma-separated, default "all":
#                  claude,codex,copilot,cursor,gemini,windsurf,cline,roo,kiro,junie,amp,opencode
#   --project DIR  install into a project repository instead of your user profile
#   --link         user scope only: symlink skills to this clone (update = git pull) instead of copying
#   --dry-run      print every action, change nothing
#   --uninstall    remove only what this script installed (marked blocks and marked skill folders)
#
# Safety: existing files are never overwritten — the rules go into a block between
#   <!-- coding-agent-instructions:begin --> and <!-- coding-agent-instructions:end -->
# which is replaced on re-run. Before its first change in a run, a file is copied to
#   ${XDG_STATE_HOME:-~/.local/state}/coding-agent-instructions/backups/<timestamp>/ (never next to it:
#   some tools load every file in their rules folder).
# Skill folders are only replaced or removed if they carry the marker file .installed-by-cai.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_RULES="$REPO/AGENTS.md"
SRC_SKILLS="$REPO/skills"
ALL="claude,codex,copilot,cursor,gemini,windsurf,cline,roo,kiro,junie,amp,opencode"
TOOLS="$ALL"; PROJECT=""; LINK=0; DRY=0; UNINSTALL=0
B='<!-- coding-agent-instructions:begin -->'
E='<!-- coding-agent-instructions:end -->'
MARK=".installed-by-cai"
TS="$(date +%Y%m%d-%H%M%S)"

while [ $# -gt 0 ]; do
  case "$1" in
    --tools) TOOLS="${2:?--tools needs a value}"; shift 2 ;;
    --project) PROJECT="${2:?--project needs a directory}"; shift 2 ;;
    --link) LINK=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1 (see --help)" >&2; exit 2 ;;
  esac
done
[ "$TOOLS" = all ] && TOOLS="$ALL"
IFS=',' read -r -a SEL <<< "$TOOLS"
for t in "${SEL[@]}"; do   # fail closed on unknown tool names
  case ",$ALL," in *",$t,"*) ;; *) echo "unknown tool: $t (known: $ALL)" >&2; exit 2 ;; esac
done
has() { case ",$TOOLS," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }
if [ -n "$PROJECT" ]; then
  [ -d "$PROJECT" ] || { echo "not a directory: $PROJECT" >&2; exit 2; }
  PROJECT="$(cd "$PROJECT" && pwd)"
  [ "$LINK" = 1 ] && { echo "--link is for user scope only (a project must not point into your clone)" >&2; exit 2; }
fi

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }
BACKUPS="${XDG_STATE_HOME:-$HOME/.local/state}/coding-agent-instructions/backups/$TS"
backup_once() { # backup_once FILE — one backup per file per run, kept OUTSIDE rules folders
  local f="$1" dest; [ -f "$f" ] || return 0
  dest="$BACKUPS/$(printf '%s' "$f" | sed 's#^/##')"
  [ -e "$dest" ] && return 0
  run mkdir -p "$(dirname "$dest")"
  run cp -p "$f" "$dest"
}

# Rules text with the skills path rewritten for where the skills were installed.
rules_text() { # rules_text SKILLS_PATH
  sed "s#\`skills/<name>/SKILL.md\` next to this file#\`$1/<name>/SKILL.md\`#" "$SRC_RULES"
}

# Write CONTENT between the markers in FILE (create, replace block, or append block).
put_block() { # put_block FILE CONTENT [FRONTMATTER]
  local f="$1" content="$2" front="${3:-}" tmp
  run mkdir -p "$(dirname "$f")"
  tmp="$(mktemp)"
  if [ -f "$f" ] && grep -qF "$B" "$f"; then
    CAI_CONTENT="$content" awk -v b="$B" -v e="$E" '
      $0==b {print b; print ENVIRON["CAI_CONTENT"]; skip=1; next}
      $0==e {skip=0; print e; next}
      !skip {print}' "$f" > "$tmp"
  elif [ -f "$f" ]; then
    { cat "$f"; printf '\n%s\n%s\n%s\n' "$B" "$content" "$E"; } > "$tmp"
  else
    { [ -n "$front" ] && printf '%s\n' "$front"; printf '%s\n%s\n%s\n' "$B" "$content" "$E"; } > "$tmp"
  fi
  if [ -f "$f" ] && cmp -s "$tmp" "$f"; then rm -f "$tmp"; say "  = $f (unchanged)"; return 0; fi
  backup_once "$f"
  if [ "$DRY" = 1 ]; then say "  [dry-run] write block -> $f"; rm -f "$tmp"; else mv "$tmp" "$f"; say "  + $f"; fi
}

drop_block() { # drop_block FILE — remove our block; delete the file only if nothing else is left
  local f="$1" tmp
  [ -f "$f" ] && grep -qF "$B" "$f" || return 0
  backup_once "$f"
  tmp="$(mktemp)"
  awk -v b="$B" -v e="$E" '$0==b{skip=1;next} $0==e{skip=0;next} !skip{print}' "$f" > "$tmp"
  # nothing but blank lines (or our own Kiro frontmatter) left -> the file was ours alone
  if [ "$(grep -v -e '^---$' -e '^inclusion: always$' "$tmp" | grep -c '[^[:space:]]' || true)" = 0 ]; then
    rm -f "$tmp"; run rm -f "$f"; say "  - $f"
  else
    if [ "$DRY" = 1 ]; then rm -f "$tmp"; say "  [dry-run] remove block from $f"; else mv "$tmp" "$f"; say "  - block from $f"; fi
  fi
}

# Install every skill folder into DEST (copy, or symlink with --link).
put_skills() { # put_skills DEST
  local dest="$1" s name target
  run mkdir -p "$dest"
  for s in "$SRC_SKILLS"/*/; do
    name="$(basename "$s")"; target="$dest/$name"
    if [ -L "$target" ]; then run rm "$target"            # a link: remove the link only, never recurse through it
    elif [ -d "$target" ]; then
      if [ -f "$target/$MARK" ]; then run rm -rf "$target"
      else say "  ! skip $target: exists and was not installed by this script"; continue; fi
    fi
    if [ "$LINK" = 1 ]; then run ln -s "${s%/}" "$target"
    else run cp -R "${s%/}" "$target"; run touch "$target/$MARK"; fi
  done
  say "  + skills -> $dest"
}

drop_skills() { # drop_skills DEST
  local dest="$1" s name target
  for s in "$SRC_SKILLS"/*/; do
    name="$(basename "$s")"; target="$dest/$name"
    if [ -L "$target" ]; then
      case "$(readlink "$target")" in "$SRC_SKILLS"/*) run rm "$target" ;; esac
    elif [ -f "$target/$MARK" ]; then run rm -rf "$target"
    fi
  done
  say "  - skills from $dest"
}

if [ -n "$PROJECT" ]; then BASE="$PROJECT"; else BASE="$HOME"; fi

# ---------- project scope ----------
if [ -n "$PROJECT" ]; then
  say "Project: $PROJECT  tools: $TOOLS"
  SK=".agents/skills"
  if [ "$UNINSTALL" = 1 ]; then
    drop_block "$BASE/AGENTS.md"; drop_block "$BASE/CLAUDE.md"; drop_block "$BASE/GEMINI.md"
    drop_block "$BASE/.kiro/steering/coding-agent-instructions.md"
    drop_skills "$BASE/.agents/skills"; drop_skills "$BASE/.claude/skills"; drop_skills "$BASE/.kiro/skills"
    exit 0
  fi
  # AGENTS.md at the root is read natively by Codex, Copilot, Cursor, Windsurf, Cline, Roo, Kiro, Junie, Amp, opencode, Zed.
  put_block "$BASE/AGENTS.md" "$(rules_text "$SK")"
  put_skills "$BASE/.agents/skills"
  # Claude Code reads CLAUDE.md (not AGENTS.md when a CLAUDE.md exists) and .claude/skills.
  # Claude Code and Cline do not document .agents/skills at project level; they read .claude/skills.
  if has claude || has cline; then put_skills "$BASE/.claude/skills"; fi
  has claude && put_block "$BASE/CLAUDE.md" "@AGENTS.md"
  has gemini && put_block "$BASE/GEMINI.md" "@AGENTS.md"
  has kiro && put_skills "$BASE/.kiro/skills"
  say "Done. Commit the new files so every agent working on this repo gets them."
  exit 0
fi

# ---------- user scope ----------
say "User profile: $HOME  tools: $TOOLS"
CANON="$HOME/.agents/AGENTS.md"          # also Cline's global AGENTS.md
SK="$HOME/.agents/skills"                # cross-tool skills dir (Codex, Copilot, Cursor, Gemini, Windsurf, Roo, Junie, Amp, opencode)

if [ "$UNINSTALL" = 1 ]; then
  for f in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/.copilot/copilot-instructions.md" \
           "$HOME/.gemini/GEMINI.md" "$HOME/.codeium/windsurf/memories/global_rules.md" \
           "$HOME/.roo/rules/coding-agent-instructions.md" "$HOME/.kiro/steering/coding-agent-instructions.md" \
           "$HOME/.junie/AGENTS.md" "$HOME/.config/amp/AGENTS.md" "$HOME/.config/opencode/AGENTS.md" "$CANON"; do
    drop_block "$f"
  done
  for d in "$SK" "$HOME/.claude/skills" "$HOME/.cline/skills" "$HOME/.kiro/skills"; do drop_skills "$d"; done
  exit 0
fi

RULES="$(rules_text "$SK")"
put_block "$CANON" "$RULES"
put_skills "$SK"

if has claude; then   # Claude Code: import the canonical file; skills in ~/.claude/skills
  put_block "$HOME/.claude/CLAUDE.md" "@$CANON"
  put_skills "$HOME/.claude/skills"
fi
has codex    && put_block "$HOME/.codex/AGENTS.md" "$RULES"
has copilot  && put_block "$HOME/.copilot/copilot-instructions.md" "$RULES"
has gemini   && put_block "$HOME/.gemini/GEMINI.md" "@$CANON"
if has windsurf; then
  WS="$HOME/.codeium/windsurf/memories/global_rules.md"
  put_block "$WS" "$RULES"
  if [ "$DRY" = 0 ]; then  # bytes >= characters, so this errs on the safe side
    n=$(wc -c < "$WS" | tr -d ' ')
    if [ "$n" -gt 6000 ]; then say "  ! $WS is $n bytes; Windsurf reads only the first 6000 characters of global rules (prefer --project)"; fi
  fi
fi
has cline    && put_skills "$HOME/.cline/skills"            # Cline reads ~/.agents/AGENTS.md already
has roo      && put_block "$HOME/.roo/rules/coding-agent-instructions.md" "$RULES"
if has kiro; then
  put_block "$HOME/.kiro/steering/coding-agent-instructions.md" "$RULES" $'---\ninclusion: always\n---'
  put_skills "$HOME/.kiro/skills"
fi
has junie    && put_block "$HOME/.junie/AGENTS.md" "$RULES"
has amp      && put_block "$HOME/.config/amp/AGENTS.md" "$RULES"
has opencode && put_block "$HOME/.config/opencode/AGENTS.md" "$RULES"
has cursor   && say "  i cursor: skills load from ~/.agents/skills; user rules live in Cursor's settings, not a file: paste $CANON into Settings → Rules → User Rules, or use --project (AGENTS.md is read natively)."
say "Done. Restart your tools so they reload rules and skills."
