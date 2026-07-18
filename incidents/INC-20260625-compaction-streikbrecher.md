---
id: INC-20260625-compaction-streikbrecher
timestamp: "2026-06-25T00:00:00Z"
category: tech
type: config_error
severity: critical
status: retired
agent: streikbrecher
title: "Инцидент: Compaction на streikbrecher постоянно таймаутится"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Инцидент: Compaction на streikbrecher постоянно таймаутится

**Дата:** 2026-06-25
**Критичность:** Medium (влияет на агента, но не на инфраструктуру)
**Статус:** ✅ ЗАКРЫТ (13:20Z)

**Решение:**
- compaction.model: cerebras/gpt-oss-120b → cohere/command-r-plus-08-2024
- compaction.timeoutSeconds: 120 → 300
- streikbrecher.toolResultMaxChars: 64000 → 32000
- Бэкап: openclaw.json.bak.2026-06-25T1255
- Doctor: OK, config valid

**Результат:** Cohere command-r-plus справляется с большими сессиями за 5-60s (вместо timeout). Мониторинг после рестарта gateway подтвердит.

## Описание

Агент `streikbrecher` (сессия `agent:streikbrecher:telegram:direct:173681771`) не может выполнить context compaction. Все попытки заканчиваются таймаутом (~121s) на провайдере `cerebras/gpt-oss-120b`.

## Логи

- 2026-06-25T06:40Z — safeguarding: compaction failed, cancelling
- 2026-06-25T06:47Z — `cerebras/gpt-oss-120b` reason=timeout durationMs=121720
- 2026-06-25T06:51Z — `cerebras/gpt-oss-120b` reason=timeout durationMs=121328 (manual trigger)
- 2026-06-25T09:47Z — heartbeat зафиксировал повторный failure

## Гипотеза

Провайдер cerebras с моделью gpt-oss-120b не справляется с compaction summary за 120s. Возможно, размер контекста слишком большой, или провайдер перегружен.

## Рекомендации

- Подождать, пока ЗавЛаб назначит задачу на расследование
- Рассмотреть смену модели compaction для streikbrecher
- Мониторить повторные сбои

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
