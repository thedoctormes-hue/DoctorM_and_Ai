#!/usr/bin/env bash
#
# incident-linter.sh — read-only аудитор инцидентов лаборатории (ADR-0056, enforcement point #2)
#
# Что делает (ТОЛЬКО чтение, НЕ удаляет и НЕ переносит файлы):
#   1. Сканирует всю лабу и флагает .md вне канонической директории, которые являются
#      инцидентами (по frontmatter) -> список на перенос в канон.
#   2. Для каждого .md в каноне проверяет обязательные поля frontmatter:
#      id, timestamp, category, type, severity, status, agent, title.
#      Отсутствие status или невалидное значение status -> ошибка.
#   3. Детектит дубликаты по полю id и по заголовку h1.
#   4. Печатает итоговый отчёт в stdout с количествами и списками нарушений.
#
# Использование:
#   incident-linter.sh [--canon DIR] [--lab ROOT] [--strict] [--quiet] [--help]
#     --strict : выходить с кодом 1 при наличии ERROR-нарушений (для гейтов/CI)
#     --quiet  : только итоговые числа (без расширенных списков)
#
# Подробности: ADR-0056 (Единый реестр инцидентов и обязательный frontmatter).
#
set -uo pipefail

CANON_DIR="/root/LabDoctorM/projects/DoctorM_and_Ai/incidents"
LAB_ROOT="/root/LabDoctorM"
STRICT=0
QUIET=0

# Валидные значения enum (по registering-incident SKILL.md / ADR-0056)
VALID_STATUS=(open investigating resolved closed)
REQUIRED_FIELDS=(id timestamp category type severity status agent title)

# Директории-исключения при поиске "размазанных" инцидентов по лабе
EXCLUDE_SUBSTRINGS=(
  "/.git/"
  "/.ops/"
  "/vault/"
  "node_modules"
  "/templates/"
  ".bak"
  "_consolidated"
  "/.github/"
)

usage() {
  grep -E '^#' "$0" | sed 's/^#\s\?//' | head -40
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --canon) CANON_DIR="$2"; shift 2 ;;
    --lab)   LAB_ROOT="$2"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    --quiet)  QUIET=1; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

# --- helpers ---------------------------------------------------------------

# Извлечь frontmatter (без ограничителей ---) или пусто, если нет.
extract_frontmatter() {
  awk '
    NR==1 && $0=="---" {infm=1; next}
    infm && $0=="---" {exit}
    infm {print}
  ' "$1"
}

# Получить значение поля frontmatter (первая строка ^field:), без обрамляющих кавычек.
get_field() {
  local file="$1" field="$2"
  extract_frontmatter "$file" \
    | grep -m1 -E "^${field}:" \
    | sed -E "s/^${field}:[[:space:]]*//" \
    | sed -E 's/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//'
}

# Первый заголовок h1 (после frontmatter).
get_h1() {
  awk '
    NR==1 && $0=="---" {infm=1; next}
    infm && $0=="---" {infm=0; next}
    !infm && /^# / { sub(/^#[[:space:]]*/,""); print; exit }
  ' "$1"
}

is_excluded() {
  local p="$1"
  local s
  for s in "${EXCLUDE_SUBSTRINGS[@]}"; do
    case "$p" in
      *"$s"*) return 0 ;;
    esac
  done
  return 1
}

# Является ли файл инцидентом (по сигнатуре имени или frontmatter)?
is_incident() {
  local file="$1"; local base; base="$(basename "$file")"
  # Каноническое имя инцидента: INC-...md
  case "$base" in
    INC-*) return 0 ;;
  esac
  local fm id status category type severity
  fm="$(extract_frontmatter "$file")"
  [ -z "$fm" ] && return 1
  id="$(printf '%s\n' "$fm" | grep -m1 -E '^id:' | sed -E 's/^id:[[:space:]]*//; s/^["\x27]//; s/["\x27]$//')"
  case "$id" in
    INC-*) return 0 ;;
  esac
  status="$(printf '%s\n' "$fm" | grep -qiE '^status:' && echo yes)"
  category="$(printf '%s\n' "$fm" | grep -qiE '^category:' && echo yes)"
  type="$(printf '%s\n' "$fm" | grep -qiE '^type:' && echo yes)"
  severity="$(printf '%s\n' "$fm" | grep -qiE '^severity:' && echo yes)"
  if [ "$status" = yes ] && [ "$category" = yes ] && [ "$type" = yes ] && [ "$severity" = yes ]; then
    return 0
  fi
  return 1
}

is_valid_status() {
  local v="$1" s
  [ -z "$v" ] && return 1
  for s in "${VALID_STATUS[@]}"; do
    [ "$v" = "$s" ] && return 0
  done
  return 1
}

# --- state -----------------------------------------------------------------
declare -a MOVE_LIST=()
declare -a INVALID_LIST=()
declare -A ID_MAP=()
declare -A H1_MAP=()
CANON_TOTAL=0
CANON_VALID=0

