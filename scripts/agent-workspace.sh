#!/bin/bash
# Agent Workspace Manager v1.0
# Управление worktrees для AI-агентов LabDoctorM
# Использование: bash scripts/agent-workspace.sh <create|remove|list|sync> [agent]

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "/root/LabDoctorM")"
WORKTREES_DIR="$REPO_ROOT/.worktrees"

# Агенты и их git config
declare -A AGENT_NAME
AGENT_NAME[ant]="Муравей"
AGENT_NAME[bestia]="Бестия"
AGENT_NAME[kot]="Кот"
AGENT_NAME[kotolizator]="Котолизатор"
AGENT_NAME[owl]="Сова"
AGENT_NAME[raven]="Ворон"
AGENT_NAME[streikbrecher]="Штайкбрехер"

declare -A AGENT_EMAIL
AGENT_EMAIL[ant]="ant@labdoctorm.ai"
AGENT_EMAIL[bestia]="bestia@labdoctorm.ai"
AGENT_EMAIL[kot]="kot@labdoctorm.ai"
AGENT_EMAIL[kotolizator]="kotolizator@labdoctorm.ai"
AGENT_EMAIL[owl]="owl@labdoctorm.ai"
AGENT_EMAIL[raven]="raven@labdoctorm.ai"
AGENT_EMAIL[streikbrecher]="streikbrecher@labdoctorm.ai"

usage() {
    echo "Использование: $0 <create|remove|list|sync> [agent]"
    echo ""
    echo "Агенты: ant, bestia, kot, kotolizator, owl, raven, streikbrecher"
    echo ""
    echo "Команды:"
    echo "  create <agent>  — создать worktree и ветку <agent>/session"
    echo "  remove <agent>  — удалить worktree и ветку"
    echo "  list            — список worktrees"
    echo "  sync <agent>    — синхронизировать worktree с main"
}

cmd_create() {
    local agent="${1:?Укажите агента}"
    local worktree="$WORKTREES_DIR/$agent"
    local branch="$agent/session"

    if [[ -d "$worktree" ]]; then
        echo "⚠️  Worktree уже существует: $worktree"
        echo "   Используйте: $0 sync $agent"
        return 1
    fi

    echo "🔧 Создаю worktree для $agent (${AGENT_NAME[$agent]:-$agent})..."

    # Создаём worktree с новой веткой от main
    git -C "$REPO_ROOT" worktree add "$worktree" -b "$branch" 2>/dev/null || \
        git -C "$REPO_ROOT" worktree add "$worktree" "$branch" 2>/dev/null || true

    # Per-agent git identity НЕ пишем в config: worktree делит .git/config
    # с корневым репо → запись вызывает гонку identity между агентами.
    # Race-free путь — обёртка scripts/lab-commit.sh (GIT_AUTHOR_* env при коммите).

    echo "✅ Worktree создан: $worktree"
    echo "   Ветка: $branch"
    echo "   Git identity: задаётся при коммите через scripts/lab-commit.sh $agent"
    echo ""
    echo "   Для работы: cd $worktree"
}

cmd_remove() {
    local agent="${1:?Укажите агента}"
    local worktree="$WORKTREES_DIR/$agent"
    local branch="$agent/session"

    if [[ ! -d "$worktree" ]]; then
        echo "⚠️  Worktree не найден: $worktree"
        return 1
    fi

    echo "🗑️  Удаляю worktree для $agent..."
    git -C "$REPO_ROOT" worktree remove "$worktree" --force 2>/dev/null || rm -rf "$worktree"

    # Удаляем ветку если она существует
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$REPO_ROOT" branch -D "$branch" 2>/dev/null || true
        echo "   Ветка $branch удалена"
    fi

    echo "✅ Worktree удалён"
}

cmd_list() {
    echo "📋 Worktrees лаборатории:"
    git -C "$REPO_ROOT" worktree list 2>/dev/null || echo "   (пусто)"
}

cmd_sync() {
    local agent="${1:?Укажите агента}"
    local worktree="$WORKTREES_DIR/$agent"

    if [[ ! -d "$worktree" ]]; then
        echo "⚠️  Worktree не найден. Создаю..."
        cmd_create "$agent"
        return
    fi

    echo "🔄 Синхронизирую $agent с main..."
    git -C "$worktree" fetch origin 2>/dev/null || true
    git -C "$worktree" merge origin/main --no-edit 2>/dev/null || true
    echo "✅ Синхронизировано"
}

# ──────────────────────────────────────────────
case "${1:-}" in
    create)  cmd_create "${2:-}" ;;
    remove)  cmd_remove "${2:-}" ;;
    list)    cmd_list ;;
    sync)    cmd_sync "${2:-}" ;;
    *)       usage ;;
esac
