---
id: INC-20260621-systemd-audit
timestamp: "2026-06-21T00:00:00Z"
category: tech
type: other
severity: medium
status: retired
agent: antcat
title: "Аудит systemd-сервисов — 2026-06-21 23:22 UTC"
resolution: Аудит systemd-сервисов проведён (2026-06-21); находки учтены в RUL-007/ops-дисциплине. Закрыт по факту.
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Аудит systemd-сервисов — 2026-06-21 23:22 UTC

## Методология
- Фактчекинг: каждый сервис проверен live через systemctl + запуск скриптов
- Сравнение с предыдущим состоянием (18 failed → 2 failed после действий antcat)

## Итоговый статус (2026-06-21 23:25 UTC)

### 🔴 REALLY FAILED (2) — падают каждый таймер-тик

**1. runtime-state-update.service**
- Причина: `/root/LabDoctorM/bin/runtime_state_builder.py` → NOT FOUND
- Таймер: каждые 15 мин → падение каждые 15 мин
- Действие: отключить сервис + таймер

**2. saas-api-health.service**
- Причина: `saas-api.service` не запущен (venv/uivorn NOT FOUND)
- Health check пытается рестартовать saas-api → не может → exit 1
- Таймер: каждые 5 мин → spam в syslog
- Действие: отключить health timer + saas-api до восстановления venv

### 🟡 INACTIVE, но таймеры тикают (6) — спамят failed при каждом тике

**3. backup-myrmex.service**
- Причина: `/root/LabDoctorM/scripts/backup-myrmex.sh` → NOT FOUND
- Скрипт существует: `/root/LabDoctorM/projects/DoctorM_and_Ai/scripts/backup-myrmex.sh`
- Симлинк не создан → unit указывает на неправильный путь
- Действие: создать симлинк ИЛИ обновить unit

**4-6. hype-daily, hype-observe, hype-orq**
- Причина: `/root/LabDoctorM/venv/bin/python` → NOT FOUND
- Скрипты проекта (`hype-pilot/channels/`) → NOT FOUND
- Весь hype-pilot проект удалён или перемещён
- Действие: отключить сервисы + таймеры

**7. context-api-reindex.service**
- Причина: `services/context-api/reindex_if_changed.py` → NOT FOUND
- Таймер: 03:30 UTC ежедневно → падение в 03:30
- context-api ранее признан избыточным (исследование Бестии 20.06)
- Действие: отключить сервис + таймер

### ✅ УЖЕ ОТКЛЮЧЕНЫ antcat (5)
- lab-index-parallel@main — disabled + inactive
- lab-index-seq@main — disabled + inactive
- lab-index-step@main — disabled + inactive
- lab-index@main — disabled + inactive
- lab-indexer@main — disabled + inactive

Примечание: таймеры для них НЕ отключены — будут запускать disabled сервисы (чужие failed)

### 🟢 РАБОТАЮТ (3 — Qwen pipeline, но бессмысленно)
- evolve-orchestrator — ✅ exited 0, работает
- self-evolve — ✅ exited 0, работает
- raven-patrol — ✅ exited 0, работает

Но: Qwen pipeline ранее признана мёртвой (238 инсайтов уже consolidated, работает вхолостую).
evolve-orchestrator и self-evolve запускают Qwen-скрипты → тратят CPU впустую.

### 🟢 РАБОТАЮТ (другие)
- artifact-aging — ✅ exited 0 (после того как скрипт починил аргументы)
- artifact-provenance — ✅ exited 0
- artifact-audit — timer работает
- artifact-health — timer работает
- artifact-stats — timer работает
- insights-consolidator — disabled
- lab-memory-* — stopped (one-shot, отработали)
- lab-write-chunks@main — stopped (one-shot, отработали)

## Рекомендации

### Немедленно (группа А — отключить мёртвые):
- runtime-state-update.service + .timer — stop + disable
- saas-api-health.service + .timer — stop + disable
- hype-daily.service + .timer — stop + disable
- hype-observe.service + .timer — stop + disable
- hype-orq.service + .timer — stop + disable
- context-api-reindex.service + .timer — stop + disable
- self-evolve.service + .timer — stop + disable (Qwen = мертв)
- evolve-orchestrator.service + .timer — stop + disable (нет инсайтов)
- таймеры lab-index-*@main — disable (сервисы уже disabled)

### На решение ЗавЛаба (группа Б):
- backup-myrmex — создать симлинк scripts/ → DoctorM_and_Ai/scripts/ ИЛИ обновить unit
- saas-api.service — восстанавливать venv или отключить полностью
- artifact-*, insights-consolidator — нужен ли Qwen pipeline вообще?
- Hype Pilot — восстанавливать проект или окончательно похоронить?

### Факты о системе:
- RAM: 7.8G total, 2.6G used, 4.8G available — OOM больше не актуален
- Swap: 1.5G/5.0G — есть запас
- Диск: 81% (45G/59G) — следить
- Docker: 7/7 Up, здоров
- Незапушенных коммитов: 0

## Примечание
Предыдущий инцидент (2026-06-20-systemd-failures.md) актуализирован.
Этот файл — полная замена.

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
