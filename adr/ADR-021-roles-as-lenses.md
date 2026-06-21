---
type: adr
id: ADR-021
title: Roles as Lenses — миграция ролей агентов в линзы и рефакторинг
status: accepted
author: owl
created: 2026-05-26
updated: 2026-05-26
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: owl_agent
tags:
- roles
- lenses
- agents
- architecture
code_refs:
- projects/myrmex-control/src/rbac.ts
freshness_score: 97
last_checked: '2026-06-20T01:00:16+00:00'
---
# ADR-021: Roles as Lenses

## Статус
accepted (26.05.2026)

## Контекст
Все роли лаборантов (`/root/.qwen/agents/*.md`) реализовывались как отдельные агенты через `agent tool`. Это приводило к:

1. **Потере контекста**: каждый вызов создавал новый процесс без доступа к QWEN.md, памяти, ADRs
2. **Дублированию**: роли описывали и методологию, и личность — но личность уже есть у лаборанта
3. **Низкому качеству**: без контекста агент-роль давал поверхностные результаты

A/B тест подтвердил: лаборант с линзой даёт лучший результат, чем отдельный агент-роль.

## Решение
Мигрировать роли в линзы. После аудита (Сова + Муравей, 26.05.2026) сокращено с 26 до **7 линз**.

**Принцип:** Линза = mental model (вопросы, которые меняют фокус). Лаборант = исполнитель с полным контекстом.

**Ключевое изменение в подходе:**
- v3 → v4: чек-листы заменены на вопросы. Не «проверь correctness, readability», а «что сломается первым? поймёт ли джуниор?»
- Линзы пишутся как смена мышления, как список галочек
- Ловец инсайтов вынесен в общий файл (`INSIGHT_CATCHER.md`) — убрана копипаста из 26 файлов

## Финальный набор (7 линз)


- **`code-reviewer`:** engineering, 5 вопросов (сломается → джуниор → изменения → атакующий → rollback)
- **`security-auditor`:** security, 5 вопросов (доверие → атакующий → компрометация → следы → эксплуатация)
- **`test-engineer`:** engineering, 5 вопросов (уверенность → граница → зависимость → хрупкость → спецификация)
- **`deploy-bot`:** engineering, 5 вопросов (rollback → staging → не код → smoke-test → пятница)
- **`incident-commander`:** orchestration, 4 вопроса (кровотечение → коммуникация → рецидив → рентген)
- **`anti-dpi-legend`:** security, 4 вопроса (блокировка → fingerprint → IP → fallback)
- **`artifact-specialist`:** engineering, 4 вопроса (удалить → дубли → новый человек → привязка)


## Удалённые линзы (19)

**Вынесены в docs/brand/** (не линзы, справочники): content-agent, content-pipeline-agent, creative-director, commercial-agent

**Удалены** (мусор/дубли/нет спроса): crypto-analyst, data-scientist, devops-engineer, docs-writer, evolve-activator, general-purpose, githugmaster, hr, metrics-storyteller, openclaw-agent, skill-architect, telegram-webapp-developer, vpn-infrastructure-agent, context-session-specialist

**Смержены:** security-audit → security-auditor

## Последствия
- ✅ 7 линз вместо 26 — редкие и точные
- ✅ Вопросы вместо чек-листов — меняют мышление, не галочки
- ✅ Один файл ловца инсайтов — нет копипасты
- ✅ security смержен — один источник правды
- ⚠️ Нет автоматической загрузки линз (лаборант сам распознает триггер)

## Связанные артефакты

- ADR-015 — LLM OpenRouter Stack: лаборанты используют модели из этого стека через линзы
- `/root/LabDoctorM/lenses/` — 7 линз + общие файлы
- `/root/LabDoctorM/lenses/INSIGHT_CATCHER.md` — общий ловец инсайтов
- `/root/LabDoctorM/docs/brand/` — 4 бренд-гайда (не линзы)
- `/root/.qwen/agents-legacy/` — deprecated копии старых ролей
