---
description: "💎 Золотые инсайты LabDoctorM"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-09
status: active
---
# 💎 Золотые инсайты LabDoctorM

*Выжимка из 26 MD-файлов. Только ценное. Обновлено: 2026-05-08.*

---

## 🏗️ Архитектура и инфраструктура

### OpenClawBox — Freemium LLM Aggregator
- **Концепция**: агрегатор бесплатных LLM API с автопереключением при исчерпании лимитов
- **6 слабых мест**: региональные блокировки, динамические лимиты, нет circuit breaker, нет кэша, один аккаунт, не учитывается размер ответа
- **Решения**: IP-detection → fallback, exponential backoff, Redis semantic cache, pool rotation, TPM tracking с резервом 20%
- **Free tier providers**: Google Gemini (15 RPM, 1M TPM), Groq (30 RPM, 6K TPM), OpenRouter :free (5-10 RPM), Together AI ($50-100 credits), Mistral (Apache 2.0)
- **Монетизация**: Free (2K req/day) → Pro $9.99 (10K) → Team $29.99 (100K)
- **Источник**: `infra/OPENCLAW_ARCH.md`

### OpenRouter Caching
- **Ключевой принцип**: детерминированные запросы = cache HIT = бесплатно
- **Обязательно фиксировать**: temperature (0), messages, model, max_tokens, top_p
- **Цель**: cache HIT rate > 70%, экономия > $50/мес, скорость < 500ms для повторов
- **Источник**: `infra/OPENROUTER_CACHE.md`

### GitHub Watch Strategy
- **Permanent watch**: QwenLM/qwen-code (24.1k), XTLS/Xray-core (38.1k), modelcontextprotocol/python-sdk (22.9k)
- **Внимание**: starlette переехал с encode/ → Kludex/
- **5 публичных репозиториев** под thedoctormes-hue
- **Источник**: `infra/GITHUB_SCAN.md`

### Systemd Timers
- **8 лабораторных таймеров**: evolution (2x/день), archive (30 мин), monitor (5-10 мин), llmevangelist (09:00), backup (03:00), xray-healthcheck (5 мин), tmp-cleanup (30 мин)
- **Источник**: `infra/SYSTEMD_TIMERS.md`

---

## 💰 Коммерция и B2B

### Позиционирование
- **Главная фраза**: "AI системы которые работают пока вы спите"
- **УТП**: self-evolving система с автономными AI-агентами
- **НЕ продаём**: ИИ как инструмент, автоматизация ради автоматизации, эксперименты
- **Продаём**: production-grade результаты с метриками
- **Источник**: `commercial/B2B_POSITIONING.md`

### Прайс-лист
| Пакет | Цена | Срок |
|-------|------|------|
| Аудит | 50-150к ₽ | 1-2 недели |
| Под ключ | от 300к ₽ | 4-6 недель |
| Консалтинг | 5-15к ₽/час | от 2 часов |
| AntColony Старт | 200к ₽ | — |
| AntColony Про | 500к ₽ | — |
| AntColony Enterprise | от 1 млн ₽ | — |
- **Источник**: `commercial/PRICE_LIST.md`

### Холодные письма — последовательность
1. Пн: Первое письмо (аудит)
2. Чт: Follow-up + кейс
3. Вт+1: История успеха
4. Пт+1: Приглашение на демо
- **Метрики**: 30% открываемость, 5% ответы, 1% закрытие
- **Источник**: `commercial/COLD_EMAIL.md`

### ROI для клиники (полипы)
| Показатель | До AI | После AI |
|------------|-------|----------|
| Время на колоноскопию | 30 мин | 5 мин |
| Точность | 80% | 96% |
| Пропущенные полипы | 25% | 2% |
| **Экономия/год** | — | **2-5 млн ₽** |
- **Источник**: `commercial/POLYP_DETECTION.md`

---

## 📝 Контент-стратегия

### Расписание публикаций
| Время | Формат | Платформы |
|-------|--------|-----------|
| 08:00 | Daily Digest | Telegram, TenChat |
| 12:00 | Quick Take | Telegram, TenChat |
| 19:00 | Deep Dive | Хабр + анонс в Telegram |

### Адаптация одного материала под 3 платформы
- **Telegram**: 3 строки + CTA + хештеги
- **TenChat**: 150 слов + ROI + экспертная формулировка
- **Хабр**: 1500+ слов, техническое руководство, метрики до/после

### ТОП-10 тем для IT-аудитории (май 2026)
1. Автономные AI-агенты (100K+)
2. CI/CD optimization (80K+)
3. Security audit / утечки токенов (70K+)
4. Монетизация AI-агентов (40K+)
5. VPN/Networking / XHTTP/REALITY (50K+)
6. Автоматический code review (45K+)
7. Python: aiogram, FastAPI (35K+)
8. React: Safari fixes, UI/UX (30K+)
9. Open Source кейсы (25K+)
10. Автоматизация workflow (40K+)

