---
description: "🔍 Честный аудит репозиториев лаборатории ЗавЛаб"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-08
status: active
---
# 🔍 Честный аудит репозиториев лаборатории ЗавЛаб

**Дата:** 2026-05-06
**Аудитор:** OWL (Qwen Code)
**Методология:** проверка каждого проекта из projects.json на существование, git-состояние, README, контакты, мусор

---

## 📊 Сводная таблица

| # | Проект | Существует | README | Git | Актуальность доки | Оценка |
|---|--------|-----------|--------|-----|-------------------|--------|
| 1 | kotolizator | ✅ | ✅ | ✅ | Устаревшая | ⚠️ |
| 2 | msk-gastro-digest-bot | ✅ | ❌ | ⚠️ Нет remote | Отсутствует | 🔴 |
| 3 | vpn-daemon | ✅ | ❌ | ⚠️ Нет remote | Отсутствует | 🔴 |
| 4 | mail-daemon | ✅ | ❌ | ✅ | Отсутствует | 🔴 |
| 5 | stenographer | ✅ | ❌ | ⚠️ Нет remote | Отсутствует | 🔴 |
| 6 | llm-evangelist | ✅ | ✅ | ✅ | Актуальна | ✅ |
| 7 | zakupki-drop-bot | ✅ | ✅ | ⚠️ Нет remote | Актуальна | ⚠️ |
| 8 | shtab-ai-gb52 | ✅ | ✅ | ⚠️ Dubious ownership | Устаревшая | ⚠️ |
| 9 | syncthing-dashboard | ✅ | ✅ | ⚠️ Нет remote | Устаревшая | ⚠️ |
| 10 | os-lab-api | ✅ | ✅ | ⚠️ Нет remote | Устаревшая | ⚠️ |
| 11 | protocol | ✅ | ❌ | ⚠️ Нет remote | Отсутствует | 🔴 |
| 12 | metrics | ✅ | ❌ | ❌ Нет .git | Отсутствует | 🔴 |
| 13 | protocol-bot | ❌ | — | — | — | 💀 |
| 14 | zprr-tracker | ❌ | — | — | — | 💀 |

---

## 🔴 КРИТИЧЕСКИЕ НАХОДКИ

### 1. МАССОВОЕ СОВПАДЕНИЕ GIT REMOTE — 6 репо указывают на один адрес

**Это самая серьёзная проблема аудита.**

Следующие 6 директорий имеют **одинаковый** git remote `https://github.com/thedoctormes-hue/zprr-tracker.git`:

| Директория | Должна быть |
|------------|-------------|
| `/root/LabDoctorM/` (kotolizator) | Свой репо |
| `msk-gastro-digest-bot/` | Свой репо |
| `stenographer/` | Свой репо |
| `zakupki-drop-bot/` | Свой репо |
| `protocol/` | Свой репо |
| `zprr-tracker/` | ✅ Верно |

Более того, все 6 репо имеют **идентичные коммиты** (`11cae4b`, `1df324b`, `fbdf4f5`). Это значит, что кто-то скопировал `.git` директорию из zprr-tracker в другие проекты, либо сделал `git init` с тем же remote. **Это не просто ошибка — это бомба.** Пуш из любого из этих репо перезапишет чужой код в репозитории zprr-tracker.

**Рекомендация:** Немедленно исправить remote у всех 5 неправильных репо.

### 2. Два проекта НЕ СУЩЕСТВУЮТ НА ДИСКЕ

- **protocol-bot** (`/root/protocol/bot/`) — директория не существует. При этом сервис `protocol-bot.service` **работает** и запускает `/root/LabDoctorM/venv/bin/python3 -m bot.main` из другого места.
- **zprr-tracker** (`/root/LabDoctorM/projects/web-apps/zprr-tracker/`) — директория не существует. При этом в `projects.json` он указан как приоритет 2, а в git remote на него ссылаются 6 репо.

### 3. 8 из 14 проектов БЕЗ README

Проекты без README: msk-gastro-digest-bot, vpn-daemon, mail-daemon, stenographer, protocol, metrics, protocol-bot (не существует), zprr-tracker (не существует).

---

## 📋 ДЕТАЛЬНЫЙ РАЗБОР КАЖДОГО ПРОЕКТА

