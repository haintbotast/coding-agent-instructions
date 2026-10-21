#!/usr/bin/env python3
"""Scan local MCP configuration: packages pulled at runtime without a pinned version, secrets written literally into the file.

Executable guardrail for the failure class ONBOARDING-OVER-REVERSIBILITY (see the failure-classes skill).
Usage: python3 check_mcp_config.py             # scan the usual config files (Claude Code/Desktop, Codex, OpenCode)
       python3 check_mcp_config.py FILE [FILE…]  # scan exactly these files
Exit 0 when clean, 1 on ERROR findings, 2 when there is no file to scan. Never prints a secret value, only the variable name and the first 3 characters.
Standard library only.
"""
import json
import os
import re
import sys
from pathlib import Path

RUNNERS = {"npx", "uvx", "bunx", "pnpm", "pipx"}
SKIP_ARGS = {"-y", "--yes", "-q", "--quiet", "dlx", "run", "exec"}
SECRET_KEY = re.compile(r"(KEY|TOKEN|SECRET|PASSWORD|PASSWD|PWD)$", re.I)
DEFAULT_FILES = [
    "~/.claude.json",
    "~/.claude/settings.json",
    "~/.claude/settings.local.json",
    "./.mcp.json",
    "~/.codex/config.toml",
    "~/.config/opencode/opencode.json",
    "./opencode.json",
    "~/Library/Application Support/Claude/claude_desktop_config.json",
]


def package_spec(args):
    for a in args:
        if not isinstance(a, str) or a.startswith("-") or a in SKIP_ARGS:
            continue
        return a
    return None


def is_pinned(spec):
    """'@scope/pkg@1.2.3' or 'pkg@1.2.3' is pinned; 'pkg', '@scope/pkg', 'pkg@latest' are not."""
    body = spec[1:] if spec.startswith("@") else spec
    if "@" not in body:
        return False
    version = body.rsplit("@", 1)[1]
    return bool(version) and version not in {"latest", "next"}


def literal_secret(value):
    if not isinstance(value, str):
        return False
    v = value.strip()
    if not v or v.startswith("$") or v.startswith("${") or v.startswith("op://") or v.startswith("keychain:"):
        return False
    return len(v) >= 8


def mask(value):
    return value[:3] + "…" if isinstance(value, str) else "…"


def walk_json(node, path, findings, fname):
    if isinstance(node, dict):
        cmd = node.get("command")
        args = node.get("args")
        if isinstance(cmd, str) and os.path.basename(cmd) in RUNNERS and isinstance(args, list):
            spec = package_spec(args)
            if spec and not is_pinned(spec):
                findings.append(f"{fname}: {path or 'root'}: {os.path.basename(cmd)} pulls package `{spec}` without a pinned version")
        env = node.get("env") or node.get("environment")
        if isinstance(env, dict):
            for k, v in env.items():
                if SECRET_KEY.search(k) and literal_secret(v):
                    findings.append(f"{fname}: {path or 'root'}: env `{k}` holds a literal value ({mask(v)}) instead of an environment-variable reference")
        for k, v in node.items():
            walk_json(v, f"{path}.{k}" if path else k, findings, fname)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk_json(v, f"{path}[{i}]", findings, fname)


def scan_toml(text, findings, fname):
    """Enough for ~/.codex/config.toml: [mcp_servers.<name>] tables with command/args, and .env sub-tables with KEY = "…"."""
    table = None
    args_buf = None
    for line in text.splitlines():
        s = line.strip()
        m = re.match(r"^\[([^\]]+)\]$", s)
        if m:
            table = m.group(1)
            args_buf = None
            continue
        if not table or not table.startswith("mcp_servers."):
            continue
        m = re.match(r'^command\s*=\s*"([^"]+)"', s)
        if m:
            cur_cmd = os.path.basename(m.group(1))
            if cur_cmd in RUNNERS:
                args_buf = (table, cur_cmd)
            continue
        m = re.match(r"^args\s*=\s*\[(.*)\]", s)
        if m and args_buf:
            args = re.findall(r'"([^"]*)"', m.group(1))
            spec = package_spec(args)
            if spec and not is_pinned(spec):
                findings.append(f"{fname}: [{args_buf[0]}]: {args_buf[1]} pulls package `{spec}` without a pinned version")
            continue
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"', s)
        if m and table.endswith(".env") and SECRET_KEY.search(m.group(1)) and literal_secret(m.group(2)):
            findings.append(f"{fname}: [{table}]: `{m.group(1)}` holds a literal value ({mask(m.group(2))}) instead of an environment-variable reference")


def main(argv):
    files = [Path(os.path.expanduser(a)) for a in (argv or DEFAULT_FILES)]
    scanned, findings = 0, []
    for f in files:
        if not f.is_file():
            continue
        scanned += 1
        text = f.read_text(encoding="utf-8", errors="replace")
        name = str(f).replace(os.path.expanduser("~"), "~")
        if f.suffix == ".toml":
            scan_toml(text, findings, name)
        else:
            try:
                walk_json(json.loads(text), "", findings, name)
            except json.JSONDecodeError as e:
                findings.append(f"{name}: invalid JSON ({e.msg} at line {e.lineno}), cannot scan")
    if scanned == 0:
        print("  no MCP config file to scan")
        return 2
    for x in findings:
        print("  ERROR  " + x)
    print(f"  {'ok   ' if not findings else ''}{scanned} file(s) scanned, {len(findings)} error(s)")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
