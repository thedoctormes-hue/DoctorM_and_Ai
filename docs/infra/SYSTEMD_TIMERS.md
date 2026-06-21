---
description: "📋 Единый реестр systemd timers лаборатории"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-08
status: active
---
# 📋 Единый реестр systemd timers лаборатории

## Лабораторные таймеры

| Таймер | Частота | Назначение |
|--------|---------|------------|
| `qwen-evolution.timer` | 2x в день в 09:00, 21:00 | Эволюция Qwen Code |
| `qwen-archive-session.timer` | каждые 30 мин | Архивирование сессий |
| `kotolizator-monitor.timer` | каждые 5 мин | Мониторинг котолизатора |
| `monitor-lab.timer` | каждые 10 мин | Мониторинг лаборатории |
| `llmevangelist.timer` | ежедневно в 09:00 | LLMevangelist бот |
| `protocol-backup.timer` | ежедневно в 03:00 | Бэкап Protocol |
| `xray-healthcheck.timer` | каждые 5 мин | Health check Xray |
| `tmp-cleanup.timer` | каждые 30 мин | Очистка /tmp |

## Системные таймеры

| Таймер | Частота | Назначение |
|--------|---------|------------|
| `apt-daily.timer` | ежедневно | Обновления пакетов |
| `fstrim.timer` | еженедельно | TRIM SSD |
| `certbot.timer` | 2x в день | SSL сертификаты |

## Архивные (удалить при наличии)

- ✅ `consilium-evening.timer` — удалён 2026-05-03