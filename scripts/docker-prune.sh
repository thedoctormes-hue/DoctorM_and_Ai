#!/bin/bash
# Еженедельная очистка Docker
# ADR-039

echo "[$(date)] Docker prune started"

# Удаляем остановленные контейнеры старше 7 дней
docker container prune -f --filter "until=168h" 2>/dev/null

# Удаляем неиспользуемые образы (без -a, чтобы не трогать тегированные)
docker image prune -f 2>/dev/null

# Удаляем dangling volumes
docker volume prune -f 2>/dev/null

# Логируем результат
echo "[$(date)] Docker system df after prune:"
docker system df 2>/dev/null
