---
name: gitlab
description: Правила работы с Git в LabDoctorM — кабинеты (projects/), workspaces, атрибуция по агенту (per-agent через git-authors.json). Корень НЕ репозиторий. Используй когда ЗавЛаб говорит «работай в кабинете X» или при любых git-операциях в лаборатории.
version: "1.0.0"
author: "ЗавЛаб"
last_reviewed: "2026-06-22"
status: active
metadata:
  {"openclaw": {"requires": {"bins": ["jq"]}}}
user-invocable: true
triggers:
  phrases:
    - "работай в кабинете"
    - "git-lab"
    - "lab-commit"
    - "кабинет"
    - "worktree"
    - "коммит через lab-commit"
    - "атрибуция коммита"
    - "новый агент в git"
    - "git-authors.json"
    - "правила git"
  patterns:
    - "как коммитить в лаборатории"
    - "как работать с git"
    - "проект + git + кабинет"
    - "добавить агента"
    - "commit + lab"
    - "ветки + стратегия"
    - "кабинет + проект + начать"
  scope:
    - любые git-операции в лаборатории
    - работа в кабинетах (projects/)
    - настройка атрибуции агентов
    - вопросы по git-структуре LabDoctorM
---

# Git-Lab — правила работы с Git в LabDoctorM

## Терминология

- **Лаборатория** — `/root/LabDoctorM`, НЕ репозиторий (корневой `.git/` удалён 22.06.2026)
- **Кабинет** — отдельный проект-репозиторий в `projects/` (например, `projects/snablab`)
- **Рабочий стол** — `workspaces/<твой_агент>/`, НЕ репозиторий
- **Атрибуция по агенту (per-agent)** — `lab-commit.sh <agent>` ставит `GIT_AUTHOR_*`/`GIT_COMMITTER_*` на основе `<кабинет>/git-authors.json`. Единого user'а нет: каждый коммит подписан конкретным агентом (имя+email берутся из git-authors.json).

## Быстрый старт

### 1. Перейти в проект

```bash
cd /root/LabDoctorM/projects/<кабинет>
```

### 2. Работать и коммитить

```bash
# ... изменения ...
./bin/lab-commit.sh <твой_агент> -m "сообщение коммита"
git push origin <ветка>
```

## Правила

1. **ВСЕГДА** используй `./bin/lab-commit.sh <агент> -m "сообщение"` — гарантирует правильную атрибуцию
2. **НЕ** используй `git config user.name` / `git config user.email` — агенты перезатирают друг друга
3. **НЕ** коммить `.env` файлы — pre-commit заблокирует
4. **НЕ** дублируй функционал — проверь существующий код через grep/glob (PAT-004)
5. Подробная документация: `projects/DoctorM_and_Ai/docs/GIT.md`

## Структура файлов

```
/root/LabDoctorM/                  # НЕ репозиторий (нет .git/)
├── projects/                       # Кабинеты (отдельные репозитории)
│   └── <кабинет>/
│       ├── .git/                   # Свой git-репозиторий
│       ├── bin/lab-commit.sh       # Скрипт атрибуции (обычный файл, копия оригинала)
│       ├── scripts/lab-commit.sh   # Оригинал скрипта (в DoctorM_and_Ai/scripts/lab-commit.sh)
│       └── git-authors.json        # Маппинг агентов (в корне кабинета, НЕ в .qwen/)
├── workspaces/                     # Рабочие столы агентов (НЕ репозитории)
├── data/                           # Данные
└── vault/                          # Хранилище
```

**Примечание:** `git-authors.json` лежит в корне кабинета (`<кабинет>/git-authors.json`), НЕ в `.qwen/` (путь `.qwen/` не используется). Это подтверждено во всех кабинетах (myrmex-control, snablab, lab-memory и др.).

## Добавление нового агента

Попроси ЗавЛаб добавить запись в `<кабинет>/git-authors.json` внутри нужного проекта:

```json
{
  "newagent": { "name": "НовыйАгент", "email": "newagent@labdoctorm.ru" }
}
```

Файл лежит в `projects/<кабинет>/git-authors.json` — свой для каждого проекта.

## Известные агенты

- antcat → Муравей
- bestia → Бестия
- dominika → Доминика
- kotolizator → КотОлизатор
- mangust → Мангуст
- owl → Сова
- raven → Ворон
- streikbrecher → Штрейкбрехер

## Обработка ошибок

### lab-commit.sh не найден
- Проверь путь: `projects/<кабинет>/bin/lab-commit.sh`
- Если нет — проверь `projects/<кабинет>/scripts/lab-commit.sh`
- Если нет нигде — скопируй оригинал (НЕ симлинк, это обычные файлы): `cp ../../DoctorM_and_Ai/scripts/lab-commit.sh projects/<кабинет>/bin/lab-commit.sh`
- Оригинал скрипта: `projects/DoctorM_and_Ai/scripts/lab-commit.sh`

### git-authors.json не найден
- Проверь `<кабинет>/git-authors.json` (корень кабинета, НЕ `.qwen/`)
- Если файла нет — попроси ЗавЛаб добавить агента
- Не создавай файл сам — формат должен быть согласован

### Коммит упал (pre-commit hook)
- `.env`, ключи, cookies — pre-commit заблокирует, это ожидаемо
- Убери файлы из staging: `git reset HEAD <файл>`
- Добавь в `.gitignore` если файл должен быть локальным

### Push rejected (non-fast-forward)
- `git pull --rebase origin <ветка>`
- Реши конфликты, затем `git push origin <ветка>`
- НЕ делай `git push --force` без согласования с ЗавЛабом

### Worktree не создаётся
- `create-worktree.sh` отсутствует в репозитории (ранее был в `shared/git-rules/`, удалён)
- Создай worktree вручную: `git -C /root/LabDoctorM/projects/<кабинет> worktree add /root/LabDoctorM/workspaces/<агент>/<кабинет> -b <ветка>`

## Формат вывода при работе с git

```
📂 Проект: <кабинет>
🌿 Ветка: <ветка>
📝 Статус: <clean / N изменений>

Коммиты сессии:
- <хеш> — <сообщение>

Команды:
- git -C /root/LabDoctorM/projects/<кабинет> <команда>
```
