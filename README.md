---
description: "DoctorM_and_Ai — README"
type: readme
last_reviewed: 2026-07-14
last_code_change: 2026-06-24
status: active
---

# DoctorM&Ai Laboratory

> **Владелец:** DoctorM&Ai | **Статус:** active | **Дата:** 2026-06-24

## О лаборатории

Мультиагентная система на базе OpenClaw. Управляется ЗавЛабом (@DoctorMES).

- 8 AI-агентов, 23 проекта, ~627 тестов (без учёта node_modules/dist/.venv)
- 61 ADR (реестр: adr/ADR-INDEX.md), 21 паттерн, 155 инцидентов с post-mortem
- Основана 25 апреля 2026

## Агенты

- **КотОлизатор** — Orchestrator: координация задач, маршрутизация, отчётность
- **Мангуст** — Analyst: анализ данных, интеграции, ADR
- **Сова** — Auditor: аудит безопасности, стандарты, качество
- **Ворон** — Researcher: исследования, мониторинг, аналитика
- **Муравей** — Builder: системная интеграция, Docker, CI/CD
- **Бестия** — Operator: операционные задачи, health checks
- **Штрейкбрехер** — Developer: разработка кода, рефакторинг, архитектура
- **Доминика** — Scout: разведка ресурсов, быстрый поиск

## Проекты

### Продакшн (работающие сервисы без SLA)

- [snablab](https://github.com/thedoctormes-hue/snablab) — автоматизация закупок для клинико-диагностической лаборатории: справочники, парсинг КП, складской учёт, заявки, оборудование, Telegram-бот
- [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) — пульт управления колонией: канбан, сессии, артефакты, чат (44 модуля, ModuleRegistry auto-discovery)
- [consilium](https://github.com/thedoctormes-hue/consilium) — AI-консилиум из 6 аналитических ролей (Скептик, Пост-мортем, Первые принципы, Рост, Аутсайдер, Исполнитель)
- [stenographer](https://github.com/thedoctormes-hue/stenographer) — транскрибация аудио/видео из Telegram в документы
- [free-api-hunter](https://github.com/thedoctormes-hue/free-api-hunter) — мониторинг бесплатных LLM API с веб-дашбордом
- [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) — управление VPN-клиентами через Telegram (Xray VLESS+REALITY)

### MVP / R&D

- [autoexpert](https://github.com/thedoctormes-hue/autoexpert) — экспертиза ущерба ДТП с AI
- [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) — трекер речевого развития для детей
- [DoctorMandDesign](https://github.com/thedoctormes-hue/DoctorMandDesign) — генератор презентаций (18 шаблонов, WCAG-AA, i18n)
- [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) — мониторинг и анализ хайпов, вирусного контента
- [msk-gastro-digest-bot](https://github.com/thedoctormes-hue/msk-gastro-digest-bot) — дайджест ресторанных новостей Москвы ($0, free-модели)
- [lab-vault](https://github.com/thedoctormes-hue/lab-vault) — секретный менеджер для агентов
- [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) — IMAP-мониторинг + AI-классификация + OCR
- [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) — мониторинг инфраструктуры (systemd timer)
- [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) — мониторинг здоровья артефактов
- [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) — фреймворк автотестов (Playwright)
- [api-hub](https://github.com/thedoctormes-hue/api-hub) — единый API-шлюз для внешних сервисов (в разработке)
- [SNZK](https://github.com/thedoctormes-hue/SNZK) — нарративный веб-проект
- [polyscope](https://github.com/thedoctormes-hue/polyscope) — интерактивный лендинг
- [remote-access](https://github.com/thedoctormes-hue/remote-access) — удалённый доступ к оборудованию
- [cheque-bot](https://github.com/thedoctormes-hue/cheque-bot) — работа с чеками
- [mcp-tools](https://github.com/thedoctormes-hue/mcp-tools) — инструменты MCP (в разработке)

### Замороженные

- Бухгалтерский бот — заморожен, не поддерживается

## Стек

**Языки:** Python · TypeScript · Go · Bash

**Backend:** FastAPI · aiogram · Express · chi · PostgreSQL · SQLite · MinIO

**Frontend:** React 18/19 · Vite 5/7/8 · Tailwind CSS · Radix UI · Zustand

**AI/LLM:** OpenRouter (мультипровайдер) · EmbeddingGemma-300m · FAISS · ONNX Runtime

**DevOps:** Docker Compose · systemd · GitHub Actions · pre-commit

**VPN:** Xray Core (VLESS/REALITY) · nginx SNI routing

## Архитектура

- Каждый агент работает в изолированном workspace
- Единая семантическая память (FAISS + EmbeddingGemma-300m, ~12700 векторов)
- Артефакты (ADR, паттерны, инциденты) хранятся в репозитории
- Каскадные аудиты: агенты проверяют код друг друга

## Безопасность

- TruffleHog + detect-secrets в pre-push hooks
- Dependabot для мониторинга зависимостей
- Git Guardian блокирует push в main без проверки

## Документация

- [Laboratory Profile](docs/laboratory-profile.md) — публичный профиль для инвесторов и партнёров
- [ADR](adr/) — архитектурные решения
- [Patterns](patterns/) — паттерны разработки
- [Incidents](incidents/) — журнал инцидентов

## Контакты

- 🌐 [shtab-ai.ru](https://shtab-ai.ru)
- 📊 [myrmexcontrol.shtab-ai.ru](https://myrmexcontrol.shtab-ai.ru)
- 📡 [@DoctorMES](https://t.me/DoctorMES)

---

© 2026 DoctorM&Ai Laboratory
