#!/bin/bash
# Мониторинг дискового пространства лаборатории
# ADR-039
# Алерт при >80%, критический при >90%

THRESHOLD_WARN=80
THRESHOLD_CRIT=90
LOG="/var/log/disk-monitor.log"
STATE_FILE="/tmp/disk-monitor-state"

# Получаем процент использования корневого раздела
USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
MOUNT="/"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

# Проверяем /tmp
TMP_USAGE=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
TMP_FILES=$(find /tmp -type f -mtime +1 2>/dev/null | wc -l)

# Проверяем /var/backups
BACKUP_SIZE=$(du -sh /var/backups 2>/dev/null | awk '{print $1}')
BACKUP_FILES=$(find /var/backups -type f -mtime +7 2>/dev/null | wc -l)

# Проверяем journal
JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+M' | head -1)

# Проверяем docker
DOCKER_RECLAIMABLE=$(docker system df 2>/dev/null | grep "Images" | awk '{print $5}')

# Формируем статус
log_msg "DISK: ${USAGE}% | /tmp: ${TMP_USAGE} (${TMP_FILES} old files) | backups: ${BACKUP_SIZE} (${BACKUP_FILES} old) | journal: ${JOURNAL_SIZE} | docker reclaimable: ${DOCKER_RECLAIMABLE}"

# Алерты
if [ "$USAGE" -ge "$THRESHOLD_CRIT" ]; then
    log_msg "CRITICAL: Disk usage ${USAGE}% >= ${THRESHOLD_CRIT}%"
    # Отправка алерта в Telegram (если настроен)
    if [ -f /root/LabDoctorM/scripts/disk-alert.sh ]; then
        bash /root/LabDoctorM/scripts/disk-alert.sh "CRITICAL" "${USAGE}%" "Disk CRITICAL: ${USAGE}% on ${MOUNT}"
    fi
elif [ "$USAGE" -ge "$THRESHOLD_WARN" ]; then
    log_msg "WARNING: Disk usage ${USAGE}% >= ${THRESHOLD_WARN}%"
    if [ -f /root/LabDoctorM/scripts/disk-alert.sh ]; then
        bash /root/LabDoctorM/scripts/disk-alert.sh "WARNING" "${USAGE}%" "Disk WARNING: ${USAGE}% on ${MOUNT}"
    fi
fi

# Сохраняем состояние
echo "usage=${USAGE} tmp=${TMP_USAGE} backups=${BACKUP_SIZE} journal=${JOURNAL_SIZE}" > "$STATE_FILE"