### 1. kotolizator — `/root/LabDoctorM/`

- **Существует:** ✅
- **README:** ✅ Красивый, с бейджами, контактами
- **Git remote:** ❌ Указывает на `zprr-tracker.git` (должен быть свой)
- **Последний коммит:** `11cae4b` — security: remove token from remote URL
- **Контакты в README:** ✅ Все 4 контакта верны (@DoctorMES, thedoctormes@gmail.com, +79032749274, shtab-ai.ru)
- **Несоответствия:**
  - README описывает "AntColony", "Polyp Detection", "ZPRR Tracker" — но это скорее лендинг-резюме, чем документация CLI-системы
  - Бейджи CI ссылаются на `zprr-tracker` — неверный репо
  - В корне лежат файлы неясного назначения: `ANT_COLONY_B2B_POSITIONING.md`, `COLD_EMAIL_STRATEGY.md`, `PRICE_LIST.md`, `TELEGRAM_POST_TEMPLATE.md`, `POLYP_DETECTION_OFFER.md` — это не код, а маркетинговые материалы. Загромождают корень.
  - Папка `OpenClawBox/` в корне — это отдельный проект, не указанный в projects.json
- **Оценка документации:** ⚠️ Устаревшая (бейджи ведут не туда, контент — резюме, а не доки)

### 2. msk-gastro-digest-bot

- **Существует:** ✅
- **README:** ❌ Нет
- **Git remote:** ❌ Указывает на `zprr-tracker.git`
- **Последний коммит:** `11cae4b` — идентичен другим (скопирован)
- **Код:** `main.py` (17967 байт), работает как systemd сервис
- **Несоответствия:**
  - Нет README вообще
  - Git remote неверный
  - Файлы `processed.json`, `processed_afternoon.json`, `processed_morning.json` — runtime данные в репозитории
  - Папка `logs/` внутри проекта
- **Оценка документации:** 🔴 Отсутствует

### 3. vpn-daemon

- **Существует:** ✅
- **README:** ❌ Нет (есть QWEN.md и STATUS_REPORT.md)
- **Git remote:** ❌ Нет remote вообще
- **Последний коммит:** `fb87649` — security: secure VPN configs
- **Код:** `src/bot/`, `scripts/`, `configs/`, `vpnconfig/` — активно развивается
- **Сервис:** работает
- **Несоответствия:**
  - Нет README
  - Нет git remote (нельзя пушить)
  - Логи в папке проекта: `bot.log` (384K), `xray-access.log` (5.1M), `xray-error.log`, `xray-health.log`
  - Папка `backups/` с бэкапами в репозитории
  - `COMMERCIAL_OFFER.md` — коммерческое предложение в коде
  - `.env` содержит REALITY ключи — секреты в потенциально коммитимом файле
- **Оценка документации:** 🔴 Отсутствует

### 4. mail-daemon

- **Существует:** ✅
- **README:** ❌ Нет (есть MEMORY.md)
- **Git remote:** ✅ `MailDaemonRobot.git`
- **Последний коммит:** `47774db` — fix: заменить выдуманный email на реальный
- **Код:** `main.py` (27947 байт), `storage.py`, `config.py`
- **Несоответствия:**
  - Нет README
  - Лог `maildaemon.log` — **4.0M** в репозитории
  - `.aider.chat.history.md` (25K) и `.aider.input.history` (4.8K) — история AI-ассистента в репо
  - `.aider.tags.cache.v4/cache.db` (32K) — кэш AI-ассистента в репо
  - `fsm.db` — runtime SQLite с WAL-файлами в репозитории
  - `.env` содержит email-пароль в открытом виде: `eilfkznmgrbmlxio`
- **Оценка документации:** 🔴 Отсутствует

### 5. stenographer

- **Существует:** ✅
- **README:** ❌ Нет (есть MEMORY.md, BIG_FILES_GUIDE.md, PROMPT_STANDARDS.md)
- **Git remote:** ❌ Указывает на `zprr-tracker.git`
- **Последний коммит:** `11cae4b` — идентичен (скопирован)
- **Код:** `bot/`, `core/`, `webapp/`, `utils/`, `prompts/`
- **Сервисы:** `stenographerobot.service` (работает), `stenographer-webapp.service` (работает), `local-bot-api.service` (**FAILED**)
- **Несоответствия:**
  - Нет README
  - Git remote неверный
  - Лог `bot.log` — **5.8M** в репозитории
  - `local-bot-api.service` — **упал** (failed, exit-code 125)
  - Папка `webapp/` — отдельный подпроект со своим README, но не зарегистрирован в projects.json
