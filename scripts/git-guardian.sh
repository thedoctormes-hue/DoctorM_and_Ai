#!/bin/bash
# Git Guardian v2.0 — ядро защиты коммитов LabDoctorM
# Использование: bash scripts/git-guardian.sh <hook-type> [file]
# Типы: pre-commit, commit-msg, pre-push, prepare-commit-msg

set -euo pipefail

HOOK_TYPE="${1:-}"
COMMIT_MSG_FILE="${2:-}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MAIN_BRANCH="main"

# Цвета
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log_error() { echo -e "${RED}[GUARDIAN]${NC} $1" >&2; }
log_warn()  { echo -e "${YELLOW}[GUARDIAN]${NC} $1" >&2; }
log_ok()    { echo -e "${GREEN}[GUARDIAN]${NC} $1"; }

# ──────────────────────────────────────────────
# PRE-COMMIT
# ──────────────────────────────────────────────
hook_pre_commit() {
    local errors=0

    # 1. Блокировка коммитов в main
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD")
    if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
        log_error "❌ Коммиты в $MAIN_BRANCH ЗАПРЕЩЕНЫ!"
        log_error "   Используй worktree: bash scripts/agent-workspace.sh create <agent>"
        log_error "   Или: git checkout -b <agent>/<feature>"
        ((errors++))
    fi

    # 2. Проверка staged файлов
    local staged_files
    staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

    if [[ -z "$staged_files" ]]; then
        log_warn "Нет staged файлов — пропуск проверок"
        return 0
    fi

    local file_count
    file_count=$(echo "$staged_files" | wc -l)

    # 3. Лимит файлов (30)
    if [[ $file_count -gt 30 ]]; then
        log_error "❌ Слишком много файлов: $file_count (лимит: 30)"
        log_error "   Разбей на несколько коммитов"
        ((errors++))
    fi

    # 4. Лимит строк (500)
    local total_lines
    total_lines=$(git diff --cached --stat 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    if [[ "${total_lines:-0}" -gt 500 ]]; then
        log_error "❌ Слишком много изменений: $total_lines строк (лимит: 500)"
        log_error "   Разбей на несколько коммитов"
        ((errors++))
    fi

    # 5. Запрет git add . из корня
    local added_from_root
    added_from_root=$(echo "$staged_files" | grep -v "/" | head -5 || true)
    if [[ -n "$added_from_root" ]] && echo "$staged_files" | grep -q "/"; then
        log_error "❌ Подозрение на 'git add .' из корня!"
        echo "$added_from_root" | while read -r f; do
            log_error "   → $f"
        done
        log_error "   Стагь файлы конкретного проекта"
        ((errors++))
    fi

    # 6. Проверка секретов
    local secret_patterns=("password*=" "token*=" "api_key*=" "private_key" "secret=" "TOKEN=" "API_KEY=" "PRIVATE")
    for pattern in "${secret_patterns[@]}"; do
        local matches
        matches=$(git diff --cached -G"$pattern" --name-only 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            log_error "⚠️  Возможный секрет ($pattern) в:"
            echo "$matches" | head -5 | while read -r f; do
                log_error "   → $f"
            done
            # Предупреждение, не блокировка
        fi
    done

    # 7. Запрет коммита config.yaml / .env с реальными значениями
    local config_files
    config_files=$(echo "$staged_files" | grep -E "(config\.yaml|\.env$|\.env\.local|\.env\.production)" || true)
    if [[ -n "$config_files" ]]; then
        log_error "❌ Запрещён коммит конфиг-файлов:"
        echo "$config_files" | while read -r f; do
            log_error "   → $f"
        done
        log_error "   Используй template (.example) вместо реальных значений"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "Коммит заблокирован: $errors ошибок"
        log_error "Обход: git commit --no-verify (только в личной ветке!)"
        return 1
    fi

    log_ok "✅ pre-commit: проверки пройдены"
    return 0
}

# ──────────────────────────────────────────────
# COMMIT-MSG
# ──────────────────────────────────────────────
hook_commit_msg() {
    local msg_file="$COMMIT_MSG_FILE"
    local msg
    msg=$(head -1 "$msg_file" 2>/dev/null || echo "")
    local errors=0

    # Пропуск merge-коммитов
    if echo "$msg" | grep -qE "^Merge "; then
        return 0
    fi

    # 1. Conventional Commits формат: type(scope): description
    if ! echo "$msg" | grep -qE "^(feat|fix|test|docs|refactor|chore|perf|ci|build|revert)(\([a-zA-Z0-9_-]+\))?: .+"; then
        log_error "❌ Формат сообщения: type(scope): описание"
        log_error "   Типы: feat|fix|test|docs|refactor|chore|perf|ci|build|revert"
        log_error "   Scope (проект) обязателен!"
        log_error "   Пример: feat(consilium): добавить vault fallback"
        ((errors++))
    fi

    # 2. Scope обязателен
    if ! echo "$msg" | grep -qE "^(feat|fix|test|docs|refactor|chore|perf|ci|build|revert)\([^)]+\):"; then
        log_error "❌ Scope (имя проекта) обязателен!"
        log_error "   Пример: feat(snablab): добавить QR-коды"
        ((errors++))
    fi

    # 3. Длина subject ≤ 72
    local subject_len
    subject_len=$(echo "$msg" | head -1 | wc -c)
    if [[ $subject_len -gt 73 ]]; then  # 73 = 72 + newline
        log_error "❌ Длина subject: $subject_len символов (лимит: 72)"
        ((errors++))
    fi

    # 4. Точка в конце — запрещена
    if echo "$msg" | head -1 | grep -qE '\.$'; then
        log_error "❌ Точка в конце subject запрещена"
        ((errors++))
    fi

    # 5. Блокировка snapshot/checkpoint/wip
    local blocked_words=("snapshot" "checkpoint" "wip" "WIP" "fix fix" "temp" "temporary" "asdf" "test test" "xxx")
    for word in "${blocked_words[@]}"; do
        if echo "$msg" | grep -qi "$word"; then
            log_error "❌ Запрещённое слово в сообщении: '$word'"
            ((errors++))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        log_error "Коммит заблокирован: $errors ошибок в сообщении"
        return 1
    fi

    log_ok "✅ commit-msg: формат корректен"
    return 0
}

# ──────────────────────────────────────────────
# PRE-PUSH
# ──────────────────────────────────────────────
hook_pre_push() {
    local errors=0

    # 1. Блокировка push в main
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD")
    if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
        log_error "❌ Push в $MAIN_BRANCH ЗАПРЕЩЁН!"
        log_error "   Используй: bash scripts/merge-to-main.sh <branch>"
        ((errors++))
    fi

    # 2. Лимит коммитов за push (20)
    local commit_count
    commit_count=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l || echo "0")
    if [[ "${commit_count:-0}" -gt 20 ]]; then
        log_error "❌ Слишком много коммитов за push: $commit_count (лимит: 20)"
        log_error "   Разбей или сделай squash"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "Push заблокирован: $errors ошибок"
        log_error "Обход: git push --no-verify (НЕ РЕКОМЕНДУЕТСЯ)"
        return 1
    fi

    log_ok "✅ pre-push: проверки пройдены"
    return 0
}

# ──────────────────────────────────────────────
# PREPARE-COMMIT-MSG (подсказка)
# ──────────────────────────────────────────────
hook_prepare_commit_msg() {
    local msg_file="$COMMIT_MSG_FILE"
    local source="${3:-}"

    # Не перезаписываем merge/squash/rebase
    if [[ "$source" == "message" || "$source" == "squash" || "$source" == "commit" ]]; then
        return 0
    fi

    # Определяем scope по staged файлам
    local staged
    staged=$(git diff --cached --name-only 2>/dev/null || true)

    local scope=""
    if echo "$staged" | grep -q "^projects/consilium/"; then scope="consilium"
    elif echo "$staged" | grep -q "^projects/snablab/"; then scope="snablab"
    elif echo "$staged" | grep -q "^projects/SNZK/"; then scope="snzk"
    elif echo "$staged" | grep -q "^projects/kotolizator/"; then scope="kotolizator"
    elif echo "$staged" | grep -q "^projects/gastro-bot/"; then scope="gastro-bot"
    elif echo "$staged" | grep -q "^projects/myrmex-control/"; then scope="myrmex-control"
    elif echo "$staged" | grep -q "^projects/artifact-pulse/"; then scope="artifact-pulse"
    elif echo "$staged" | grep -q "^projects/lab-vault/"; then scope="lab-vault"
    elif echo "$staged" | grep -q "^services/context-api/"; then scope="context-api"
    elif echo "$staged" | grep -q "^adr/"; then scope="adr"
    fi

    # Определяем тип
    local type="feat"
    local msg_temp
    msg_temp=$(head -1 "$msg_file" 2>/dev/null || echo "")
    if echo "$msg_temp" | grep -qE "^(feat|fix|test|docs|refactor|chore|perf|ci|build|revert)"; then
        return 0  # Уже есть правильный тип
    fi

    # Добавляем подсказку
    if [[ -n "$scope" ]]; then
        echo "" >> "$msg_file"
        echo "# 💡 Git Guardian: рекомендуемый scope → $scope" >> "$msg_file"
        echo "#    Формат: type($scope): описание" >> "$msg_file"
    fi

    return 0
}

# ──────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────
case "$HOOK_TYPE" in
    pre-commit)
        hook_pre_commit
        ;;
    commit-msg)
        hook_commit_msg
        ;;
    pre-push)
        hook_pre_push
        ;;
    prepare-commit-msg)
        hook_prepare_commit_msg
        ;;
    *)
        echo "Использование: $0 <pre-commit|commit-msg|pre-push|prepare-commit-msg> [file]"
        exit 1
        ;;
esac
