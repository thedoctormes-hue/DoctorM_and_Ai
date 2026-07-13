---
name: "ebsh"
description: "Протокол решения задач: классификация, labsearch, скилы, финализация."
status: active
version: "1.2.0"
date: "2026-07-10T18:45:00.000Z"
metadata: { "openclaw": { "emoji": "⚡" } }
author: "ЗавЛаб, Муравей"
last_reviewed: "2026-06-29"
user-invocable: true
triggers:
  phrases:
    - "примени скил ебш"
    - "ебш"
    - "решить задачу"
    - "спланировать задачу"
    - "оркестрация"
    - "разложить задачу"
    - "как решить"
    - "что делать с"
    - "подойди к задаче"
    - "комплексное решение"
  patterns:
    - "задача + решение"
    - "сложный запрос"
    - "много шагов"
    - "нужен план"
    - "исследовать + реализовать"
  scope:
    - любая задача требующая более одного шага
    - задачи с неочевидным подходом
    - комплексные исследования
    - планирование и декомпозиция
---

# ЕБШ — Универсальный протокол решения задач

## Название

**ЕБШ** (утверждено ЗавЛабом).

## Назначение

Любую задачу можно решить эффективнее, если выполнить 3 шага:
1. Оценить задачу и заспавнить необходимое количество агентов
2. Выбрать релевантные скилы и/или инструменты
3. Найти инсайты и паттерны в семантической памяти лаборатории и при глубоком исследовании в интернете

Этот скил — **оркестратор-маршрутизатор**. Он не решает задачу сам, а определяет КАК решать и какие скилы/агенты задействовать.

## Жизненный цикл сессии (Session Lifecycle)

ЕБШ — не только брокер задач, но и оркестратор жизненного цикла сессии. Любая сессия проходит 5 стадий; ЕБШ маршрутизирует между ними и гарантирует передачу контекста (handoff), чтобы скилы не переспрашивали состояние.

Стадии:
- **Stage 0 — Start** → `starting-session` (обязателен при старте; проверяет здоровье, пишет handoff-state). ЕБШ инициирует его первым, если ещё не пройден в этой сессии.
- **Stage 1 — Understand** → `deep-dive` (исследовать/разобраться) ИЛИ `root-cause-archaeologist` (инцидент/баг/сага ошибок).
- **Stage 2 — Act** → сама работа (может зацикливаться; под защитой anti-loop).
- **Stage 3 — Accept** → `accepting-work` (проверка DoD: тесты, линтер, гит, документация) перед объявлением «готово».
- **Stage 4 — Close** → `finishing-session` (дневник + MEMORY + git + хвосты).

**Handoff-контракт:** Stage 0 пишет `memory/<date>-session-state.json` со структурой `{agent, role, checks_summary, open_incidents, open_questions, relevant_services}`. Downstream-скилы (Stage 1/3/4) ЧИТАЮТ его вместо повторного опроса. Поля `open_questions` и `relevant_services` — связующее звено между стартом и работой агента.

## Триггеры

**Основные фразы:**
- «примени скил ебш»
- «ебш»
- «решить задачу [описание]»
- «как решить [описание]»
- «спланировать [описание]»
- «разложи задачу»
- «комплексное решение»
- «подойди к задаче системно»

**Паттерны:**
- Задача с несколькими неочевидными шагами
- Запрос на исследование + реализацию
- Нужен план действий
- Сложный запрос без явного решения

## Обязательное правило

**Веб-поиск ТОЛЬКО через research-скил.** Никаких прямых вызовов web_search или web_fetch в рамках протокола ЕБШ. Если labsearch не дал результата — спавним research-агент.

## Протокол (4 шага)

### Шаг 0 — Классификация задачи

Агент получает задачу → определяет task-type через skill-matrix.json.

**Session-bootstrap (приоритет):** если это старт сессии и файл `memory/<date>-session-state.json` отсутствует → СНАЧАЛА выполнить `starting-session` (Stage 0 жизненного цикла), затем продолжить классификацию. Это гарантирует, что агент видит здоровье системы и открытые инциденты до взятия задачи.

**Уверенность:** классификация автоматическая, но при низкой уверенности или неоднозначном типе — спросить пользователя: «Какой тип задачи: [список 9 типов]?», не угадывать. Согласовано с разделом «Обработка ошибок».

**9 типов задач:**
- `skill-improvement` — улучшить/создать скил
- `code-fix` — исправить баг
- `research` — исследовать технологию/подход
- `deploy` — задеплоить сервис
- `new-feature` — новая фича
- `docs-update` — обновить документацию
- `incident` — инцидент/сбой
- `audit` — провести аудит
- `config-change` — изменить конфигурацию

