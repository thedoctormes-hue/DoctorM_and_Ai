---
name: tg-webapp-council-ux
description: 'UX-паттерны для консилиума в Telegram Web App: inline-карточки, пошаговый
  reveal, интерактивные кнопки'
type: pattern
id: PAT-007
title: 'PAT-007: UX совета в Telegram WebApp'
status: active
layer: skills
source: manual
tags:
- pattern
- ux
- telegram-webapp
- council
code_refs:
- projects/web-apps/council/
author: system
created: 2026-05-24
updated: 2026-05-24
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
freshness_score: 94
last_checked: '2026-06-20T01:00:33+00:00'
---

# Telegram Web App Council UX

## Проблема
Скил `council` работает как CLI-протокол — неинтерактивно. В Telegram ожидается компактный UX с кнопками и анимациями.

## Паттерн

### 1. 👤 Inline-карточки экспертов
```
👨‍💻 Линус Торвальдс
   Системная архитектура
   [➕ Добавить]
```
`InlineKeyboardMarkup` с callback-обновлением состояния.

### 2. ⚡ Пошаговый reveal позиций
Эксперты "печатают..." с анимацией, кнопка "Следующий эксперт ⏭️".

### 3. 🎯 Карточка финального решения
```
✅ Feature flags + env-конфиг
[✅ Принять] [🔄 Итерировать]
```

## Техническая реализация
- `InlineKeyboardMarkup` + `editMessageReplyMarkup`
- `CloudStorage` для сохранения состава
- Push-уведомления через `sendMessage`

## Связанные артефакты

- ADR-012 — Dual Auth: Telegram Web App использует cookie + access_token
- ADR-013 — E2E тесты: паттерн inline-карточек тестируется через Playwright

[INSIGHT: pattern] Telegram Web App консилиум нуждается в интерактивных карточках вместо текстовых простыней [layer: skills] [source: telegram_webapp_developer]
