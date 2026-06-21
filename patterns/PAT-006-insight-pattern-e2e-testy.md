---
type: pattern
id: PAT-006
title: 'PAT-006: [INSIGHT: pattern] E2E тесты могут висать бескон'
status: archived
author: system
created: 2026-05-24 17:16:12+00:00
updated: 2026-05-24 17:16:12+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- pattern
- migrated
freshness_score: 94
last_checked: '2026-06-20T01:00:33+00:00'
---

# PAT-006: [INSIGHT: pattern] E2E тесты могут висать бесконечно если за

## Название
[INSIGHT: pattern] E2E тесты могут висать бесконечно если за

## Категория
architecture

## Контекст
[INSIGHT: pattern] E2E тесты могут висать бесконечно если зависят от внешних сервисов. Решение: запускать unit и E2E отдельно, E2E только при работающих сервисах. test_e2e_mailbox.py и test_e2e_*.py зависают без myrmex-control. [layer: testing]

## Решение
<!-- Опиши решение подробнее -->

## Примеры
```
# Добавь пример кода
```

## Критерии применимости
- [ ] условие 1

## Связанные инсайты
- ins_004

## Связанные артефакты
- Нет

## Примечания
Создано автоматически из инсайта #4 (скор: 7/10)

## Архивировано
