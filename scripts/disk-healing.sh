#!/bin/bash
# disk-healing.sh — Автоматическое исправление проблем с дисками
# Запуск: ежедневно через systemd timer или cron
# Идемпотентный, безопасный, логирует каждое действие

set -euo pipefail

# ─── Конфигурация ───────────────────────────────────────────────
LOGFILE="/var/log/disk-healing.log"
THRESHOLD_WARNING=85    # Начинаем чистку
THRESHOLD_CRITICAL=90   # Дополнительная оптимизация логов
THRESHOLD_EMERGENCY=95  # Уведомление администратора
ADMIN_EMAIL="${ADMIN_EMAIL:-root@localhost}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')

# ─── Функции логирования ────────────────────────────────────────
log() {
    echo "[$TIMESTAMP] $*" >> "$LOGFILE"
    logger -t DISK_HEALING "$*"
}

log_info()  { log "[INFO] $*"; }
log_warn()  { log "[WARN] $*"; }
log_error() { log "[ERROR] $*"; }

# ─── Получение текущего использования ──────────────────────────
get_disk_usage() {
    local usage
    usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    echo "${usage:-0}"
}

get_disk_free() {
    df -h / | tail -1 | awk '{print $4}'
}

# ─── 1. Очистка /tmp (безопасные паттерны) ──────────────────────
clean_tmp() {
    log_info "Starting /tmp cleanup..."

    # Временные файлы старше 24 часов (исключаем socket-файлы)
    find /tmp -mindepth 1 -type f -mtime +1 -delete 2>/dev/null || true

    # Go build cache
    find /tmp -mindepth 1 -type d -name 'go-build*' -exec rm -rf {} + 2>/dev/null || true

    # Node compile cache
    find /tmp -mindepth 1 -type d -name 'node-compile-cache' -exec rm -rf {} + 2>/dev/null || true

    # Python temp build envs
    find /tmp -mindepth 1 -type d -name 'pip-build-env-*' -exec rm -rf {} + 2>/dev/null || true
    find /tmp -mindepth 1 -type d -name 'tmp*' -mtime +1 -exec rm -rf {} + 2>/dev/null || true

    # Архивы в /tmp
    find /tmp -mindepth 1 -type f -name '*.tar.*' -mtime +1 -delete 2>/dev/null || true

    log_info "/tmp cleanup completed"
}

# ─── 2. Очистка Go cache ───────────────────────────────────────
clean_go_cache() {
    log_info "Cleaning Go cache..."

    if command -v go &>/dev/null; then
        go clean -cache 2>/dev/null || true
        go clean -testcache 2>/dev/null || true
        go clean -modcache 2>/dev/null || true
        log_info "Go cache cleaned"
    else
        # Даже если go не в PATH, чистим известные директории
        rm -rf /root/go/pkg/mod/cache/download 2>/dev/null || true
        rm -rf /tmp/go-build* 2>/dev/null || true
        log_info "Go cache directories cleaned (go binary not found, cleaned dirs directly)"
    fi
}

# ─── 3. Очистка Docker build cache ─────────────────────────────
clean_docker_cache() {
    log_info "Cleaning Docker build cache..."

    if command -v docker &>/dev/null && docker info &>/dev/null; then
        # Только build cache, НЕ образы и НЕ контейнеры
        docker builder prune -f --filter "until=168h" 2>/dev/null || true
        log_info "Docker build cache cleaned"
    else
        log_info "Docker not available, skipping"
    fi
}

# ─── 4. Оптимизация логов (порог >90%) ────────────────────────
optimize_logs() {
    log_info "Optimizing system logs..."

    # Journal vacuum — оставляем последние 7 дней или 500M
    if command -v journalctl &>/dev/null; then
        journalctl --vacuum-time=7d 2>/dev/null || true
        journalctl --vacuum-size=500M 2>/dev/null || true
        log_info "Journal vacuum completed"
    fi

    # Ротация syslog
    if command -v logrotate &>/dev/null; then
        logrotate -f /etc/logrotate.conf 2>/dev/null || true
        log_info "Logrotate forced"
    fi

    # Очистка старых логов в /var/log
    find /var/log -name '*.gz' -mtime +30 -delete 2>/dev/null || true
    find /var/log -name '*.old' -mtime +30 -delete 2>/dev/null || true
    find /var/log -name '*-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' -mtime +30 -delete 2>/dev/null || true

    log_info "Log optimization completed"
}

