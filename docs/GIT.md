# Git Infrastructure — LabDoctorM

## Терминология

- **Лаборатория** — `/root/LabDoctorM`, общая директория
- **Кабинет** — отдельный проект-репозиторий внутри `projects/`
- **Рабочий стол (workspace)** — персональная папка агента: `workspaces/<agent>/`

## Структура

```
/root/LabDoctorM/
├── projects/                     # Кабинеты (отдельные git-репозитории)
│   ├── snablab/
│   ├── hype-pilot/
│   ├── lab-monitoring/
│   └── ... (21 проект)
├── workspaces/                   # Рабочие столы агентов
│   ├── owl/
│   ├── antcat/
│   └── ... (8 агентов)
├── bin/
│   └── lab-commit.sh             # Симлинк на scripts/lab-commit.sh
└── scripts/
    └── lab-commit.sh             # Основной скрипт коммита
```

## Агенты и их идентичности

Каждый агент имеет уникальное имя для коммитов:

- **antcat** → Муравей <antcat@labdoctorm.ru>
- **bestia** → Бестия <bestia@labdoctorm.ru>
- **dominika** → Доминика <dominika@labdoctorm.ru>
- **kotolizator** → КотОлизатор <kotolizator@labdoctorm.ru>
- **mangust** → Мангуст <mangust@labdoctorm.ru>
- **owl** → Сова <owl@labdoctorm.ru>
- **raven** → Ворон <raven@labdoctorm.ru>
- **streikbrecher** → Штрейкбрехер <streikbrecher@labdoctorm.ru>

## Как агенту работать с гитом

### 1. Получить кабинет (указывает ЗавЛаб)

Пример: «работай в кабинете snablab»

### 2. Работать в кабинете

```bash
cd /root/LabDoctorM/projects/<cabinet>
# ... писать код ...
```

### 3. Коммитить

```bash
cd /root/LabDoctorM/projects/<cabinet>
git add <файлы>
./bin/lab-commit.sh <agent> -m "feat(scope): описание изменений"
```

Скрипт автоматически установит `GIT_AUTHOR_NAME` и `GIT_AUTHOR_EMAIL` через переменные окружения (race-free).

### 4. Пушить

```bash
git pull --rebase origin main
git push origin <текущая_ветка>
```

Правило: сначала `git pull --rebase`, потом `git push` (защита от race).

## Pre-commit хуки

В каждом кабинете:

- **gitleaks** — сканирование секретов
- **Блокировка .env** — файлы `.env` нельзя закоммитить
- **Проверка формата сообщения** — `type(scope): описание`

## Добавление нового агента

1. Добавить запись в `lab-commit.sh` (массив AGENTS)
2. Готово — скрипт сразу подхватит.

## Реестр кабинетов (21)

- api-hub, artifact-pulse, autoexpert, cheque-bot, consilium, free-api-hunter
- hype-pilot, lab-monitoring, lab-playwright-expert, lab-vault
- mail-daemon, mcp-tools, msk-gastro-digest-bot, myrmex-control, remote-access
- snablab, SNZK, stenographer, vpn-daemon, zprr-tracker

## Важно

- **НЕ использовать** `git config user.name` / `git config user.email` — агенты перезатирают друг друга
- **ВСЕГДА** использовать `bin/lab-commit.sh <agent>` — атрибуция через переменные окружения
- **НЕ коммитить** `.env` файлы — pre-commit хук заблокирует
- **НЕ дублировать** функционал — перед созданием нового кода проверить существующий (PAT-004)
- **НЕ пушить** в main напрямую — через PR или с разрешения ЗавЛаба/Кота
