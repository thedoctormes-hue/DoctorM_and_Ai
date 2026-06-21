---
description: "GIT GUARDIAN"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-06-18
status: active
---

# 🛡️ Git Guardian v2.0 — документация системы защиты коммитов

> **Создано Совой.** Утверждено ЗавЛабом.
> Дата: 05.06.2026. Статус: active.

## Философия

**Не ограничивать скорость — направлять её.**

Мы не запрещаем коммить — мы делаем так, чтобы каждый коммит был осмысленным, безопасным и обратимым. Система проверяет — не командует.

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    GIT GUARDIAN v2.0                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  pre-commit  │  │ commit-msg   │  │    pre-push       │  │
│  │             │  │              │  │                   │  │
│  │ • Блокировка│  │ • Conventional│  │ • Проверка        │  │
│  │   main      │  │   Commits    │  │   размера пуша    │  │
│  │ • Проверка  │  │ • Scope      │  │ • Блокировка      │  │
│  │   секретов  │  │   обязателен │  │   push в main     │  │
│  │ • Проверка  │  │ • Блокировка │  │ • Проверка        │  │
│  │   конфигов  │  │   snapshot   │  │   дубликатов      │  │
│  │ • Лимит     │  │ • Лимит      │  │                   │  │
│  │   файлов    │  │   длины      │  │                   │  │
│  └─────────────┘  └──────────────┘  └───────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              prepare-commit-msg                      │   │
│  │  • Автоподстановка scope по изменённым файлам        │   │
│  │  • Подсказка типа коммита                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Компоненты

### 1. `git-guardian.sh` — ядро системы

**Путь:** `scripts/git-guardian.sh`

**Режимы:**
- `pre-commit` — проверка ветки, секретов, конфигов, размера изменений
- `commit-msg` — проверка формата сообщения (Conventional Commits)
- `pre-push` — проверка перед пушем (размер, дубликаты, push в main)
- `prepare-commit-msg` — автоподстановка scope и type

**Конфигурация (внутри скрипта):**
```bash
MAX_FILES_PER_COMMIT=30        # Макс файлов в одном коммите
MAX_LINES_PER_COMMIT=500       # Макс строк изменений
MAX_SUBJECT_LENGTH=72          # Макс длина первой строки
MAX_BODY_LINE_LENGTH=100       # Макс длина строки в теле
```

**Проверки pre-commit:**
| # | Проверка | Блокирует | Сообщение |
|---|----------|-----------|-----------|
| 1 | Ветка = main/master | ✅ Да | Прямые коммиты в main запрещены |
| 2 | >30 файлов в коммите | ✅ Да | Разбить на атомарные коммиты |
| 3 | >500 строк изменений | ✅ Да | Слишком большой коммит |
| 4 | Секреты (password, token, key) | ✅ Да | Секреты в коммитах запрещены |
| 5 | Конфиги (config.yaml, .env) | ✅ Да | Конфиги не должны коммититься |
| 6 | Файлы вне стандартных директорий | ✅ Да | Вероятно git add . из корня |

**Проверки commit-msg:**
| # | Проверка | Блокирует | Сообщение |
|---|----------|-----------|-----------|
| 1 | Формат Conventional Commits | ✅ Да | `<type>(<scope>): <описание>` |
| 2 | Scope обязателен | ✅ Да | Без scope — не пройдёт |
| 3 | Длина subject ≤72 символов | ✅ Да | Сократить описание |
| 4 | Нет точки в конце | ✅ Да | Точка не нужна |
| 5 | Нет snapshot/checkpoint/wip | ✅ Да | Технические снимки → в ветку |
| 6 | Длина строк в теле ≤100 | ✅ Да | Переносить строки |

### 2. `agent-workspace.sh` — управление worktrees

**Путь:** `scripts/agent-workspace.sh`

**Команды:**
```bash
# Создать worktree для агента
bash agent-workspace.sh create owl                    # ветка: owl/main
bash agent-workspace.sh create owl owl/artifact-v2     # своя ветка

# Удалить worktree
bash agent-workspace.sh remove owl

# Список worktrees
bash agent-workspace.sh list

# Синхронизировать с main (rebase)
bash agent-workspace.sh sync owl

# Статус всех worktrees
bash agent-workspace.sh status
```

### 3. `merge-to-main.sh` — безопасный мердж в main

**Путь:** `scripts/merge-to-main.sh`

**Использование (только для Муравья и ЗавЛаба):**
```bash
# Обычный мердж (merge-commit)
bash merge-to-main.sh owl/artifact-v2

# Squash-мердж (все коммиты → один)
bash merge-to-main.sh owl/artifact-v2 --squash
```

