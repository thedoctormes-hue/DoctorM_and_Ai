---
id: INC-20260625-compaction-raven
timestamp: "2026-06-25T00:00:00Z"
category: tech
type: config_error
severity: medium
status: retired
agent: raven
title: "Incident: Raven Compaction Failures (Cohere Timeout)"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Incident: Raven Compaction Failures (Cohere Timeout)

**Filed:** 2026-06-25 14:28Z by КотОлизатОр
**Severity:** Medium (raven can't compact, will eventually hit context limit)
**Status:** Active (partially resolved)

## Update 2026-06-26 22:50Z

Raven's session `agent:raven:telegram:direct:173681771` failed completely — model `@cf/moonshotai/kimi-k2.7-code` returns HTTP 400 on every attempt (3 retries, all failed). This is a Cloudflare model incompatibility with OpenClaw's request format.

**Root cause chain:**
1. Cohere compaction timed out (~300s) → someone switched Raven to `@cf/moonshotai/kimi-k2.7-code`
2. Cloudflare model returns 400 — session died
3. Session is now in `failed` state, will auto-recover on next inbound message (new session = default model)

**Action needed:**
- Investigate why cohere/command-r-plus times out at 300s (separate issue)
- The `@cf/moonshotai/kimi-k2.7-code` override was a bad pivot — Cloudflare models may not be compatible

## Summary

Raven's context-engine compaction is failing repeatedly on `cohere/command-r-plus-08-2024`. Three consecutive failures observed in the last hour.

## Evidence

```
14:18:18 — compaction failed: Request was aborted (timeout)
14:23:16 — compaction-diag: trigger=manual, provider=cohere/command-r-plus-08-2024, attempt=1, outcome=failed, reason=timeout, durationMs=301327
14:28:24 — compaction-diag: trigger=budget, provider=cohere/command-r-plus-08-2024, attempt=1, outcome=failed, reason=timeout, durationMs=300951
```

## Impact

- Raven cannot compact its context. When context fills up, it will lose coherence or fail to respond.
- Cohere's API is timing out at ~300s (5 min) — this is the request timeout, not a short timeout.

## Context

- Config reload was applied at 12:55Z today — did not fix the issue.
- Streikbrecher has a separate compaction issue (cerebras/gpt-oss-120b).
- Raven was previously on nemotron-3-super as failover (noted at 13:02Z), but the compaction provider is still cohere.

## Recommended Actions

1. Check if cohere API is experiencing latency issues
2. Consider switching raven's compaction provider to a faster model
3. Check if `command-r-plus-08-2024` has a different endpoint/region that's slow

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
