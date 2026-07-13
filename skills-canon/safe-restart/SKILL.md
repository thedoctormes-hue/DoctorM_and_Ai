---
name: "safe-restart"
description: "Безопасный рестарт сервисов: graceful shutdown, проверка состояния, откат при ошибке. Максимум 3 попытки, анализ причины, circuit breaker для критических сервисов."
version: "2.0.0"
date: "2026-06-23T20:07:00.000Z"
author: "Ворон (raven) — ревизия на основе исследования best practices"
last_reviewed: "2026-06-23"
status: active
user-invocable: true
triggers:
  phrases:
    - "перезапусти"
    - "рестарт"
    - "restart"
    - "safe restart"
    - "graceful shutdown"
  patterns:
    - "сервис не отвечает + перезапуск"
    - "gateway restart"
    - "systemd restart"
  scope:
    - рестарт gateway, systemd сервисов, любых процессов агента
---

# Safe Restart Protocol v2

## Назначение
Безопасный перезапуск сервисов с проверкой состояния, откатом при ошибке и защитой от зацикливания.

Основан на:
- INC-023: Сова 6 раз повторила "Gateway is restarting"
- Best practices 2025-2026: graceful shutdown, health checks, circuit breaker, max 3 attempts

## Процедура

### Шаг 1: Диагностика ДО рестарта
1. Проверить PID: `ps aux | grep <service>`
2. Проверить health: `curl -s http://127.0.0.1:<port>/health`
3. Проверить логи: `tail -50 /tmp/openclaw/*.log`
4. Определить причину — возможно рестарт не нужен

### Шаг 2: Graceful stop
1. Отправить SIGTERM: `kill <PID>`
2. Подождать 5 секунд
3. Проверить что процесс остановился: `ps aux | grep <PID>`
4. Если не остановился — SIGKILL: `kill -9 <PID>`
5. Подождать 2 секунды
6. Убедиться что PID больше не существует

### Шаг 3: Запуск

Выбор команды запуска зависит от типа сервиса:

**OpenClaw Gateway:**
```bash
openclaw gateway restart
# или если не работает:
openclaw gateway stop && sleep 2 && openclaw gateway start
```

**systemd-сервис (onnx-embedder и др.):**
```bash
sudo systemctl restart <service-name>
# Проверка статуса:
sudo systemctl status <service-name>
```

**Процесс запускаемый напрямую (без systemd):**
```bash
# 1. Запустить процесс из рабочей директории
cd /path/to/service
./start.sh 2>&1 &
# или
nohup ./service-binary > /var/log/service.log 2>&1 &

# 2. Сохранить PID
echo $! > /tmp/service.pid
```

**Универсальный порядок:**
1. Запустить сервис командой из списка выше
2. Подождать 3-5 секунд
3. Проверить health: `curl -s http://127.0.0.1:<port>/health`
4. Проверить логи на ошибки: `tail -20 /var/log/<service>.log` (или `/tmp/openclaw/*.log`)
5. Для systemd: убедиться что `systemctl is-active <service>` = `active`

### Шаг 4: Верификация
1. Health check = OK
2. Нет ошибок в логах
3. Сервис отвечает на запросы

## Обработка ошибок

### systemctl недоступен
Если `systemctl` возвращает ошибку (нет DBUS):
1. Использовать `kill` вместо `systemctl stop`
2. Запускать процесс напрямую
3. Сообщить пользователю: "systemctl недоступен, использую kill"

### Рестарт не помог (3 попытки)
1. Остановить попытки
2. Сообщить пользователю: "⚠️ 3 неудачных рестарта. Требуется ручная диагностика."
3. Привести: PID, последние логи, статус health
4. НЕ повторять — это anti-loop триггер

### Процесс не убивается
1. `kill -9 <PID>`
2. Проверить: `ps aux | grep <PID>`
3. Если всё ещё жив — "⚠️ Процесс не убивается. Возможно zombie. Требуется ручное вмешательство."

## Правила

- Максимум 3 попытки рестарта
- Между попытками — анализ причины неудачи
- Не повторять одну и ту же команду
- При 3 неудачах — эскалация пользователю
- Всегда иметь rollback plan (начальное состояние перед рестартом)

## Инциденты-источники
- INC-023: Сова 6 раз повторила "Gateway is restarting"
