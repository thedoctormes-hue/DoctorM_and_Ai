#!/usr/bin/env bash
# verification-loop.sh — автономный цикл верификации (6 фаз) + VERIFICATION REPORT.
# Стек детектится по манифесту. Фазы: Build/Type/Lint/Test/Security/Diff.
# Exit: 0=READY, 1=NOT READY, 2=N/A (нет кода) или ошибка запуска.
# usage: bash bin/verification-loop.sh [project_dir]
set -uo pipefail

TARGET="${1:-.}"
if ! cd "$TARGET" 2>/dev/null; then
  echo "VERIFICATION ERROR: не могу перейти в '$TARGET'" >&2
  exit 2
fi

# --- детект стека ---
STACK="unknown"
if [ -f package.json ]; then STACK="node"
elif [ -f go.mod ]; then STACK="go"
elif [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then STACK="python"
elif [ -f Cargo.toml ]; then STACK="rust"
elif [ -f Makefile ]; then STACK="make"
fi

RES_BUILD=""; RES_TYPE=""; RES_LINT=""; RES_TEST=""; RES_SEC=""; RES_DIFF=""
FAILS=0; SKIPS=0; TOTAL=0

# run_phase <имя_переменной_результата> <команда>
# команда пустая -> SKIP; первое слово не найдено как бинарь (кроме npx) -> SKIP;
# rc!=0 -> FAIL; иначе PASS.
run_phase() {
  local var="$1"; local cmd="$2"
  TOTAL=$((TOTAL+1))
  if [ -z "$cmd" ]; then
    printf -v "$var" "SKIP (неприменимо к стеку %s)" "$STACK"
    SKIPS=$((SKIPS+1)); return
  fi
  local firstword="${cmd%% *}"
  if [ "$firstword" != "npx" ] && ! command -v "$firstword" >/dev/null 2>&1; then
    printf -v "$var" "SKIP (нет бинаря %s)" "$firstword"
    SKIPS=$((SKIPS+1)); return
  fi
  local out rc
  out=$(bash -c "$cmd" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then
    printf -v "$var" "PASS"
  else
    local tail3
    tail3=$(printf '%s\n' "$out" | tail -3 | tr '\n' ' ' | cut -c1-120)
    printf -v "$var" "FAIL (rc=%s): %s" "$rc" "$tail3"
    FAILS=$((FAILS+1))
  fi
}

# --- фазы по стеку ---
case "$STACK" in
  node)
    run_phase RES_BUILD  "npm run build >/dev/null 2>&1"
    run_phase RES_TYPE   "npx tsc --noEmit"
    run_phase RES_LINT   "npx eslint ."
    run_phase RES_TEST   "npm test"
    run_phase RES_SEC     "npm audit --audit-level=high"
    ;;
  go)
    run_phase RES_BUILD  "go build ./..."
    run_phase RES_TYPE   "go vet ./..."
    run_phase RES_LINT   "golangci-lint run"
    run_phase RES_TEST   "go test ./..."
    run_phase RES_SEC     "govulncheck ./..."
    ;;
  python)
    run_phase RES_BUILD  "python -m compileall -q ."
    run_phase RES_TYPE   "python -m mypy ."
    run_phase RES_LINT   "ruff check ."
    run_phase RES_TEST   "pytest"
    run_phase RES_SEC     "pip-audit"
    ;;
  rust)
    run_phase RES_BUILD  "cargo build"
    run_phase RES_TYPE   "cargo check"
    run_phase RES_LINT   "cargo clippy"
    run_phase RES_TEST   "cargo test"
    run_phase RES_SEC     "cargo audit"
    ;;
  make)
    run_phase RES_BUILD  "make build"
    run_phase RES_TYPE   ""
    run_phase RES_LINT   ""
    run_phase RES_TEST   "make test"
    run_phase RES_SEC     ""
    ;;
  *)
    run_phase RES_BUILD  ""
    run_phase RES_TYPE   ""
    run_phase RES_LINT   ""
    run_phase RES_TEST   ""
    run_phase RES_SEC     ""
    ;;
esac

# --- Diff (независимо от стека) ---
TOTAL=$((TOTAL+1))
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  SECRET_HIT=$(git diff --cached 2>/dev/null | grep -iE '(api_key|secret|token|password)\s*=' | head -1)
  if [ -n "$SECRET_HIT" ]; then
    RES_DIFF="FAIL (секрет в staged: ${SECRET_HIT:0:80})"
    FAILS=$((FAILS+1))
  else
    FILES=$(git diff --stat; git diff --cached --stat 2>/dev/null)
    CNT=$(printf '%s\n' "$FILES" | grep -c '|')
    RES_DIFF="PASS (${CNT} files changed)"
  fi
else
  RES_DIFF="SKIP (не git-репозиторий)"
  SKIPS=$((SKIPS+1))
fi

# --- вывод ---
echo "=== VERIFICATION REPORT ==="
printf "Build:    %s\n" "$RES_BUILD"
printf "Type:     %s\n" "$RES_TYPE"
printf "Lint:     %s\n" "$RES_LINT"
printf "Test:     %s\n" "$RES_TEST"
printf "Security: %s\n" "$RES_SEC"
printf "Diff:     %s\n" "$RES_DIFF"
echo "---"
if [ "$STACK" = "unknown" ]; then
  echo "Overall:  N/A (стек не детектится — не код-проект)"
  exit 2
elif [ "$FAILS" -eq 0 ]; then
  echo "Overall:  READY"
  exit 0
else
  echo "Overall:  NOT READY ($FAILS FAIL)"
  exit 1
fi
