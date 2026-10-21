#!/usr/bin/env python3
"""pin_mcp_config.py — pin the version of npx/uvx packages in an MCP config file (JSON).

Usage: pin_mcp_config.py <config.json> pkg@ver [pkg@ver ...] [--apply] [--force]
  Without --apply: only prints the diff. With --apply: backs up to <file>.bak-<date>, then writes.
GUARDRAIL (from a real incident, failure class EDIT-UNDER-RUNNING-OWNER): Claude Desktop keeps its config
in memory and rewrites the whole file whenever its state changes, so editing the file while the app is running
is silently reverted to the old version. The script refuses to write while the app that owns the file is running, unless --force.
"""
import json, os, subprocess, sys, datetime, shutil

RUNNERS = {"npx", "uvx", "bunx", "pnpm", "pipx"}

def owner_running(path):
    if "Application Support/Claude/" in path:
        # pgrep -x does not match the Electron process; compare the full path (the first guard version missed it)
        r = subprocess.run(["ps", "-axo", "comm="], capture_output=True, text=True)
        return any(l.strip().endswith("/Claude.app/Contents/MacOS/Claude") for l in r.stdout.splitlines())
    return False

def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    apply, force = "--apply" in argv, "--force" in argv
    if len(args) < 2:
        print(__doc__); return 2
    path, pins = os.path.expanduser(args[0]), {}
    for p in args[1:]:
        name, _, ver = p.rpartition("@")
        if not name or not ver: print(f"  ERROR  '{p}' must be of the form pkg@ver"); return 2
        pins[name] = ver
    raw = open(path, encoding="utf-8").read()
    data = json.loads(raw)
    changes = []
    for sname, s in (data.get("mcpServers") or {}).items():
        if not isinstance(s, dict) or os.path.basename(str(s.get("command", ""))) not in RUNNERS: continue
        a = s.get("args") or []
        for i, tok in enumerate(a):
            base = tok.rsplit("@", 1)[0] if tok.count("@") > (1 if tok.startswith("@") else 0) else tok
            if base in pins and tok != f"{base}@{pins[base]}":
                changes.append((sname, tok, f"{base}@{pins[base]}")); a[i] = f"{base}@{pins[base]}"
    if not changes:
        print(f"  ok    {path}: all packages already pinned correctly"); return 0
    for sname, old, new in changes: print(f"  {sname}: {old} → {new}")
    if not apply:
        print("  (nothing written; add --apply to write)"); return 1
    if owner_running(path) and not force:
        print("  REFUSED  Claude Desktop is running: the app will overwrite this file from memory."
              " Quit the app (Cmd+Q) and run again, or use --force if you accept losing the edit."); return 3
    bak = f"{path}.bak-{datetime.date.today():%Y%m%d}"
    if not os.path.exists(bak): shutil.copy2(path, bak)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False); f.write("\n")
    back = json.load(open(path, encoding="utf-8"))
    for sname, _, new in changes:
        assert new in (back["mcpServers"][sname].get("args") or []), f"after writing, {new} was not found on re-read"
    print(f"  WROTE  {len(changes)} change(s), backup {bak}"); return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