**Классификация — автоматическая** (LLM по описанию задачи). Без подтверждения пользователя.

### Шаг 1 — Семантический поиск (labsearch)

**Устойчивость (снять SPOF):** перед вызовом сделать pre-check эмбеддера — `curl -s --max-time 5 http://127.0.0.1:8082/health`. Если не OK → сразу переходить к fallback (research-агент), не вызывая labsearch. Сам вызов `lab_search.py` обернуть в retry: 1–2 попытки с backoff 3–5с. Только после неудачи ВСЕХ попыток считать labsearch недоступным и спавнить research-агента (веб только через research-скил).

```bash
python3 /root/LabDoctorM/projects/lab-memory/scripts/lab_search.py search "<описание задачи>" --limit 5
```

**Пороги:**
- score >= 0.65 → результат релевантен, используем локальную память
- score < 0.60 → шум или пусто → спавним research-агент (веб через research-скил)
- 0.60–0.65 → используем с осторожностью, помечать как «возможно не релевантно»

**Что ищем:**
- Решения аналогичных задач из памяти
- ADR по теме
- Инциденты и их решения
- Паттерны и правила лаборатории
- Существующие скилы и их ограничения

### Шаг 2 — Применение скилов

Берёт скилы из skill-matrix.json по определённому task-type.

**Pre-flight валидация:** перед спавном проверить, что каждый скилл из плана (список `skills` + все узлы `depends_on`) физически существует: `ls /root/.openclaw/skills/<skill>/SKILL.md`. Если скилл отсутствует — не спавнить, пропустить с пометкой в отчёте (или эскалировать). Защита от дрифта матрицы: при удалении/переименовании скилла — чистить `skill-matrix.json`.

**Параллельно vs последовательно:**
- Если `depends_on` пустой → спавним всех параллельно
- Если `depends_on` есть → выполняем по цепочке зависимостей

**Пример зависимостей для `new-feature`:**
```
research + spike (параллельно) → change-management (ждёт оба) → accepting-work (ждёт change-management) → finishing-session (ждёт accepting-work)
```

**Anti-loop:** каждый спавненный агент работает под защитой anti-loop — скилл даёт правила против зацикливания (circuit breaker, retry-limit на каждого спавненного агента), перехватывающие зависания и эскалирующие при исчерпании попыток.

### Шаг 3 — Финализация

**Синтез результатов:** если несколько спавненных агентов вернули конфликтующие выводы — разрешить по приоритету источников и пометить противоречие; свести в единый отчёт. Только после синтеза — финализация.

- Если был код → запускаем **accepting-work** (тесты, линтер, гит, документация)
- Всегда → запускаем **finishing-session** (запись итогов в память, проверка инцидентов)

## Skill-Matrix

Хранится в `~/.openclaw/skills/ebsh/references/skill-matrix.json`.

⚠️ `skill-creator` и `spike` из матрицы — это built-in/plugin скилы OpenClaw (доступны как плагины, а не как canon-симлинки в `~/.openclaw/skills`). Они живые; pre-flight проверка `ls ~/.openclaw/skills/<skill>/SKILL.md` для них неприменима — спавнить напрямую как plugin-скилы. См. `_builtin_plugin_skills` в skill-matrix.json.

**Структура записи:**
```json
{
  "task-type": {
    "skills": ["skill1", "skill2"],
    "complexity": "small|medium|large",
    "depends_on": {
      "skill_later": ["skill_earlier1", "skill_earlier2"]
    }
  }
}
```

**Текущая матрица:**

- **skill-improvement** → skill-creator, fact-check, accepting-work, change-management | complexity: medium | depends_on: accepting-work → [skill-creator, fact-check]
- **code-fix** → spike, change-management, accepting-work, anti-loop | complexity: small-medium | depends_on: accepting-work → [spike, change-management]
- **research** → research, spike, anti-loop, fact-check | complexity: medium | depends_on: {} (параллельно)
- **deploy** → safe-restart, change-management, accepting-work | complexity: medium | depends_on: accepting-work → [safe-restart, change-management]
- **new-feature** → research, spike, change-management, anti-loop, accepting-work, finishing-session | complexity: large | depends_on: change-management → [research, spike], accepting-work → [change-management], finishing-session → [accepting-work]
- **docs-update** → skill-creator, fact-check, change-management | complexity: small | depends_on: {} (параллельно)
- **incident** → registering-incident, safe-restart, anti-loop | complexity: small-medium | depends_on: {} (параллельно)
- **audit** → research, fact-check, anti-loop | complexity: medium | depends_on: {} (параллельно)
- **config-change** → change-management, safe-restart, accepting-work | complexity: medium | depends_on: accepting-work → [change-management, safe-restart]
- **session-start** → starting-session | complexity: small | depends_on: {} | stage: 0
- **investigate** → deep-dive, research, fact-check | complexity: medium | depends_on: {} | stage: 1
- **incident-deep** → root-cause-archaeologist, registering-incident, anti-loop | complexity: medium | depends_on: {} | stage: 1

