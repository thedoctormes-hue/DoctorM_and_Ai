---
id: protocol-infra
name: Protocol Infra
owner: zavlab
status: active
priority: medium
stack: [Python, Bash]
path: infrastructure/monitoring/protocol
---

# Protocol Infra

Инфраструктурный мониторинг — скрипты проверки процессов, логов, БД.

## Быстрый старт

```bash
cd infrastructure/monitoring/protocol
./check_process.sh
./check_logs.sh
./check_db.py
```

## Документация

- [README](README.md)
- [BENCHMARK_SPEC.md](BENCHMARK_SPEC.md)
