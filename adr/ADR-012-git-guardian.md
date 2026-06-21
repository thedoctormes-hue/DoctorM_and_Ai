---
description: 'ADR-012: Git Guardian — система защиты коммитов и workflow лаборатории'
type: adr
id: ADR-012
title: Git Guardian — система защиты коммитов
status: accepted
date: 2026-06-05
created: 2026-06-05
updated: 2026-06-12
author: Сова
supersedes: []
superseded_by: []
code_refs:
- scripts/git-guardian.sh
- scripts/agent-workspace.sh
- scripts/merge-to-main.sh
- .pre-commit-config.yaml
- docs/GIT_GUARDIAN.md
last_verified: 2026-06-11
confidence: outdated
source: agent
freshness_score: 98
last_checked: '2026-06-20T01:00:15+00:00'
---# ADR-012: Git Guardian — система защиты коммитов и workflow лаборатории

## Статус
**Accepted** — создан 05.06.2026, внедрён и протестирован
**Enforcement:** активен с 10.06.2026 — git-guardian.sh + 4 хука (pre-commit, commit-msg, pre-push, prepare-commit-msg)

## Контекст

Аудит коммитов 01–04.06.2026 выявил 197 коммитов в main за 4 дня. Все от `ЗавЛаб`.
Проблемы:
- Нет ветвления — всё идёт прямо в main
- Нет атомарности — поглощения размазаны по 3-4 коммитам
- `chore: snapshot` в main — технические снимки засоряют историю
- `WIP on streikbrecher/main` — индексные коммиты в main
- `Revert` цепочки — сломал, откатил, откат сломал ещё раз
- config.yaml деплоится из репозитория — архитектурная бомба
- Хуки v1.2 есть, но ЗавЛаб обходит их через `--no-verify` или работает из корня
- Worktrees не создаются автоматически — директория пуста

## Исследование

Проведён анализ трёх моделей workflow:
- **Git-Flow** — не подходит: сложен, долгие ветки, не для AI-агентов
- **Trunk-Based Development** — частично подходит: короткие ветки, частые коммиты
- **Conventional Commits** — основа: уже частично внедрён, но не работает

**Специфика лаборатории:**
- 1 человек (ЗавЛаб) + 7 AI-агентов
- 25+ проектов в одном репозитории (монорепо)
- Агенты работают параллельно, автономно
- Скорость критична — агент не должен ждать

## Решение

### Архитектура Git Guardian v2.0

**Философия:** Не ограничивать скорость — направлять её.

**Компоненты:**
1. `git-guardian.sh` — ядро: 4 типа хуков (pre-commit, commit-msg, pre-push, prepare-commit-msg)
2. `agent-workspace.sh` — управление worktrees агентов
3. `merge-to-main.sh` — безопасный мердж в main (для Муравья)
4. `.pre-commit-config.yaml` — конфигурация pre-commit

### 1. Защита main — абсолютная

- **Прямые коммиты в main — ЗАПРЕЩЕНЫ для всех**, включая ЗавЛаба
- **Push в main — ЗАПРЕЩЕН** через pre-push hook
- **Merge в main — только через Муравья** (тимлид) или ЗавЛаба через `merge-to-main.sh`
- Merge-commits и rebase в main — разрешены (для мержа от Муравья)

### 2. Worktree-ориентированный workflow

```bash
# Агент создаёт worktree
bash agent-workspace.sh create owl
cd /root/LabDoctorM/worktrees/owl/

# Работает, коммитит в свою ветку
git add projects/owl/specific-files
git commit -m 'feat(owl): добавить проверку качества'
git push origin owl/main

# Муравей мержит
bash merge-to-main.sh owl/main --squash
git push origin main
```

### 3. Автоподсказка scope (prepare-commit-msg)

При коммите агент видит подсказку:
```
# 💡 Git Guardian подсказка:
#    Рекомендуемый формат: feat(owl): <описание>
#    Отмени с: git commit --no-verify (только в личной ветке!)
```

### 4. Проверки качества (4 уровня)

**pre-commit:**
- Блокировка main/master
- Лимит: 30 файлов, 500 строк
- Проверка секретов (password, token, api_key, private key)
- Проверка конфигов (config.yaml, .env, secrets)
- Проверка на git add . из корня

**commit-msg:**
- Conventional Commits формат
- Scope обязателен
- Длина subject ≤72 символов
- Нет точки в конце
- Блокировка snapshot/checkpoint/wip

**pre-push:**
- Блокировка push в main
- Лимит: 20 коммитов за push
- Проверка дубликатов

**prepare-commit-msg:**
- Автоподстановка scope по изменённым файлам
- Подсказка типа (test/docs/chore)

### 5. Конфиги вне git

- config.yaml → config.yaml.template (в git)
- config.yaml → генерируется из template + .env (не в git)
- .env → в .gitignore

### 6. Формат сообщений

```
<type>(<scope>): <описание на русском>
```

**type:** `feat` | `fix` | `test` | `docs` | `refactor` | `chore` | `perf` | `ci` | `build` | `revert`
**scope:** имя проекта (обязательно!)
**описание:** повелительное наклонение, на русском

## Последствия

**Что получим:**
- Чистая история в main — каждый коммит осмыслен
- Возможность откатить один проект без затрагивания других
- Лаборанты работают изолированно, не ломают друг другу код
- Автоматическая проверка качества — без ручного ревью каждого коммита
- Конфиги и секреты — вне git

**Что потеряем:**
- Скорость — работа в worktree + push в ветку = 30 сек на коммит вместо 5 сек напрямую в main
- Привычка «коммитить всё подряд» — придётся переучивать

**Риски:**
- Worktree не обновляется автоматически — нужен `sync` при переключении
- Лаборанты могут игнорировать hook — нужен контроль от Муравья
- `--no-verify` обходит проверки — но push в main всё равно заблокирован

## Связанные документы

- `docs/GIT_GUARDIAN.md` — полная документация системы
- `docs/QUALITY_STANDARDS.md` — стандарты (секция 12)
- `scripts/git-guardian.sh` — ядро системы
- `scripts/agent-workspace.sh` — управление worktrees
- `scripts/merge-to-main.sh` — безопасный мердж
- `.pre-commit-config.yaml` — конфигурация pre-commit
