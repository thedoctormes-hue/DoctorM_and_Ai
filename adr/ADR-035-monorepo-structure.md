---
description: "ADR-035: Структура монорепозитория лаборатории"
type: adr
last_reviewed: 2026-06-18
status: proposed
---
# ADR-035: Структура монорепозитория лаборатории

## Контекст
Репозиторий лаборатории содержит проекты, workspaces агентов, конфигурации, скрипты и документацию в одном месте. Без чёткой структуры — хаос.

## Решение
Стандартная структура монорепо:
```
/root/LabDoctorM/
├── projects/       # Реальные продукты и сервисы
├── workspaces/     # Рабочие зоны агентов (git worktrees)
├── shared/         # Общие скрипты и правила
├── .qwen/          # Система инсайтов и артефакты
├── adr/            # Architecture Decision Records
├── patterns/       # Паттерны
├── rules/          # Правила
├── specs/          # Спецификации
├── docs/           # Документация
└── scripts/        # Скрипты автоматизации
```

**Ключевое:** workspaces/ НЕ являются проектами. Они управляются через git worktrees и не сканируются project-indexer.

## Следствия
- Чёткое разделение: projects (продукты) vs workspaces (зоны агентов)
- Упрощение onboarding новых агентов
- Исключение ложных срабатываний project-indexer

## Связанные артефакты
- ADR-003: lab-architecture-entities
- ADR-022: monorepo-strategy
- ADR-031: agent-zones-separation
- INS-20260617180534-a: инсайт об инвентаризации проектов
