---
id: INC-012
timestamp: "2026-06-21T00:32:29+00:00"
category: tech
type: incident
severity: high
status: retired
agent: unknown
title: "INC-012: Дубль snablab-bot — два каталога, один бот"
description: "INC-012: Дубль snablab-bot — Бестия перенесла без коммита, Штрейкбрехер"
author: Бестия
created: 2026-06-13
updated: 2026-06-13
last_reviewed: 2026-06-13
last_code_change: 2026-06-13
related:
freshness_score: 97
last_checked: "2026-06-20T01:00:20+00:00"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-012: Дубль snablab-bot — два каталога, один бот

## Описание
В проектах лаборатории существуют два каталога с одним и тем же ботом:
- `projects/snablab/bot/` — перенесён Бестией, НЕ в git
- `projects/snablab-bot/` — воссоздан Штрейкбрехером, в git

Активный systemd unit запускает бинарник из `snablab/bot/`, но код в git — только в `snablab-bot/`. Рассинхронизация.

## Severity
🟠 HIGH — рассинхронизация кода и git, риск потери рабочей версии при деплое.

## Хронология (из git log)
1. **10.06** — Ворон создал `projects/snablab-bot/` (начальная структура, handlers, notifier, тесты)
2. **12.06 13:13** — Штрейкбрехер: коммит `bff0904f` «вынести проекты в отдельные репозитории (11 проектов)» — snablab-bot затронут
3. **13.06** — Бестия: перенесла `projects/snablab-bot/` → `projects/snablab/bot/`, обновила config (godotenv, путь к .env), пересобрала, запустила. **Не закоммитила.**
4. **13.06 14:05** — Муравей (от имени Штрейкбрехера): коммит `2fb5199e` — воссоздал `projects/snablab-bot/` с нуля (17 файлов). Не знал о переносе Бестии.

## Корневая причина
Бестия перенесла бота в `projects/snablab/bot/`, но не закоммитила изменения. Штрейкбрехер/Муравей, не видя в git следов переноса, воссоздал `projects/snablab-bot/` заново. Результат: два каталога, рассинхронизированный код, рабочий бинарник не соответствует git.

## Различия между версиями
- `config.go`: snablab/bot использует `TELEGRAM_BOT_TOKEN` + godotenv от `/root/LabDoctorM/projects/snablab/.env`; snablab-bot использует `SNABLAB_BOT_TOKEN` + Environment в systemd unit
- `Makefile`: snablab/bot содержит `sudo systemctl daemon-reload`; snablab-bot — нет
- `snablab-bot.service`: snablab/bot — WorkingDirectory на `snablab/bot`; snablab-bot — на `snablab-bot`
- Бинарник `/usr/local/bin/snablab-bot` собран из `snablab/bot/` (systemd указывает туда)

## Действия
- [x] Инцидент зарегистрирован
- [x] Определить, какую версию оставить — snablab/bot/ (рабочая)
- [x] Удалить дубль — snablab-bot/ удалён из git и с диска
- [x] Синхронизировать git с рабочим состоянием — 14 файлов закоммичены
- [x] Закоммитить

## Критерии устранения
- [x] Один каталог с кодом бота — snablab/bot/
- [x] Git синхронизирован с рабочим кодом — 14 файлов, 2 коммита
- [x] systemd unit указывает на правильный каталог — WorkingDirectory=snablab/bot
- [x] Дубль удалён — snablab-bot/ стёрт из git и с диска

## Результат
✅ Все критерии выполнены. Бот работает (active, polling), git синхронизирован, дубля нет.

## Статус
resolved

## Ответственный
Бестия (перенос) + Штрейкбрехер/Муравей (восстановление)

## Связанные материалы
- `projects/snablab/bot/` — рабочая версия (не в git)
- `projects/snablab-bot/` — версия в git
- SESSION_HANDOFF Бестии: «snablab-bot перенесён в projects/snablab/bot/»

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
