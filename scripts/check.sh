#!/usr/bin/env bash
# check.sh — validate this repository. Exit 0 = PASS. Run before every commit (CI runs it too).
#   bash scripts/check.sh            # everything
#   bash scripts/check.sh --quick    # skip script self-tests and the install test
# Optional private deny-list (never committed): one regex per line in
#   $CAI_DENYLIST or ~/.config/coding-agent-instructions/denylist.txt
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$REPO"
QUICK=0; [ "${1:-}" = "--quick" ] && QUICK=1
FAIL=0
step() { printf '\n== %s\n' "$1"; }
res()  { if [ "$1" = 0 ]; then echo "  ok"; else echo "  FAIL"; FAIL=1; fi; }

step "skills: frontmatter, names, descriptions, routing, sizes, cross-references"
python3 -I - "$REPO" <<'PY'; res $?
import pathlib, re, sys
root = pathlib.Path(sys.argv[1]); err = []
ALLOWED = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
RETIRED = ["lop-loi", "an-toan-thao-tac", "mcp-vetting", "github-repo-ops", "skills-first-workflow",
           "epic-context", "daily-research-brief", "tai-lieu-vn", "do-web-mac", "harness-maintainer",
           "bao-cao-va-duc-ket", "annotate-artifact", "diagram-design", "dataviz"]
skills = sorted(p.parent.name for p in root.glob("skills/*/SKILL.md"))
dirs = sorted(p.name for p in (root / "skills").iterdir() if p.is_dir())
if skills != dirs: err.append(f"skill folders without SKILL.md: {set(dirs) - set(skills)}")
for name in skills:
    t = (root / "skills" / name / "SKILL.md").read_text(encoding="utf-8")
    m = re.match(r"---\n(.*?)\n---\n", t, re.S)
    if not m: err.append(f"{name}: no frontmatter"); continue
    fm = dict(re.findall(r"^([A-Za-z-]+):\s*(.*)$", m.group(1), re.M))
    extra = set(fm) - ALLOWED
    if extra: err.append(f"{name}: non-standard frontmatter keys {extra}")
    if fm.get("name") != name: err.append(f"{name}: name '{fm.get('name')}' != folder")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) or len(name) > 64: err.append(f"{name}: bad name")
    d = fm.get("description", "").strip().strip('"')
    if not 1 <= len(d) <= 1024: err.append(f"{name}: description length {len(d)}")
    if not re.search(r"\bUse (when|before|at)\b", d, re.I): err.append(f"{name}: description lacks a 'Use when/before/at' trigger")
    sibling = any(re.search(rf"\b{re.escape(s)}\b", d) for s in skills if s != name)
    if not (re.search(r"\bNot (for|when)\b", d, re.I) or sibling):
        err.append(f"{name}: description lacks a negative clause ('Not for …' or a pointer to the sibling skill)")
    body = t[m.end():]
    if body.count("\n") > 500: err.append(f"{name}: body over 500 lines")
    for r in RETIRED:
        if re.search(rf"`{re.escape(r)}`", body) or re.search(rf"\b{re.escape(r)}\b", d):
            err.append(f"{name}: refers to retired/private skill '{r}'")
    for ref in set(re.findall(r"`([a-z]+(?:-[a-z]+)+)`", body + d)):
        looks_like_skill = ref.count("-") >= 1 and ref in {s for s in skills} | set(RETIRED)
        if looks_like_skill and ref not in skills: err.append(f"{name}: unknown skill `{ref}`")
    for rel in set(re.findall(r"`(?:python3 |bash )?((?:scripts|references)/[A-Za-z0-9_.-]+)", body)):
        if (root / "skills" / name / rel.split("/")[0]).is_dir() and not (root / "skills" / name / rel).exists(): err.append(f"{name}: missing file {rel}")
