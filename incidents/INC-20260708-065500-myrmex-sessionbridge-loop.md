---
id: INC-20260708-065500-myrmex-sessionbridge-loop
timestamp: "2026-07-08T06:55:00Z"
category: tech
type: incident
severity: high
status: resolved
agent: antcat
title: "INC-20260708-065500: myrmex-control SessionBridge runaway error loop (диск заполняется)"
description: "INC-20260708-065500: myrmex-control SessionBridge в петле ошибок — лог 2.6GB, растёт, contextApi down"
last_reviewed: 2026-07-08
last_code_change: 2026-07-08
---

# INC-20260708-065500: myrmex-control SessionBridge runaway error loop (диск заполняется)

> Обнаружено в ходе плановой диагностики лаборатории (ЕБШ, тип audit) по роли Builder.

---

## Описание
Сервис `myrmex-control.service` запущен и отвечает на `/api/health`, но его компонент **SessionBridge** находится в бесконечной петле ошибок. Каждый тик таймера (`session-bridge.js:184 Timeout._onTimeout`) пытается прочитать session-файлы агентов и падает с `ENOENT`, записывая stack trace в `/var/log/myrmex-control.err.log`.

Root cause (проверено live):
- `SessionBridge.readNewMessages()` открывает `/root/.openclaw/agents/<agent>/sessions/<uuid>.jsonl` для dominika, streikbrecher, owl, antcat и др. — **файлы отсутствуют** (`ENOENT: no such file or directory`). Session ID-шники в коде, видимо, устарели / указывают не на тот путь.
- Лог пишется напрямую в файл (journald пуст для юнита), поэтому накопился до **2.6 GB** и **активно растёт** (подтверждено: размер не менялся между замерами в одну секунду? нет — растёт, mtime 06:55, в рамках сессии; диск вырос 42→44 GB за ~20 мин).
- В голове лога также: `[Context proxy] [TypeError: fetch failed] connect ECONNREFUSED 127.0.0.1:8100`. **Это НЕ инцидент:** context proxy (порт 8100) удалён по решению лаборатории, семантический поиск — единственный labsearch (`lab_search.py`, CLI). `services.contextApi: false` в `/api/health` — ожидаемо (8100 мёртв). Фича «Контекст» УЖЕ работает на labsearch: `/api/labsearch/context` → `runLabSearch` → `execFile lab_search.py`. 8100 висит только в `checkContextApi()` (health-ping). Правка: переключить `CONTEXT_API_URL` на живой бэкенд семпоиска (ONNX embedder 8082), чтобы health-чек пинговал его вместо мёртвого 8100.

Затронутый компонент: myrmex-control (панель управления лабораторией, статистика агентов/серверов).
Побочный эффект: **заполнение диска** (78% и растёт) → риск падения всех сервисов при 100%.

## Severity
- 🔴 HIGH — диск активно заполняется, через несколько часов возможен отказ по месту; функционал contextApi уже недоступен. Сам myrmex-control не падает (process жив), но данные о серверах некорректны.

## Обнаружено
- **Источник:** manual / audit (ЕБШ, тип audit)
- **Инструмент:** df, journalctl, ls -lh, tail, curl /api/health
- **Сессия:** agent:antcat:telegram:direct:173681771
- **Инсайт:** рост диска 75%→78% за сессию = не логи ОС, а именно `myrmex-control.err.log` (2.6GB)

## Действия
- [ ] Остановить заполнение диска: `truncate -s 0 /var/log/myrmex-control.err.log` (лог ошибок, безопасно) — НЕ делать без подтверждения ЗавЛаба
- [ ] Локализовать причину ENOENT: проверить, куда реально пишутся session-файлы агентов и почему SessionBridge смотрит в `/root/.openclaw/agents/<agent>/sessions/*.jsonl`
- [ ] Переключить `CONTEXT_API_URL` на живой бэкенд семпоиска: в `.env` (EnvironmentFile сервиса) задать `CONTEXT_API_URL=http://127.0.0.1:8082` (ONNX embedder, питает `lab_search.py`). `checkContextApi()` начнёт пинговать `/health` на 8082 → `contextApi: true`, fetch-ошибки уйдут. НЕ поднимать 8100 — он удалён намеренно; фича «Контекст» уже на labsearch.
- [ ] Перезапустить `myrmex-control.service` после правки (по согласованию — это сервис, не openclaw gateway, но влияет на панель)
- [ ] Добавить logrotate / max-size на `myrmex-control.err.log`, чтобы петля ошибок не съедала диск

