#!/usr/bin/env bash
#
# incident-drift-cron.sh — обёртка для ежедневного doc↔registry drift-чекa (ADR-0056/0057, PAT-019 I-19).
# Запускает bin/incident-drift-check.sh (READ-ONLY), пишет лог, возвращает non-zero при найденном
# рассинхроне (NOT_IN_REGISTRY / DRIFT) — чтобы systemd-service помечался failed и можно было алертить/CI-гейтить.
# Аналогия: incident-linter-cron.sh (ADR-0056 enforcement #2), но для связности doc↔registry.
#
set -uo pipefail

SCRIPT="/root/LabDoctorM/projects/DoctorM_and_Ai/bin/incident-drift-check.sh"
INC_DIR="/root/LabDoctorM/projects/DoctorM_and_Ai/incidents"
LOGDIR="/root/LabDoctorM/projects/DoctorM_and_Ai/logs/incident-drift"
mkdir -p "$LOGDIR"
RUN="$LOGDIR/$(date +%F)-$(date +%s).run"
LOG="$LOGDIR/$(date +%F).log"

"$SCRIPT" "$INC_DIR" 2>&1 | tee "$RUN" | tee -a "$LOG"
rc=${PIPESTATUS[0]}

# Скрипт report-only (всегда exit 0). Детектим рассинхрон по выводу прогона.
if grep -qE '\[NOT_IN_REGISTRY\]|DRIFT:' "$RUN"; then
  echo "[alert] drift detected — see $RUN" | tee -a "$LOG"
  exit 1   # failed => systemd-failure => видно в list-timers/status, можно алертить
fi
exit "$rc"
