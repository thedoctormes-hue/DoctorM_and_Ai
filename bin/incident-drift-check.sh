#!/usr/bin/env bash
# incident-drift-check.sh — генератор+drift-чек рассинхрона «prose-док ↔ реестр инцидентов».
# Аналог ADR-0047 (gen-port-timer-map.sh), но для статусов инцидентов в доках.
# Не правит доки — только флагает рассинхрон. Правка доков = руками агентом.
set -euo pipefail

INC_DIR="${1:-/root/LabDoctorM/projects/DoctorM_and_Ai/incidents}"
shift || true

# Доки по умолчанию (можно переопределить аргументами после $INC_DIR).
# ADR-0059: сканируем ВСЕ агентские workspace (/root/LabDoctorM/workspaces/*/),
# канон incidents/ — SSOT. Сканер READ-ONLY (только читает, не правит чужое).
DOCS=("$@")
if [ ${#DOCS[@]} -eq 0 ]; then
  DOCS=()
  for w in /root/LabDoctorM/workspaces/*/; do
    [ -d "$w" ] || continue
    # стабильные доки агента
    for doc in "$w"MEMORY.md "$w"AGENTS.md "$w"IDENTITY.md; do
      [ -f "$doc" ] && DOCS+=("$doc")
    done
    # ежедневные заметки и бэклоги памяти (динамически, без жёсткой даты)
    for m in "$w"memory/*.md; do
      [ -f "$m" ] && DOCS+=("$m")
    done
  done
fi

python3 - "$INC_DIR" "${DOCS[@]}" <<'PY'
import os, re, sys

inc_dir = sys.argv[1]
docs = sys.argv[2:]

# --- 1. Парсим реестр: id(full) -> status, short_id -> status ---
registry = {}      # full id (INC-...-hash) -> status
short_status = {} # INC-YYYYMMDD-HHMMSS -> status
short_file = {}   # YYYYMMDD-HHMMSS -> status (filename stem без hash)

def short_of(token):
    # Канонизируем ВСЕ формы в INC-YYYYMMDD-HHMMSS (убираем дефисы в дате, снимаем любой суффикс).
    m = re.match(r'^INC-(\d{4})-(\d{2})-(\d{2})-(\d{6})(?:-.*)?$', token)
    if m:
        return f'INC-{m.group(1)}{m.group(2)}{m.group(3)}-{m.group(4)}'
    m = re.match(r'^INC-(\d{8})-(\d{6})(?:-.*)?$', token)
    if m:
        return f'INC-{m.group(1)}-{m.group(2)}'
    m = re.match(r'^(\d{4})-(\d{2})-(\d{2})-(\d{6})(?:-.*)?$', token)
    if m:
        return f'INC-{m.group(1)}{m.group(2)}{m.group(3)}-{m.group(4)}'
    return None

for fn in sorted(os.listdir(inc_dir)):
    if not fn.endswith('.md'): continue
    if fn.lower().startswith('readme'): continue
    p = os.path.join(inc_dir, fn)
    t = open(p, encoding='utf-8', errors='ignore').read()
    fm = re.match(r'^---\s*\n(.*?)\n---', t, re.S)
    rid = rstat = None
    if fm:
        sm = re.search(r'^id:\s*(\S+)', fm.group(1), re.M)
        if sm: rid = sm.group(1).strip().strip('"').strip("'")
        sm2 = re.search(r'^status:\s*(\S+)', fm.group(1), re.M)
        if sm2: rstat = sm2.group(1).strip().strip('"').strip("'")
    if rid is None:
        rid = fn[:-3]  # filename stem
    if rstat is None:
        rstat = 'untracked'
    registry[rid] = rstat
    s = short_of(rid)
    if s:
        short_status.setdefault(s, rstat)
        short_file.setdefault(s.replace('INC-',''), rstat)

# --- 1b. Дообогащаем SSOT из реестра триажа (MASTER_REGISTRY.json, 2026-07-13) ---
# Реестр incidents/ — канон (SSOT-1). Но реально зарегистрированные в триаже
# инциденты (напр. INC-20260620-140000) могут отсутствовать в incidents/ и
# ловиться сканером как NOT_IN_REGISTRY (фантомы, попадающие в часовой отчёт).
# Подтягиваем их из MASTER_REGISTRY как SSOT-2, ТОЛЬКО если ID ещё нет в
# registry (incidents/ имеет приоритет). Формат вывода DRIFT не меняется. ADR-0059.
MASTER_REGISTRY = "/root/LabDoctorM/workspaces/owl/incident-triage/MASTER_REGISTRY.json"
ALLOWED_STATUS = {"open","investigating","resolved","retired","closed","monitoring","triage"}

def _norm_status(raw):
    # Приводим статус к допустимому множеству; иначе 'triage'.
    if not raw:
        return "triage"
    s = str(raw).strip().lower()
    if s in ALLOWED_STATUS:
        return s
    # синонимы / неполные формы (порядок: open до closed)
    if "open" in s or "active" in s:
        return "open"
    if "investig" in s:
        return "investigating"
    if "resolv" in s:
        return "resolved"
    if "clos" in s:
        return "closed"
    if "retir" in s:
        return "retired"
    if "monitor" in s:
        return "monitoring"
    return "triage"

def _extract_inc_id(rec):
    # Ищем таймстамп-форму INC-ID в полях записи (только она совпадает с токенами
    # прозы). Возвращаем канонический short_of(...) либо None.
    cand = []
    if isinstance(rec, dict):
        cand += [str(rec.get(k, "")) for k in ("id","incident_id","source_file","title","status_declared")]
    else:
        cand = [str(rec)]
    pat = re.compile(r'INC-(?:\d{4}-\d{2}-\d{2}|\d{8})-\d{6}(?:-[\w-]+)?')
    for c in cand:
        m = pat.search(c)
        if m:
            sid = short_of(m.group(0))
            if sid:
                return sid
    return None

try:
    import json
    with open(MASTER_REGISTRY, encoding="utf-8") as _mf:
        _mr = json.load(_mf)
    _entries = []
    if isinstance(_mr, dict):
        if isinstance(_mr.get("incidents"), list):
            _entries = _mr["incidents"]
        else:
            # dict, ключи вида INC-... — используем ключ как ID
            for _k, _v in _mr.items():
                if isinstance(_k, str) and _k.startswith("INC-"):
                    _entries.append({"__id__": _k, "__status__": _v})
    for _e in _entries:
        if not isinstance(_e, dict):
            continue
        _rid = _e.get("__id__") or _extract_inc_id(_e)
        if not _rid:
            continue
        _st = _e.get("__status__")
        if _st is None:
            for _f in ("status","state","status_declared"):
                if _f in _e and _e[_f] is not None:
                    _st = _e[_f]
                    break
        _st = _norm_status(_st)
        if _rid not in registry:   # incidents/ имеет приоритет
            registry[_rid] = _st
            _s = short_of(_rid)
            if _s:
                short_status.setdefault(_s, _st)
                short_file.setdefault(_s.replace("INC-",""), _st)
except FileNotFoundError:
    pass  # триаж-реестр отсутствует — не фатально, incidents/ остаётся SSOT
except Exception as _e2:
    sys.stderr.write(f"[warn] MASTER_REGISTRY load failed: {_e2}\n")

# --- 2. Сканируем прозу ---
TOKEN_RE = re.compile(r'INC-(?:\d{4}-\d{2}-\d{2}|\d{8})-\d{6}(?:-[\w-]+)?')
OPEN_KW = re.compile(r'\b(open|активн|блокер|жду|ожида|требу|confirm|разреш|не закрыт|pending)\b', re.I)

flags = []
allrefs = []
for doc in docs:
    if not os.path.exists(doc): continue
    for lineno, line in enumerate(open(doc, encoding='utf-8', errors='ignore'), 1):
        for tok in TOKEN_RE.findall(line):
            sid = short_of(tok)
            true_status = (short_status.get(sid) or
                           short_file.get(sid.replace('INC-','')) or
                           registry.get(tok) or 'NOT_IN_REGISTRY')
            claims_open = False
            idx = line.find(tok)
            if idx >= 0:
                window = line[idx:idx+len(tok)+50]  # только ближайший контекст после токена
                claims_open = bool(OPEN_KW.search(window))
            allrefs.append((doc, lineno, tok, true_status, claims_open))
            if true_status == 'NOT_IN_REGISTRY':
                flags.append((doc, lineno, tok, true_status, 'ССЫЛКА НЕ В РЕЕСТРЕ'))
            elif true_status in ('resolved','closed','retired') and claims_open:
                flags.append((doc, lineno, tok, true_status, 'DRIFT: doc утверждает open-статус, реестр='+true_status))

# --- 3. Вывод ---
print("=== DRIFT (рассинхрон doc↔registry) ===")
if flags:
    for doc, ln, tok, st, note in flags:
        print(f"  🟡  {doc}:{ln}  {tok}  [{st}]  {note}")
else:
    print("  ✅ рассинхрона нет")

print("\n=== Все ссылки на инциденты в доках (для проверки) ===")
for doc, ln, tok, st, co in allrefs:
    mark = "  <-- DRIFT" if (st in ('resolved','closed','retired') and co) else ""
    print(f"  {doc}:{ln}  {tok}  registry={st}{mark}")
PY
