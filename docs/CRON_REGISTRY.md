# CRON_REGISTRY.md — Реестр cron-заданий лаборатории

Последнее обновление: 2026-06-22 00:54 UTC

Активные задания: 3
Отключены: 0
Последний аудит: 2026-06-22 (raven)
Активных агентов: 9 (antcat, bestia, dominika, kotolizator, mangust, owl, raven, streikbrecher + main)

## Отключённые сервисы (2026-06-22)

- `lab-index-parallel@main` — oneshot, выполнился, отключён
- `lab-index-seq@main` — oneshot, выполнился, отключён
- `lab-index-step@main` — oneshot, выполнился, отключён
- `lab-indexer@main` — oneshot, выполнился, отключён
- `lab-memory-force@main` — oneshot, выполнился, отключён
- `lab-memory-index@main` — oneshot, выполнился, отключён
- `lab-write-chunks@main` — oneshot, выполнился, отключён
- `saas-api-health` — мониторинг над failed saas-api, отключён
- `context-api-reindex` — скрипт удалён, отключён
- `backup-myrmex` — static, скрипт удалён, остановлен
- `hype-daily` — static, скрипт удалён, остановлен
- `hype-observe` — static, скрипт удалён, остановлен
- `hype-orq` — disabled, скрипт удалён, отключён
- `hype-promo` — static, скрипт удалён, остановлен
- `runtime-state-update` — static, скрипт удалён, остановлен

---

## raven — Tavily Daily Usage Report
- **ID:** `2af4012e-b041-45df-bbf0-e8d01ce182d2`
- **Расписание:** ежедневно 08:00 MSK
- **Target:** isolated
- **Статус:** ✅ активен
- **Последний запуск:** ok (47s, доставлено)
- **Ошибок подряд:** 0
- **Что делает:** ежедневный отчёт по юседжу Tavily API → Telegram
- **Создан:** 2026-06-17

---

## raven — weekly-automation-audit
- **ID:** `581a69a9-7c89-455e-8634-a836a0161895`
- **Расписание:** понедельник 08:00 MSK
- **Target:** isolated
- **Статус:** ✅ активен
- **Последний запуск:** ожидает (создание будущего понедельника)
- **Ошибок подряд:** 0
- **Что делает:** еженедельный аудит всех cron-заданий лаборатории → Telegram
- **Создан:** 2026-06-17

---

## raven — raven-tech-radar
- **ID:** `0cba16ce-92ee-433c-8d39-ca258cd850d9`
- **Расписание:** среда 12:00 MSK
- **Target:** isolated
- **Статус:** ✅ активен
- **Последний запуск:** ожидает (не было среды с создания)
- **Ошибок подряд:** 0
- **Что делает:** GitHub Trending + arXiv + HN → Technology Radar → Telegram
- **Создан:** 2026-06-17
