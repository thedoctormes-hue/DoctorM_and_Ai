---
description: "DoctorM_and_Ai — README"
type: readme
last_reviewed: 2026-06-21
last_code_change: 2026-06-21
status: active
---

# LabDoctorM — Лаборатория

> **Владелец:** DoctorM&Ai | **Статус:** active

## Описание

Мультиагентная система на базе OpenClaw. Управляется ЗавЛабом (@DoctorMES). Включает 9 агентов, 21 проект, систему артефактов и инсайтов.

## Быстрый старт

```bash
# Клонировать
git clone https://github.com/thedoctormes-hue/LabDoctorM.git
cd LabDoctorM

# Установить зависимости (для Python-проектов)
pip install -r requirements.txt

# Запустить тесты
pytest tests/ -v
```

## Архитектура

**Стек:** Python, Go, JavaScript/TypeScript, React, FastAPI, PostgreSQL, Docker, OpenClaw Gateway

**Структура:**
- `workspaces/` — рабочие пространства агентов (по одному на агента)
- `projects/` — проекты лаборатории
- `docs/` — документация (ADR, patterns, rules, specs, insights)
- `incidents/` — журнал инцидентов
- `adr/` — Architecture Decision Records

**Агенты:**
- КотОлизатор — Orchestrator
- Мангуст — Analyst
- Сова — Auditor
- Ворон — Researcher
- Муравей — Builder
- Бестия — Operator
- Штрейкбрехер — Developer
- Доминика — Scout

## Разработка

```bash
# Тесты
pytest tests/ -v

# Линтер
ruff check .

# Форматирование
ruff format .
```

## Деплой

```bash
# Сборка
docker-compose up -d

# Проверка
systemctl status openclaw
```

## Документация

- [Стандарты качества](docs/QUALITY_STANDARDS.md)
- [Git Flow](docs/GIT_FLOW.md)
- [Git Guardian](docs/GIT_GUARDIAN.md)
- [ADR](docs/adr/)
- [Процессы](docs/processes/)
- [Инциденты](incidents/)
- [Артефакты](docs/ARTIFACT_REGISTRY.md)