### Метрики успеха
- Telegram: 1000+ просмотров/пост
- TenChat: 500+ просмотров/пост
- Хабр: 5000+ просмотров/статья
- Вовлеченность: 5%+ от охвата
- **Источник**: `content/CONTENT_STRATEGY.md`

---

## 🔍 Аудит проектов (2026-05-06)

### Сводка
- **14 проверено**, 4 не найдено (💀)
- **6 без README** 🔴
- **5 без remote** ⚠️
- **2 полностью работают** ✅ (llm-evangelist, kotolizator)

### Мёртвые проекты
- protocol-bot — не существует
- zprr-tracker — не существует

### Критические проблемы
- 6 проектов без README
- 5 проектов без git remote
- Дубликаты: myrmex-dashboard (3 копии), .lab/ (параллельная структура)
- **Источник**: `strategy/AUDIT_2026_FULL.md`

---

## 🎯 Ключевые решения и паттерны

### Что работает
1. **Multi-agent оркестрация** — 3 агента (Кот, Муравей, ЗавЛаб) с авто-балансировкой по весу
2. **Session Start протокол** — автоматический старт сессии через kanban API
3. **Content Pipeline** — 1-3 поста/день с адаптацией под платформы
4. **OpenRouter caching** — детерминированные запросы = 70%+ cache HIT

### Что не работало (и было исправлено)
1. **Дубликаты** — 3 копии myrmex-dashboard удалены
2. **Параллельная структура .lab/** — удалена
3. **Мёртвый kanban.service** — удалён (хардкод ключа)
4. **nginx конфликт** — убран дублирующий server_name
5. **tokens.env в корне** — удалён (безопасность)
6. **Мёртвые decompose agents** — удалены (не подключены к бэкенду)

### Архитектурные принципы
- **Myrmex Command — НЕ ТРОГАТЬ** — критическая оркестрация
- **Данные в одном месте** — evolution_backlog.json
- **Ключи в shared/.env** — не в коде, не в git
- **Фронт деплоится через nginx** — npm build → dist/ → /var/www/html/dashboard-react/

## 🛠️ Текущие инсайты

* **INSIGHT-git-identity-race** – race condition в git author, решено  + pre‑commit hook.
* **INSIGHT-worktree-isolation** – каждый агент в отдельном worktree, изоляция веток.
* **INSIGHT-branch-discipline** – ветки только от , имена .
* **INSIGHT-sw-cache-stale-ui** – Service Worker кэширует старый UI, обновление CACHE_NAME обязательно.
* **INSIGHT-reference-parsing** – парсинг внешних сайтов через .
* **INSIGHT-no-alarm-on-startup** – не кричать алерты при старте сессии.
* **INSIGHT-raven-scope** – Ворон = патруль внешнего мира, не швейцарский нож.
* **INSIGHT-hype-pilot** – обзор проекта Hype Pilot, контент‑машина.
* **INSIGHT-agent-names** – канонические имена агентов и их email.
* **INSIGHT-project-structure** – каждый проект отдельный репозиторий, не монорепо.
* **INSIGHT-cron-to-systemd** – миграция cron → systemd timers.
* **INSIGHT-shell-death** –  падает при отсутствии worktree, добавить проверку.
* **INSIGHT-task-checklist** – правило пошаговой отметки задач.
* **INSIGHT-commit-authors** – commit authors из белого списка .

## 🛠️ Текущие инсайты

* **INSIGHT-git-identity-race** – race condition в git author, решено  + pre‑commit hook.
* **INSIGHT-worktree-isolation** – каждый агент в отдельном worktree, изоляция веток.
* **INSIGHT-branch-discipline** – ветки только от , имена .
* **INSIGHT-sw-cache-stale-ui** – Service Worker кэширует старый UI, обновление CACHE_NAME обязательно.
* **INSIGHT-reference-parsing** – парсинг внешних сайтов через .
* **INSIGHT-no-alarm-on-startup** – не кричать алерты при старте сессии.
* **INSIGHT-raven-scope** – Ворон = патруль внешнего мира, не швейцарский нож.
* **INSIGHT-hype-pilot** – обзор проекта Hype Pilot, контент‑машина.
* **INSIGHT-agent-names** – канонические имена агентов и их email.
* **INSIGHT-project-structure** – каждый проект отдельный репозиторий, не монорепо.
* **INSIGHT-cron-to-systemd** – миграция cron → systemd timers.
* **INSIGHT-shell-death** –  падает при отсутствии worktree, добавить проверку.
* **INSIGHT-task-checklist** – правило пошаговой отметки задач.
* **INSIGHT-commit-authors** – commit authors из белого списка .
