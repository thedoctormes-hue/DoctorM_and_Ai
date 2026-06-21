---
type: backlog
id: BL-018
title: 'BL-025: CDN и VPN-интеграция для обхода блокировок'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:24+00:00'
---
# BL-025: CDN и VPN-интеграция для обхода блокировок

> 🟢 P2 | Вес: 5 | Приоритет: medium | Статус: pending

## Контекст
Dashboard доступен публично без CDN. Реальный IP сервера открыт. В странах с цензурой (Китай, Иран) — недоступен без VPN. Существующая VPN-инфраструктура (vpn-daemon) не интегрирована с dashboard.

**Обнаружено:** dpi, network (2 агента, критично для международной аудитории).

## Цель
Cloudflare CDN для скрытия IP и DDoS-защиты. Кнопка «Подключить VPN» в dashboard.

## Зачем
Доступность в странах с цензурой, защита от DDoS.

## Проект/контекст
myrmex-control → nginx config, dashboard UI

## Что сделать
- [ ] Подключить Cloudflare CDN для всех доменов
- [ ] Настроить nginx: `app.set('trust proxy', 1)`, real_ip от Cloudflare
- [ ] Добавить в dashboard страницу «VPN»:
  - Кнопка «Подключить VPN» с генерацией VLESS-конфигурации
  - Мониторинг статуса VPN в реальном времени
  - QR-код для мобильных клиентов
- [ ] Опубликовать Docker-образ для self-hosted развертывания
- [ ] Добавить инструкцию по настройке VPN-прокси в docs/

## Критерии готовности
- [ ] Cloudflare CDN перед всеми доменами
- [ ] Реальный IP сервера скрыт
- [ ] Страница VPN в dashboard с генерацией конфигурации
- [ ] Docker-образ опубликован
- [ ] Self-hosted инструкция в docs/

## Зависимости
- Нет

## Назначение
- **Вес:** 5
- **Скиллы:** vpn-infrastructure-agent, anti-dpi-legend
- **Статус:** pending
- **Приоритет:** medium
- **Ответственный:** anti-dpi-legend

---
*Summary: Подключить Cloudflare CDN и интегрировать VPN в dashboard для доступности в странах с цензурой → myrmex-control network*
