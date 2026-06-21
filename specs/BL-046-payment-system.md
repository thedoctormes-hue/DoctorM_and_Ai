---
type: backlog
id: BL-046
title: BL-004-payment-system.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:29+00:00'
---# BL-004: Платёжная система — Telegram Stars + Crypto + Карты РФ

## Контекст
Без платёжной системы нет монетизации. Нужны способы оплаты для 60к пользователей.

## Цель
Реализовать платёжный модуль: Telegram Stars, USDT TRC20/TON, карты РФ (ЮKassa).

## Зачем
Монетизация сервиса. Целевая модель: free trial → premium 290-990 руб/мес.

## Проект/контекст
vpn-daemon → payment module

## Что сделать
- [ ] Telegram Stars через Bot API (`sendInvoice`, `answerPreCheckoutQuery`)
- [ ] Crypto через NOWPayments или CryptoPay API
- [ ] Карты РФ через ЮKassa
- [ ] Модуль подписок: создание, продление, отмена, grace period
- [ ] Webhook handler для платёжных провайдеров
- [ ] Retry и reconciliation для failed payments
- [ ] Уведомления: успешная оплата, истекающая подписка, failed payment

## Критерии готовности
- [ ] Все 3 способа оплаты работают в sandbox
- [ ] Webhooks обрабатываются корректно
- [ ] Подписки создаются/продлеются/отменяются
- [ ] Reconciliation работает (сверка платежей)

## Зависимости
- BL-002 (PostgreSQL)
- BL-003 (модульная архитектура)

## Назначение
- **Вес:** 4
- **Скиллы:** cascade
- **Статус:** pending
- **Приоритет:** critical

## Примечания
Оценка: 5-7 дней
Тарифы: Trial 3 дня → Basic 290 руб → Premium 590 руб → Unlimited 990 руб