- **Оценка документации:** 🔴 Отсутствует

### 6. llm-evangelist

- **Существует:** ✅
- **README:** ✅ Подробный, с командами и примерами
- **Git remote:** ✅ `llm-evangelist.git` (с токеном в URL — см. проблемы)
- **Последний коммит:** `27bb1d6` — feat: llm-evangelist premium README
- **Код:** `main.py` (26663 байт), `analyzer/`, `scanner/`, `model_selector/`, `cache/`
- **Несоответствия:**
  - В git remote URL закодирован GitHub токен: `***GITHUB_TOKEN_REDACTED***@github.com/...` — **секрет в remote URL**
  - Две папки venv: `.venv/` (3 уровня вложенности) и `venv/` — дубликат
  - `models.db` (244K) и `models_cache.json` (140K) — runtime данные в репо
  - `llm_history.db` (16K) — runtime данные в репо
  - `config.json` закоммичен — может содержать чувствительные настройки
  - В README нет контактов (@DoctorMES, email, телефон, сайт)
- **Оценка документации:** ✅ Актуальна (но без контактов)

### 7. zakupki-drop-bot

- **Существует:** ✅
- **README:** ✅ Есть, с командами
- **Git remote:** ❌ Указывает на `zprr-tracker.git`
- **Последний коммит:** `11cae4b` — идентичен (скопирован)
- **Код:** `zakupki_parser.py`, `price_analyzer.py`, `zakupki_database.py`, `drop_shipping_bot.py`, `webapp/`
- **Несоответствия:**
  - Git remote неверный
  - В README нет контактов
  - Папка `webapp/` — подпроект, не зарегистрирован в projects.json
- **Оценка документации:** ⚠️ Актуальна, но неполная

### 8. shtab-ai-gb52

- **Существует:** ✅
- **README:** ✅ Есть
- **Git:** ⚠️ Dubious ownership (www-data vs root)
- **Код:** `index.html`, `assets/` — статический сайт
- **Несоответствия:**
  - README описывает "КДЛ — Клинико-диагностическая лаборатория" — но сайт выглядит как лендинг DoctorM&Ai
  - В README нет контактов
  - Git ownership проблема — репо принадлежит www-data, но git работает от root
  - Нет информации о том, что это за сайт на самом деле
- **Оценка документации:** ⚠️ Устаревшая / вводящая в заблуждение

### 9. syncthing-dashboard

- **Существует:** ✅
- **README:** ✅ Подробный, с бейджами
- **Git remote:** ❌ Нет remote
- **Последний коммит:** нет (нет .git? — есть .git, но нет remote)
- **Код:** React + Vite + TypeScript, `src/`, `dist/`
- **Несоответствия:**
  - Нет git remote
  - Бейджи CI ссылаются на `LabDoctorM/syncthing-dashboard` — но репо не существует на GitHub
  - Ссылка "Live Demo" → `https://dashboard.shtab-ai.ru` — не проверено, работает ли
  - В README нет контактов
  - `node_modules/` (387 директорий) — в репозитории (должна быть в .gitignore)
  - `package-lock.json` (339K) — можно коммитить для npm, но засоряет историю
- **Оценка документации:** ⚠️ Устаревшая (бейджи ведут в никуда)

### 10. os-lab-api

- **Существует:** ✅
- **README:** ✅ Подробный, с бейджами
- **Git remote:** ❌ Нет remote
- **Последний коммит:** нет remote
- **Код:** FastAPI, `main.py`, `tests/`
- **Сервис:** `os-lab-dashboard-api.service` — **работает**
- **Несоответствия:**
  - Нет git remote
  - Бейджи CI ссылаются на `thedoctormes-hue/os-lab-api` — но репо не существует на GitHub
  - В README нет контактов
  - `.pytest_cache/`, `.ruff_cache/` — кэши в репозитории
  - Утверждение "100% critical path coverage" — не подтверждено (в tests/ мало файлов)