agents = (root / "AGENTS.md").read_text(encoding="utf-8")
listed = set(re.findall(r"`([a-z0-9]+(?:-[a-z0-9]+)*)`", agents.split("## Skills", 1)[1]))
listed = {x for x in listed if not x.startswith("skills")}
if listed != set(skills): err.append(f"AGENTS.md skill index mismatch: missing {set(skills)-listed}, unknown {listed-set(skills)}")
# Installed size: the block written to a global rules file, with markers and a long home path.
home = "/Users/a-rather-long-user-name"  # privacy-ok (test value)
block = ("<!-- coding-agent-instructions:begin -->\n" + agents.replace("`skills/<name>/SKILL.md` next to this file", f"`{home}/.agents/skills/<name>/SKILL.md`")
         + "\n<!-- coding-agent-instructions:end -->\n")
if len(block.encode()) > 6000: err.append(f"installed rules block is {len(block.encode())} bytes (> 6000: Windsurf global limit)")
# Routing collisions: two descriptions sharing too many keywords will compete for the same trigger.
STOP = set("use when with that this before after from your into only every them they then what which while there their about other skill skills does done work code".split())
def kw(s): return {w for w in re.findall(r"[a-z]{4,}", s.lower()) if w not in STOP}
descs = {n: kw(re.search(r"^description:(.*)$", (root/"skills"/n/"SKILL.md").read_text(encoding="utf-8"), re.M).group(1)) for n in skills}
for i, a in enumerate(skills):
    for b in skills[i+1:]:
        j = len(descs[a] & descs[b]) / max(1, len(descs[a] | descs[b]))
        if j >= 0.5: err.append(f"descriptions of {a} and {b} overlap (Jaccard {j:.2f} >= 0.50)")
classes_a = re.findall(r"`([A-Z]+(?:-[A-Z]+)+)`", agents.split("## Failure classes", 1)[1].split("## Skills", 1)[0])
fc = (root / "skills/failure-classes/SKILL.md").read_text(encoding="utf-8")
classes_f = re.findall(r"^- `([A-Z]+(?:-[A-Z]+)+)`", fc, re.M)
if sorted(classes_a) != sorted(classes_f) or len(set(classes_f)) != len(classes_f):
    err.append(f"failure classes differ: AGENTS-only {set(classes_a)-set(classes_f)}, skill-only {set(classes_f)-set(classes_a)}")
m = re.search(r"(\d+) named classes", fc)
if not m or int(m.group(1)) != len(classes_f): err.append(f"failure-classes description count != {len(classes_f)}")
for p in [root / "AGENTS.md", *root.glob("skills/**/*.md")]:
    for c in set(re.findall(r"`([A-Z]{3,}(?:-[A-Z]+)+)`", p.read_text(encoding="utf-8"))):
        if c not in classes_f and c not in {"WCAG-AA"}: err.append(f"{p.relative_to(root)}: unknown failure class {c}")
print("\n".join("  - " + e for e in err) or f"  {len(skills)} skills, {len(classes_f)} failure classes, AGENTS.md {len(agents)} chars")
sys.exit(1 if err else 0)
PY

step "privacy: no personal paths, private IPs, e-mails, or deny-listed terms in tracked text"
python3 -I - "$REPO" "${CAI_DENYLIST:-$HOME/.config/coding-agent-instructions/denylist.txt}" <<'PY'; res $?
import pathlib, re, sys
root = pathlib.Path(sys.argv[1]); deny = pathlib.Path(sys.argv[2])
pats = [r"/Users/[A-Za-z0-9._-]+", r"/home/(?!<|user\b)[a-z][a-z0-9_-]+/", r"Obsidian|iCloud|Mobile Documents|OneDrive -",  # privacy-ok (the patterns themselves)
        r"\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}\b", r"\b192\.168\.\d{1,3}\.\d{1,3}\b",
        r"\b172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}\b",
        r"[A-Za-z0-9._%+-]+@(?!example\.|anthropic\.com|users\.noreply)[A-Za-z0-9-]+\.[A-Za-z.]{2,}"]
