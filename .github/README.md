<div align="center">

# 🧬 LabDoctorM

**AI-лаборатория, которая работает, пока ты читаешь этот ридми.**

*Основана 25 апреля 2026. За 70 дней — 18 репозиториев, ~950 тестов, 0 дней простоя.*

[![Website](https://img.shields.io/badge/Website-shtab--ai.ru-00D4AA?style=flat-square)](https://shtab-ai.ru)
[![Dashboard](https://img.shields.io/badge/Dashboard-myrmexcontrol.shtab--ai.ru-00D4AA?style=flat-square)](https://myrmexcontrol.shtab-ai.ru)
[![Telegram](https://img.shields.io/badge/Telegram-@DoctorMES-00D4AA?style=flat-square)](https://t.me/DoctorMES)

[🇷🇺 Русский](#) · [🇬🇧 English](README_EN.md)

</div>

---

## Почему ты должен это читать

У нас нет pitch deck. Нет «whitepaper». Нет слайдов с красивых бездомных и припиской «AI-powered».

Вот что у нас есть:

- **6 AI-агентов**, которые пишут код 24/7 — не как демо, а на production
- **Стейкхолдерский день рождения** — когда один агент накосячил, другой агент провёл post-mortem. Человеку даже не пришлось вмешиваться.
- **950+ тестов** — потому что мы не верим «оно у меня работает»

Если тебе это интересно — продолжай. Если нужен ещё proof — мы докажем.

---

## Агенты

Шесть специалистов. Никто не «assistent». Каждый — мастер своего дела.

| Агент | Специализация | Что реально делает |
|-------|--------------|---------------------|
| 🐱 **Котолизатор** | Координация | VPN, данные, мониторинг. Знает, что происходит в каждый момент |
| 🐜 **Муравей** | Разработка | Myrmex Control, боты, автоматизация. Пишет код, который не переделывают |
| 🐺 **Бестия** | Инфраструктура | СнабЛаб, сервисы. Держит production |
| ⚡ **Штрейкбрехер** | Фулстек | Кросс-проектная разработка. Там, где нужен кто-то, кто видит картину целиком |
| 🦉 **Сова** | Аудит и качество | Стандарты, архитектура. Не пропустит фигню в коде |
| 🐦‍⬛ **Ворон** | Разведка | Мониторинг, аналитика, контент. Летит вперёд и ищет угрозы |

**ЗавЛаб** — человек-оператор. Ставит задачи. Принимает стратегические решения. Не пишет код в 3 часа ночи (агенты делают это за него).

---

## Проекты, которые работают прямо сейчас

### 🟢 Production — работают, приносят ценность

| Проект | Что делает | Стек |
|--------|------------|------|
| [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) ⚡ | Пульт управления лабораторией: канбан, сессии, артефакты, чат. 116 тестов | React 19, TS, Express |
| [lab-vault](https://github.com/thedoctormes-hue/lab-vault) 🔐 | Секретный менеджер для агентов. Go. Работает. Секреты целы | Go |
| [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) 📬 | IMAP-мониторинг + AI-классификация + OCR результатов. Без фантазий — просто работает | Go |
| [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) 👶 | Трекер речевого развития для детей. Реальные дети, реальный результат | FastAPI, React, PostgreSQL |
| [consilium](https://github.com/thedoctormes-hue/consilium) 🧠 | AI-консультант. Анализирует, рекомендует, сообщает когда нет | Go |

### 🟡 Active — в разработке, близки к продакшену

| Проект | Что делает | Стек |
|--------|------------|------|
| [autoexpert](https://github.com/thedoctormes-hue/autoexpert) | Экспертиза ущерба ДТП с AI. 132 теста | FastAPI, React/Vite, PostgreSQL |
| [snablab](https://github.com/thedoctormes-hue/snablab) | Управление закупками лаб. расходников | Python, PostgreSQL |
| [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) | Автопостинг в Telegram. 44 теста. Постит, пока ты спишь | Python, Playwright |
| [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) | Мониторинг всего. 81 тест. systemd timer. Спит с нами | Python, systemd |
| [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) | Здоровье артефактов лаборатории. Следит за целостностью данных | Python |
| [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) | Фреймворк автотестов. 326 тестов для тестирования тестов | Python, Playwright |
| [stenographer](https://github.com/thedoctormes-hue/stenographer) | Транскрибация аудио/видео из Telegram. 12 тестов | Python, aiogram |
| [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) | VPN-управление через Telegram. 36 тестов | Python, aiogram, PostgreSQL |
| [SNZK](https://github.com/thedoctormes-hue/SNZK) | Нарративный веб-проект | TypeScript, Vite, Canvas |
| [remote-access](https://github.com/thedoctormes-hue/remote-access) | Удалённый доступ к оборудованию | Bash, Xray, SSH |

### 🔴 Cheque-bot — заморожен

Был бухгалтерский бот. Заморожен. Не будем врать что он «в планах».

---

## Архитектура. Дерзко и точно.

```
ЗавЛаб
  └── Myrmex Control
        ├── Котолизатор ─── VPN, данные, координация
        ├── Муравей ───────── разработка, Myrmex, боты
        ├── Бестия ─────────── инфраструктура, СнабЛаб
        ├── Штрейкбрехер ──── фулстак, архитектура
        ├── Сова ──────────── аудит, стандарты, качество
        └── Ворон ──────────── разведка, мониторинг
```

**Факты без украшений:**
- Каждый агент работает в своём **изолированном git worktree** — никаких конфликтов
- **25 ADR** в корне + **14 ADR** в myrmex-control — каждое решениезадокументировано
- **13 инцидентов** зафиксированы с post-mortem — и ни один не повторился
- **Git Guardian** не даёт запушить фигню в main. Даже нам.

---

## Стек

Мы не гонимся за модными технологиями. Берём то, что работает.

```
Языки:       Python · TypeScript · Go · Bash
Backend:     FastAPI · aiogram · Express · PostgreSQL · SQLite
Frontend:    React 19 · Vite · Tailwind CSS · Telegram Web Apps
DevOps:      Docker · systemd · GitHub Actions · pre-commit
VPN:         Xray Core (VLESS/REALITY) · nginx SNI routing
AI-ядро:     Qwen Code · мультиагентка · self-evolution
```

*Заметили отсутствие «blockchain» и «web3»? Мы тоже.*

---

## Quality. Серьёзно.

**~950+ тестов** — и это консервативная оценка:
- myrmex-control: 116
- autoexpert: 132
- lab-monitoring: 81
- lab-playwright-expert: 326
- hype-pilot: 44
- vpn-daemon: 36
- stenographer: 12
- artifact-pulse: 5

**Безопасность:**
- TruffleHog + detect-secrets в pre-push hooks
- Dependabot следит за зависимостями автоматически
- 23 high severity уязвимостей обнаружены Dependabot — все в процессе закрытия

**Каскадные аудиты:** агенты проверяют код друг друга. Если один накосячил — другой поймает. Человеку не нужно быть code reviewer 24/7.

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
- ❌ Команды из 50 человек (у нас 6 агентов и они делают больше)

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
