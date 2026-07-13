#!/usr/bin/env bash
#
# git-hygiene-linter-cron.sh — обёртка для ежедневного запуска git-hygiene-linter.sh (systemd timer).
# Пишет итоговый отчёт в журнал (stdout->journal) и в ежедневный лог-файл.
# Сам линтер — read-only и ничего не коммитит/не удаляет/не пушит.
#
set -uo pipefail

SCRIPT="/root/LabDoctorM/projects/DoctorM_and_Ai/scripts/git-hygiene-linter.sh"
LOGDIR="/root/LabDoctorM/projects/DoctorM_and_Ai/logs/git-hygiene-linter"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/$(date +%F).log"

"$SCRIPT" 2>&1 | tee -a "$LOG"
# report-only: выходим с кодом линтера (0 — чисто, 1 — есть грязные деревья при --strict)
exit ${PIPESTATUS[0]}