## Оценка сложности → количество агентов

**Сложность из матрицы + контекст задачи:**

- **small** (малая) → соло, 0-1 агент. Пример: обновить README, исправить опечатку.
- **medium** (средняя) → 2-3 агента параллельно. Пример: улучшить скил, провести аудит.
- **large** (большая) → 3-5 агентов + taskflow для координации. Пример: новая фича с исследованием, реализацией и деплоем.

**Правило:** если контекст задачи сложнее типичного для её типа → повышаем сложность на уровне.

## Формат вывода

```
⚡ ЕБШ активирован

📋 Задача: <описание>
🏷 Тип: <task-type>
📊 Сложность: <small/medium/large>

🔍 Семантический поиск:
- <результат 1> (score: X)
- <результат 2> (score: Y)

🛤 План выполнения:
1. <скил 1> — <что делает>
2. <скил 2> — <что делает> (зависит от: <скил 1>)
3. <финализация>

🚀 Спавню N агентов...
```

## Обработка ошибок

- **labsearch недоступен** → сразу спавним research-агент
- **Не удалось классифицировать** → спросить пользователя: «Какой тип задачи: [список]?»
- **Агент упал** → anti-loop перехватывает → повторить или эскалировать
- **Зависимость не выполнена** → ждать или пропустить с пометкой в отчёте
- **research-скил не найден** → эскалировать к пользователю с пометкой. НЕ использовать сырой web_fetch/web_search (нарушение правила «Веб-поиск ТОЛЬКО через research-скил»).

## Правила

- Веб-поиск ТОЛЬКО через research-скил
- Классификация автоматическая, но при низкой уверенности — спросить пользователя (см. Шаг 0 / Обработка ошибок)
- Anti-loop обязателен для каждого спавна
- Финализация всегда включает finishing-session
- Если код менялся — accepting-work обязателен
- starting-session обязателен при старте сессии (Stage 0 жизненного цикла)
- Не создавать пустых коммитов
- Не додумывать факты (PAT-005)
- Не использовать таблицы в Telegram (PAT-006)

## Связанные скилы

- **research** — глубокое исследование (веб только через него)
- **spike** — быстрый прототип, проверка выполнимости
- **change-management** — план изменений
- **anti-loop** — защита от зацикливания
- **accepting-work** — приёмка работы с кодом
- **finishing-session** — завершение сессии, запись итогов
- **starting-session** — старт сессии, health-check, handoff-state (Stage 0)
- **deep-dive** — глубокое погружение в код/систему (Stage 1)
- **root-cause-archaeologist** — раскопки корневой причины инцидента (Stage 1)
- **skill-creator** — создание/редактирование скилов
- **fact-check** — проверка фактов
- **safe-restart** — безопасный рестарт сервисов
- **registering-incident** — регистрация инцидентов

## Пример работы

**Запрос:** «Проведи аудит скила starting-session»

**ЕБШ:**
1. Классификация → `audit` (авто)
2. Сложность → `medium` (из матрицы)
3. labsearch: «audit starting-session skill» → score 0.72 → нашёл ADR-0056 (skill-creation-standard), incidents
4. Скилы из матрицы: research (уже использован), fact-check, anti-loop
5. depends_on пустой → спавнит fact-check + anti-loop параллельно
6. Собирает результаты → формирует отчёт
7. Финализация: finishing-session → запись в memory/YYYY-MM-DD.md

### Пример жизненного цикла

**Старт сессии агента:**
1. ЕБШ видит старт → Stage 0: `starting-session` проверяет gateway/сервисы/инциденты, пишет `memory/<date>-session-state.json` (роль + свои сервисы + открытые инциденты).
2. Пользователь даёт задачу «разберись почему apihub down» → Stage 1: `root-cause-archaeologist` читает handoff-state (видит INC-20260708-apihub-down, не переспрашивает), раскапывает причину.
3. Stage 2: правка/реализация под защитой anti-loop.
4. Stage 3: `accepting-work` проверяет DoD.
5. Stage 4: `finishing-session` пишет дневник + обновляет MEMORY + git.

## Источники

- ADR-0048 (Gateway Config Management Standard)
- PAT-005 (Не додумывать факты)
- PAT-006 (Без таблиц в Telegram)
- Hoff Digital — Definition of Done in AI-Assisted Codebase (2026)
- Scrum.org — DoD for AI Agents (2026)
- Опыт лаборатории: улучшение 3 скилов (starting-session, accepting-work, finishing-session), 2026-06-29
