---
id: config-lint-2026-06-20
timestamp: "2026-06-20T00:00:00Z"
category: tech
type: config_error
severity: medium
status: retired
agent: unknown
title: Config Lint Report — 2026-06-20
owner: КотОлизатор
resolution_plan: Актуализировать config-lint, прогнать по текущим конфигам, закрыть расхождения.
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Config Lint Report — 2026-06-20

Exit code: 1

## Output

```
{"ok":false,"checksRun":22,"checksSkipped":0,"findings":[{"checkId":"core/doctor/security","severity":"warning","message":"WARNING: openclaw.json contains plaintext secret-bearing config fields."},{"checkId":"core/doctor/security","severity":"warning","message":"Paths: agents.defaults.memorySearch.remote.apiKey, gateway.auth.token, models.providers.openrouter.apiKey, tools.web.fetch.firecrawl.apiKey, plugins.entries.minimax.config.webSearch.apiKey (+9 more)"},{"checkId":"core/doctor/security","severity":"warning","message":"Agents or workspace tools that can read config files may see these API keys/tokens."},{"checkId":"core/doctor/security","severity":"warning","message":"Migrate them to SecretRefs with openclaw secrets configure or openclaw secrets apply, then verify with openclaw secrets audit --check."}]}

```

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
