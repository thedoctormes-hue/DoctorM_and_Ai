---
description: "CRON REGISTRY"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-06-18
status: active
---

# CRON_REGISTRY.md — Реестр автоматизации лаборатории

**Последнее обновление:** 2026-06-19 18:45 UTC
**Всего заданий:** 16 активных (3 отключены)
**Агенты с заданиями:** 7
**Настроен failureAlert:** 3 критичных задания
**Telegram groupPolicy:** disabled (19.06.2026)

---

## Сводка по статусам

- ✅ Стабильно работают: 5
- ⚠️ Падают: 1 (streikbrecher-dep-check, 4 ошибки подряд)
- 🔴 Отключены: 3 (artifact-insights-consolidate, artifact-factcheck, оба — скрипт удалён)
- 🆕 Ещё не запускались (idle): 12

---

## Mangust (4 задания)

### fallback-stats-4h
- **Расписание:** каждые 4 часа
- **Статус:** idle (ещё не запускался)
- **Назначение:** статистика fallback-ов моделей за последние 4 часа
- **Действия при сбое:** проверить логи gateway, упростить запрос

### filter-free-models-12h
- **Расписание:** каждые 12 часов
- **Статус:** ✅ ok (88s)
- **Назначение:** фильтрация бесплатных моделей OpenRouter
- **Действия при сбое:** проверить API-ключ OpenRouter

### free-api-hunter-scan
- **Расписание:** каждые 12 часов (было 30 мин, исправлено)
- **Статус:** ✅ ok (29s)
- **Назначение:** сканирование бесплатных API-провайдеров
- **Проблема:** hunter сам пышет в Telegram (404) — нужно убрать из hunter вызов Telegram API
- **Действия при сбое:** проверить путь /root/LabDoctorM/projects/free-api-hunter

### mangust-adr-scan
- **Расписание:** понедельник 10:00 MSK
- **Статус:** idle
- **Назначение:** анализ git history для создания ADR
- **Действия при сбое:** проверить доступ к git-репозиторию

---

## Dominika (5 заданий)

### artifact_refresh_daily
- **Расписание:** ежедневно 01:00 UTC
- **Статус:** ✅ ok (110s)
- **Назначение:** обновление артефактов artifact-pulse
- **Действия при сбое:** проверить systemd-сервис artifact-pulse, логи через journalctl

### factcheck_all_daily
- **Расписание:** ежедневно 02:00 UTC
- **Статус:** ✅ ok (225s)
- **Назначение:** ежедневная проверка фактов артефактов
- **Действия при сбое:** проверить конфигурацию artifact-pulse, запуск вручную через artifact-health

### dominika-cve-scan
- **Расписание:** ежедневно 10:00 MSK
- **Статус:** ✅ ok (52s)
- **Назначение:** поиск CVE для зависимостей лаборатории
- **Действия при сбое:** проверить pip audit, web_search

### artifact-factcheck
- **Расписание:** понедельник 06:00 MSK
- **Статус:** idle
- **Назначение:** еженедельный фактчекинг артефактов artifact-pulse
- **Действия при сбое:** проверить artifact_health.py, artifact_insights.py

### dominika-dependency-watch
- **Расписание:** понедельник 09:00 MSK
- **Статус:** idle
- **Назначение:** еженедельная проверка устаревших зависимостей
- **Действия при сбое:** проверить pip list --outdated, pip audit

---

## Raven (3 задания)

### Tavily Daily Usage Report
- **Расписание:** ежедневно 08:00 MSK
- **Статус:** idle (разблокирован 19.06 — allowUnsafeExternalContent)
- **Назначение:** ежедневный отчёт по использованию Tavily API
- **Действия при сбое:** проверить API-ключ Tavily, allowUnsafeExternalContent

### raven-tech-radar
- **Расписание:** среда 12:00 MSK
- **Статус:** idle
- **Назначение:** еженедельный Technology Radar (GitHub Trending, arXiv, HN)
- **Действия при сбое:** проверить web_search

### weekly-automation-audit
- **Расписание:** понедельник 08:00 MSK
- **Статус:** idle (создано 19.06.2026)
- **Назначение:** еженедельный сбор статистики по всем cron-заданиям лаборатории
- **Действия при сбое:** проверить openclaw cron list, упростить запрос