if deny.is_file():
    pats += [l.strip() for l in deny.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")]
rx = re.compile("|".join(f"(?:{p})" for p in pats), re.I)
hits = []
for p in root.rglob("*"):
    if not p.is_file() or ".git" in p.parts or p.suffix in {".png", ".jpg", ".pyc"} or p.name.startswith("LICENSE") or p.parent.name == "licenses":
        continue
    for i, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if rx.search(line) and "privacy-ok" not in line:
            hits.append(f"  - {p.relative_to(root)}:{i}: {line.strip()[:100]}")
print("\n".join(hits) or f"  clean ({'with' if deny.is_file() else 'without'} private deny-list)")
sys.exit(1 if hits else 0)
PY

step "shell and python syntax"
rc=0
for f in scripts/*.sh skills/*/scripts/*.sh; do bash -n "$f" || rc=1; done
for f in skills/*/scripts/*.py; do python3 -I -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$f" || rc=1; done
res $rc

if [ "$QUICK" = 0 ]; then
  step "script self-tests (each must also go red on a seeded bad case)"
  rc=0
  bash skills/git-safety/scripts/secret-scan.sh --test >/dev/null || { echo "  secret-scan --test failed"; rc=1; }
  N="$(mktemp -d)"; (cd "$N" && bash "$REPO/skills/git-safety/scripts/secret-scan.sh" >/dev/null 2>&1); c=$?
  [ $c = 2 ] || { echo "  secret-scan outside a git repo must exit 2, got $c"; rc=1; }
  (cd "$N" && git init -q && printf 'TOKEN="Zq8xLw3vNp2rTy7u"\n' > new.env && bash "$REPO/skills/git-safety/scripts/secret-scan.sh" --working >/dev/null 2>&1); c=$?
  [ $c = 1 ] || { echo "  secret-scan --working missed a secret in an untracked file (exit $c)"; rc=1; }
  rm -rf "$N"
  python3 -I skills/ui-design/scripts/check_ui.py --self-test >/dev/null || { echo "  check_ui --self-test failed"; rc=1; }
  out=$(python3 -I skills/ui-design/scripts/contrast_check.py "#777777:#ffffff" "#1E40AF:#FFFFFF"); c=$?
  { [ $c = 1 ] && grep -q "4.48:1" <<<"$out" && grep -q "8.72:1" <<<"$out"; } || { echo "  contrast_check wrong"; rc=1; }
  W="$(mktemp -d)"
  ( cd "$W" && git init -q && git config user.email t@example.com && git config user.name t \
    && printf 'x = 1\n' > a.py && git add a.py && git commit -qm base && git branch -q base \
    && printf 'x = 1\ny = 2\n' > a.py && git commit -qam clean ) >/dev/null
  (cd "$W" && python3 -I "$REPO/skills/quality-floor/scripts/floor_check.py" --base base >/dev/null) || { echo "  floor_check red on a clean diff"; rc=1; }
  ( cd "$W" && printf 'z = 3  # noqa\n' >> a.py && git commit -qam seeded ) >/dev/null
  (cd "$W" && python3 -I "$REPO/skills/quality-floor/scripts/floor_check.py" --base base >/dev/null) && { echo "  floor_check missed a seeded # noqa"; rc=1; }
  printf '{"mcpServers":{"a":{"command":"npx","args":["-y","some-mcp@1.2.3"],"env":{"API_KEY":"${API_KEY}"}}}}' > "$W/ok.json"
  printf '{"mcpServers":{"a":{"command":"npx","args":["-y","some-mcp"],"env":{"API_KEY":"sk-live-abcdef123456"}}}}' > "$W/bad.json"
  python3 -I skills/vetting-third-party/scripts/check_mcp_config.py "$W/ok.json" >/dev/null || { echo "  check_mcp_config red on a pinned config"; rc=1; }
  python3 -I skills/vetting-third-party/scripts/check_mcp_config.py "$W/bad.json" >/dev/null && { echo "  check_mcp_config missed an unpinned package + literal key"; rc=1; }
  rm -rf "$W"
  res $rc

  step "installer behaviour (throwaway HOME and project)"
  bash scripts/test-install.sh >/dev/null; res $?
fi

echo; [ "$FAIL" = 0 ] && echo "check: PASS" || echo "check: FAIL"
exit "$FAIL"
