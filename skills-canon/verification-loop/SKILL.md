---
name: verification-loop
description: "Технический гейт перед сдачей: 6 фаз (Build/Type/Lint/Test/Security/Diff) + VERIFICATION REPORT."
version: "1.0.0"
author: "antcat"
last_reviewed: "2026-07-17"
status: "active"
user-invocable: true
triggers:
  phrases:
    - "проверь код"
    - "верификация"
    - "verification loop"
    - "прогони проверки"
    - "готово к сдаче проверь"
  patterns:
    - "нужна верификация перед коммитом"
    - "проверь сборку и тесты"
    - "прогони build/lint/test"
  scope:
    - любая задача с кодом перед коммитом/сдачей
    - перед accepting-work (технический gate)
    - после рефакторинга/правок
metadata:
  openclaw:
    requires:
      bins: ["bash", "git"]
      env: []
      config: []
    primaryEnv: "NA"
---

# Verification Loop — технический гейт перед сдачей

Автономный цикл проверки готовности кода. Прогоняет 6 фаз и выдаёт
каноничный `VERIFICATION REPORT`. Это **техническая** проверка —
процессная приёмка (документация, хвосты, git-стратегия) остаётся за
`accepting-work`.

## Когда применять
- Перед коммитом/сдачей любой задачи с кодом (независимо от accepting-work)
- После рефакторинга/правок — убедиться, что ничего не сломалось
- Когда пользователь просит «проверь код» / «верификация» / «прогони проверки»
- Как быстрый gate перед accepting-work (этот скил = техника, accepting-work = процесс)

## Границы применимости
- Не заменяет `accepting-work` (документация, хвосты, git-стратегия) — только 6 технических фаз
- Не исправляет ошибки автоматически — только сообщает PASS/FAIL/SKIP
- Не пушит в remote и не создаёт PR — только локальная проверка + дифф
- Не применим к задачам без кода (дока/аналитика) — все фазы SKIP, Overall N/A
- Стек определяется автодетектом (package.json / go.mod / requirements.txt / pyproject.toml); неизвестный стек → фазы SKIP с пометкой

## Чек-лист качества
- [ ] Все 6 фаз прогнаны (Build / Type / Lint / Test / Security / Diff)
- [ ] По каждой фазе есть статус PASS/FAIL/SKIP (не «пропустил не глядя»)
- [ ] VERIFICATION REPORT выведен в каноничном формате
- [ ] Overall = READY только если обязательные фазы PASS/SKIP (0 FAIL)
- [ ] При NOT READY — названы конкретные FAIL-фазы и причина

## Анти-паттерны
- «Сделано, коммичу» без прогона verification-loop (рецидив I-02 «файл ≠ работающая система»)
- Игнорирование FAIL в Diff (коммит случайных/секретных файлов)
- Путать verification-loop с accepting-work (двойная работа или пропуск процесса)
- SKIP фазы «потому что долго» без отметки в отчёте

---

## Протокол: 6 фаз

Стек детектится по наличию манифеста в рабочей директории:
- `package.json` → Node/TS (npm/pnpm/yarn)
- `go.mod` → Go
- `requirements.txt` / `pyproject.toml` / `setup.py` → Python
- `Makefile` / `Cargo.toml` → fallback

По каждой фазе выбирается команда для детектированного стека. Если команда
неприменима (нет в стеке) → фаза `SKIP`.

### 1. Build — собирается ли проект
- Node: `npm run build` (или `yarn build` / `pnpm build`)
- Go: `go build ./...`
- Python: `python -m compileall -q .`
- Иное: `make build` (если есть Makefile)

### 2. Type — типизация (если применимо)
- Node/TS: `npx tsc --noEmit`
- Go: `go vet ./...`
- Python: `python -m mypy .` (если установлен mypy)
- Нет типизации в стеке → SKIP

### 3. Lint — стиль/ошибки статич. анализа
- Node: `npx eslint .` (или `biome lint`)
- Go: `golangci-lint run` (или `go vet`)
- Python: `ruff check .` (или `flake8`)
- Нет линтера → SKIP

### 4. Test — тесты
- Node: `npm test` (или `vitest run` / `jest`)
- Go: `go test ./...`
- Python: `pytest` (или `python -m unittest`)
- Нет тестов → SKIP (с пометкой «no tests»)

### 5. Security — базовая проверка
- Node: `npm audit --audit-level=high`
- Go: `govulncheck ./...` (если установлен)
- Python: `pip-audit` или `bandit -r .`
- Универсальный fallback: `git diff --cached | grep -iE '(api_key|secret|token|password)\s*='` (поиск секретов в staged)
- Нет инструмента → SKIP

### 6. Diff — что попадёт в коммит
- `git status --short` + `git diff --stat` (показать изменения)
- Проверка на случайные/секретные файлы в staged (`.env`, `*.key`, `credentials`)
- Если не в git-репозитории → SKIP с сообщением

## Формат VERIFICATION REPORT

Выводится ровно в этом формате (агент или скрипт `bin/verification-loop.sh`):

```
=== VERIFICATION REPORT ===
Build:    PASS (npm run build, 1.2s)
Type:     PASS (tsc --noEmit)
Lint:     FAIL (eslint: 3 errors in src/x.ts)
Test:     PASS (vitest: 42 passed)
Security: SKIP (npm audit: no lockfile)
Diff:     PASS (2 files, +15 -3, no secrets)
---
Overall:  NOT READY (1 FAIL: Lint)
==============================
```

Правила статуса:
- `PASS` — команда отработала с кодом 0
- `FAIL` — команда вернула ненулевой код ИЛИ найдены критичные проблемы
- `SKIP` — фаза неприменима к стеку (не значит ошибка)
- `Overall: READY` — только если ВСЕ фазы PASS или SKIP (0 FAIL)
- `Overall: NOT READY` — если хотя бы одна фаза FAIL (перечислить какие)
- `Overall: N/A` — стек не детектится (не код-проект, верификация неприменима)

Exit-код скрипта: `0` при READY, `1` при NOT READY, `2` при N/A (чтобы CI мог использовать).

## Автоматизация

`bin/verification-loop.sh` — готовый детектор стека + прогон 6 фаз с выводом
VERIFICATION REPORT. Запуск: `bash bin/verification-loop.sh [путь_к_проекту]`.
Без аргумента работает в текущей директории.