# --- scan 1: misplaced incidents (whole lab, outside canonical) ------------
while IFS= read -r -d '' f; do
  # пропускаем сам канон (и всё, что внутри него)
  case "$f" in
    "$CANON_DIR"|"$CANON_DIR"/*) continue ;;
  esac
  is_excluded "$f" && continue
  if is_incident "$f"; then
    MOVE_LIST+=("$f")
  fi
done < <(find "$LAB_ROOT" -type f -name '*.md' -print0 2>/dev/null)

# --- scan 2: canonical validation + duplicate collection -------------------
if [ -d "$CANON_DIR" ]; then
  while IFS= read -r -d '' f; do
    CANON_TOTAL=$((CANON_TOTAL+1))
    base="$(basename "$f")"
    missing=()
    for field in "${REQUIRED_FIELDS[@]}"; do
      val="$(get_field "$f" "$field")"
      if [ -z "$val" ]; then missing+=("$field"); fi
    done
    status_val="$(get_field "$f" "status")"
    status_err=""
    if [ -z "$status_val" ]; then
      status_err="status:MISSING"
    elif ! is_valid_status "$status_val"; then
      status_err="status:INVALID($status_val)"
    fi

    if [ "${#missing[@]}" -gt 0 ] || [ -n "$status_err" ]; then
      INVALID_LIST+=("$base|missing:${missing[*]}|$status_err")
    fi

    # duplicate keys
    id_val="$(get_field "$f" "id")"
    if [ -n "$id_val" ]; then
      ID_MAP["$id_val"]+="$base"$'\n'
    fi
    h1_val="$(get_h1 "$f")"
    if [ -n "$h1_val" ]; then
      H1_MAP["$h1_val"]+="$base"$'\n'
    fi
  done < <(find "$CANON_DIR" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)
fi

# счётчик валидных = total - invalid
INVALID_COUNT=${#INVALID_LIST[@]}
CANON_INVALID=$INVALID_COUNT
CANON_VALID=$((CANON_TOTAL - CANON_INVALID))

# --- duplicate groups ------------------------------------------------------
DUP_ID_GROUPS=()
for k in "${!ID_MAP[@]}"; do
  n=$(printf '%s' "${ID_MAP[$k]}" | grep -c .)
  if [ "$n" -gt 1 ]; then
    DUP_ID_GROUPS+=("$k|${ID_MAP[$k]}")
  fi
done
DUP_H1_GROUPS=()
for k in "${!H1_MAP[@]}"; do
  n=$(printf '%s' "${H1_MAP[$k]}" | grep -c .)
  if [ "$n" -gt 1 ]; then
    DUP_H1_GROUPS+=("$k|${H1_MAP[$k]}")
  fi
done

# --- report ----------------------------------------------------------------
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SEP="================================================================"

if [ "$QUIET" -eq 0 ]; then
  echo "$SEP"
  echo " INCIDENT LINTER REPORT  (ADR-0056, enforcement point #2)"
  echo " Generated : $NOW"
  echo " Canonical : $CANON_DIR"
  echo " Lab root  : $LAB_ROOT"
  echo "$SEP"
  echo
  echo "[1] Misplaced incident files (outside canonical) -> need move: ${#MOVE_LIST[@]}"
  if [ "${#MOVE_LIST[@]}" -gt 0 ]; then
    for m in "${MOVE_LIST[@]}"; do echo "    - $m"; done
  fi
  echo
  echo "[2] Canonical incidents: total=$CANON_TOTAL valid=$CANON_VALID invalid=$CANON_INVALID"
  if [ "$CANON_INVALID" -gt 0 ]; then
    echo "    Invalid files (missing required fields / bad status):"
    for inv in "${INVALID_LIST[@]}"; do echo "    - $inv"; done
  fi
  echo
  echo "[3] Duplicate 'id' groups: ${#DUP_ID_GROUPS[@]}"
  for g in "${DUP_ID_GROUPS[@]}"; do
    key="${g%%|*}"; files="${g#*|}"
    echo "    - id '$key': $(printf '%s' "$files" | tr '\n' ' ')"
  done
  echo
  echo "[4] Duplicate h1 heading groups: ${#DUP_H1_GROUPS[@]}"
  for g in "${DUP_H1_GROUPS[@]}"; do
    key="${g%%|*}"; files="${g#*|}"
    echo "    - '$key': $(printf '%s' "$files" | tr '\n' ' ')"
  done
  echo
fi

echo "$SEP"
echo " SUMMARY"
echo "   misplaced_outside_canonical : ${#MOVE_LIST[@]}"
echo "   canonical_total             : $CANON_TOTAL"
echo "   canonical_invalid           : $CANON_INVALID"
echo "   duplicate_id_groups         : ${#DUP_ID_GROUPS[@]}"
echo "   duplicate_h1_groups         : ${#DUP_H1_GROUPS[@]}"
ERR_COUNT=$(( ${#MOVE_LIST[@]} + CANON_INVALID + ${#DUP_ID_GROUPS[@]} + ${#DUP_H1_GROUPS[@]} ))
echo "   total_violations            : $ERR_COUNT"
echo "$SEP"

if [ "$STRICT" -eq 1 ] && [ "$ERR_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
