#!/bin/bash
# backup-verify.sh — Проверка целостности бэкапов проектов
# Запуск: ежедневно через systemd timer или cron
# Проверяет incremental-бэкапы всех проектов в /root/LabDoctorM/projects/

set -euo pipefail

# ─── Конфигурация ───────────────────────────────────────────────
PROJECTS_DIR="/root/LabDoctorM/projects"
BACKUP_BASE="/root/LabDoctorM/backups"
LOGFILE="/var/log/backup-verify.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
FAILED=0
PASSED=0
SKIPPED=0

# ─── Логирование ────────────────────────────────────────────────
log() {
    echo "[$TIMESTAMP] $*" >> "$LOGFILE"
}

log_info()  { log "[INFO] $*"; }
log_pass()  { log "[PASS] $*"; }
log_fail()  { log "[FAIL] $*"; }
log_skip()  { log "[SKIP] $*"; }

# ─── Проверка целостности .git в бэкапе ────────────────────────
verify_git_backup() {
    local backup_dir="$1"
    local project_name="$2"

    # 1. .git/HEAD существует
    if [ ! -f "$backup_dir/.git/HEAD" ]; then
        log_fail "BACKUP_VERIFY_FAIL: $project_name — .git/HEAD missing in $backup_dir"
        logger -t BACKUP_VERIFY_FAIL "Project: $project_name — .git/HEAD missing"
        return 1
    fi

    # 2. refs читаются (refs/heads и/или refs/tags)
    local refs_ok=false
    if [ -d "$backup_dir/.git/refs/heads" ] && [ -n "$(ls -A "$backup_dir/.git/refs/heads" 2>/dev/null)" ]; then
        refs_ok=true
    fi
    if [ -d "$backup_dir/.git/refs/tags" ] && [ -n "$(ls -A "$backup_dir/.git/refs/tags" 2>/dev/null)" ]; then
        refs_ok=true
    fi
    if [ -f "$backup_dir/.git/packed-refs" ]; then
        refs_ok=true
    fi

    if [ "$refs_ok" = false ]; then
        log_fail "BACKUP_VERIFY_FAIL: $project_name — no readable refs in $backup_dir"
        logger -t BACKUP_VERIFY_FAIL "Project: $project_name — no refs found"
        return 1
    fi

    # 3. objects/ не пустой
    if [ ! -d "$backup_dir/.git/objects" ]; then
        log_fail "BACKUP_VERIFY_FAIL: $project_name — .git/objects/ missing in $backup_dir"
        logger -t BACKUP_VERIFY_FAIL "Project: $project_name — .git/objects/ missing"
        return 1
    fi

    local obj_count
    obj_count=$(find "$backup_dir/.git/objects" -type f 2>/dev/null | wc -l)
    if [ "$obj_count" -eq 0 ]; then
        log_fail "BACKUP_VERIFY_FAIL: $project_name — .git/objects/ is empty in $backup_dir"
        logger -t BACKUP_VERIFY_FAIL "Project: $project_name — .git/objects/ empty"
        return 1
    fi

    # 4. Проверяем что HEAD указывает на валидный ref
    local head_ref
    head_ref=$(cat "$backup_dir/.git/HEAD" 2>/dev/null || echo "ERROR")

    # Нормализуем: 'ref: refs/heads/master' -> 'refs/heads/master'
    if [[ "$head_ref" == ref:* ]]; then
        head_ref="${head_ref#ref: }"
    fi

    if [[ "$head_ref" == refs/* ]]; then
        # Символическая ссылка — проверяем что целевой ref существует
        if [ ! -f "$backup_dir/.git/$head_ref" ] && [ ! -f "$backup_dir/.git/packed-refs" ]; then
            log_fail "BACKUP_VERIFY_FAIL: $project_name — HEAD points to non-existent ref: $head_ref"
            logger -t BACKUP_VERIFY_FAIL "Project: $project_name — broken HEAD ref: $head_ref"
            return 1
        fi
    elif [[ "$head_ref" =~ ^[0-9a-f]{40}$ ]]; then
        # Detached HEAD — проверяем что объект существует
        if [ ! -f "$backup_dir/.git/objects/${head_ref:0:2}/${head_ref:2}" ]; then
            log_fail "BACKUP_VERIFY_FAIL: $project_name — detached HEAD points to missing object: $head_ref"
            logger -t BACKUP_VERIFY_FAIL "Project: $project_name — missing HEAD object: $head_ref"
            return 1
        fi
    else
        log_fail "BACKUP_VERIFY_FAIL: $project_name — invalid .git/HEAD content: '$head_ref'"
        logger -t BACKUP_VERIFY_FAIL "Project: $project_name — invalid HEAD: $head_ref"
        return 1
    fi

    return 0
}

# ─── Поиск последнего incremental-бэкапа проекта ──────────────
find_latest_backup() {
    local project_name="$1"
    local project_backup_dir="$BACKUP_BASE/$project_name"

    if [ ! -d "$project_backup_dir" ]; then
        echo ""
        return
    fi

    # Ищем последний бэкап (сортируем по имени = по дате в формате YYYY-MM-DD)
    local latest
    latest=$(find "$project_backup_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -r | head -1)

    echo "${latest:-}"
}

# ─── Ротация лога ───────────────────────────────────────────────
rotate_log() {
    if [ -f "$LOGFILE" ] && [ "$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)" -gt 5000 ]; then
        tail -500 "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"
    fi
}

# ─── Основная логика ────────────────────────────────────────────
main() {
    log_info "=== backup-verify.sh started ==="

    # Проверяем что директория бэкапов существует
    if [ ! -d "$BACKUP_BASE" ]; then
        log_info "Backup directory $BACKUP_BASE does not exist, nothing to verify"
        log_info "=== backup-verify.sh completed (no backups) ==="
        return 0
    fi

    # Проверяем каждый проект
    for project_dir in "$PROJECTS_DIR"/*/; do
        project_dir="${project_dir%/}"  # Remove trailing slash
        [ -d "$project_dir" ] || continue

        local project_name
        project_name=$(basename "$project_dir")

        # Пропускаем скрытые и системные директории
        [[ "$project_name" == .* ]] && continue

        local latest_backup
        latest_backup=$(find_latest_backup "$project_name")

        if [ -z "$latest_backup" ]; then
            # Нет бэкапа в директории backups — проверяем .git напрямую в проекте
            if [ -d "$project_dir/.git" ]; then
                log_info "No backup found for $project_name, verifying working .git directly"
                if verify_git_backup "$project_dir" "$project_name (working tree)"; then
                    log_pass "$project_name — working tree .git is valid"
                    PASSED=$((PASSED + 1))
                else
                    FAILED=$((FAILED + 1))
                fi
            else
                log_skip "$project_name — no .git directory and no backup"
                SKIPPED=$((SKIPPED + 1))
            fi
            continue
        fi

        # Проверяем бэкап
        if [ -d "$latest_backup/.git" ]; then
            if verify_git_backup "$latest_backup" "$project_name (backup: $(basename "$latest_backup"))"; then
                local obj_count
                obj_count=$(find "$latest_backup/.git/objects" -type f 2>/dev/null | wc -l)
                log_pass "$project_name — backup $(basename "$latest_backup") is valid ($obj_count objects)"
                PASSED=$((PASSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        else
            # Бэкап может быть tar-архивом — проверяем альтернативно
            log_info "$project_name — backup $(basename "$latest_backup") has no .git, checking as archive..."
            if [ -f "$latest_backup" ]; then
                log_pass "$project_name — backup archive exists: $(basename "$latest_backup")"
                PASSED=$((PASSED + 1))
            else
                log_skip "$project_name — backup directory exists but no .git and no archive"
                SKIPPED=$((SKIPPED + 1))
            fi
        fi
    done

    # Итоговый отчёт
    log_info "=== Summary: $PASSED passed, $FAILED failed, $SKIPPED skipped ==="

    # Если есть ошибки — пишем в syslog
    if [ "$FAILED" -gt 0 ]; then
        logger -t BACKUP_VERIFY_FAIL "backup-verify: $FAILED project(s) failed integrity check"
    fi

    log_info "=== backup-verify.sh completed ==="
    rotate_log

    # Return non-zero if any failures
    [ "$FAILED" -eq 0 ]
}

main "$@"
