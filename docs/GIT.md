# Git Infrastructure — LabDoctorM

## Терминология

- **Лаборатория** — `/root/LabDoctorM`, общий монорепозиторий
- **Кабинет** — отдельный проект-репозиторий внутри `projects/`
- **Рабочий стол (workspace)** — персональная папка агента: `workspaces/<agent>/`

## Структура

```
/root/LabDoctorM/
├── .qwen/
│   └── git-authors.json          # Маппинг агентов → имя + email
├── projects/                     # Кабинеты (отдельные репозитории)
│   ├── snablab/
│   ├── hype-pilot/
│   ├── lab-monitoring/
│   └── ... (18 проектов)
├── workspaces/                   # Рабочие столы агентов
│   ├── owl/
│   ├── antcat/
│   └── ... (8 агентов)
├── bin/
│   └── lab-commit.sh → ../scripts/lab-commit.sh (симлинк)
└── scripts/
    └── lab-commit.sh             # Основной скрипт коммита
```

## Агенты и их идентичности

Каждый агент имеет запись в `.qwen/git-authors.json`:

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
/root/LabDoctorM/bin/lab-commit.sh <agent> -m "feat: описание изменений"
```

Скрипт автоматически установит `GIT_AUTHOR_NAME` и `GIT_AUTHOR_EMAIL` из `git-authors.json`.

### 4. Пушить

```bash
git push origin <текущая_ветка>
```

Правило: сначала `git pull --rebase`, потом `git push` (защита от race).

## Pre-commit хуки

В каждом кабинете:

- **gitleaks** — сканирование секретов
- **Блокировка .env** — файлы `.env` нельзя закоммитить
- **Проверка автора** — только агенты из `git-authors.json`

## Добавление нового агента

1. Добавить запись в `/root/LabDoctorM/.qwen/git-authors.json`
2. Готово — `lab-commit.sh` сразу подхватит.

## Реестр кабинетов (18)

- artifact-pulse, autoexpert, cheque-bot, consilium, free-api-hunter
- hype-pilot, lab-monitoring, lab-playwright-expert, lab-vault
- mail-daemon, msk-gastro-digest-bot, myrmex-control, remote-access
- snablab, SNZK, stenographer, vpn-daemon, zprr-tracker

## Важно

- **НЕ использовать** `git config user.name` / `git config user.email` — агенты перезатирают друг друга
- **ВСЕГДА** использовать `bin/lab-commit.sh <agent>` — атрибуция через переменные окружения
- **НЕ коммитить** `.env` файлы — pre-commit хук заблокирует
- **НЕ дублировать** функционал — перед созданием нового кода проверить существующий (PAT-004)
- **НЕ пушить** в main напрямую — через PR или с разрешения ЗавЛаба/Кота
