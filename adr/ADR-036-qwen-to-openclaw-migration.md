---
description: "ADR-036: Миграция Qwen → OpenClaw — hooks и skills"
type: adr
last_reviewed: 2026-06-18
status: proposed
---
# ADR-036: Миграция Qwen → OpenClaw — hooks и skills

## Контекст
При миграции с Qwen на OpenClaw все PostToolUse hooks перестают работать. В Qwen они были встроены, в OpenClaw — перенастраиваются на skills + cron.

## Решение
1. Все Qwen-hooks мигрируются в **skills** (`/root/LabDoctorM/workspaces/<agent>/.openclaw/skills/`)
2. Периодические задачи (которые были hooks) переносятся в **cron** через gateway
3. Каждый агент имеет свой набор skills, загружаемых при старте
4. Документируется в SOUL.md и TOOLS.md агента

## Следствия
- Единый механизм расширения функционала через skills
- Периодические задачи видны в cron, не скрыты в hooks
- Агенты могут делиться skills через Skill Workshop
- Требуется проверка всех мигрированных hooks

## Связанные артефакты
- ADR-004: model-cascade-refactor
- PAT-005: no-facts-without-proof (если актуально)
- INS-20260617133233-6: инсайт о миграции Qwen→OpenClaw
