---
title: "INC-20260714-services-autorestart"
date: 2026-07-14
status: open
severity: warning
observer: dominika (lab-monitor)
root_cause: не расследован (ждёт DDP-спавн по «го»)
fix: pending «го» (ЗавЛаб)
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