---

## Bestia (1 задание)

### bestia-health-check
- **Расписание:** ежедневно 08:00 MSK
- **Статус:** ✅ ok (93s)
- **Назначение:** ежедневный health check инфраструктуры (диск, RAM, CPU, сервисы)
- **Действия при сбое:** проверить systemctl, df, free

---

## Owl (2 задания)

### Автоочистка git-мусора
- **Расписание:** ежедневно 06:00 MSK
- **Статус:** idle
- **Назначение:** очистка stash, мёртвых веток, мусора в git
- **Действия при сбое:** проверить git-права

### owl-security-audit
- **Расписание:** понедельник 07:00 MSK
- **Статус:** idle
- **Назначение:** еженедельный аудит безопасности (секреты, права, токены)
- **Действия при сбое:** проверить grep-паттерны

---

## Antcat (1 задание)

### antcat-drift-detection
- **Расписание:** понедельник + четверг 06:00 MSK
- **Статус:** idle
- **Назначение:** детекция рассинхрона конфигураций (git vs реальность)
- **Действия при сбое:** проверить доступ к конфигам

---

## Kotolizator (1 задание)

### kotolizator-colony-report
- **Расписание:** понедельник 09:00 MSK
- **Статус:** idle
- **Назначение:** еженедельный отчёт по состоянию колонии агентов
- **Действия при сбое:** проверить sessions_list

---

## Streikbrecher (2 задания)

### streikbrecher-dep-check ⚠️ БЛОКЕР
- **Расписание:** вторник + пятница 11:00 MSK
- **Статус:** ❌ error (4 ошибки подряд, consecutiveErrors=4)
- **Назначение:** проверка и обновление зависимостей проектов
- **Проблема:** модель gpt-oss-120b:free не успевает за 180s cron-лимит. timeoutSeconds уже 300s — не поможет.
- **Решение:** сменить модель на быструю (nemotron-3-super), упростить промпт, убрать pip audit
- **Действия при сбое:** уведомить ЗавЛаба, передать Штрейкбрехеру

### Archive Cleanup Check
- **Расписание:** 24.06.2026 12:00 UTC (одноразовое)
- **Статус:** idle
- **Назначение:** напоминание проверить актуальность архива
- **Действия после выполнения:** удалить задание (deleteAfterRun)

---

## Потенциальное дублирование

- **dominika-dependency-watch** + **streikbrecher-dep-check** — оба проверяют pip audit/зависимости
- **factcheck_all_daily** + **artifact-factcheck** — оба фактчекинг артефактов
- **dominika-cve-scan** + **owl-security-audit** — оба проверяют безопасность

**Рекомендация:** разграничить зоны ответственности или объединить.

---

## TaskFlow (8 штук, все mirrored)

- startup-context-test → succeeded
- gastro-merge → ❌ failed
- Cross-analysis (инсайты + Context API) → succeeded
- Исследование проектов (antcat) → succeeded
- insights_queue.json fix → succeeded
- systemd-timer → succeeded
- insights-tests → succeeded
- orphan-linker → ❌ failed

**Требует внимания:** gastro-merge, orphan-linker — проверить причины падения.

---

## Реализовано (19.06.2026)

- **Еженедельный аудит автоматизации** — weekly-automation-audit (пн 08:00 MSK, raven) ✅
- **failureAlert** — настроен для 3 критичных заданий: streikbrecher-dep-check, bestia-health-check, dominika-cve-scan ✅

## Требует внимания

- **free-api-hunter**: hunter шлёт в Telegram (404), нужно убрать из hunter вызов Telegram API
- **TaskFlow**: gastro-merge и orphan-linker — failed, требуют разбора
- **Конфигурация**: 12 секретов в открытом виде (R-2, R-3), nginx без trustedProxies (R-1)
- **Модели**: все 9 агентов на owl-alpha, рекомендовано распределить (R-10)

## Решено (19.06.2026)

- streikbrecher-dep-check: модель → nemotron-3-super, промпт упрощён, timeout → 120s
- dominika-dependency-watch: отключена (дублировала dep-check)
- artifact-factcheck: отключена (скрипт удалён)
- cve-scan + security-audit: не дублирование, разные зоны — оставлено
- Telegram groupPolicy: disabled (явный запрет групп)