# ─── 5. Очистка Docker dangling images ─────────────────────────
clean_docker_dangling() {
    log_info "Removing dangling Docker images..."

    if command -v docker &>/dev/null && docker info &>/dev/null; then
        docker image prune -f 2>/dev/null || true
        # Также удаляем неиспользуемые volumes
        docker volume prune -f 2>/dev/null || true
        log_info "Docker dangling images/volumes cleaned"
    fi
}

# ─── 6. Уведомление администратора (>95%) ──────────────────────
notify_admin() {
    local pct="$1"
    local free="$2"
    local subject="[CRITICAL] LabDoctorM disk usage: ${pct}% (free: ${free})"
    local body="Server LabDoctorM root partition is at ${pct}% (${free} free).

Automatic cleanup has been performed, but manual intervention may be needed.

Top space consumers:
$(du -sh /root 2>/dev/null | head -1)
$(du -sh /tmp 2>/dev/null | head -1)
$(du -sh /var/log 2>/dev/null | head -1)

Timestamp: $TIMESTAMP"

    log_warn "Sending admin notification: $subject"

    # Попытка отправить через mail
    if command -v mail &>/dev/null; then
        echo "$body" | mail -s "$subject" "$ADMIN_EMAIL" 2>/dev/null || true
    fi

    # Попытка через systemd-cat для journald
    echo "$body" | systemd-cat -t DISK_HEALING -p emerg 2>/dev/null || true

    # Запись в wall для залогиненных пользователей
    echo "WARNING: $subject" | wall 2>/dev/null || true
}

# ─── Ротация собственного лога ──────────────────────────────────
rotate_own_log() {
    if [ -f "$LOGFILE" ] && [ "$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)" -gt 5000 ]; then
        tail -500 "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"
        log_info "Own log rotated (kept last 500 lines)"
    fi
}

# ─── Основная логика ────────────────────────────────────────────
main() {
    log_info "=== disk-healing.sh started ==="

    local pct
    pct=$(get_disk_usage)
    local free
    free=$(get_disk_free)

    log_info "Current disk usage: ${pct}%, free: ${free}"

    # Проверка что pct — число
    if ! [[ "$pct" =~ ^[0-9]+$ ]]; then
        log_error "Failed to parse disk usage: got '$pct'"
        exit 1
    fi

    # Порог 1: >85% — базовая очистка
    if [ "$pct" -gt "$THRESHOLD_WARNING" ]; then
        log_warn "Disk usage ${pct}% > ${THRESHOLD_WARNING}% threshold, starting cleanup"
        clean_tmp
        clean_go_cache
        clean_docker_cache
    fi

    # Порог 2: >90% — оптимизация логов
    if [ "$pct" -gt "$THRESHOLD_CRITICAL" ]; then
        log_warn "Disk usage ${pct}% > ${THRESHOLD_CRITICAL}% threshold, optimizing logs"
        optimize_logs
        clean_docker_dangling
    fi

    # Порог 3: >95% — уведомление администратора
    if [ "$pct" -gt "$THRESHOLD_EMERGENCY" ]; then
        log_error "Disk usage ${pct}% > ${THRESHOLD_EMERGENCY}% threshold, notifying admin"
        notify_admin "$pct" "$free"
    fi

    # Показываем результат
    local new_pct
    new_pct=$(get_disk_usage)
    local new_free
    new_free=$(get_disk_free)
    log_info "After cleanup: ${new_pct}% used, ${new_free} free (was ${pct}% / ${free})"

    # Ротация своего лога
    rotate_own_log

    log_info "=== disk-healing.sh completed ==="
}

main "$@"
