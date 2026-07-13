#!/usr/bin/env bash
#
# incident-linter-cron.sh — обёртка для ежедневного запуска incident-linter.sh (systemd timer).
# Пишет итоговый отчёт в журнал (stdout->journal) и в ежедневный лог-файл.
# Сам линтер — read-only и ничего не удаляет/не переносит.
#
set -uo pipefail

SCRIPT="/root/LabDoctorM/projects/DoctorM_and_Ai/scripts/incident-linter.sh"
LOGDIR="/root/LabDoctorM/projects/DoctorM_and_Ai/logs/incident-linter"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/$(date +%F).log"

"$SCRIPT" 2>&1 | tee -a "$LOG"
# линтер по умолчанию выходит 0 (report-only); --strict вернул бы 1 при нарушениях
exit ${PIPESTATUS[0]}
