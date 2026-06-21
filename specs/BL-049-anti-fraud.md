---
type: backlog
id: BL-049
title: BL-007-anti-fraud.md
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
---# BL-007: Anti-fraud и rate limiting

## Контекст
При 60к пользователей появится абуз: массовая регистрация, multi-accounting для trial, brute force.

## Цель
Внедрить систему защиты от мошенничества и злоупотреблений.

## Зачем
- Защита trial от массового абуза
- Предотвращение multi-accounting
- Защита от DDoS и brute force

## Проект/контекст
vpn-daemon → anti-fraud

## Что сделать
- [ ] Rate limiting: 1 trial на Telegram ID, 3 аккаунта на IP/24ч
- [ ] Device fingerprinting (Web App): отслеживание повторных регистраций
- [ ] Обнаружение аномалий: >5 регистраций с одного IP/час
- [ ] Капча после 3 неудачных попыток (inline captcha через callback)
- [ ] Blacklist: Telegram ID + IP для нарушителей
- [ ] Risk score для каждого пользователя (0-100)
- [ ] Автоматическая блокировка при score > 80 + ручная модерация при score 50-80
- [ ] Логирование всех fraud events

## Критерии готовности
- [ ] Rate limiting работает на всех endpoints
- [ ] Fraud events логируются и видны админу
- [ ] Массовая регистрация с одного IP блокируется

## Зависимости
- BL-005 (Redis)

## Назначение
- **Вес:** 2
- **Скиллы:** cascade
- **Статус:** in_progress
- **Приоритет:** medium

## Прогресс
- [x] middleware/rate_limit.py создан
- [x] modules/admin/fraud_service.py создан
- [x] Rate limiting: Telegram ID + IP limits
- [x] Risk scoring (0-100) с расчетами
- [x] Blacklist функционал (Telegram ID + IP)
- [ ] Интегрировать в handlers
- [ ] Добавить device fingerprinting
- [ ] CAPTCHA после 3 неудачных попыток

## Примечания
Оценка: 2-3 дня
