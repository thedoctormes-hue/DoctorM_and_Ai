---
name: adr-index
description: "Реестр всех ADR лаборатории (SSOT)"
type: index
version: "1.0.0"
author: "owl (Сова)"
last_reviewed: "2026-07-14"
status: active
---

# ADR-INDEX — реестр архитектурных решений лаборатории

> Единый источник истины (SSOT) для списка ADR. Создан 14.07.2026 при консолидации docs/ADR + docs/adr → adr/.
> Всего ADR-файлов: 63.

## Полный список

| Файл | Заголовок (H1) | Статус |
|------|----------------|--------|
| `0043-dreams-rotation-and-compaction` | ADR-0043: DREAMS Rotation and Compaction | proposed |
| `0052-model-rating-methodology` | ADR-0052: Стандарт составления рейтинга LLM-моделей | accepted |
| `039-heartbeat-all-agents` | ADR-039: Heartbeat для всех агентов лаборатории | — |
| `2026-06-22-heartbeat-config-lint` | ADR-0046: Heartbeat-based Config Lint вместо cron job | — |
| `2026-06-22-secrets-migration-secretref` | ADR-0044: Миграция plaintext secrets на SecretRef | — |
| `2026-06-29-openclaw-model-fallback-gpt-oss-120b` | ADR: Замена gpt-oss-20b на gpt-oss-120b в fallback-цепочке OpenClaw | — |
| `2026-06-29-skill-naming-convention-gerund` | ADR: Стандарт именования скилов — gerund form | — |
| `2026-06-29-snablab-kp-parser-position-based` | ADR: Переход KP-парсера на позиционный парсинг | — |
| `2026-06-29-snablab-security-passlib-to-bcrypt` | ADR: Замена passlib на bcrypt в СнабЛаб | — |
| `2026-06-29-snablab-test-infrastructure-postgresql` | ADR: Перенос тестов СнабЛаб на PostgreSQL | — |
| `2026-07-19-gateway-manual-restart` | ADR-2026-07-19: Ручной рестарт гейтвея — только ЗавЛаб | accepted |
| `ADR-000-template` | ADR-XXX: [Название решения] | proposed |
| `ADR-001-custom-skills-restructure` | ADR-001: Стандартизация кастомных скилов лаборатории | accepted |
| `ADR-001-myrmex-control-realizovan` | ADR-001: Myrmex Control: реализован WebSocket сервер (BL-028), Health | accepted |
| `ADR-002-write-state-merge` | ADR-002: writeState() должен мержить, а не перезаписывать | accepted |
| `ADR-003-lab-architecture-entities` | ADR-003: Архитектура сущностей лаборатории — Лаборанты vs Роли | accepted |
| `ADR-004-model-cascade-refactor` | ADR-004: Рефакторинг каскада моделей OpenRouter | accepted |
| `ADR-0047-ports-timers-canonical-registry` | ADR-0047: Канонический реестр портов и таймеров | accepted |
| `ADR-005-vcru-ispolzuet-osnovareme` | ADR-005: vc.ru использует osnova-remember куки + auth-refresh-token в | accepted |
| `ADR-0053-shim-mandatory-interception-for-gatekeeper` | ADR-0053: Принудительный shim-перехват для MCP Gatekeeper | — |
| `ADR-0054-gatekeeper-dead-heal-mandatory-retry` | ADR-0054: Gatekeeper — протокол «dead + heal + mandatory_retry» | — |
| `ADR-0055-gatekeeper-threat-model-mitigations` | ADR-0055: Gatekeeper — Threat Model & Mitigations (Product-Ready Hardening) | — |
| `ADR-0055-service-existence-verification` | ADR-0055: Верификация существования сервисов агентами | accepted |
| `ADR-0056-gatekeeper-system-of-record-ssot` | ADR-0056: Gatekeeper как System-of-Record (SSOT) | accepted |
| `ADR-0056-skill-creation-standard` | ADR-0056: Стандарт создания и редактирования скиллов (устранение хаоса при создании) | — |
| `ADR-0056` | ADR-0056 (DRAFT): Единый реестр инцидентов и дисциплина хранения | accepted |
| `ADR-006-snablab-parser-kp-zah` | ADR-006: СнабЛаб: парсер КП захватывает количество из цены (известная | archived |
| `ADR-007-snablab-v010-fastapi-back` | ADR-007: РЎРЅР°Р±Р›Р°Р± v0.1.0: FastAPI backend СЃ РїРѕР»РЅРѕР№ РјРѕРґРµР»СЊСЋ РґР°РЅРЅС‹С… (8 СЃ | archived |
| `ADR-008-kotolizator-v20-polna` | ADR-008: Котолizатор v2.0: полная система оповещений, 355+ тестов, E2 | archived |
| `ADR-009-myrmex-control-spa-requir` | ADR-009: Myrmex Control SPA requires dual auth: cookie (myrmex_sessio | archived |
| `ADR-010-playwright-networkidle-ha` | ADR-010: Playwright networkidle hangs on SPA with lazy-loaded chunks | accepted |
| `ADR-011-frontend-build-output-dis` | ADR-011: Frontend build output (dist/) != server static path (client/ | archived |
| `ADR-012-git-guardian` | Агент создаёт worktree | accepted |
| `ADR-013-myrmex-control-e2e-testing` | ADR-013: Myrmex Control — E2E тестирование (Playwright) | accepted |
| `ADR-014-context-api-http` | ADR-001: Context API — HTTP-сервис загрузки контекста | accepted |
| `ADR-015-llm-openrouter-stack` | Стек LLM-моделей лаборатории на OpenRouter | accepted |
| `ADR-016-inc004-polna-remediaci` | ADR-016: INC-004: РїРѕР»РЅР°СЏ СЂРµРјРµРґРёР°С†РёСЏ СѓС‚РµС‡РєРё СЃРµРєСЂРµС‚РѕРІ РІ GitHub. РЈРґР°Р»РµРЅС‹ | accepted |
| `ADR-017-v-myrmex-control-mozhno-d` | ADR-017: В Myrmex Control можно добавить секцию Продуктивность — KPI | accepted |
| `ADR-018-vpn-60k-polnyy-cikl-komm` | ADR-017: VPN 60K: РїРѕР»РЅС‹Р№ С†РёРєР» РєРѕРјРјРёС‚-РґРµРїР»РѕР№-РёРЅСЃР°Р№С‚-С‡РµРєРїРѕРёРЅС‚ Р·Р° РѕРґРЅСѓ СЃ | accepted |
| `ADR-020-playwright-textvoyti-ne-r` | ADR-004: Playwright: text=Войти не работает в document.querySelector | accepted |
| `ADR-021-roles-as-lenses` | ADR-021: Roles as Lenses | accepted |
| `ADR-022-monorepo-strategy` | ADR-022: Стратегия монорепозитория LabDoctorM | active |
| `ADR-024-channel-config-evolution` | ADR-024: Channel Config Evolution — MUST Language, Block Streaming, maxOutputTokens | accepted |
| `ADR-025-agent-cwd-standard` | ADR-025: Стандарт рабочего пространства агента в OpenClaw | accepted |
| `ADR-026-migration-safety` | ADR-026: Предотвращение поломки сервисов при миграции/удалении проектов | proposed |
| `ADR-027-git-identity-race` |  | accepted |
| `ADR-028-openclaw-json-agent-registry` | ADR-028: openclaw.json как единственный источник истины для реестра агентов | accepted |
| `ADR-029` | ADR-029: Vault Integration for Secret Storage | superseded |
| `ADR-030` | ADR-030: Myrmex JSON – Single Source of Truth | active |
| `ADR-031-agent-zones-separation` | ADR-031: Разделение проектов и агентов в myrmex.json | accepted |
| `ADR-032-myrmex-json-single-source-of-truth` | ADR-032: openclaw.json как единственный источник реестра агентов | rejected |
| `ADR-033-dual-myrmex-json` | ADR-033: Два файла myrmex.json — корневой и серверный | accepted |
| `ADR-034-git-worktree-isolation` | ADR-034: Git worktree как стандарт изоляции рабочих зон агентов | accepted |
| `ADR-035-monorepo-structure` | ADR-035: Структура монорепозитория лаборатории | accepted |
| `ADR-036-qwen-to-openclaw-migration` | ADR-036: Миграция Qwen → OpenClaw — hooks и skills | accepted |
| `ADR-037-agent-registry` | ADR-037: Agent Registry — openclaw.json как единственный источник истины | accepted |
| `ADR-038-agent-to-agent-connectivity` | ADR-038: Agent-to-Agent Connectivity — настройка связи между агентами | accepted |
| `ADR-039-agent-config-improvements` | ADR 039: Улучшения конфигурации агентов OpenClaw | — |
| `ADR-039-disk-rotation-policy` | ADR-039: Политика ротации и очистки дискового пространства | accepted |
| `ADR-042-agent-config-fine-tuning` |  | accepted |
| `ADR-043-agent-config-top5-improvements` |  | accepted |
| `ADR-044-agent-config-fine-tuning` |  | accepted |
| `ADR-045-quality-analysis` |  | accepted |
| `ADR-046-bestia-master-push-rights` | ADR-046: Делегирование bestia push-прав в master (doctorm-unify-protocol) | accepted |
| `ADR-0060-workspace-storage-policy` | ADR-0060: Политика хранения в воркспейсах агентов | accepted |

## ⚠️ Коллизии номеров ADR (требуют перенумерации)

Один и тот же номер ADR присвоен нескольким файлам. Это ломает однозначность ссылки 'ADR-XXX'.

- **ADR-001 ×2**: ADR-001-custom-skills-restructure.md, ADR-001-myrmex-control-realizovan.md
- **ADR-039 ×3**: 039-heartbeat-all-agents.md, ADR-039-agent-config-improvements.md, ADR-039-disk-rotation-policy.md
- **ADR-0055 ×2**: ADR-0055-service-existence-verification.md, ADR-0055-gatekeeper-threat-model-mitigations.md
- **ADR-0056 ×3**: ADR-0056.md, ADR-0056-gatekeeper-system-of-record-ssot.md, ADR-0056-skill-creation-standard.md

## Блокирующее обстоятельство для перенумерации

Перенумерация ударит по ссылкам в ДРУГИХ репозиториях лабы (PAT-004):

- ADR-001-myrmex-control-realizovan → projects/myrmex-control/GETTING_STARTED.md
- ADR-0055-gatekeeper-threat-model-mitigations → projects/mcp-tools/mcp-gatekeeper/shim/README.md
- ADR-0056 (bare) → projects/lab-memory/docs/ADR/*, skills-canon/skill-manager, skills-canon/ebsh, incidents/*

Эти репозитории принадлежат другим агентам (Муравей, Доминика, Штрейкбрехер). Правка без согласования = нарушение зоны владельца + GUARDIAN.
**Решение:** перенумерация отложена до координации со владельцами репо. Реестр выше — единственный SSOT для текущего состояния.
