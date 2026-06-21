---
description: "📋 Единый реестр systemd timers лаборатории"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-06-21
status: active
---
# 📋 Единый реестр systemd timers лаборатории

> Обновлено после миграции на OpenClaw (июнь 2026). Таймеры Qwen Code удалены.

## Активные таймеры

| Таймер | Частота | Назначение |
|--------|---------|------------|
| `monitor-lab.timer` | каждые 10 мин | Мониторинг лаборатории |
| `xray-healthcheck.timer` | каждые 5 мин | Health check Xray |
| `tmp-cleanup.timer` | каждые 30 мин | Очистка /tmp |

## Системные таймеры

| Таймер | Частота | Назначение |
|--------|---------|------------|
| `apt-daily.timer` | ежедневно | Обновления пакетов |
| `fstrim.timer` | еженедельно | TRIM SSD |
| `certbot.timer` | 2x в день | SSL сертификаты |

## Удалённые таймеры (Qwen Code)

Следующие таймеры были частью системы Qwen Code и удалены после миграции на OpenClaw:

- `qwen-evolution.timer` — эволюция Qwen Code (заменён на OpenClaw cron)
- `qwen-archive-session.timer` — архивирование сессий Qwen
- `kotolizator-monitor.timer` — мониторинг через Qwen channels
- `llmevangelist.timer` — LLMevangelist бот
- `protocol-backup.timer` — бэкап Protocol
- `consilium-evening.timer` — удалён ранее
