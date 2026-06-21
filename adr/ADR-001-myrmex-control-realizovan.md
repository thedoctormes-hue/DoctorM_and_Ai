---
type: adr
id: ADR-001
title: 'ADR-001: Myrmex Control: реализован WebSocket сервер (BL-028), H'
status: accepted
author: system
created: 2026-05-24 17:16:12+00:00
updated: 2026-05-24 17:16:12+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- adr
- migrated
code_refs:
- projects/myrmex-control/src/ws-server.ts
- projects/myrmex-control/src/health.ts
- projects/myrmex-control/src/rbac.ts
- projects/myrmex-control/src/monitoring.ts
freshness_score: 97
last_checked: '2026-06-20T01:00:13+00:00'
---

# ADR-001: Myrmex Control: реализован WebSocket сервер (BL-028), Health

## Статус
proposed

## Контекст
Myrmex Control: реализован WebSocket сервер (BL-028), Health Score dashboard (BL-029), Security hardening HSTS+Permissions-Policy (BL-031), RBAC 5 ролей (BL-040), Monitoring API (BL-032), Cost Tracking (BL-033), Dark Theme Design System с auto/light/dark (BL-036). Все модули скомпилированы, деплоены на production и demo. Серверная часть 0 ошибок TypeScript.

## Решение
Реализован комплексный подход к архитектуре Myrmex Control:
- WebSocket сервер для real-time обновлений
- Health Score dashboard для мониторинга
- Security hardening: HSTS + Permissions-Policy
- RBAC с 5 ролями (admin, manager, developer, viewer, guest)
- Monitoring API для сбора метрик
- Cost tracking для AI-моделей
- Dark Theme Design System с автоматическим переключением

## Последствия
- ✅ Модульная архитектура, production-ready
- ✅ Все модули скомпилированы без ошибок TypeScript
- ⚠️ Сложность деплоя (12 модулей)

## Альтернативы

- **Текущий:** ..., ...


## Связанные инсайты
- ins_073

## Связанные артефакты
- ADR-002 — writeState() мержит, не перезаписывает
- ADR-014 — Context API: HTTP-сервис загрузки контекста
- ADR-016 — Ремедиация утечки секретов
- ADR-018 — VPN 60K: полный цикл коммит-деплой-инсайт
- ADR-020 — Playwright: text=Войти не работает в querySelector

## Примечания
Создано автоматически из инсайта #73 (скор: 9/10)
