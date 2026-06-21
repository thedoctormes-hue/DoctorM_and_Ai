---
name: ram-guardian
description: "Контроль ACP/MCP процессов: лимит количества ACP, авто-kill MCP-дублей, мониторинг памяти. Use when: нужно ограничить потребление памяти агентами, настроить авто-убийство дубликатов, мониторить RAM. NOT for: деплой сервисов (используй auto-deploy-check), профилирование производительности (используй performance-optimization)."
owner: "LabDoctorM"
last-reviewed: "2026-05-25"
version: 1.0.0
category: infrastructure
location: user
---

# ram-guardian


Контроль ACP процессов: лимит 2 ACP одновременно, авто-kill MCP дублей. Мониторинг памяти.

## Triggers

- "контроль acp процессов"
- "ram guardian"
- "авто-kill mcp"
- "лимит acp"

## Steps

1. Создать `scripts/ram_guardian.py`:
   ```python
   import psutil
   import time
   import subprocess

   class RAMGuardian:
       def __init__(self, acp_limit=2, memory_threshold=80):
           self.acp_limit = acp_limit
           self.memory_threshold = memory_threshold

       def get_acp_processes(self):
           return [p for p in psutil.process_iter(['pid', 'name', 'cmdline'])
                   if 'acp' in ' '.join(p.info['cmdline']).lower()]

       def kill_mcp_duplicates(self):
           seen = {}
           for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
               if 'mcp' in proc.info['cmdline'][0] if proc.info['cmdline'] else False:
                   server_name = proc.info['cmdline'][1] if len(proc.info['cmdline']) > 1 else None
                   if server_name in seen:
                       proc.kill()
                       print(f"Killed duplicate MCP: {server_name}")
                   else:
                       seen[server_name] = proc.info['pid']

       def enforce_limits(self):
           acp_procs = self.get_acp_processes()
           if len(acp_procs) > self.acp_limit:
               for proc in acp_procs[self.acp_limit:]:
                   proc.kill()
                   print(f"Killed ACP process {proc.pid}")

           self.kill_mcp_duplicates()

           memory = psutil.virtual_memory().percent
           if memory > self.memory_threshold:
               print(f"WARNING: Memory usage {memory}%")
   ```

2. Добавить в crontab:
   ```cron
   */5 * * * * python3 /root/LabDoctorM/scripts/ram_guardian.py
   ```

3. Создать systemd сервис `/etc/systemd/system/ram-guardian.service`:
   ```ini
   [Unit]
   Description=RAM Guardian for ACP/MCP
   After=network.target

   [Service]
   ExecStart=/usr/bin/python3 /root/LabDoctorM/scripts/ram_guardian.py --daemon
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

4. Активировать:
   ```bash
   systemctl daemon-reload
   systemctl enable ram-guardian
   systemctl start ram-guardian
   ```

5. Настроить алерты:
   ```bash
   # При превышении порога
   curl -X POST "https://api.notify.com/send" -d "RAM usage critical: 85%"
   ```

## Tools

- `psutil.process_iter()` — мониторинг процессов
- `systemctl` — управление сервисом
- `cron` — планировщик


## 🔮 Маркировка инсайтов

При обнаружении инсайта в процессе работы, в конце вывода добавляй маркер:

```
[INSIGHT: <тип>] <краткое описание>
[layer: <rules|memory|skills|backlog|agents>]
[source: <откуда инсайт>]
```

## Why

ACP процессы потребляют до 2GB RAM каждый. Без контроля система падает при 3+ активных ACP.
