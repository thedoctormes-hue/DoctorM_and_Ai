# LabDoctorM — Лаборатория

Мультиагентная система на базе OpenClaw. Управляется ЗавЛабом (@DoctorMES).

## Структура

- `workspaces/` — рабочие пространства агентов (по одному на агента)
- `projects/` — проекты лаборатории (snablab, hype-pilot, artifact-pulse)
- `docs/` — документация (ADR, patterns, rules, specs, insights)
- `shared/` — общие скрипты и утилиты
- `incidents/` — журнал инцидентов

## Агенты

- КотОлизатор — Orchestrator
- Мангуст — Analyst
- Сова — Auditor
- Ворон — Researcher
- Муравей — Builder
- Бестия — Operator
- Штрейкбрехер — Developer
- Доминика — Scout

## Стандарты качества

- Тесты — ≥85% покрытия для AI-кода, edge cases, exit code 0
- Документация — README, комментарии, нетривиальные решения
- Git — только через lab-commit.sh, атомарные коммиты, без секретов
- Чистота — временные файлы, worktree, git status clean

## Git-правила

Подробнее: `docs/GIT_FLOW.md`, `docs/GIT_GUARDIAN.md`

Создать worktree:
```
bash shared/git-rules/create-worktree.sh <агент> projects/<кабинет>
```

Коммитить — ВСЕГДА через lab-commit.sh:
```
./bin/lab-commit.sh <агент> -m "сообщение"
```

## Документация

- `docs/adr/` — Architecture Decision Records
- `docs/patterns/` — Паттерны разработки
- `docs/rules/` — Правила лаборатории
- `docs/specs/` — Спецификации
- `docs/insights/` — Инсайты
- `docs/processes/` — Процессы и протоколы
- `incidents/` — Журнал инцидентов

## Стек

- Python, Go, JavaScript/TypeScript
- React/Vue, FastAPI, PostgreSQL
- Docker, CI/CD
- OpenClaw Gateway
