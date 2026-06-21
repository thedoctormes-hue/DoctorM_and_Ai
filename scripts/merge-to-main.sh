#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# merge-to-main.sh — безопасный мердж feature-веток в main
# ═══════════════════════════════════════════════════════════════════════════
#
# Использование:
#   bash merge-to-main.sh <branch> [--squash] [--no-push] [--dry-run]
#
# Параметры:
#   <branch>     Ветка для мержа (например, owl/main)
#   --squash     Объединить все коммиты в один (рекомендуется)
#   --no-push    Не пушить в origin после мержа
#   --dry-run    Показать что будет сделано, без выполнения
#
# Примеры:
#   bash merge-to-main.sh owl/main --squash
#   bash merge-to-main.sh raven/main --squash --no-push
#   bash merge-to-main.sh owl/main --dry-run
#
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

LAB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_BRANCH="main"

# ─── Аргументы ─────────────────────────────────────────────────────────────

SOURCE_BRANCH=""
SQUASH=false
NO_PUSH=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --squash)
            SQUASH=true
            shift
            ;;
        --no-push)
            NO_PUSH=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo "[merge] Неизвестный флаг: $1" >&2
            exit 1
            ;;
        *)
            SOURCE_BRANCH="$1"
            shift
            ;;
    esac
done

if [[ -z "$SOURCE_BRANCH" ]]; then
    echo "[merge] Ошибка: ветка не указана" >&2
    echo "Использование: bash merge-to-main.sh <branch> [--squash] [--no-push] [--dry-run]" >&2
    exit 1
fi

# ─── Цвета ─────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[merge]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[merge]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[merge]${NC} $*"; }
log_error() { echo -e "${RED}[merge]${NC} $*"; }

# ─── Проверки ───────────────────────────────────────────────────────────────

cd "$LAB_ROOT"

# Не в main
current_branch=$(git branch --show-current)
if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
    log_error "Уже в ${MAIN_BRANCH}. Для мержа в main нужен отдельный процесс."
    exit 1
fi

# Ветка существует
if ! git show-ref --verify --quiet "refs/heads/${SOURCE_BRANCH}"; then
    # Проверяем в remote
    if git show-ref --verify --quiet "refs/remotes/origin/${SOURCE_BRANCH}"; then
        log_info "Ветка ${SOURCE_BRANCH} найдена в remote, создаю локальную..."
        if [[ "$DRY_RUN" == false ]]; then
            git fetch origin "$SOURCE_BRANCH"
            git branch "$SOURCE_BRANCH" "origin/${SOURCE_BRANCH}"
        fi
    else
        log_error "Ветка ${SOURCE_BRANCH} не найдена ни локально, ни в remote"
        exit 1
    fi
fi

# ─── Статистика ветки ───────────────────────────────────────────────────────

log_info "Анализ ветки ${SOURCE_BRANCH}..."

commits_count=$(git rev-list --count "${MAIN_BRANCH}..${SOURCE_BRANCH}" 2>/dev/null || echo "0")
files_count=$(git diff --name-only "${MAIN_BRANCH}..${SOURCE_BRANCH}" 2>/dev/null | wc -l)
lines_added=$(git diff --numstat "${MAIN_BRANCH}..${SOURCE_BRANCH}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
lines_removed=$(git diff --numstat "${MAIN_BRANCH}..${SOURCE_BRANCH}" 2>/dev/null | awk '{s+=$2} END {print s+0}')

echo ""
log_info "Статистка ветки ${SOURCE_BRANCH}:"
echo "  Коммитов:     ${commits_count}"
echo "  Файлов:       ${files_count}"
echo "  +строк:       ${lines_added}"
echo "  -строк:       ${lines_removed}"
echo ""

# ─── Показать коммиты ───────────────────────────────────────────────────────

log_info "Коммиты для мержа:"
git log --oneline "${MAIN_BRANCH}..${SOURCE_BRANCH}" 2>/dev/null | while IFS= read -r line; do
    echo "  ${line}"
done
echo ""

# ─── Dry run ────────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" == true ]]; then
    log_info "DRY RUN — изменения не применены"
    log_info "Будет выполнено:"
    echo "  1. git checkout ${MAIN_BRANCH}"
    echo "  2. git merge ${SOURCE_BRANCH} $([[ "$SQUASH" == true ]] && echo '--squash' || echo '--no-ff')"
    echo "  3. git add -A && git commit"
    echo "  4. git push origin ${MAIN_BRANCH} $([[ "$NO_PUSH" == true ]] && echo '(пропущено)' || echo '')"
    exit 0
fi

# ─── Подтверждение ───────────────────────────────────────────────────────────

if [[ "$SQUASH" == true ]]; then
    log_warn "Squash merge: все ${commits_count} коммитов объединятся в один"
fi

read -rp "Продолжить мердж ${SOURCE_BRANCH} → ${MAIN_BRANCH}? [y/N] " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    log_info "Мердж отменён"
    exit 0
fi

# ─── Мердж ───────────────────────────────────────────────────────────────────

log_info "Переключаюсь на ${MAIN_BRANCH}..."
git checkout "$MAIN_BRANCH"

log_info "Обновляю ${MAIN_BRANCH}..."
git pull origin "$MAIN_BRANCH" 2>/dev/null || log_warn "Не удалось обновить ${MAIN_BRANCH} (возможно, нет remote)"

if [[ "$SQUASH" == true ]]; then
    log_info "Squash merge ${SOURCE_BRANCH} → ${MAIN_BRANCH}..."
    git merge --squash "$SOURCE_BRANCH"

    # Формируем сообщение коммита
    agent_name=$(echo "$SOURCE_BRANCH" | cut -d'/' -f1)
    commit_msg="chore(${agent_name}): squash merge ${SOURCE_BRANCH}"

    log_info "Создаю merge-коммит: ${commit_msg}"
    git commit -m "$commit_msg"
else
    log_info "Merge ${SOURCE_BRANCH} → ${MAIN_BRANCH} (no-ff)..."
    git merge --no-ff "$SOURCE_BRANCH" -m "merge: ${SOURCE_BRANCH} → ${MAIN_BRANCH}"
fi

log_ok "Мердж завершён"
log_ok "Текущая ветка: $(git branch --show-current)"
log_ok "Последний коммит: $(git log --oneline -1)"

# ─── Push ────────────────────────────────────────────────────────────────────

if [[ "$NO_PUSH" == false ]]; then
    echo ""
    read -rp "Push в origin/${MAIN_BRANCH}? [y/N] " push_confirm
    if [[ "$push_confirm" =~ ^[yY]$ ]]; then
        log_info "Push в origin/${MAIN_BRANCH}..."
        git push origin "$MAIN_BRANCH"
        log_ok "Push завершён"
    else
        log_info "Push пропущен. Выполни вручную:"
        echo "  git push origin ${MAIN_BRANCH}"
    fi
else
    log_info "Push пропущен (--no-push)"
fi

# ─── Итог ───────────────────────────────────────────────────────────────────

echo ""
log_ok "Mердж ${SOURCE_BRANCH} → ${MAIN_BRANCH} завершён"
echo ""
log_info "Следующие шаги:"
echo "  1. Агент обновляет worktree: bash agent-workspace.sh sync ${agent_name}"
echo "  2. Ветка ${SOURCE_BRANCH} можно удалить: git branch -D ${SOURCE_BRANCH}"
echo ""
