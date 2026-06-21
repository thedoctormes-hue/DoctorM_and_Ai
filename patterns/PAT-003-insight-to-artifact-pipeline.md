---
type: pattern
id: PAT-003
title: 'PAT-003: Конвейер Инсайт → Артефакт'
status: active
author: system
created: 2026-05-24 21:07:07+00:00
updated: 2026-05-24 21:07:07+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- pattern
- migrated
code_refs:
- projects/artifact-pulse/scripts/insight_catcher.sh
- projects/artifact-pulse/scripts/self_evolve.sh
freshness_score: 94
last_checked: '2026-06-20T01:00:32+00:00'
---
# PAT-003: Конвейер Инсайт → Артефакт

## Категория
architecture

## Контекст
В лаборатории накапливаются инсайты (мысли, идеи, наблюдения). Без системной обработки они остаются сырьём и не превращаются в полезные артефакты.

## Решение
Автоматический конвейер:
1. **Ловля** — insight_catcher.sh ловит инсайты из всех tool calls
2. **Скоринг** — оценка полезности (0-10)
3. **Маршрутизация** — self_evolve.sh направляет инсайт в нужный тип артефакта:
   - risk/security (score ≥ 8) → incident + rule
   - optimization → ADR
   - pattern → PAT
   - architecture → ADR
   - task → spec (BL)
4. **Создание** — автоматическое создание артефакта по шаблону

## Критерии применимости
- [ ] Инсайт имеет score ≥ 4 (с маркером) или ≥ 6 (без маркера)
- [ ] Тип инсайта определён
- [ ] Есть соответствующий шаблон артефакта

## Связанные артефакты
- `hooks/insight_catcher.sh` — ловля инсайтов
- `self_evolve.sh` — маршрутизация
- `evolve_orchestrator.sh` — оркестрация

## Примечание
Текущая проблема: 392 инсайта в графе, но 0 рёбер. Инсайты не связаны между собой. Нужно построить связи.
