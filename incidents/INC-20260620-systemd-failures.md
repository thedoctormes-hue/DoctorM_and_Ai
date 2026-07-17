---
id: INC-20260620-systemd-failures
timestamp: "2026-06-20T00:00:00Z"
category: tech
type: bug
severity: medium
status: retired
agent: unknown
title: "Инцидент: systemd сервисы не запускаются (2026-06-20)"
owner: Бестия
resolution_plan: Проверить 3 failed systemd-юнита (dnsmasq, irqbalance, update-notifier-download); решить или пометить intentionally-disabled.
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Инцидент: systemd сервисы не запускаются (2026-06-20)

## Обнаружено
- **15:29 UTC** — heartbeat обнаружил ошибки в journalctl

## Затронутые сервисы
1. **myrmex-demo.service** — `Failed at step EXEC spawning /root/.nvm/versions/node/v22.22.3/bin/node: No such file or directory`
2. **myrmex-twa.service** — аналогичная ошибка (node v22.22.3 не найден)
3. **saas-api.service** — `Failed at step EXEC spawning /root/LabDoctorM/venv/bin/uvicorn: No such file or directory`

## Корневая причина
- Node.js v22.22.3 был удалён или перезаписан (текущая версия NVM: v24.16.0)
- venv uvicorn отсутствует или повреждён

## Статус
- 🔴 Требует вмешательства ЗавЛаба
- Сервисы в цикле рестарта (RestartSec срабатывает каждые ~5 сек)

## Рекомендации
- Пересоздать systemd unit-файлы с правильным путём к node (через nvm wrapper или системный node)
- Пересоздать venv для saas-api

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
