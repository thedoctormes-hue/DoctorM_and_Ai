---
id: INC-20260701-onnx-embedder-crash
timestamp: "2026-07-01T00:00:00Z"
category: tech
type: bug
severity: medium
status: retired
agent: unknown
title: ONNX Embedder Service Crash
date: "2026-07-01T06:50:00+00:00"
author: Доминика
tags: [onnx, labsearch, embedder, crash]
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Инцидент: ONNX Embedder Service Crash

## Симптомы
- При запуске сессии: `memory search is paused because the memory index was built with a different embedding provider/model/settings`
- `curl http://127.0.0.1:8082/health` возвращал таймаут
- lab_search.py падал при запросах

## Диагностика
1. Сервис `onnx-embedder.service` показывал `active (running)`, но не отвечал на HTTP запросы
2. PID 1409338 существовал, но процесс завис (не обрабатывал сетевые запросы)
3. При попытке рестарта через systemctl возникала ошибка `Address already in use`
4. Логи показали: `OSError: [Errno 98] Address already in use`

## Причина
- Процесс ONNX-эмбеддера завис при обработке запросов
- Порт 8082 оставался занятым мёртвым процессом
- Попытки graceful restart через systemd не сработали из-за зависшего состояния сервиса

## Решение
1. Принудительное устранение процесса: `kill -9 1409338`
2. Очистка порта 8082
3. Запуск нового процесса напрямую: `python3 onnx-embedder.py`
4. Проверка health endpoint: `{"status": "ok", ...}`
5. Тест lab_search.py: успешный возврат результатов

## Время восстановления
~15 минут (06:50 - 07:05 MSK)

## Комментарий
Сервис ONNX критичен для labsearch. Нужно добавить:
- Автоматический health-check таймер
- Механизм перезапуска при зависании
- Мониторинг состояния порта

## Связанные артефакты
- `/tmp/onnx-embedder.log` — логи перезапуска
- `memory/2026-07-01.md` — дневниковая запись