**Проверки перед мержом:**
1. Ветка существует
2. Нет snapshot/checkpoint/wip коммитов
3. Все коммиты — Conventional Commits
4. Нет запрещённых файлов (config.yaml, .env)
5. Нет конфликтов с main
6. Не более 50 изменённых файлов

## Workflow агента

```
┌─────────────────────────────────────────────────────────────────┐
│                    РАБОЧИЙ ПРОЦЕСС АГЕНТА                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. СОДАТЬ WORKTREE                                             │
│     bash agent-workspace.sh create <agent>                      │
│     cd /root/LabDoctorM/worktrees/<agent>/                      │
│                                                                 │
│  2. РАБОТАТЬ                                                    │
│     # ...  edit code ...                                        │
│                                                                 │
│  3. КОММИТИТЬ (atomарно)                                        │
│     git add projects/my-project/specific-files                   │
│     git commit -m 'feat(my-project): добавить фичу'             │
│     ↓                                                           │
│     Git Guardian автоматически:                                 │
│     • Проверяет формат (prepare-commit-msg подскажет scope)      │
│     • Блокирует main (check-main-commit)                        │
│     • Проверяет конфиги/секреты                                 │
│     • Проверяет размер                                          │
│                                                                 │
│  4. PUSH В СВОЮ ВЕТКУ                                           │
│     git push origin <agent>/main                                │
│     ↓                                                           │
│     Git Guardian автоматически:                                 │
│     • Блокирует push в main                                     │
│     • Проверяет количество коммитов                             │
│     • Проверяет дубликаты                                       │
│                                                                 │
│  5. ЗАПРОСITb МЕРДЖ В MAIN                                      │
│     → К Муравью (@antcat)                                       │
│     → Или к ЗавЛабу                                             │
│                                                                 │
│  6. МУРАВЕЙ МЕРЖИТ                                              │
│     bash merge-to-main.sh <agent>/main --squash                 │
│     git push origin main                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Workflow Муравья (тимлид)

```
┌─────────────────────────────────────────────────────────────────┐
│                    РАБОЧИЙ ПРОЦЕСС МУРАВЬЯ                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. ПОЛУЧИТЬ ЗАПРОС НА МЕРДЖ                                    │
│     Агент создал ветку и запросил мердж                         │
│                                                                 │
│  2. ПРОВЕРИТЬ КОД                                               │
│     git fetch origin                                            │
│     git log origin/main..origin/<agent>/main                    │
│     git diff origin/main..origin/<agent>/main                   │
│                                                                 │
│  3. ВЫПОЛНИТЬ МЕРДЖ                                             │
│     bash merge-to-main.sh <agent>/main --squash                 │
│                                                                 │
│  4. ЗАПУШИТЬ                                                   │
│     git push origin main                                        │
│                                                                 │
│  5. УВЕДОМИТЬ АГЕНТА                                            │
│     Агент может синхронизироваться:                             │
│     bash agent-workspace.sh sync <agent>                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Правила коммитов (ADR-012, обновлено)

### Формат сообщений

```
<type>(<scope>): <описание на русском>

[тело — опционально]

[footer — опционально]
```

**type:** `feat` | `fix` | `test` | `docs` | `refactor` | `chore` | `perf` | `ci` | `build` | `revert`
**scope:** имя проекта (обязательно!): `autoexpert`, `hype-pilot`, `monitoring`, `owl`, `snablab`
**описание:** повелительное наклонение, на русском: «Добавить тест», «Исправить баг»

### Примеры правильных коммитов

```
feat(autoexpert): добавить Fobil парсер через curl+regex
fix(hype-pilot): исправить сломанные импорты после поглощения PIE
refactor(equipment): убрать дубль Equipment, всё через LabEquipment
test(servers): добавить 13 тестов soft-delete и E2E lifecycle
docs(monitoring): обновить архитектуру алертов
chore(ci): обновить pre-commit hooks до v2.0
perf(autoexpert): кэшировать результаты парсинга в Redis
```

### Примеры неправильных коммитов

```
fix: исправить всё                    ← нет scope
feat: add test                        ← не на русском
chore: snapshot — wip в main           ← snapshot в main запрещён
test(autoexpert): test               ← пустое описание
```

### Запрещено

