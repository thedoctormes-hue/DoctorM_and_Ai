---
name: gitlab
description: Правила работы с Git в LabDoctorM — кабинеты (projects/), workspaces, единый git user. Корень НЕ репозиторий. Используй когда ЗавЛаб говорит «работай в кабинете X» или при любых git-операциях в лаборатории.
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
- **Единый git user** — `LabDoctorM / agents@labdoctorm.ru` во всех проектах

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
5. Подробная документация: `projects/DoctorM_and_Ai/archive/root-files/GIT.md`

## Структура файлов

```
/root/LabDoctorM/                  # НЕ репозиторий (нет .git/)
├── projects/                       # Кабинеты (отдельные репозитории)
│   └── <кабинет>/
│       ├── .git/                   # Свой git-репозиторий
│       ├── bin/lab-commit.sh       # Скрипт атрибуции (симлинк на scripts/lab-commit.sh)
│       ├── scripts/lab-commit.sh   # Оригинал скрипта
│       └── .qwen/git-authors.json  # Маппинг агентов (свой для каждого проекта)
├── workspaces/                     # Рабочие столы агентов (НЕ репозитории)
├── data/                           # Данные
└── vault/                          # Хранилище
```

## Добавление нового агента

Попроси ЗавЛаб добавить запись в `.qwen/git-authors.json` внутри нужного проекта:

```json
{
  "newagent": { "name": "НовыйАгент", "email": "newagent@labdoctorm.ru" }
}
```

Файл лежит в `projects/<кабинет>/.qwen/git-authors.json` — свой для каждого проекта.

## Известные агенты

- antcat → Муравей
- bestia → Бестия
- dominika → Доминика
- kotolizator → КотОлизатор
- mangust → Мангуст
- owl → Сова
- raven → Ворон
- streikbrecher → Штрейкбрехер
