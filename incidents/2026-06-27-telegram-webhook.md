---
id: 2026-06-27-telegram-webhook
timestamp: "2026-06-27T00:00:00Z"
category: tech
type: other
severity: low
status: open
agent: unknown
title: Telegram deleteWebhook Network Errors
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
