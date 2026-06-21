#!/bin/bash
# backup-myrmex.sh — внешний бэкап myrmex.json (дополнительный слой к in-process модулю)
set -euo pipefail

MYRMEX_FILE="/root/LabDoctorM/projects/myrmex-control/myrmex.json"
BACKUP_DIR="/var/backups/myrmex"
MAX_BACKUPS=24  # 24 часа

mkdir -p "$BACKUP_DIR"

if [ ! -f "$MYRMEX_FILE" ]; then
  echo "[backup] ERROR: myrmex.json not found: $MYRMEX_FILE"
  exit 1
fi

DATE=$(date -u +%Y-%m-%dT%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/auto-${DATE}.json"

cp "$MYRMEX_FILE" "$BACKUP_FILE"
echo "[backup] Created: $BACKUP_FILE ($(wc -c < "$BACKUP_FILE") bytes)"

# Ротация: оставляем последние N
cd "$BACKUP_DIR"
ls -t auto-*.json 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f
