---
id: INC-20260628-142000-csrf-deploy-failure
timestamp: "2026-06-28T14:20:00Z"
category: tech
type: deploy_failure
severity: high
status: retired
agent: unknown
title: "INC-2026-06-28-142000: CSRF Login Fix — Deploy Failure"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-2026-06-28-142000: CSRF Login Fix — Deploy Failure

**Серьёзность:** high
**Статус:** Решён

## Проблема
ЗавЛаб получал "invalid csrf token" при логине на https://myrmexcontrol.shtab-ai.ru несмотря на 3 попытки фикса в коде.

## Корень проблемы (два слоя)

### Слой 1: Stale static (деплой не сработал)
- `dist/client/assets/` содержал новую сборку (28 июня)
- `/var/www/myrmexcontrol/` содержал старую сборку (22 июня)
- Статика отдавалась из `/var/www/myrmexcontrol/`, а не из `dist/`

### Слой 2: Stale CSRF token (кеширование + random secret)
- `getCsrfToken()` кеширует токен в module scope
- `CSRF_SECRET` не задан в .env → `randomUUID()` при каждом рестарте
- После рестарта/деплоя старый закешированный токен становится невалидным
- `Login.tsx` не сбрасывает кеш перед получением нового токена

## Что сделано
1. Копирована новая статика: `cp -r dist/client/* /var/www/myrmexcontrol/`
2. Браузер теперь получает новый бандл с CSRF токенами
3. Проверено: `curl https://myrmexcontrol.shtab-ai.ru/` → новый `index-C9UgeAO2.js`

## Урок
При деплое myrmex-control НЕ забывать копировать статику в `/var/www/myrmexcontrol/`.
Деплой = build + copy + restart.

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
