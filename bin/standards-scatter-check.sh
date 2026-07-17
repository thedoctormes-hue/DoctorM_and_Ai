#!/usr/bin/env bash
# standards-scatter-check.sh — линтер разброса документов и нарушений стандартов.
# СТРОГО read-only: только find/glob/ls, никаких записей и удалений.
# 3-й часовой сканер Совы (после git-гигиены и рассинхрона инцидентов).
# Вывод вставляется в часовой отчёт ЗавЛабу. ADR-0059.
set -euo pipefail

ROOT="${1:-/root/LabDoctorM}"

python3 - "$ROOT" <<'PY'
import os, sys, fnmatch

ROOT = sys.argv[1]
findings = []  # строки находок (без эмодзи и без ведущего "-")

# ---------------------------------------------------------------------------
# (a) PAT-005: корень /root/LabDoctorM/ — не свалка.
# Разрешены ТОЛЬКО: data, projects, vault, workspaces, .ops, и скрытые (с '.').
# ---------------------------------------------------------------------------
ALLOWED_NONHIDDEN = {"data", "projects", "vault", "workspaces"}
try:
    root_entries = sorted(os.listdir(ROOT))
except OSError as e:
    sys.stderr.write(f"[warn] не могу прочитать корень {ROOT}: {e}\n")
    root_entries = []

for name in root_entries:
    if name.startswith('.'):
        continue  # скрытые разрешены
    if name in ALLOWED_NONHIDDEN:
        continue
    findings.append(f"PAT-005: в корне вне разрешённых: {os.path.join(ROOT, name)}")

# ---------------------------------------------------------------------------
# (b) Дубликаты basename по workspace (≥2 разных workspace).
# Сканируем непосредственные дети каждого workspace.
# ---------------------------------------------------------------------------
PATTERNS = [
    "HANDOFF*", "*.bak*", "scan_garbage*", "AUDIT_REPORT*", "SECURITY_AUDIT*",
    "Poliscop*", "slides*", "*_v2.*", "*_v3.*", "*_v4.*", "extract_*.py", "*.png",
]
ws_root = os.path.join(ROOT, "workspaces")
base_to_ws = {}  # basename -> set(имена workspace)
if os.path.isdir(ws_root):
    for w in sorted(os.listdir(ws_root)):
        wpath = os.path.join(ws_root, w)
        if not os.path.isdir(wpath):
            continue
        seen = set()
        try:
            children = sorted(os.listdir(wpath))
        except OSError:
            continue
        for entry in children:
            for pat in PATTERNS:
                if fnmatch.fnmatch(entry, pat):
                    seen.add(entry)
                    break
        for bn in seen:
            base_to_ws.setdefault(bn, set()).add(w)

for bn in sorted(base_to_ws):
    wsset = base_to_ws[bn]
    if len(wsset) >= 2:
        agents = ", ".join(sorted(wsset))
        findings.append(f"дубликат {bn} ×{len(wsset)}: {agents}")

# ---------------------------------------------------------------------------
# (c) Backup-мусор: рекурсивный find *.bak* в workspaces.
# (пересекается с (b) по смыслу, но оставляем оба — разные цели)
# ---------------------------------------------------------------------------
bak_paths = []
if os.path.isdir(ws_root):
    for dirpath, dirnames, filenames in os.walk(ws_root):
        for f in filenames + dirnames:
            if fnmatch.fnmatch(f, "*.bak*"):
                bak_paths.append(os.path.join(dirpath, f))
for p in sorted(bak_paths):
    findings.append(f"backup-мусор: {p}")

# ---------------------------------------------------------------------------
# Вывод
# ---------------------------------------------------------------------------
if not findings:
    print("✅ Стандарты и разброс: чисто")
else:
    print(f"🟡 Рассинхрон стандартов/разброса: {len(findings)} находок.")
    for f in findings:
        print(f"- {f}")
PY
