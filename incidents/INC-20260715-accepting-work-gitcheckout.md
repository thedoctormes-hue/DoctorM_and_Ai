---
id: INC-20260715-accepting-work-gitcheckout
date: 2026-07-15
status: closed
severity: medium
agent: raven
title: "INC-20260715-accepting-work-gitcheckout"
resolution: "self-caught + fixed same day (git checkout -- трап: восстановление из индекса вместо HEAD); PDP 82 passed, commit b31202c"
resolved_at: "2026-07-15"
---

# INC-20260715-accepting-work-gitcheckout

- **Дата:** 2026-07-15 15:2x (МСК)
- **Агент:** Ворон (raven)
- **Статус:** closed (self-caught + fixed)
- **Связано:** accepting-work приёмка коммита `8c407ef` (gatekeeper)

## Что случилось
При прогоне PDP-тестов на старой политике сделал:
1. `git checkout 9b869c8 -- policies/policy_v1.yaml` — рабочий файл + индекс стали СТАРОЙ версией (без 8080/8090/8099/3002).
2. `git checkout -- policies/policy_v1.yaml` — восстановил файл из **индекса** (где уже была старая версия), а не из HEAD.

Итог: рабочий `policy_v1.yaml` потерял правку резерва инфра-портов. Поскольку живой gatekeeper читает этот же репо-файл, **аудитная правка (тишина по 8080/8090/8099/3002) фактически не работала**, пока не заметил по падению PDP-тестов.

## Почему это ловушка
`git checkout -- <file>` копирует содержимое из **индекса**, не из HEAD. После `git checkout <commit> -- <file>` индекс уже содержит версию `<commit>`, поэтому последующий `git checkout -- <file>` возвращает именно её, а не HEAD.

## Фикс
- Восстановил из HEAD: `git checkout HEAD -- policies/policy_v1.yaml`.
- На живом гейткипере проверено: `gk-register 8080` → REJECT (зарезервирован), `gk-register 9500` → ALLOW. Аудит снова молчит по инфра-портам.
- PDP-тесты починены (порты агента сдвинуты на свободные 8081/8085/8098 + явная проверка reserve). 82 passed. Commit `b31202c`, push в origin/main.

## Правило (занести в MEMORY.md)
Чтобы вернуть файл к комиту/HEAD — `git checkout HEAD -- <file>` (или `git restore --source=HEAD --staged --worktree <file>`). НЕ `git checkout -- <file>` после `git checkout <commit> -- <file>`.

## Влияние
- Временно (пока не заметил) аудит мог слать алерты по зарезервированным инфра-портам. Реального ущерба нет (алерты по легитимным портам — шум, не инцидент безопасности).
- Регрессия закрыта до ухода в прод.