## Критерии устранения
- [ ] `/var/log/myrmex-control.err.log` не растёт (или ограничен logrotate)
- [ ] `curl localhost:3000/api/health` → `overall` ближе к 100, `services.contextApi: true` (через 8082), `servers.online` корректно
- [ ] диск стабилен (<85%)

## Решение (2026-07-08, ЕБШ code-fix)

Все действия выполнены и проверены на живом сервисе:

- [x] **Корень (SessionBridge):** `src/server/session-bridge.ts` — `readNewMessages` теперь при ошибке чтения переоткрывает активную сессию через `findActiveSession` (ре-поинт на новый файл, курсор в конец без бурста). Добавлен счётчик `failures`: если папка агента исчезла — опрос останавливается после 3 неудач (`session.active=false`). Ревью кода: APPROVE.
- [x] **8100 → 8082:** в `.env` задан `CONTEXT_API_URL=http://127.0.0.1:8082` (живой ONNX embedder, питает labsearch). `contextApi` стал `true`, fetch-ошибки на 8100 ушли. 8100 НЕ поднимался — удалён намеренно.
- [x] **Сборка:** вскрыта вторая первопричина — `NODE_ENV=production` заставлял `npm install` отсекать ВСЕ devDependencies (typescript, vite, @types/*). Возвращены dev-инструменты; `package.json` (typescript→^6.0.3, добавлен @types/node), `tsconfig.server.json` (убрана невалидная lib `"node"`) поправлены. `npm run build` → `dist/server/index.js` собран.
- [x] **Рестарт:** `systemctl restart myrmex-control.service` — сервис `active`.
- [x] **logrotate:** `/etc/logrotate.d/myrmex-control` (size 100M, rotate 5, copytruncate, `su root root`) + systemd-таймер `logrotate-myrmex.timer` (ежедневно, enabled/active), т.к. cron отключён.

**Верификация (после рестарта):**
- `curl localhost:3000/api/health` → `services.contextApi: true`, `servers.online: 1/1`, `agents.active: 8/8`.
- `ENOENT` в логе после рестарта: **0**. `127.0.0.1:8100` ошибок: **0**.
- Размер `/var/log/myrmex-control.err.log`: **2.5K** (стабилен, не растёт).
- Диск: **42G/59G (75%)** — 2.6 ГБ возвращены (было 78%).

Побочное наблюдение (вне инцидента): в логе warning `git config --global --add safe.directory /root/LabDoctorM/projects/lab-vault` — myrmex-control читает git лог lab-vault, владелец отличается. Не блокирует работу, отдельная мелочь.

## Статус
resolved

## Финализация (VCS, 2026-07-08)
- Фикс слит в `main` fast-forward (без merge-коммита): `56d1ab7..19a4ac0`, запушено в `origin/main`.
- Коммиты: `2da952c` (session-bridge re-discovery), `ad1f089` (devDeps под production), `b2ac797` (default CONTEXT_API_URL=8082), `19a4ac0` (revert TS 6.0.3 → ^5.6.0).
- Ветка `antcat/fix-session-bridge-enoent` сохранена на remote.
- Долговечность: при чистом `git checkout main && npm run build` баг 8100/ENOENT не вернётся (default в коде = 8082, re-discovery в session-bridge).
- Примечание (accepting-work): `ad1f089` необоснованно поднял typescript до 6.0.3 (корень был в `NODE_ENV=production`, отсекавшем devDeps, а не в версии TS) → сломал client typecheck. Откачен в `19a4ac0` (возврат `^5.6.0` + оригинальный tsconfig; devDeps ставятся `npm install --legacy-peer-deps --include=dev`). Client typecheck теперь зелёный, кроме дорегрессионного error в `src/client/pages/Login.tsx` (клиентский файл, вне зоны инцидента).
