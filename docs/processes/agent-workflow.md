---
description: "Воркфлоу лаборантов — структура, коммиты, ветки"
type: process
last_reviewed: 2026-06-21
last_code_change: 2026-06-08
status: active
---
# Agent Workflow — Воркфлоу лаборантов

**Версия:** 3.0 (ADR-012, ADR-037)
**Обновлено:** 2026-06-21

## Обзор

Каждый лаборант Лаборатории работает в своей папке (`projects/<agent>/`), имеет свой контекст (IDENTITY.md, SOUL-compact.md, CHECKPOINT.md) и коммитит по правилам ADR-012.

## Структура папки лаборанта

```
projects/<agent>/
├── IDENTITY.md        # Кто я, роль, зона ответственности
├── SOUL-compact.md    # Характер, стиль, табу (компактная версия)
├── SOUL-deep.md       # Глубокая версия души (опционально)
├── SOUL.md            # Полная версия (опционально)
├── CHECKPOINT.md      # Текущее состояние работы
└── [проекты]          # Рабочие файлы лаборанта
```

## 9 лаборантов

- **kotolizator** — Координация, аудит, документация (workspaces/kotolizator/)
- **antcat** — Myrmex Control, бэкенд (workspaces/antcat/)
- **bestia** — Фронтенд, UI, дизайн (workspaces/bestia/)
- **raven** — Разведка, мониторинг, контент (workspaces/raven/)
- **owl** — Аудит, стандарты качества, архитектура (workspaces/owl/)
- **streikbrecher** — Интеграции, парсеры, автоматизация (workspaces/streikbrecher/)
- **mangust** — Аналитика (workspaces/mangust/)
- **dominika** — Разведка (workspaces/dominika/)
- **muravey** — Системная интеграция (workspaces/muravey/)

## Запуск сессии

При старте сессии лаборант загружает свой контекст из воркспейса (`workspaces/<агент>/`):

1. `IDENTITY.md` → кто я и моя роль
2. `SOUL.md` → мой характер и стиль
3. `MEMORY.md` → долгосрочная память (только в основной сессии)
4. `memory/YYYY-MM-DD.md` → последние заметки

Контекст загружается автоматически через OpenClaw при инициализации агента.

## Коммиты (lab-commit.sh)

Каждый коммит лаборанта проходит через `lab-commit.sh` (расположен в `projects/<проект>/bin/lab-commit.sh`):

```bash
cd /root/LabDoctorM/projects/<проект>
./bin/lab-commit.sh <агент> -m "<тип>(<скоуп>): <описание>"
```

### Параметры

- **агент** — имя агента (kotolizator, antcat, bestia, raven, owl, streikbrecher, mangust, dominika, muravey)
- **тип** — feat | fix | test | docs | refactor | chore
- **скоуп** — проект или зона (например: vpn-daemon, myrmex-control)
- **описание** — на русском

### Правила (ADR-012, ADR-037)

1. **Ветка:** `<agent>/<type>-<scope>` — создаётся автоматически от main
2. **Формат:** `type(scope): описание на русском`
3. **Прямые коммиты в main — ЗАПРЕЩЕНЫ**
4. **snapshot/wip/checkpoint** в сообщении — заблокированы
5. **git add -u** — только tracked файлы, без мусора
6. **Автор коммита** — указывается через параметр `<агент>`, не через git config

### Примеры

```bash
# Котолизатор добавляет healthcheck
cd /root/LabDoctorM/projects/vpn-daemon
./bin/lab-commit.sh kotolizator -m "feat(vpn-daemon): добавить healthcheck endpoint"

# Сова обновляет документацию
cd /root/LabDoctorM/projects/DoctorM_and_Ai
./bin/lab-commit.sh owl -m "docs(audit): обновить реестр артефактов"

## Жизненный цикл ветки

```
main → <agent>/<type>-<scope> → merge в main (через Кота или ЗавЛаба)
```

1. Лаборант создаёт ветку через agent-commit.sh
2. Работает, коммитит
3. Мерж в main — через Кота (@kotolizator) или ЗавЛаба
4. После мержа в main локальная ветка удаляется (cleanup-норма, QUALITY_STANDARDS §12.6):
   ```bash
   git fetch origin
   git branch -d <agent>/<type>-<scope>   # git откажет, если не слита
   git push origin --delete <agent>/<type>-<scope>   # если ветка была запушена
   ```
   Не оставляй stale-ветки.

## Тестирование

Тесты каждой функции находятся в проектах:

- `projects/<проект>/tests/` — тесты проекта
- `projects/DoctorM_and_Ai/tests/` — системные тесты

Запуск:
```bash
cd /root/LabDoctorM/projects/<проект>
pytest tests/ -v
```

## Известные ограничения

- **Shell death** — после `git checkout` на другую ветку shell может потерять CWD. Обход: использовать `cd /root/LabDoctorM` в начале каждой команды.
- **Author коммитов** — git config не персонализирован по агентам. Все коммиты от системного пользователя.
- **Stash конфликты** — при первом коммите агента (когда файлов ещё нет на main) stash pop может вызвать конфликт modify/delete. Разрешается автоматически в пользу стэша.
