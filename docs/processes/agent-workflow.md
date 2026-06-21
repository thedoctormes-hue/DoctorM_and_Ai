# Agent Workflow — Воркфлоу лаборантов

**Статус:** активен
**Версия:** 2.0 (ADR-012)
**Обновлено:** 2026-06-08

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

## 6 лаборантов

| Агент | Папка | Роль |
|-------|-------|------|
| kotolizator | projects/kotolizator/ | Инфраструктура, VPN, серверы |
| antcat | projects/antcat/ | Myrmex Control, бэкенд |
| bestia | projects/bestia/ | Фронтенд, UI, дизайн |
| raven | projects/raven/ | Разведка, мониторинг, контент |
| owl | projects/owl/ | Документация, аналитика |
| streikbrecher | projects/streikbrecher/ | Интеграции, парсеры, автоматизация |

## Запуск сессии (session_startup.sh)

При старте сессии лаборанта выполняется `session_startup.sh`, который:

1. Определяет агента по имени/алиасу через myrmex.json
2. Загружает IDENTITY.md → кто я и моя роль
3. Загружает SOUL-compact.md → мой характер и стиль
4. Загружает RULES-BASE секция 3 → правила коммитов (ADR-012)
5. Для Ворона — загружает raven-alerts.py

```bash
bash .qwen/scripts/session_startup.sh <agent>
```

## Коммиты (agent-commit.sh)

Каждый коммит лаборанта проходит через `agent-commit.sh`:

```bash
bash .qwen/scripts/agent-commit.sh <agent> <type> "<scope>" "<message>"
```

### Параметры

- **agent** — kotolizator | antcat | bestia | raven | owl | streikbrecher
- **type** — feat | fix | test | docs | refactor | chore
- **scope** — проект или зона (например: "vpn-daemon", "myrmex-control")
- **message** — описание на русском

### Правила (ADR-012)

1. **Ветка:** `<agent>/<type>-<scope>` — создаётся автоматически от main
2. **Формат:** `type(scope): описание на русском`
3. **Прямые коммиты в main — ЗАПРЕЩЕНЫ**
4. **snapshot/wip/checkpoint** в сообщении — заблокированы
5. **git add -u** — только tracked файлы, без мусора
6. **Stash** — незакоммиченные изменения стэшатся перед checkout

### Примеры

```bash
# Котолизатор добавляет healthcheck
bash .qwen/scripts/agent-commit.sh kotolizator feat "vpn-daemon" "добавить healthcheck endpoint"

# Ворон фиксит импорт
bash .qwen/scripts/agent-commit.sh raven fix "hype-pilot" "исправить импорт telegraf"

# Муравей пишет тест
bash .qwen/scripts/agent-commit.sh antcat test "myrmex-control" "добавить тест DELETE handler"
```

### Что делает скрипт

1. Валидирует agent, type, scope, message
2. Блокирует snapshot/wip
3. Если на main — автоматически создаёт feature-ветку
4. Стэшит незакоммиченные изменения перед checkout
5. Создаёт/переключается на ветку `<agent>/<type>-<scope>` от main
6. Восстанавливает стэш на новой ветке
7. `git add -u` — только tracked файлы
8. `git commit -m "type(scope): message"`

## Жизненный цикл ветки

```
main → <agent>/<type>-<scope> → merge в main (через Кота или ЗавЛаба)
```

1. Лаборант создаёт ветку через agent-commit.sh
2. Работает, коммитит
3. Мерж в main — через Кота (@kotolizator) или ЗавЛаба
4. После мержа ветка удаляется

## Тестирование

Тесты находятся в `.qwen/scripts/`:

- `test_session_startup_v14.sh` — тесты session_startup.sh v14
- `test_agent_commit.sh` — тесты agent-commit.sh

Запуск:
```bash
bash .qwen/scripts/test_session_startup_v14.sh
bash .qwen/scripts/test_agent_commit.sh
```

## Известные ограничения

- **Shell death** — после `git checkout` на другую ветку shell может потерять CWD. Обход: использовать `cd /root/LabDoctorM` в начале каждой команды.
- **Author коммитов** — git config не персонализирован по агентам. Все коммиты от системного пользователя.
- **Stash конфликты** — при первом коммите агента (когда файлов ещё нет на main) stash pop может вызвать конфликт modify/delete. Разрешается автоматически в пользу стэша.