- **Оценка документации:** ⚠️ Устаревшая (бейджи ведут в никуда, завышены метрики)

### 11. protocol

- **Существует:** ✅
- **README:** ❌ Нет (есть QWEN.md, STATE_OF_PROTOCOL.md, SPRINT спеки)
- **Git remote:** ❌ Указывает на `zprr-tracker.git`
- **Последний коммит:** `11cae4b` — идентичен (скопирован)
- **Код:** `app/`, `bot/`, `frontend/`, `tests/`, `scripts/`
- **Несоответствия:**
  - Git remote неверный
  - Нет README
  - **7 устаревших спецификаций** в корне: `SPRINT3_SPEC.md` (26K), `SPRINT3_FINAL_SPEC.md`, `SPRINT3_ULTIMATE.md`, `SPRINT4_SPEC.md`, `FIXES_SPEC.md`, `STATE_OF_PROTOCOL.md`, `TRANSITION.md`, `TECHNICAL_AUDIT.md` — 80% из них устарели
  - `Skeleton front.zip` (152K) — бинарник в репозитории
  - `protocol.zip` (11K) — зачем?
  - `protocol.db` (0 байт) — пустой файл
  - Куча shell-скриптов в корне: `check_db.py`, `check_logs.sh`, `check_process.sh`, `clean_db.py`, `clean_test_data.sh`, `cleanup.sh`, `exec.py`, `fix_commands.sh`, `get_logs.py`, `read_db.py`, `run_bot.sh`, `run_get_logs.sh`, `run_query.py`, `run_sql.sh` — мусор
  - Тестовые файлы в корне: `test_everything.py`, `test_final.py`, `test_fts.py`, `test_full_cycle.py` — должны быть в `tests/`
- **Оценка документации:** 🔴 Отсутствует (вместо README — свалка спек)

### 12. metrics

- **Существует:** ✅
- **README:** ❌ Нет
- **Git:** ❌ Нет .git вообще
- **Код:** `collect.py` (1590 байт), `weekly/2026-05-01.json`, `yearly/` (пусто)
- **Несоответствия:**
  - Нет git — нельзя отслеживать изменения
  - Нет README
  - Один скрипт и папки с данными — это не проект, а скрипт
  - `yearly/` пустой — данные не собираются
- **Оценка документации:** 🔴 Отсутствует

### 13. protocol-bot

- **Существует:** ❌ Директория `/root/protocol/bot/` не существует
- **Сервис:** `protocol-bot.service` — **работает**, но запускает код из `/root/LabDoctorM/venv/bin/python3 -m bot.main` (из venv корня, не из отдельной папки)
- **Несоответствия:**
  - projects.json указывает путь, которого нет
  - Сервис работает, но код лежит не там, где указано
  - В projects.json указан `channel: @Protocolstandbot` — не проверено
- **Оценка документации:** 💀 Проект не существует на диске

### 14. zprr-tracker

- **Существует:** ❌ Директория `/root/LabDoctorM/projects/web-apps/zprr-tracker/` не существует
- **Несоответствия:**
  - Проект указан в projects.json как приоритет 2
  - На него ссылаются 6 git remote
  - Сам проект отсутствует на диске
  - В памяти (MEMORY.md) есть записи о ZPRR — проект был, но куда-то делся
- **Оценка документации:** 💀 Проект не существует на диске

---

## 🗑️ МУСОР И ДУБЛИ

### Логи в репозиториях (НЕ ДОЛЖНЫ БЫТЬ В GIT)
| Файл | Размер |
|------|--------|
| `mail-daemon/maildaemon.log` | 4.0M |
| `stenographer/bot.log` | 5.8M |
| `vpn-daemon/logs/xray-access.log` | 5.1M |
| `vpn-daemon/logs/bot.log` | 384K |
| `vpn-daemon/logs/xray-health.log` | 92K |
| `vpn-daemon/logs/xray-error.log` | 76K |
| `protocol/bot.log` | 492K |

**Итого:** ~16.7M логов в репозиториях

