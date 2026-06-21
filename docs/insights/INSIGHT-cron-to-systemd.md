---
name: cron-to-systemd
description: Cron мигрирован на systemd timers — 10+ активных таймеров.
type: insight
status: active
verified: 2026-06-17
source: cron-to-systemd-migration.md
---

# ⏰ Cron → Systemd Timers

## Состояние (подтверждено 2026-06-17)

Cron мигрирован на systemd timers. Активные таймеры:
- runtime-state-update.timer
- backup-myrmex.timer
- hype-orq.timer
- saas-api-health.timer
- pg-backup.timer
- raven-patrol.timer
- artifact-health.timer
- artifact-audit.timer
- artifact-stats.timer
- lab-monitoring.timer

crontab пуст.

## Почему это важно

- Systemd таймеры = логи, зависимости, управление через systemctl
- Единая точка управления всеми периодическими задачами
- Не нужно разбираться с crontab форматированием
