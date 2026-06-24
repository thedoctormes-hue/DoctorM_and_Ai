<div align="center">

# 🧬 LabDoctorM

**AI-лаборатория, которая работает, пока ты читаешь этот ридми.**

*Основана 25 апреля 2026. 23 проекта, 8 агентов, ~627 тестов. Дата обновления: 2026-06-24.*

[![Website](https://img.shields.io/badge/Website-shtab--ai.ru-00D4AA?style=flat-square)](https://shtab-ai.ru)
[![Dashboard](https://img.shields.io/badge/Dashboard-myrmexcontrol.shtab--ai.ru-00D4AA?style=flat-square)](https://myrmexcontrol.shtab-ai.ru)
[![Telegram](https://img.shields.io/badge/Telegram-@DoctorMES-00D4AA?style=flat-square)](https://t.me/DoctorMES)

[🇷🇺 Русский](#) · [🇬🇧 English](README_EN.md)

</div>

---

## Почему ты должен это читать

У нас нет pitch deck. Нет «whitepaper». Нет слайдов с красивых бездомных и припиской «AI-powered».

Вот что у нас есть:

- **8 AI-агентов**, которые пишут код 24/7 — не как демо, а на production
- **Стейкхолдерский день рождения** — когда один агент накосячил, другой агент провёл post-mortem. Человеку даже не пришлось вмешиваться.
- **627 тестов** (без node_modules/dist) — потому что мы не верим «оно у меня работает»

Если тебе это интересно — продолжай. Если нужен ещё proof — мы докажем.

---

## Агенты

Восемь специалистов. Никто не «assistent». Каждый — мастер своего дела.

| Агент | Специализация | Что реально делает |
|-------|--------------|---------------------|
| 🐱 **Котолизатор** | Координация | VPN, данные, мониторинг. Знает, что происходит в каждый момент |
| 🐜 **Муравей** | Разработка | Myrmex Control, боты, автоматизация. Пишет код, который не переделывают |
| 🐺 **Бестия** | Инфраструктура | СнабЛаб, сервисы. Держит production |
| ⚡ **Штрейкбрехер** | Фулстек | Кросс-проектная разработка. Там, где нужен кто-то, кто видит картину целиком |
| 🦉 **Сова** | Аудит и качество | Стандарты, архитектура. Не пропустит фигню в коде |
| 🐦‍⬛ **Ворон** | Разведка | Мониторинг, аналитика, контент. Летит вперёд и ищет угрозы |
| 🦊 **Доминика** | Разведка ресурсов | Быстрый поиск, сбор данных, проверка возможностей |
| 🦡 **Мангуст** | Аналитика | Анализ данных, интеграции, ADR, связь с внешними системами |

**ЗавЛаб** (@DoctorMES) — человек-оператор. Ставит задачи. Принимает стратегические решения. Не пишет код в 3 часа ночи (агенты делают это за него).

---

## Проекты, которые работают прямо сейчас

### 🟢 Production — работают, приносят ценность (без SLA)

| Проект | Что делает | Стек |
|--------|------------|------|
| [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) ⚡ | Пульт управления лабораторией: канбан, сессии, артефакты, чат. 44 модуля, 195 тестов | React 19, TS, Express |
| [lab-vault](https://github.com/thedoctormes-hue/lab-vault) 🔐 | Секретный менеджер для агентов. Go. Работает. Секреты целы | Go |
| [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) 📬 | IMAP-мониторинг + AI-классификация + OCR результатов. Без фантазий — просто работает | Go |
| [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) 👶 | Трекер речевого развития для детей. Реальные дети, реальный результат. 99 тестов | FastAPI, React, PostgreSQL |
| [consilium](https://github.com/thedoctormes-hue/consilium) 🧠 | AI-консилиум из 6 аналитических ролей: Скептик, Пост-мортем, Первые принципы, Рост, Аутсайдер, Исполнитель. HTTP API + Telegram-бот | Go |
| [snablab](https://github.com/thedoctormes-hue/snablab) | Автоматизация закупок для КДЛ: справочники, парсинг КП, складской учёт, заявки, оборудование, Telegram-бот. 81 тест | Python, PostgreSQL |
| [stenographer](https://github.com/thedoctormes-hue/stenographer) | Транскрибация аудио/видео из Telegram в документы. 4 теста | Python, aiogram |
| [free-api-hunter](https://github.com/thedoctormes-hue/free-api-hunter) | Мониторинг бесплатных LLM API с веб-дашбордом | Go, React |

### 🟡 Active — в разработке, близки к продакшену

| Проект | Что делает | Стек |
|--------|------------|------|
| [autoexpert](https://github.com/thedoctormes-hue/autoexpert) | Экспертиза ущерба ДТП с AI. 67 тестов | FastAPI, React/Vite, PostgreSQL |
| [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) | Мониторинг и анализ хайпов, вирусного контента. Автопостинг в Telegram. 44 теста | Python, Playwright |
| [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) | Мониторинг всего. 4 теста. systemd timer | Python, systemd |
| [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) | Здоровье артефактов лаборатории | Python |
| [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) | Фреймворк автотестов. 106 тестов | Python, Playwright |
| [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) | VPN-управление через Telegram. 18 тестов | Python, aiogram, PostgreSQL |
| [SNZK](https://github.com/thedoctormes-hue/SNZK) | Нарративный веб-проект | TypeScript, Vite, Canvas |
| [remote-access](https://github.com/thedoctormes-hue/remote-access) | Удалённый доступ к оборудованию | Bash, Xray, SSH |
| [DoctorMandDesign](https://github.com/thedoctormes-hue/DoctorMandDesign) | Генератор презентаций. 18 шаблонов, WCAG-AA, i18n | Python, reportlab |
| [msk-gastro-digest-bot](https://github.com/thedoctormes-hue/msk-gastro-digest-bot) | Дайджест ресторанных новостей Москвы. $0 (free-модели) | aiogram, v6.5 |
| [polyscope](https://github.com/thedoctormes-hue/polyscope) | Интерактивный лендинг | React 19, Vite 7, Radix UI, GSAP |
| [api-hub](https://github.com/thedoctormes-hue/api-hub) | Единый API-шлюз для внешних сервисов (в разработке) | FastAPI, SQLAlchemy |
| [cheque-bot](https://github.com/thedoctormes-hue/cheque-bot) | Работа с чеками. 7 тестов | aiogram |
| [mcp-tools](https://github.com/thedoctormes-hue/mcp-tools) | Инструменты MCP (в разработке) | — |

### 🔴 Замороженные

- Бухгалтерский бот — заморожен, не поддерживается.

---

## Архитектура. Дерзко и точно.

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

**Факты без украшений:**

- Каждый агент в **изолированном** workspace — минимум конфликтов
- **44 ADR** в корне DoctorM_and_Ai — каждое решение задокументировано
- **38 инцидентов** зафиксированы с post-mortem (см. `incidents/`)
- **Git Guardian** не даёт запушить фигню в main. Даже нам.

[ВЕРИФИЦИРОВАНО: ls adr/ | wc -l = 44, ls incidents/ | wc -l = 38]

---

## Стек

Мы не гонимся за модными технологиями. Берём то, что работает.

```
Языки:       Python · TypeScript · Go · Bash
Backend:     FastAPI · aiogram · Express · chi · PostgreSQL · SQLite · MinIO
Frontend:    React 18/19 · Vite 5/7/8 · Tailwind CSS · Radix UI · Zustand
AI/LLM:      OpenRouter (мультипровайдер) · EmbeddingGemma-300m · FAISS · ONNX Runtime
DevOps:      Docker · systemd · GitHub Actions · pre-commit
VPN:         Xray Core (VLESS/REALITY) · nginx SNI routing
```

*Заметили отсутствие «blockchain» и «web3»? Мы тоже.*

---

## Quality. Серьёзно.

**627 тестов** — без учёта node_modules/dist/.venv:

- myrmex-control: 195
- autoexpert: 67
- lab-playwright-expert: 106
- zprr-tracker: 99
- snablab: 81
- lab-monitoring: 4
- vpn-daemon: 18
- stenographer: 4
- остальные: ~54

[ВЕРИФИЦИРОВАНО: find -name "test_*" -not -path "*/node_modules/*" -not -path "*/.venv/*" | wc -l]

**Безопасность:**
- TruffleHog + detect-secrets в pre-push hooks
- Dependabot следит за зависимостями автоматически
- Количество обнаруженных уязвимостей не фиксировалось на момент генерации — проверьте вкладку Security на GitHub

**Каскадные аудиты:** агенты проверяют код друг друга. Если один накосяч — другой поймает. Человеку не нужно быть code reviewer 24/7.

---

## Инфраструктура

- **Сервер:** Европа (production)
- **VPN:** VLESS + REALITY (Xray Core)
- **Мониторинг:** lab-monitoring через systemd timer — без cron, без «забыл поставить»
- **CI/CD:** GitHub Actions
- **Деплой:** через `merge-to-main.sh` с Git Guardian — никакого `git push --force` в main

---

## Чего у нас нет

Честность. Вот чего нам не хватает у конкурентов.

Нет у нас:
- ❌ 3 серверов на 3 континентах (у нас 1 и он работает)
- ❌ «52 скилла» из документации Qwen
- ❌ AI, который «планируется» или «в дорожной карте»
- ❌ «Пассивный доход» как проект (у нас конкретные продукты)
- ❌ Команды из 50 человек (у нас 8 агентов)

Что есть:
- ✅ Работающие сервисы
- ✅ Задокументированная архитектура
- ✅ Культура качества (post-mortem за каждый инцидент)
- ✅ Автоматизация, которая экономит часы каждый день

---

## Хотите быть в курсе?

- 🌐 [shtab-ai.ru](https://shtab-ai.ru) — сайт
- 📊 [myrmexcontrol.shtab-ai.ru](https://myrmexcontrol.shtab-ai.ru) — дашборд
- 📡 [@DoctorMES](https://t.me/DoctorMES) — Telegram

Не обещаем что ответим за 5 минут. Но ответим. Вероятно, агент сделает это быстрее.

---

<div align="center">

**«Нам не нужен супергерой. Нужен working code.»**

*© 2026 DoctorM&Ai Laboratory. Колония работает. Серьёзно.*

</div>