1. ❌ `git add .` из корня — закоммитит чужие проекты
2. ❌ Коммиты без scope — `fix: исправить всё` = мусор в истории
3. ❌ `snapshot`/`checkpoint`/`wip` в main — технические снимки → в личную ветку
4. ❌ Более 3 коммитов в час в main — признак raid-коммитов
5. ❌ Коммит с 50+ файлами — признак `git add .` из корня
6. ❌ Прямой push в main — только через Муравья или ЗавЛаба
7. ❌ Коммит config.yaml, .env, secrets — конфиги вне git

### Атомарность

- **Одна задача = один коммит.** Поглощение (absorb) — одним коммитом, не тремя
- Если PR делает 5 логических вещей — 5 коммитов или squash перед мержем
- **Максимум 30 файлов и 500 строк** в одном коммите

## Установка

```bash
# 1. Установить pre-commit
pip install pre-commit

# 2. Установить все типы хуков
cd /root/LabDoctorM
pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push --hook-type prepare-commit-msg

# 3. Проверить установку
pre-commit --version
git worktree list

# 4. Запустить проверку вручную
pre-commit run --all-files
```

## Обновление хуков

```bash
cd /root/LabDoctorM
pre-commit autoupdate
pre-commit clean
```

## Отключение (только для экстренных случаев)

```bash
# Разовый коммит без проверок (только в личной ветке!)
git commit --no-verify -m 'fix(critical): экстренный патч'

# НЕ ИСПОЛЬЗОВАТЬ В MAIN — Guardian всё равно заблокирует push
```

## Troubleshooting

### Хук блокирует коммит в main, но я — ЗавЛаб

Guardian блокирует **всех** — это сделано специально. Даже ЗавЛаб должен работать через worktree и мердж через Муравья. Это гарантирует, что:
- Каждый коммит проверен
- История main чиста
- Никаких случайных изменений

### Хук говорит "секрет обнаружен", но это тестовый код

Если это тестовый фиктивный токен (например, `token = "test-123"`), используй `--no-verify` для этого конкретного коммита. Но лучше — вынеси в `.env` или `config.yaml.template`.

### prepare-commit-msg не подсказывает scope

Scope определяется по первым путям изменённых файлов. Если файлы не в `projects/` — подсказки не будет. Это нормально для изменений в `docs/`, `scripts/`, корне.

### Как перенести текущую работу в worktree

```bash
# 1. Сохранить текущие изменения
git stash

# 2. Создать worktree
bash agent-workspace.sh create owl

# 3. Перейти в worktree
cd /root/LabDoctorM/worktrees/owl/

# 4. Применить stash
git stash pop

# 5. Работать как обычно
```

## Идентичность коммитов (ADR-027)

Все агенты коммитят из общего worktree `/root/LabDoctorM` → запись identity в общий
`.git/config` вызывает гонку (параллельный агент перетирает автора). Решение —
задавать автора через env **в момент коммита**, а не через config:

```bash
# Коммить ТОЛЬКО через обёртку (race-free):
scripts/lab-commit.sh <agent> -m "сообщение"
# или
LAB_AGENT=<agent> scripts/lab-commit.sh -m "сообщение"
```

Скрипт `lab-commit.sh` резолвит автора из параметра `<агент>` и ставит `GIT_AUTHOR_*` локально (race-free).
`pre-commit` содержит **гейт идентичности**: если `LAB_AGENT` задан — автор обязан
совпадать с его identity; иначе автор обязан быть в белом списке. Иначе коммит блокируется.

> ⚠️ Прямой `git commit` без обёртки может уйти под чужим автором. Хук `export
> GIT_AUTHOR_NAME` НЕ работает (хук — дочерний процесс, env не доходит до `git commit`).

Тест: `tests/test_git_identity_gate.sh` (4 сценария, включая воспроизведение гонки).

## История изменений

| Дата | Версия | Изменения |
|------|--------|-----------|
| 16.06.2026 | v2.1 | ADR-027: гейт идентичности в pre-commit + обёртка lab-commit.sh (race-free атрибуция). Убрана racy-запись config из session_startup/agent-workspace |
| 05.06.2026 | v2.0 | Git Guardian: 4 типа хуков, проверка секретов, конфигов, размера, worktree manager, merge-to-main |
| 03.06.2026 | v1.2 | Pre-commit: block-direct-main + check-commit-format |
| 03.06.2026 | v1.1 | Обновлены QUALITY_STANDARDS, ADR-012 |
| 20.05.2026 | v1.0 | Создан ADR-012, базовые правила коммитов |

---

*Документ создан Совой 05.06.2026.*
*Вопросы — через почту лаборатории, адресат: owl.*
