#!/bin/bash
# Daily backup with 7-day rotation
set -euo pipefail

BACKUP_DIR="/root/LabDoctorM/backups/daily"
RETENTION=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

tar czf "$BACKUP_FILE" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='.venv' \
    --exclude='*.pyc' \
    -C /root/LabDoctorM \
    openclaw.json \
    projects/ \
    workspaces/ \
    scripts/ \
    config/ \
    2>/dev/null || true

# Rotate old backups
ls -t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | tail -n +$((RETENTION + 1)) | xargs -r rm -f

echo "[$(date)] Backup saved: $BACKUP_FILE"
echo "[$(date)] Size: $(du -h "$BACKUP_FILE" | cut -f1)"
