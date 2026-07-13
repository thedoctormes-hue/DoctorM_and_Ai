#!/bin/bash
# backup-policy-audit.sh — Еженедельный аудит backup-политики
# Проверяет .backupignore, cron/timer, ротацию логов
# Отчёт пишет в /var/log/backup-policy-audit.log

set -euo pipefail

# ─── Конфигурация ───────────────────────────────────────────────
PROJECTS_DIR="/root/LabDoctorM/projects"
LOGFILE="/var/log/backup-policy-audit.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
REPORT_FILE="/var/log/backup-policy-audit-report.txt"
WARNINGS=0
ERRORS=0

# Критические пути, которые НЕ должны быть исключены из бэкапа
CRITICAL_PATHS=(
    ".git/objects/"
    ".git/hooks/"
    ".git/HEAD"
    ".git/refs/"
    ".git/packed-refs"
)

# ─── Логирование ────────────────────────────────────────────────
log() {
    echo "[$TIMESTAMP] $*" >> "$LOGFILE"
}

report() {
    echo "$*" >> "$REPORT_FILE"
}

# ─── Проверка .backupignore для одного проекта ─────────────────
check_backupignore() {
    local project_dir="$1"
    local project_name="$2"
    local backupignore="$project_dir/.backupignore"

    # 1. .backupignore существует?
    if [ ! -f "$backupignore" ]; then
        report "  [WARN] $project_name — .backupignore missing"
        log "[WARN] $project_name — .backupignore missing"
        ((WARNINGS++))
        return
    fi

    # 2. .backupignore не пустой?
    if [ ! -s "$backupignore" ]; then
        report "  [WARN] $project_name — .backupignore is empty"
        log "[WARN] $project_name — .backupignore is empty"
        ((WARNINGS++))
        return
    fi

    # 3. Проверяем что критические пути НЕ исключены
    local violations=()
    for critical in "${CRITICAL_PATHS[@]}"; do
        # Проверяем точное совпадение и glob-паттерны
        if grep -qE "(^|/)${critical}(|/|$)" "$backupignore" 2>/dev/null || \
           grep -qE "\*.*${critical}" "$backupignore" 2>/dev/null || \
           grep -qE "^${critical//\./\\.}" "$backupignore" 2>/dev/null; then
            violations+=("$critical")
        fi
    done

    if [ ${#violations[@]} -gt 0 ]; then
        report "  [ERROR] $project_name — .backupignore excludes critical paths: ${violations[*]}"
        log "[ERROR] $project_name — .backupignore excludes critical: ${violations[*]}"
        ((ERRORS++))
    else
        report "  [OK] $project_name — .backupignore present, critical paths protected"
        log "[OK] $project_name — .backupignore valid"
    fi
}

# ─── Проверка cron/timer бэкапов ───────────────────────────────
check_backup_timers() {
    report ""
    report "─── Backup Cron/Timer Status ───"
    log "Checking backup cron/timers..."

    # Проверяем systemd timers
    local timer_found=false
    if command -v systemctl &>/dev/null; then
        # Ищем все таймеры связанные с backup
        local timers
        timers=$(systemctl list-timers --all 2>/dev/null | grep -i "backup\|labdoctor" || true)

        if [ -n "$timers" ]; then
            timer_found=true
            report "  [OK] Systemd timers found:"
            while IFS= read -r line; do
                report "    $line"
            done <<< "$timers"

            # Проверяем что таймеры активны (не failed)
            local failed_timers
            failed_timers=$(systemctl list-units --state=failed --type=timer 2>/dev/null | grep -i "backup\|labdoctor" || true)
            if [ -n "$failed_timers" ]; then
                report "  [ERROR] Failed timers detected:"
                while IFS= read -r line; do
                    report "    $line"
                done <<< "$failed_timers"
                log "[ERROR] Failed backup timers: $failed_timers"
                ((ERRORS++))
            else
                report "  [OK] No failed backup timers"
                log "[OK] All backup timers healthy"
            fi
        fi
    fi

    # Проверяем cron
    local cron_found=false
    if command -v crontab &>/dev/null; then
        local cron_entries
        cron_entries=$(crontab -l 2>/dev/null | grep -i "backup\|labdoctor" || true)

        if [ -n "$cron_entries" ]; then
            cron_found=true
            report "  [OK] Cron backup entries found:"
            while IFS= read -r line; do
                report "    $line"
            done <<< "$cron_entries"
        fi
    fi

    # Проверяем /etc/cron.d/
    if ls /etc/cron.d/*labdoctor* /etc/cron.d/*backup* 2>/dev/null | grep -q .; then
        cron_found=true
        report "  [OK] /etc/cron.d/ backup entries found"
    fi

    if [ "$timer_found" = false ] && [ "$cron_found" = false ]; then
        report "  [WARN] No backup timers or cron entries found"
        log "[WARN] No backup schedule detected"
        ((WARNINGS++))
    fi
}

# ─── Проверка ротации disk-usage.log ──────────────────────────
check_log_rotation() {
    report ""
    report "─── Log Rotation Status ───"
    log "Checking log rotation..."

    local disk_usage_log="/var/log/disk-usage.log"

    if [ ! -f "$disk_usage_log" ]; then
        report "  [WARN] $disk_usage_log does not exist"
        log "[WARN] disk-usage.log not found"
        ((WARNINGS++))
        return
    fi

    local size
    size=$(stat -c%s "$disk_usage_log" 2>/dev/null || echo 0)
    local lines
    lines=$(wc -l < "$disk_usage_log" 2>/dev/null || echo 0)

    # Проверяем что logrotate настроен для disk-usage.log
    if [ -f "/etc/logrotate.d/disk-usage" ] || grep -q "disk-usage" /etc/logrotate.conf 2>/dev/null; then
        report "  [OK] logrotate configured for disk-usage.log"
        log "[OK] logrotate configured for disk-usage.log"
    else
        report "  [WARN] No logrotate config found for disk-usage.log (size: ${size}B, lines: ${lines})"
        log "[WARN] disk-usage.log not in logrotate config (size: ${size}B, lines: ${lines})"
        ((WARNINGS++))
    fi

    # Предупреждение если лог слишком большой (>10MB)
    if [ "$size" -gt 10485760 ]; then
        report "  [WARN] disk-usage.log is large: $(( size / 1024 / 1024 ))MB"
        log "[WARN] disk-usage.log size: ${size}B"
        ((WARNINGS++))
    fi
}

# ─── Проверка что бэкапы вообще существуют ────────────────────
check_backups_exist() {
    report ""
    report "─── Backup Existence Check ───"
    log "Checking backup existence..."

    local projects_with_backup=0
    local projects_without_backup=0

    for project_dir in "$PROJECTS_DIR"/*/; do
        [ -d "$project_dir" ] || continue
        local name
        name=$(basename "$project_dir")
        [[ "$name" == .* ]] && continue

        local backup_dir="/root/LabDoctorM/backups/$name"
        if [ -d "$backup_dir" ] && [ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]; then
            ((projects_with_backup++))
        else
            ((projects_without_backup++))
            report "  [WARN] $name — no backups found"
            log "[WARN] $name — no backups"
        fi
    done

    report ""
    report "  Projects with backup: $projects_with_backup"
    report "  Projects without backup: $projects_without_backup"
    log "Backup existence: $projects_with_backup with, $projects_without_backup without"

    if [ "$projects_without_backup" -gt 0 ]; then
        ((WARNINGS++))
    fi
}

# ─── Основная логика ────────────────────────────────────────────
main() {
    log "=== backup-policy-audit.sh started ==="

    report "═══════════════════════════════════════════════════"
    report "  LabDoctorM Backup Policy Audit Report"
    report "  Generated: $TIMESTAMP"
    report "═══════════════════════════════════════════════════"
    report ""

    # ─── 1. Проверка .backupignore для всех проектов ─────────
    report "─── .backupignore Checks ───"
    log "Checking .backupignore for all projects..."

    for project_dir in "$PROJECTS_DIR"/*/; do
        [ -d "$project_dir" ] || continue
        local name
        name=$(basename "$project_dir")
        [[ "$name" == .* ]] && continue
        check_backupignore "$project_dir" "$name"
    done

    # ─── 2. Проверка cron/timer ───────────────────────────────
    check_backup_timers

    # ─── 3. Проверка ротации disk-usage.log ──────────────────
    check_log_rotation

    # ─── 4. Проверка существования бэкапов ────────────────────
    check_backups_exist

    # ─── Итоговый отчёт ───────────────────────────────────────
    report ""
    report "═══════════════════════════════════════════════════"
    report "  Summary: $ERRORS errors, $WARNINGS warnings"
    report "═══════════════════════════════════════════════════"

    log "=== Summary: $ERRORS errors, $WARNINGS warnings ==="
    log "=== backup-policy-audit.sh completed ==="

    # Ротация лога
    if [ -f "$LOGFILE" ] && [ "$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)" -gt 5000 ]; then
        tail -500 "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"
    fi

    # Return non-zero if errors found
    [ "$ERRORS" -eq 0 ]
}

main "$@"
