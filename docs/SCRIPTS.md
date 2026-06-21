---
description: "⚙️ Структура скриптов .qwen/"
type: guide
last_reviewed: 2026-06-11
last_code_change: 2026-06-11
status: active
---
# ⚙️ Структура скриптов .qwen/

```
/root/.qwen/
├── orchestrators/   ← оркестраторы (self_evolve, evolve_orchestrator, session_startup, boot_sequence)
├── hooks/           ← хуки жизненного цикла (session_init, session_finalize, insight_catcher, ...)
├── scripts/         ← утилиты по доменам
│   ├── dev/         ← разработка (check_qwen_releases, git_pre_commit, analyze_errors)
│   ├── infra/       ← инфраструктура (tier-control)
│   ├── security/    ← безопасность (auto-incident, security-check)
│   ├── telegram/    ← Telegram (telegram_cli, telegram_webhook)
│   ├── lib/         ← библиотеки (decision_log, devils_advocate, frontend_guardian)
│   ├── agent-commit.sh   ← коммит лаборанта по ADR-012
│   ├── session_end.sh    ← финализация сессии агента
│   ├── test_agent_commit.sh ← 29 тестов agent-commit.sh
│   └── test_session_end.sh  ← 12 тестов session_end.sh
├── tests/           ← тесты скриптов (test_self_evolve, test_evolve_orchestrator, test_migration)
└── *.sh → symlinks  ← симлинки на orchestrators/ для обратной совместимости
```

Примечание: скрипты в корне `.qwen/` (self_evolve.sh, evolve_orchestrator.sh, session_startup.sh, boot_sequence.sh, analyze_errors.py) — это симлинки на `orchestrators/` и `scripts/dev/`. Перенесены для порядка, обратная совместимость сохранена.

## Автоматический старт сессии (УВП)
🔥 Каждая сессия начинается с `session_startup.sh`:
- `/root/.qwen/hooks/session_start.sh` — оптимизированный старт (~200 токенов)
- Использует kanban API: `http://localhost:3000/api/kanban/session-start?agent=kotolizator`

Для полной картины: `jq` по `evolution_backlog.json`

### session_startup.sh — загрузка контекста

**Расположение:** `.qwen/scripts/session_startup.sh`

**Использование:**
```bash
bash session_startup.sh <agent>
```

**Что загружает (порядок вывода):**
1. `IDENTITY.md` — роль, зона ответственности, правила
2. `SOUL-compact.md` — характер, принципы, стиль работы
3. `SESSION_HANDOFF.md` — заметка с прошлой сессии (что сделано / что не доделано / что проверить)
4. (только для raven) `raven-alerts.py --summary` — сводка алертов

**SESSION_HANDOFF.md — формат:**
```markdown
# 🔄 SESSION HANDOFF — <Агент>

## Что сделано
- Краткий список завершённых задач

## Что не доделано
- Открытые задачи, блокеры

## Что проверить в первую очередь
- Критичные проверки при старте
```

**Правила:**
- Файл обновляется в конце каждой сессии лаборантом
- Максимум полстраницы — только суть
- Без таблиц, без оверинжиниринга

**Тесты:** `test_session_startup_v14.sh` — 49 тестов (скрипт, агенты, контекст, алиасы, raven alerts, rules-base)

## agent-commit.sh — коммит лаборанта

**Расположение:** `.qwen/scripts/agent-commit.sh`

**Использование:**
```bash
agent-commit.sh <agent> <type> "<scope>" "<message>" [--push]
```

**Параметры:**
- `agent` — имя лаборанта: `kotolizator|antcat|bestia|raven|owl|streikbrecher`
- `type` — тип коммита: `feat|fix|test|docs|refactor|chore`
- `scope` — область изменений (проект)
- `message` — описание на русском
- `--push` — опционально, пуш в origin

**Правила (ADR-012):**
- Ветка: `<agent>/<type>-<scope>` (создаётся автоматически от main)
- Формат сообщения: `type(scope): описание`
- Прямые коммиты в main — ЗАПРЕЩЕНЫ
- snapshot/checkpoint/wip — блокируются
- Только tracked файлы (`git add -u`), без мусора
- Stash при незакоммиченных изменениях перед checkout

**Тесты:** `test_agent_commit.sh` — 29 тестов (валидация, формат, ветки, stash, 6 агентов, recommit, блокировка main)

## session_end.sh — финализация сессии

**Расположение:** `.qwen/scripts/session_end.sh`

**Использование:**
```bash
session_end.sh <agent>
```

**Что делает:**
- Резолвит директорию агента через `myrmex.json`
- Обновляет `CHECKPOINT.md` (last_reviewed, last_code_change)
- Запускает evolve, consolidation, changelog
- Собирает статистику артефактов
- Проверяет frontmatter всех файлов агента
- Проверяет наличие незакоммиченных изменений

**Тесты:** `test_session_end.sh` — 12 тестов (существование, содержимое, без аргументов, флаг, с агентом)

## session_startup.sh — старт сессии агента

**Расположение:** `.qwen/scripts/session_startup.sh`

**Использование:**
```bash
bash session_startup.sh <agent_id|alias>
```

**Параметры:**
- `agent_id` — идентификатор агента: `kotolizator|antcat|bestia|raven|owl|streikbrecher`
- Поддерживаются алиасы: `cat`, `kot`, `ant`, `myrmex`, `beast`, `streik`, `sova`

**Порядок загрузки контекста:**
1. `IDENTITY.md` — идентичность агента (frontmatter + описание)
2. `SOUL-compact.md` — компактная душа (старт сессии)
3. `SESSION_HANDOFF.md` — передача смены (3-точечный формат)
4. *(только raven)* `RAVEN ALERTS` — алерты из `raven-alerts.py`

**Формат SESSION_HANDOFF.md:**
```markdown
---
description: "🔄 Передача смены <Агента>"
type: handoff
last_reviewed: YYYY-MM-DD
last_code_change: YYYY-MM-DD
status: active
---
# 🔄 SESSION HANDOFF — <Агент>

## 📊 TL;DR
Краткое резюме последней сессии.

## Что сделано ✅
- Пункт 1
- Пункт 2

## Что не доделано ⏸️
- Пункт 1

## Что проверить 🔍
- Пункт 1
```

**Правила:**
- Каждый лаборант обновляет свой SESSION_HANDOFF.md при закрытии сессии
- При старте сессии — скрипт загружает HANDOFF автоматически
- Отсутствие HANDOFF — ошибка (exit 0, но предупреждение в логе)
- Алиасы резолвятся через `myrmex.json`

**Тесты:** `test_session_startup_v14.sh` — 49 тестов:
- БЛОК 1: Скрипт существует и читаем
- БЛОК 2: Неизвестный агент — exit 1 + предупреждение
- БЛОК 3: Все 6 лаборантов — exit 0, IDENTITY + SOUL + HANDOFF
- БЛОК 4: Алиасы резолвятся корректно (13 алиасов)
- БЛОК 5: Raven алерты загружаются
- БЛОК 6: RULES-BASE файл существует и секция 3 не пуста
