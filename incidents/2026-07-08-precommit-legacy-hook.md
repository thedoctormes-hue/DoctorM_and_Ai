---
id: INC-20260708-precommit-legacy-hook
timestamp: "2026-07-08T00:00:00Z"
category: tech
type: config_error
severity: low
status: retired
agent: unknown
title: free-api-hunter pre-commit legacy hook blocked all commits
date: "2026-07-08T08:30:00+00:00"
author: streikbrecher
tags: [free-api-hunter, git, pre-commit, hooks, infra]
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Инцидент: pre-commit legacy hook блокировал коммиты в free-api-hunter

## Симптомы
- `lab-commit.sh` завершался с `EXIT=1`, коммит не создавался.
- В выводе: `Использование: .../.git/hooks/pre-commit.legacy <pre-commit|commit-msg|pre-push|prepare-commit-msg> [file]` и `/bin/sh: 8: Bad substitution`.
- При этом реальные хуки pre-commit.com (gitleaks, detect-private-key, trailing-whitespace и т.д.) отрабатывали и показывали `Passed`.

## Диагностика
1. `git status` — файл staged (`M configs/free-api-hunter.service`), но коммит не создаётся.
2. `GIT_TRACE=1 git commit` показал, что git запускает только `.git/hooks/pre-commit` (pre-commit.com-шаблон), но изнутри прогона сыплется usage от `pre-commit.legacy`.
3. `.git/hooks/pre-commit.legacy` — это бэкап СТАРОГО хука (Git Guardian v2.0), который pre-commit.com оставляет при `install` (переименовывает предыдущий хук в `.legacy`).
4. Скрипт имеет shebang `#!/bin/bash`, но вызывался через `/bin/sh` (dash) → `ARGS=(...)` массив давал `Bad substitution` и падал.
5. Нигде в конфигах/кэше pre-commit.com ссылок на `pre-commit.legacy` нет — это дохлый backup, который тем не менее вызывался и обрушивал коммит.

## Причина
- Устаревший backup-хук `pre-commit.legacy` (Git Guardian) ошибочно вызывался в цепочке коммита и падал, прерывая `git commit` до создания коммита, несмотря на то что основной pre-commit.com хук проходил.

## Решение
- Официальная чистка pre-commit.com: `python3 -mpre_commit install -f`
  - перезаписывает `.git/hooks/pre-commit` актуальным шаблоном
  - удаляет `.git/hooks/pre-commit.legacy` (флаг `-f` = overwrite удаляет legacy-бэкап)
- После этого `lab-commit.sh` отработал: коммит `9ba86c5` создан и запушен (`fd7fc63..9ba86c5 main -> main`).
- gitleaks / detect-private-key / остальные хуки — Passed, секретов в staged нет.

## Предупреждение
- При будущих коммитах в free-api-hunter: если снова видишь usage от `pre-commit.legacy` + `Bad substitution` — это вернувшийся дохлый backup. Лечение: `python3 -mpre_commit install -f` в корне репозитория.
- Не путать с реальными провалами хуков (gitleaks и т.п.) — те печатают `Failed`, а не usage.

## Связь с задачей
- Обнаружено при accepting-work по фиксу безопасности: привязка free-api-hunter API к `127.0.0.1` вместо `0.0.0.0` (закрытие прямой публичной экспозиции порта 8090). Фикс закоммичен как `9ba86c5`.
