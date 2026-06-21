---
description: "⚙️ Реестр скриптов лаборатории"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-06-21
status: active
---
# ⚙️ Реестр скриптов лаборатории

Актуальные скрипты после миграции на OpenClaw (июнь 2026).

## Структура

```
/root/LabDoctorM/
├── bin/                          # Общие утилиты
│   └── lab-commit.sh             # Коммит от имени агента (через проект)
├── scripts/                      # Системные скрипты
│   ├── safe-config-edit.sh       # Безопасное редактирование openclaw.json
│   └── ...
├── projects/
│   └── <проект>/
│       ├── bin/
│       │   └── lab-commit.sh     # Коммит агента в проект
│       └── scripts/              # Скрипты проекта
└── workspaces/
    └── <агент>/                  # Воркспейс агента
```

## lab-commit.sh — коммит агента

**Расположение:** `projects/<проект>/bin/lab-commit.sh`

**Использование:**
```bash
cd /root/LabDoctorM/projects/<проект>
./bin/lab-commit.sh <агент> -m "тип(скоуп): описание"
```

**Параметры:**
- `агент` — имя агента (kotolizator, antcat, bestia, raven, owl, streikbrecher, mangust, dominika, muravey)
- `тип` — feat | fix | test | docs | refactor | chore
- `скоуп` — проект или зона
- `описание` — на русском

**Правила (ADR-012, ADR-037):**
- Ветка: `<agent>/<type>-<scope>` (создаётся автоматически от main)
- Формат сообщения: `type(scope): описание`
- Прямые коммиты в main — ЗАПРЕЩЕНЫ
- snapshot/checkpoint/wip — блокируются
- Только tracked файлы (`git add -u`), без мусора
- Автор коммита — указывается через параметр, не через git config

**Примеры:**
```bash
cd /root/LabDoctorM/projects/vpn-daemon
./bin/lab-commit.sh kotolizator -m "feat(vpn-daemon): добавить healthcheck endpoint"

cd /root/LabDoctorM/projects/DoctorM_and_Ai
./bin/lab-commit.sh owl -m "docs(audit): обновить реестр артефактов"
```

## safe-config-edit.sh — безопасное редактирование конфига

**Расположение:** `/root/LabDoctorM/scripts/safe-config-edit.sh`

**Использование:**
```bash
bash /root/LabDoctorM/scripts/safe-config-edit.sh [editor]
```

**Что делает:**
1. Останавливает OpenClaw gateway
2. Создаёт бэкап `openclaw.json`
3. Открывает редактор
4. Проверяет JSON валидность
5. Запускает gateway

**Правила:**
- ВСЕГДА использовать этот скрипт перед правками конфига
- Никогда не редактировать `openclaw.json` напрямую при работающем gateway
- Никогда не использовать `tee`/`echo` в конфиг напрямую

## merge-to-main.sh — мерж в main

**Расположение:** `projects/DoctorM_and_Ai/scripts/merge-to-main.sh`

**Использование:**
```bash
cd /root/LabDoctorM/projects/DoctorM_and_Ai
./scripts/merge-to-main.sh <ветка>
```

**Правила:**
- Мерж в main — только через Кота или ЗавЛаба
- Перед мержем — убедиться что ветка актуальна (`git pull --rebase`)

## git-guardian.sh — защита коммитов

**Расположение:** `projects/DoctorM_and_Ai/scripts/git-guardian.sh`

**Что проверяет:**
- Нет ли секретов (ключи, токены, пароли) в коммите
- Формат сообщения коммита
- Нет ли запрещённых файлов (.env, ключи)

## Утилиты для работы с голосом

**Расположение:** системные утилиты (whisper, sherpa-onnx)

**whisper-cli** — STT (speech-to-text):
```bash
whisper-cli -l ru <file.wav>
```

**sherpa-onnx-offline-tts** — TTS (text-to-speech):
```bash
voice-speak "текст" [speaker] [output]
```
Голоса: dmitri (default), irina, denis, ruslan

## Устаревшие скрипты (не используются)

Следующие скрипты были частью системы `.qwen/` и более не используются:
- `.qwen/scripts/session_startup.sh` — заменён на OpenClaw инициализацию
- `.qwen/scripts/agent-commit.sh` — заменён на `lab-commit.sh`
- `.qwen/scripts/session_end.sh` — заменён на OpenClaw закрытие сессии
- `.qwen/hooks/` — заменены на OpenClaw hooks/skills
