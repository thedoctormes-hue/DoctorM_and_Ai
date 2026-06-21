---
name: hype-pilot
description: Hype Pilot — контент-машина DoctorM&Ai. Обзор экосистемы.
type: insight
status: active
verified: 2026-06-17
source: hype-pilot-overview.md
---

# 🚀 Hype Pilot — Контент-Машина

## Что это

Автоматизированная система производства и публикации контента бренда DoctorM&Ai.

## Текущее состояние (подтверждено 2026-06-17)

Проект `/root/LabDoctorM/projects/hype-pilot/` содержит:
- `HYPE_PROTOCOL_SPEC.md` — спецификация протокола
- `publish_helper.py` — полуавтоматический публикатор (CLI, Habr + VC.ru)
- `content_log.md` — лог публикаций
- `channels/` — Telegram-каналы и кросс-постинг (crosspost.py, daily_report.py, observe_and_post.py)
- `inbox/` — инбокс статей (articles/, reviews/, archive/)
- `audit/` — аудит контента
- `approval_queue.json` — очередь на одобрение

## Ключевой документ

`HYPE_PROTOCOL_SPEC.md` — контент-стратегия, частота, маппинг событий → контент.
