#!/bin/bash
# openclaw-backup.sh — бэкап критичных данных OpenClaw на Яндекс Диск
# Запуск: каждые 2 часа через systemd-таймер
# Ротация: автоудаление бэкапов старше 24 часов
# Формат: папка с датой/временем, файлы загружаются по одному

set -euo pipefail

BACKUP_BASE="/colony/backups/openclaw"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REMOTE_DIR="$BACKUP_BASE/$TIMESTAMP"
YANDEX_SH="/root/LabDoctorM/projects/DoctorM_and_Ai/bin/yandex.sh"
RETENTION_HOURS=24
LOG="/root/LabDoctorM/logs/openclaw-backup.log"

log() { echo "[$(date -u +%FT%TZ)] $1" | tee -a "$LOG"; }

log "Начинаю бэкап → $REMOTE_DIR"

# --- Создаём структуру папок на Диске ---
$YANDEX_SH disk mkdir "$REMOTE_DIR" 2>/dev/null || true
$YANDEX_SH disk mkdir "$REMOTE_DIR/workspaces" 2>/dev/null || true
$YANDEX_SH disk mkdir "$REMOTE_DIR/skills" 2>/dev/null || true
$YANDEX_SH disk mkdir "$REMOTE_DIR/state" 2>/dev/null || true
log "✅ Структура папок создана"

# --- Загружаем файлы на Диск ---

# 1. openclaw.json
if [ -f /root/.openclaw/openclaw.json ]; then
  $YANDEX_SH disk put /root/.openclaw/openclaw.json "$REMOTE_DIR/openclaw.json"
  log "✅ openclaw.json"
fi

# 2. secrets.json
if [ -f /root/.openclaw/secrets.json ]; then
  $YANDEX_SH disk put /root/.openclaw/secrets.json "$REMOTE_DIR/secrets.json"
  log "✅ secrets.json"
fi

# 3. workspaces/ — каждый workspace отдельно
if [ -d /root/.openclaw/workspaces ]; then
  for ws in /root/.openclaw/workspaces/*/; do
    ws_name=$(basename "$ws")
    $YANDEX_SH disk mkdir "$REMOTE_DIR/workspaces/$ws_name" 2>/dev/null || true
    # Загружаем файлы рекурсивно
    for file in $(find "$ws" -type f 2>/dev/null); do
      rel_path="${file#$ws}"
      $YANDEX_SH disk put "$file" "$REMOTE_DIR/workspaces/$ws_name/$rel_path" 2>/dev/null || log "⚠️ Не удалось: $file"
    done
    log "✅ workspaces/$ws_name"
  done
fi

# 4. skills/ — каждый скил отдельно
if [ -d /root/.openclaw/skills ]; then
  for skill in /root/.openclaw/skills/*/; do
    skill_name=$(basename "$skill")
    $YANDEX_SH disk mkdir "$REMOTE_DIR/skills/$skill_name" 2>/dev/null || true
    for file in $(find "$skill" -type f 2>/dev/null); do
      rel_path="${file#$skill}"
      $YANDEX_SH disk put "$file" "$REMOTE_DIR/skills/$skill_name/$rel_path" 2>/dev/null || log "⚠️ Не удалось: $file"
    done
    log "✅ skills/$skill_name"
  done
fi

# 5. state/
if [ -d /root/.openclaw/state ]; then
  $YANDEX_SH disk mkdir "$REMOTE_DIR/state" 2>/dev/null || true
  for file in $(find /root/.openclaw/state -type f 2>/dev/null); do
    rel_path="${file#/root/.openclaw/state/}"
    $YANDEX_SH disk put "$file" "$REMOTE_DIR/state/$rel_path" 2>/dev/null || log "⚠️ Не удалось: $file"
  done
  log "✅ state/"
fi

# --- Ротация: удаляем бэкапы старше RETENTION_HOURS ---
log "Ротация: удаляю бэкапы старше $RETENTION_HOURS часов..."
BACKUP_COUNT=0
DELETED_COUNT=0
# Используем process substitution вместо pipe чтобы избежать subshell
while IFS= read -r backup_name; do
  # Пропускаем пустые строки
  [ -z "$backup_name" ] && continue
  # Извлекаем timestamp из имени папки
  backup_date="${backup_name%%_*}"  # YYYY-MM-DD
  backup_time="${backup_name##*_}"   # HH-MM-SS
  # Конвертируем в epoch
  backup_epoch=$(date -u -d "${backup_date} ${backup_time:0:2}:${backup_time:3:2}:${backup_time:5:2}" +%s 2>/dev/null || echo 0)
  if [ "$backup_epoch" -eq 0 ]; then
    log "  ⚠️ Не удалось распарсить: $backup_name (пропускаю)"
    continue
  fi
  now_epoch=$(date -u +%s)
  age_hours=$(( (now_epoch - backup_epoch) / 3600 ))
  BACKUP_COUNT=$((BACKUP_COUNT + 1))
  if [ "$age_hours" -gt "$RETENTION_HOURS" ]; then
    log "  Удаляю: $backup_name (${age_hours}ч)"
    $YANDEX_SH disk del "$BACKUP_BASE/$backup_name" 2>/dev/null || log "  ⚠️ Не удалось удалить: $backup_name"
    DELETED_COUNT=$((DELETED_COUNT + 1))
  fi
done < <($YANDEX_SH disk ls "$BACKUP_BASE" 2>/dev/null | grep -oP '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}' || true)
log "Ротация завершена: проверено $BACKUP_COUNT, удалено $DELETED_COUNT"

log "✅ Бэкап завершён: $REMOTE_DIR"
