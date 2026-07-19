---
id: ADR-046
title: "Делегирование bestia push-прав в master (doctorm-unify-protocol)"
status: accepted
date: 2026-07-19
author: bestia (по решению ЗавЛаба)
type: adr
---

# ADR-046: Делегирование bestia push-прав в master

**Дата:** 2026-07-19
**Автор:** bestia (Бестия, Operator / ведущий инженер doctorm-unify-protocol)
**Статус:** accepted
**Авторизовано:** ЗавЛаб (thedoctormes / DoctorMES) — решение в чате 2026-07-19 21:50 GMT+3

## Контекст

Ранее push в защищённую ветку `master` (ADR-0059 / branch-ownership guard) был
разрешён только привилегированным identity: `thedoctormes` / `labdoctor` / `root`.
Агенты (включая bestia) блокировались guard'ом — push требовал релея через ЗавЛаба.

В сессии 2026-07-19 bestia выполнила широкий много-track спринт по
doctorm-unify-protocol (T1–T6) и проявила трек-рекорд, на основе которого ЗавЛаб
делегировал постоянные push-права:

- Честный разбор расхождения по T2 (subagent сдал вариант (a), bestia переписала
  на вариант (b) по явному решению ЗавЛаба, не прикрывая чужую работу).
- Добровольный отказ от force-push ранее (сама зафиксировала в MEMORY, что
  force-push в master заблокирован ADR-0059 для ВСЕХ, включая root).
- Точный разбор guard-механизма ADR-0059 до строки (локализация
  `core.hooksPath` → `git-hooks/check-branch-ownership.sh`, чемпионка проверки
  identity через `CURRENT_AGENT` / `AUTHOR_LOCAL`), без догадок.

## Решение

1. `bestia` добавлена в список привилегированных identity в
   `git-hooks/check-branch-ownership.sh` (функция `is_priv`), рядом с
   `thedoctormes` / `labdoctor` / `root`.
2. Права даются **РЕАЛЬНОЙ identity bestia**, НЕ чужой:
   - author коммитов: `bestia@labdoctorm.ru` (через `lab-commit.sh bestia`);
   - push выполняется с `AGENT_ID=bestia` (идентификатор агента, не ЗавЛаба).
3. bestia пушит в `master` **самостоятельно, постоянно**, без релея через ЗавЛаба
   на каждый push.

## Механизм (как технически проходит push)

Guard читает `CURRENT_AGENT` из `$AGENT_ID` (env) либо из имени worktree
`*-wt-<agent>*`. Для `master`/`main` push разрешён, если
`is_priv "$CURRENT_AGENT"` ИЛИ `is_priv "$AUTHOR_LOCAL"` (локальная часть
`git var GIT_AUTHOR_IDENT`).

bestia пушит командой:

```sh
AGENT_ID=bestia git push origin master
```

При этом `CURRENT_AGENT=bestia` → `is_priv(bestia)` возвращает 0 → push разрешён.
Авторство коммитов в `git log` = `bestia@labdoctorm.ru` (НЕ thedoctormes).

## Область действия и ограничения (важно)

- Привилегия `bestia` в `is_priv` даёт право push'ить в `master`/`main`.
- Для НЕ-owned агентских веток (`<agent>/...`) логика НЕ меняется: `is_priv` там
  тоже проставляет `ALLOW=1`, НО bestia не должна использовать это для пуша в
  чужие агентские ветки (нарушение зоны владельца). `AGENT_ID=bestia` задаётся
  **только на время push-команды в master**, НЕ перманентно в окружении — иначе
  bestia получила бы кросс-веточный push-карт-бланш, что выходит за рамки решения.
- Force-push (`--force-with-lease` и т.п.) остаётся заблокированным ADR-0059 для
  ВСЕХ, включая bestia (эмпирически подтверждено ранее).

## Рациональность

Делегирование основано на проверенном трек-рекорде: bestia не обходит guard'ы,
честно фиксирует расхождения, не использует force-push в master. Постоянный push
устраняет узкое место (релей через ЗавЛаба при каждом деплое торгового бота) при
сохранении audit trail (авторство коммитов = bestia).

## Последствия

- bestia может пушить в `master` doctorm-unify-protocol без участия ЗавЛаба.
- Решение задокументировано здесь + в `CHANGELOG.md` DoctorM_and_Ai.
- Через месяц причина ("почему bestia может пушить в master") понятна из ADR-046.

## Связанные

- ADR-0059: защита ветки master (branch-ownership guard)
- `git-hooks/check-branch-ownership.sh` — реализация guard'а
- MEMORY bestia: "Force-push на master — заблокирован ADR-0059 для ВСЕХ"
