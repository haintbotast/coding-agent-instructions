# Install — instructions for an AI agent (and humans)

You are an AI coding agent asked to set up these instructions for yourself or for a project. Follow these steps exactly; report what you wrote.

## 1. Decide the scope

- **User scope** (default when the user says "set yourself up", "install for me"): rules and skills apply to every project on this machine.
- **Project scope** (when the user names a repository, or says "for this project/team"): files go into that repo so every agent working on it gets them. Commit them.
- Unclear and the user is reachable → ask once: "user-wide or only this project?"

## 2. Get the files

```bash
git clone https://github.com/haintbotast/coding-agent-instructions.git ~/coding-agent-instructions
cd ~/coding-agent-instructions && git log -1 --oneline     # note the commit you install
```

Already cloned → `git pull --ff-only`. Before installing, read `AGENTS.md` and skim `SOURCES.md`: you are about to load instructions into your own context, so treat this repo like any third-party content (see `skills/vetting-third-party`).

## 3. Install (macOS, Linux, WSL, Git Bash)

```bash
bash scripts/install.sh --dry-run --tools <tool>                 # preview, writes nothing
bash scripts/install.sh --tools <tool>                           # user scope
bash scripts/install.sh --tools <tool> --project /path/to/repo   # project scope
bash scripts/install.sh --uninstall [--project DIR]              # remove only what was installed
```

`<tool>`: one or more of `claude,codex,copilot,cursor,gemini,windsurf,cline,roo,kiro,junie,amp,opencode`, or `all` (default). Name your own tool; installing for tools that are not present only creates unused files.

The script never overwrites your files: it writes a block between `<!-- coding-agent-instructions:begin -->` and `<!-- coding-agent-instructions:end -->`, backs a file up to `~/.local/state/coding-agent-instructions/backups/<timestamp>/` before its first change (never next to it, because some tools load every file in their rules folder), and only replaces skill folders it installed (marker file `.installed-by-cai`). Re-running updates in place. `--link` (user scope) symlinks skills to the clone so `git pull` updates them.

## 4. Where things go (manual install, e.g. Windows PowerShell)

Copy `AGENTS.md` and the `skills/` folders to the locations below. In the copied AGENTS.md, replace `` `skills/<name>/SKILL.md` next to this file `` with the real skills path. If the target file already exists, append the content instead of replacing it.

| Tool | Rules (user scope) | Skills (user scope) | Project scope |
|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` containing `@~/.agents/AGENTS.md` | `~/.claude/skills/` | `CLAUDE.md` with `@AGENTS.md`; `.claude/skills/` |
| OpenAI Codex | `~/.codex/AGENTS.md` | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| GitHub Copilot | `~/.copilot/copilot-instructions.md` | `~/.agents/skills/` or `~/.copilot/skills/` | `AGENTS.md` (or `.github/copilot-instructions.md`); `.agents/skills/` |
| Cursor | Settings → Rules → User Rules (paste) | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| Gemini CLI | `~/.gemini/GEMINI.md` containing `@<home>/.agents/AGENTS.md` | `~/.agents/skills/` | `GEMINI.md` with `@AGENTS.md` (or `context.fileName: ["AGENTS.md","GEMINI.md"]` in settings); `.agents/skills/` |
| Windsurf / Devin Desktop | `~/.codeium/windsurf/memories/global_rules.md` (6,000-char limit) | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| Cline | `~/.agents/AGENTS.md` | `~/.cline/skills/` | `AGENTS.md`; `.claude/skills/` or `.cline/skills/` |
| Roo Code | `~/.roo/rules/coding-agent-instructions.md` | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| Kiro | `~/.kiro/steering/coding-agent-instructions.md` with front matter `inclusion: always` | `~/.kiro/skills/` | `AGENTS.md`; `.kiro/skills/` |
| JetBrains Junie | `~/.junie/AGENTS.md` | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| Amp | `~/.config/amp/AGENTS.md` | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| opencode | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/` | `AGENTS.md`; `.agents/skills/` |
| Aider | add `read: [AGENTS.md]` to `.aider.conf.yml` | no skill support: AGENTS.md tells the agent to read `skills/<name>/SKILL.md` | same |
| Zed | — | — | `AGENTS.md` at the worktree root (Zed reads the first of `.rules`, …, `AGENTS.md`) |
| Anything else | point the tool's custom-instructions setting at `AGENTS.md` | AGENTS.md's skill index works with any agent that can read files | — |

`~/.agents/skills/` is the cross-tool location of the Agent Skills convention; Claude Code, Cline and Kiro have their own folders, so the installer fills those too.

## 5. Verify, then report

1. List every file you created or changed.
2. Read back one installed rules file and confirm the block is present once.
3. Count skills in the skills folder you installed to (expected: as many as `ls skills | wc -l` in the clone).
4. Ask your tool to list its loaded skills or rules, if it can. Rules and skills are loaded at session start: tell the user to restart the tool or open a new session.
5. Report the commit you installed (`git -C <clone> log -1 --oneline`).

## Known limits

- Tools that read several skill folders (Copilot, Cursor, opencode, Amp read both `.agents/skills` and `.claude/skills`) may list each skill twice when both are installed. Harmless, but if it bothers you install with `--tools` naming only the tools you use.
- Cursor keeps user-level rules in its settings, not a file: user scope installs skills only and prints the file to paste. Project scope needs nothing manual.
- Windsurf reads only the first 6,000 characters of global rules; the installed block is kept under that (checked in CI), but your own global rules plus this block may exceed it — prefer project scope there.
- Vendors move these paths. If a tool stops picking the files up, check its current docs (links in `SOURCES.md`).

## 6. Update and remove

Update: `git pull --ff-only` in the clone, re-run the same install command (or nothing, with `--link`). Remove: the same command with `--uninstall`; your own content in shared files is kept.