### Runtime данные в репозиториях (НЕ ДОЛЖНЫ БЫТЬ В GIT)
- `mail-daemon/fsm.db` + WAL-файлы (52K)
- `mail-daemon/.aider.tags.cache.v4/cache.db` (32K)
- `llm-evangelist/models.db` (244K)
- `llm-evangelist/models_cache.json` (140K)
- `llm-evangelist/llm_history.db` (16K)
- `msk-gastro-digest-bot/processed*.json` (3 файла)
- `OpenClawBox/openclawbox.db` (20K)
- `protocol/protocol.db` (0 байт — пустой, зачем в репо?)

### Дубликаты
- `llm-evangelist` — два venv: `.venv/` и `venv/`
- `protocol` — 7 спецификаций с пересекающимся содержимым (SPRINT3_SPEC, SPRINT3_FINAL_SPEC, SPRINT3_ULTIMATE)
- `kotolizator` — маркетинговые файлы в корне (5+ .md файлов, не относящихся к коду)

### Бинарники в репозиториях
- `protocol/Skeleton front.zip` (152K)
- `protocol/protocol.zip` (11K)

---

## 🔒 ПРОБЛЕМЫ БЕЗОПАСНОСТИ

1. **GitHub токен в git remote URL** — `llm-evangelist` remote содержит `***GITHUB_TOKEN_REDACTED***@github.com/...`
2. **REALITY ключи в .env** — `vpn-daemon/.env` содержит private/public keys для 3 серверов
3. **Email пароль в .env** — `mail-daemon/.env` содержит `eilfkznmgrbmlxio`
4. **OpenRouter API ключа** — в .env файлах 4 проектов
5. **Telegram bot токены** — в .env файлах 5 проектов
6. **local-bot-api.service** — упал (failed), но не чинился 24 часа

---

## 📞 АУДИТ КОНТАКТОВ

Требуемые контакты: Telegram @DoctorMES, email thedoctormes@gmail.com, сайт shtab-ai.ru, телефон +79032749274

| Проект | README есть? | @DoctorMES | Email | Телефон | Сайт |
|--------|-------------|------------|-------|---------|------|
| kotolizator | ✅ | ✅ | ✅ | ✅ | ✅ |
| llm-evangelist | ✅ | ❌ | ❌ | ❌ | ❌ |
| zakupki-drop-bot | ✅ | ❌ | ❌ | ❌ | ❌ |
| shtab-ai-gb52 | ✅ | ❌ | ❌ | ❌ | ✅ |
| syncthing-dashboard | ✅ | ❌ | ❌ | ❌ | ❌ |
| os-lab-api | ✅ | ❌ | ❌ | ❌ | ❌ |

**Только 1 из 6 README** содержит полный набор контактов.

---

## 🏆 ИТОГОВЫЙ ВЕРДИКТ

| Метрика | Значение |
|---------|----------|
| Проектов в projects.json | 14 |
| Существуют на диске | 12 из 14 |
| Имеют README | 6 из 14 |
| Имеют верный git remote | 2 из 14 |
| Имеют полные контакты в README | 1 из 14 |
| Не имеют мусора в репо | 2 из 14 |
| Сервисы работают | 5 из 6 (local-bot-api упал) |

### Главные проблемы:
1. **6 git remote указывают на один репо** — критический баг, требует немедленного исправления
2. **8 проектов без README** — невозможно онбордиться
3. **16.7M логов** в репозиториях
4. **Секреты в .env** — потенциально коммитимые
5. **2 проекта не существуют** на диске, но указаны в projects.json
6. **Контакты отсутствуют** в 5 из 6 README

### Рекомендации (по приоритету):
1. 🔴 **Немедленно:** Исправить git remote у 5 проектов (убрать zprr-tracker remote)
2. 🔴 **Немедленно:** Удалить GitHub токен из remote URL llm-evangelist
3. 🟡 **Эта неделя:** Создать README для 8 проектов
4. 🟡 **Эта неделя:** Добавить контакты во все README
5. 🟡 **Эта неделя:** Почистить логи и runtime данные из репозиториев
6. 🟢 **Этот месяц:** Удалить устаревшие спецификации из protocol
7. 🟢 **Этот месяц:** Определить судьбу zprr-tracker и protocol-bot (восстановить или удалить из projects.json)
8. 🟢 **Этот месяц:** Исправить local-bot-api.service
