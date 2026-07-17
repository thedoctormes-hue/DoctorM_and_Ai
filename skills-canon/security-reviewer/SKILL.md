---
name: security-reviewer
description: "Статический security-аудит кода: 5 категорий (Secrets/Input/SQLi/Auth/XSS) + SECURITY REPORT."
version: "1.0.0"
author: "antcat"
last_reviewed: "2026-07-17"
status: "active"
user-invocable: true
triggers:
  phrases:
    - "проверь безопасность"
    - "security review"
    - "аудит безопасности"
    - "прогони секьюрити"
    - "проверь на уязвимости"
  patterns:
    - "нужен security-аудит перед коммитом"
    - "проверь код на sql-инъекции и xss"
  scope:
    - любая задача с кодом перед коммитом/сдачей
    - после функциональных правок (новые endpoint, SQL, HTML-вывод)
    - по запросу ЗавЛаба или аудитора (owl)
metadata:
  openclaw:
    requires:
      bins: ["bash", "git", "grep"]
      env: []
      config: []
    primaryEnv: "NA"
---

# Security Reviewer — статический аудит безопасности

Дополняет `accepting-work` (там только «секреты не в staged») и
`verification-loop` (Security-фаза). Проводит углублённый статический
разбор кода по 5 категориям и выдаёт `SECURITY REPORT`.

## Когда применять
- Перед коммитом/сдачей любой задачи с кодом (особенно new endpoint / SQL / HTML)
- После правок, затрагивающих ввод пользователя, БД-запросы, вывод в HTTP/HTML
- Когда ЗавЛаб или аудитор (owl) просит security-аудит
- Как расширение Security-фазы `verification-loop`

## Границы применимости
- Статический анализ (grep/чтение), НЕ динамический пентест и не SAST-инструмент
- Не исправляет уязвимости автоматически — только находит и сообщает
- Не заменяет `accepting-work` (процессную приёмку) — только security-слой
- Не пушит и не создаёт PR — только локальная проверка + дифф
- Не ловит бизнес-логические уязвимости (race conditions, logic flaws) — только очевидные паттерны

## Чек-лист качества
- [ ] Все 5 категорий прогнаны (Secrets / Input Val / SQLi / Auth / XSS)
- [ ] По каждой категории есть статус PASS/WARN/FAIL (не «пропустил»)
- [ ] SECURITY REPORT выведен в каноничном формате
- [ ] Overall = CLEAN только если 0 FAIL и 0 WARN
- [ ] При FAIL — назван файл:строка и тип уязвимости

## Анти-паттерны
- Коммитить код с FAIL в Secrets (рецидив утечки ключей)
- Путать с accepting-work (тот только staged-secrets, этого мало)
- Считать WARN «безопасным» — WARN тоже требует взгляда человека
- Игнорировать SQLi/XSS как «не моя зона» — это база безопасности веба

---

## Протокол: 5 категорий

Сканируются файлы в staged (`git diff --cached --name-only`) и рабочие
изменения. Базовый инструмент — `grep -nE` по паттернам (настраиваемо
под стек). Ниже — дефолтные паттерны; адаптируй под язык.

### 1. Secrets — секреты не попадают в репозиторий
- Паттерн: `(api_key|apikey|secret|token|password|passwd|private_key)\s*=\s*['"][^'"]+['"]`
- Плюс: `.env` в tracked (`git ls-files | grep -E '\.env$'`), отсутствие `.env` в `.gitignore`
- FAIL — если найден реальный секрет в staged или `.env` tracked
- WARN — если `.env` нет в `.gitignore` (риск случайного коммита)

### 2. Input Validation — ввод не валидируется
- Паттерн: `eval\(`, `exec\(`, `os\.system\(`, `subprocess\.(call|run|Popen)\([^)]*\{|\$\(`, `child_process\.exec\(`
- WARN — если в вызов передаётся переменная из внешнего ввода без фильтра
- FAIL — если прямая вставка пользовательского ввода в shell/exec

### 3. SQLi — SQL без параметризации
- Паттерн: `execute\([^)]*(\+|%|\.format|f['\"])`, `raw\(`, `cursor\.execute\([^)]*['"][^'\"]*\{`
- FAIL — если SQL-строка собирается конкатенацией/интерполяцией переменных
- WARN — если ORM raw-запрос с переменной

### 4. Auth — авторизация и доступы
- Паттерн: `verify=False`, `check_hostname=False`, `auth=None`, `allow_unauthenticated`, `skip_auth`
- FAIL — если отключена проверка TLS/аутентификации
- WARN — если hardcoded credential или токен с пустой проверкой

### 5. XSS — неэкранированный вывод в HTML/HTTP
- Паттерн: `innerHTML\s*=`, `dangerouslySetInnerHTML`, `res\.send\([^)]*req\.`, `render\([^)]*user`, `echo \$_`
- FAIL — если пользовательский ввод пишется в HTML/response без экранирования
- WARN — если используется `innerHTML` без санитайзера

## Формат SECURITY REPORT

```
=== SECURITY REPORT ===
Secrets:   PASS (no secrets in staged, .env ignored)
Input Val: WARN (2 unvalidated subprocess calls in src/runner.py:42,55)
SQLi:      PASS
Auth:      FAIL (verify=False in src/client.py:88)
XSS:       FAIL (innerHTML with user input in src/ui/chat.tsx:120)
---
Overall:   BLOCKER (2 FAIL, 1 WARN) — коммит запрещён до исправления
==============================
```

Правила статуса:
- `PASS` — паттерны не найдены / найденное безопасно
- `WARN` — подозрительное, требует взгляда человека (не блокирует, но фиксируется)
- `FAIL` — очевидная уязвимость
- `Overall: CLEAN` — 0 FAIL и 0 WARN
- `Overall: NEEDS REVIEW` — есть WARN (нет FAIL)
- `Overall: BLOCKER` — есть FAIL (коммит запрещён до исправления)

Exit-код: `0` при CLEAN, `1` при NEEDS REVIEW/BLOCKER (чтобы CI/приёмка могла блокировать).

## Интеграция

- Дополняет `accepting-work`: тот проверяет «секреты не в staged», этот —
  полный аудит (SQLi/XSS/Auth/Input). Запускай security-reviewer ДО
  accepting-work.
- Расширяет `verification-loop`: Security-фаза может делегировать сюда
  (этот skill — углублённая версия Security-фазы).
- Аудитор (owl) доукомплектовывает verification steps поверх этого skill.
