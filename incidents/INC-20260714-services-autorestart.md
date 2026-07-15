---
title: "INC-20260714-services-autorestart"
date: 2026-07-14
status: closed
severity: warning
observer: dominika (lab-monitor)
root_cause: не расследован (ждёт DDP-спавн по «го»)
fix: pending «го» (ЗавЛаб)
verified: false
verified_at: "2026-07-15"
recommended_close: true
---

# INC-20260714 — Сервисы в auto-restart / failed (наблюдение монитора)

## Обнаружено
- 2026-07-14 ~16:01 МСК, lab-monitor (категория [9] «Сервисы», commit 2052640) показал:
  - `doctor-m-bot.service`: `SUB=auto-restart` (бот падает и циклически перезапускается)
  - `llmevangelist.service`: `SUB=auto-restart` (то же)
  - `reindex-incremental.service`: юнит упал (`failed`)
  - `autoexpert.service`: NRestarts +378 (растёт)
  - `snablab-backend.service`: NRestarts +287 (растёт)
  - `zprr-backend.service`: NRestarts +416 (растёт)
  - `dnsmasq`/`irqbalance`/`update-notifier-download`: `failed` (известные OOM-жертвы 09.07 / сломанный python3-debian)

## Влияние
- `doctor-m-bot` / `llmevangelist` — ТГ-боты колонии могут быть недоступны (перезапускаются циклически).
- `reindex-incremental` failed — инкрементальный реиндекс поиска не бежит; `lab_search` при этом работает (vectors=37596 OK на 16:00 МСК).

## Рекомендация (не применено)
- Спаунить DDP-подагентов (read-only: journalctl/systemctl cat логов/grep исходников) для root-cause каждого падающего сервиса.
- Фикс применять ТОЛЬКО по прямой команде ЗавЛаба («го»). Монитор НЕ чинит инфру самовольно.

## Статус
- OPEN / наблюдается монитором. Фикс не применён (нет команды).

## Fact-check (2026-07-15, owl) — РЕЗУЛЬТАТ: СТАЛ / ЛОЖНЫЙ АЛЕРТ
Сверено с живой системой (systemctl show NRestarts/SubState):
- doctor-m-bot: inactive/dead, NRestarts=0 (не auto-restart).
- llmevangelist: inactive/dead, NRestarts=0 (не auto-restart).
- reindex-incremental: юнит НЕ существует.
- autoexpert: active/running, NRestarts=0 (заявлено +378 — ЛОЖЬ).
- snablab-backend: active/running, NRestarts=0 (заявлено +287 — ЛОЖЬ).
- zprr-backend: active/running, NRestarts=0 (заявлено +416 — ЛОЖЬ).
- dnsmasq/irqbalance/update-notifier-download: failed→ сейчас inactive/inactive/failed; только update-notifier-download реально failed.
ВЫВОД: снимок монитора 16:01 2026-07-14 не соответствует текущему состоянию. Наблюдение устарело. recommended_close=true.
