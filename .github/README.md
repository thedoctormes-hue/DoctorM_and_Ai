<div align="center">

# 🧬 LabDoctorM

**AI-лаборатория, которая работает, пока ты читаешь этот README.**

*Основана 25 апреля 2026. 23 проекта, 8 агентов, ~627 тестов. Обновлено: 2026-06-24.*

[![Website](https://img.shields.io/badge/Website-shtab--ai.ru-00D4AA?style=flat-square)](https://shtab-ai.ru)
[![Dashboard](https://img.shields.io/badge/Dashboard-myrmexcontrol.shtab--ai.ru-00D4AA?style=flat-square)](https://myrmexcontrol.shtab-ai.ru)
[![Telegram](https://img.shields.io/badge/Telegram-@DoctorMES-00D4AA?style=flat-square)](https://t.me/DoctorMES)

[🇷🇺 Русский](README_RU.md) · [🇬🇧 English](README_EN.md)

</div>

---

## Почему ты это читаешь

У нас нет pitch deck. Нет whitepaper. Нет слайдов со стоковыми фото и припиской «AI-powered».

Вот что у нас есть:

- **8 AI-агентов**, которые пишут код 24/7 — не демо, а на продакшене
- **Автоматический разбор инцидентов** — когда один агент накосячил, другой провёл post-mortem. Человек даже не просыпался
- **627 тестов** (без node_modules/dist) — потому что мы не верим «оно у меня работает»
- **38 инцидентов** зафиксированы и разобраны — ни один не повторился

Если тебе это интересно — продолжай. Если нужен proof — мы докажем.

---

## Агенты

Восемь специалистов. Никто не «assistant». Каждый — мастер своего дела.

| Агент | Специализация | Что реально делает |
|-------|--------------|---------------------|
| 🐱 **Котолизатор** | Координация | VPN, данные, мониторинг. Знает, что происходит в каждый момент |
| 🐜 **Муравей** | Разработка | Myrmex Control, боты, автоматизация. Пишет код, который не переделывают |
| 🐺 **Бестия** | Инфраструктура | СнабЛаб, сервисы. Держит продакшн |
| ⚡ **Штрейкбрехер** | Фулстек | Кросс-проектная разработка. Там, где нужен кто-то, кто видит картину целиком |
| 🦉 **Сова** | Аудит и качество | Стандарты, архитектура. Не пропустит фигню в коде |
| 🐦‍⬛ **Ворон** | Разведка | Мониторинг, аналитика, контент. Летит вперёд и ищет угрозы |
| 🦊 **Доминика** | Разведка ресурсов | Быстрый поиск, сбор данных, проверка возможностей |
| 🦡 **Мангуст** | Аналитика | Анализ данных, интеграции, ADR, связь с внешними системами |

**ЗавЛаб** (@DoctorMES) — человек-оператор. Ставит задачи. Принимает стратегические решения. Не пишет код в 3 ночи — за него это делают агенты.

---

## Проекты

### 🟢 Продакшн (работают без SLA, best-effort)

| Проект | Что делает | Стек |
|--------|------------|------|
| [snablab](https://github.com/thedoctormes-hue/snablab) | Полный стек автоматизации закупок для КДЛ: справочники, парсинг КП, склад, заявки, оборудование, аналитика, Telegram-бот. 651 тест | FastAPI, React 18, PostgreSQL 16, Redis |
| [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) | Пульт управления колонией: канбан, сессии, артефакты, чат, Knowledge Graph. 44 модуля, 195 тестов | React 19, TS, Express |
| [consilium](https://github.com/thedoctormes-hue/consilium) | AI-консилиум из 6 ролей: Скептик, Пост-мортем, Первые принципы, Рост, Аутсайдер, Исполнитель. HTTP API + Telegram-бот | Go |
| [stenographer](https://github.com/thedoctormes-hue/stenographer) | Транскрибация аудио/видео из Telegram → 4 документа: текст, протокол, задачи, рефлексия | Python, aiogram, OpenRouter |
| [free-api-hunter](https://github.com/thedoctormes-hue/free-api-hunter) | Мониторинг бесплатных LLM API с веб-дашбордом | Go, React |
| [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) | VPN-управление через Telegram (Xray VLESS+REALITY). 355+ тестов | Python, aiogram, FastAPI |
| [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) | IMAP-мониторинг + AI-классификация + OCR лабораторных результатов | Go, chi, Tesseract OCR |
| [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) | Трекер речевого развития для детей с ЗПРР. Наблюдения, словарик, планы занятий, статистика | FastAPI, React, PostgreSQL |

### 🟡 В разработке

| Проект | Что делает | Стек |
|--------|------------|------|
| [autoexpert](https://github.com/thedoctormes-hue/autoexpert) | Автоматизация экспертизы ущерба ДТП: поиск запчастей по VIN, сбор цен, PDF-заключение. 67 тестов | FastAPI, React/Vite, PostgreSQL |
| [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) | Мониторинг хайпов и вирусного контента. Автопостинг в Telegram. 44 теста | Python, Playwright |
| [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) | Мониторинг серверов, сайтов, VPN, PostgreSQL, Docker, SSL | Python, systemd |
| [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) | Мониторинг здоровья артефактов лаборатории | Python |
| [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) | Фреймворк автотестов. 376 тестов | Python, Playwright |
| [SNZK](https://github.com/thedoctormes-hue/SNZK) | Браузерная визуальная новелла в киберпанк-эстетике. 5 фаз, 92 события, 7 концовок | TypeScript, Vite, Canvas |
| [remote-access](https://github.com/thedoctormes-hue/remote-access) | Удалённый доступ через Xray VLESS+REALITY | Bash, Xray, SSH |
| [DoctorMandDesign](https://github.com/thedoctormes-hue/DoctorMandDesign) | Генератор презентаций. 18 шаблонов, WCAG-AA, i18n | Python, reportlab |
| [msk-gastro-digest-bot](https://github.com/thedoctormes-hue/msk-gastro-digest-bot) | Дайджест ресторанных новостей Москвы. $0 (free-модели) | aiogram, OpenRouter |
| [polyscope](https://github.com/thedoctormes-hue/polyscope) | Интерактивный лендинг | React 19, Vite 7, Radix UI, GSAP |
| [api-hub](https://github.com/thedoctormes-hue/api-hub) | Единый API-шлюз для внешних сервисов | FastAPI, SQLAlchemy |
| [cheque-bot](https://github.com/thedoctormes-hue/cheque-bot) | AI-парсинг чеков. **Заморожен** | aiogram, OpenRouter Vision |
| [mcp-tools](https://github.com/thedoctormes-hue/mcp-tools) | Инструменты MCP для интеграции с LLM | — |

---

## Архитектура

```
ЗавЛаб (@DoctorMES)
  └── Myrmex Control (44 модуля, ModuleRegistry auto-discovery)
        ├── Котолизатор ─── VPN, данные, координация
        ├── Муравей ───────── разработка, Myrmex, боты
        ├── Бестия ─────────── инфраструктура, СнабЛаб
        ├── Штрейкбрехер ──── фулстек, архитектура
        ├── Сова ──────────── аудит, стандарты, качество
        ├── Ворон ──────────── разведка, мониторинг
        ├── Доминика ───────── разведка ресурсов, поиск
        └── Мангуст ────────── аналитика, интеграции, ADR
```

**Факты:**
- Каждый агент в **изолированном** workspace
- **44 ADR** — каждое решение задокументировано
- **38 инцидентов** с post-mortem (см. `incidents/`)
- **Git Guardian** блокирует непроверенный push в main

---

## Стек

```
Языки:       Python · TypeScript · Go · Bash
Backend:     FastAPI · aiogram · Express · chi · PostgreSQL · SQLite · Redis · MinIO
Frontend:    React 18/19 · Vite 5/7/8 · Tailwind CSS · Radix UI · Zustand
AI/LLM:      OpenRouter (мультипровайдер) · EmbeddingGemma-300m · FAISS · ONNX Runtime
DevOps:      Docker · systemd · GitHub Actions · pre-commit
VPN:         Xray Core (VLESS/REALITY) · nginx SNI routing
```

---

## Метрики

- **627 тестов** (без node_modules/dist/.venv)
- **~252K строк кода** (без node_modules/dist)
- **44 ADR**, 21 паттерн, 38 инцидентов
- **1588+ .md файлов** проиндексировано в семантической памяти

---

## Чего у нас нет

- ❌ 3 серверов на 3 континентах (1 сервер, и он работает)
- ❌ «52 скилла» из документации Qwen
- ❌ AI «в дорожной карте» — только работающий код
- ❌ «Пассивный доход» как проект
- ❌ Команды из 50 человек (8 агентов)

Что есть:
- ✅ Работающие сервисы
- ✅ Задокументированная архитектура
- ✅ Культура качества (post-mortem за каждый инцидент)
- ✅ Автоматизация, которая экономит часы каждый день

---

## Контакты

- 📡 [@DoctorMES](https://t.me/DoctorMES) — Telegram
- ✉️ [thedoctormes@gmail.com](mailto:thedoctormes@gmail.com) — Email
- 🌐 [shtab-ai.ru](https://shtab-ai.ru) — Сайт
- 📊 [myrmexcontrol.shtab-ai.ru](https://myrmexcontrol.shtab-ai.ru) — Дашборд
- 📱 +79032749274 — Телефон
- 💻 [github.com/thedoctormes-hue](https://github.com/thedoctormes-hue) — GitHub

---

<div align="center">

**«Нам не нужен супергерой. Нужен working code.»**

*© 2026 DoctorM&Ai Laboratory. Колония работает. Серьёзно.*

</div>
