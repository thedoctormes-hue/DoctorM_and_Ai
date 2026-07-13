---
id: config-lint-2026-06-20
timestamp: "2026-06-20T00:00:00Z"
category: tech
type: config_error
severity: medium
status: open
agent: unknown
title: Config Lint Report — 2026-06-20
owner: КотОлизатор
resolution_plan: Актуализировать config-lint, прогнать по текущим конфигам, закрыть расхождения.
---

# Config Lint Report — 2026-06-20

Exit code: 1

## Output

```
{"ok":false,"checksRun":22,"checksSkipped":0,"findings":[{"checkId":"core/doctor/security","severity":"warning","message":"WARNING: openclaw.json contains plaintext secret-bearing config fields."},{"checkId":"core/doctor/security","severity":"warning","message":"Paths: agents.defaults.memorySearch.remote.apiKey, gateway.auth.token, models.providers.openrouter.apiKey, tools.web.fetch.firecrawl.apiKey, plugins.entries.minimax.config.webSearch.apiKey (+9 more)"},{"checkId":"core/doctor/security","severity":"warning","message":"Agents or workspace tools that can read config files may see these API keys/tokens."},{"checkId":"core/doctor/security","severity":"warning","message":"Migrate them to SecretRefs with openclaw secrets configure or openclaw secrets apply, then verify with openclaw secrets audit --check."}]}

```
