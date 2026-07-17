---
id: INC-20260627-telegram-webhook
timestamp: "2026-06-27T00:00:00Z"
category: tech
type: other
severity: low
status: retired
agent: unknown
title: Telegram deleteWebhook Network Errors
owner: Бестия
resolution_plan: Разобрать Telegram deleteWebhook network errors; при необходимости переустановить webhook.
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Telegram deleteWebhook Network Errors

**Started:** 2026-06-27 ~00:53 UTC
**Status:** Ongoing
**Severity:** Low (recoverable — polling fallback active)

## Summary

`deleteWebhook` keeps failing with network errors every ~1-2 minutes. The system recovers by continuing to polling mode, so Telegram messaging still works.

## Evidence

```
Jun 27 00:53:03 [telegram] deleteWebhook failed with a recoverable network error
Jun 27 00:55:26 [telegram] deleteWebhook failed with a recoverable network error
... continuing through 01:13
```

## Impact

- Telegram bot operates in polling mode (functional but less efficient)
- No message loss expected

## Action

- Monitor — likely transient network issue with Telegram API
- If persists >12h, escalate to ЗавЛаб

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
