#!/bin/bash
# Gateway Memory Watchdog
# Проверяет RSS gateway, при превышении 2 GB делает graceful restart

PID=$(pgrep -f "openclaw.*gateway" | head -1)
if [ -z "$PID" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') gateway not found" >> /root/LabDoctorM/.ops/logs/gateway-memory.log
    exit 1
fi

RSS_KB=$(ps -p "$PID" -o rss= --no-headers 2>/dev/null | tr -d ' ')
RSS_MB=$((RSS_KB / 1024))
LIMIT_MB=2048

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') PID=$PID RSS=${RSS_MB}MB limit=${LIMIT_MB}MB" >> /root/LabDoctorM/.ops/logs/gateway-memory.log

if [ "$RSS_MB" -gt "$LIMIT_MB" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') THRESHOLD EXCEEDED — restarting gateway" >> /root/LabDoctorM/.ops/logs/gateway-memory.log
    openclaw gateway restart 2>&1
    sleep 10
    NEW_PID=$(pgrep -f "openclaw.*gateway" | head -1)
    NEW_RSS=$(ps -p "$NEW_PID" -o rss= --no-headers 2>/dev/null | tr -d ' ')
    NEW_RSS_MB=$((NEW_RSS / 1024))
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') Restarted: PID=$NEW_PID RSS=${NEW_RSS_MB}MB" >> /root/LabDoctorM/.ops/logs/gateway-memory.log
fi
