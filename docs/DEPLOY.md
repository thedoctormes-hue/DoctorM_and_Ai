---
description: "🚀 Деплой проектов лаборатории"
type: guide
last_reviewed: 2026-06-18
last_code_change: 2026-06-04
status: active
---
# 🚀 Деплой проектов

## Общие правила
- **.env**: не трогать без подтверждения ЗавЛаба
- **Python**: `cd /root/LabDoctorM/<project> && systemctl restart <service>`
- **React**: `npm run build && cp -r dist/* /var/www/<project>/`

## ⚠️ Критические правила Nginx

**НИКОГДА:**
- Не использовать `listen 443 ssl` в http блоках — stream модуль управляет 443 (VPN!)
- Не делать `rm -f *` в sites-enabled — удалять только конкретные файлы
- Не перезапускать nginx без `nginx -t` сначала
- Не трогать stream модуль — он маршрутизирует 443 между web (8443) и xray VPN

**Архитектура:**
```
Интернет → :443 (stream/SNI) → :8443 (nginx http) → сайты
                               → :443 (xray REALITY VPN)
```
Все сайты слушают **8443**, stream модуль делает SNI routing.

---

## Myrmex Control — Три инстанса

| Инстанс | Домен | Порт | Назначение |
|---------|-------|------|------------|
| Production | myrmexcontrol.shtab-ai.ru | 3000 | Основной, реальные данные |
| Demo | demo.shtab-ai.ru | 3001 | Публичное демо, изолированные данные |
| TWA | tgminiappmyrmex.shtab-ai.ru | 3002 | Telegram Mini App |

---

## Myrmex Control (Production)

### Быстрый деплой
```bash
cd /root/LabDoctorM/projects/myrmex-control
./scripts/deploy.sh
```

### Ручной деплой
```bash
cd /root/LabDoctorM/projects/myrmex-control
npm run build
cp -r dist/client/* /var/www/myrmexcontrol/
cp -r dist/server/* server-dist/
cp .env server-dist/.env
cp myrmex.json server-dist/myrmex.json
systemctl restart myrmex-control
```

### Nginx конфиг
```bash
sudo cp scripts/nginx-myrmexcontrol.conf /etc/nginx/sites-available/myrmexcontrol.shtab-ai.ru
sudo ln -sf /etc/nginx/sites-available/myrmexcontrol.shtab-ai.ru /etc/nginx/sites-enabled/myrmexcontrol.shtab-ai.ru
sudo nginx -t && sudo systemctl reload nginx
```

⚠️ **НЕ** копировать `myrmex.json` из корня проекта — он содержит данные agents/projects/staff. Файл в `server-dist/` — единственный источник данных.

---

## Myrmex Demo

Demo использует `MYRMEX_FILE=myrmex-demo.json` — изолированный файл данных.
Auth автоматически отключён для demo-режима (см. `auth.ts:requireAuth`).

### Первоначальная настройка
```bash
# 1. Копируем seed данные
mkdir -p /root/LabDoctorM/projects/myrmex-control/server-dist/data
cp /root/LabDoctorM/projects/myrmex-control/data/seed-demo.json \
   /root/LabDoctorM/projects/myrmex-control/server-dist/data/myrmex-demo.json

# 2. Устанавливаем systemd unit
sudo cp scripts/myrmex-demo.service /etc/systemd/system/myrmex-demo.service
sudo systemctl daemon-reload
sudo systemctl enable myrmex-demo

# 3. Устанавливаем nginx конфиг
sudo cp scripts/nginx-demo.conf /etc/nginx/sites-available/demo.shtab-ai.ru
sudo ln -sf /etc/nginx/sites-available/demo.shtab-ai.ru /etc/nginx/sites-enabled/demo.shtab-ai.ru

# 4. Перезапускаем
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl start myrmex-demo
```

### Деплой обновлений
```bash
cd /root/LabDoctorM/projects/myrmex-control
./scripts/deploy.sh --demo
```

---

## Myrmex TWA (Telegram Web App)

TWA использует тот же билд что и production, но на отдельном порту.
Требует `TELEGRAM_BOT_TOKEN` в environment.

### Первоначальная настройка
```bash
# 1. Устанавливаем systemd unit
sudo cp scripts/myrmex-twa.service /etc/systemd/system/myrmex-twa.service
sudo systemctl daemon-reload
sudo systemctl enable myrmex-twa

# 2. Добавляем TELEGRAM_BOT_TOKEN
sudo systemctl edit myrmex-twa
# Добавить:
# [Service]
# Environment=TELEGRAM_BOT_TOKEN=your_token_here

# 3. Устанавливаем nginx конфиг
sudo cp scripts/nginx-twa.conf /etc/nginx/sites-available/tgminiappmyrmex.shtab-ai.ru
sudo ln -sf /etc/nginx/sites-available/tgminiappmyrmex.shtab-ai.ru /etc/nginx/sites-enabled/tgminiappmyrmex.shtab-ai.ru

# 4. Перезапускаем
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl start myrmex-twa
```

### Деплой обновлений
```bash
cd /root/LabDoctorM/projects/myrmex-control
./scripts/deploy.sh --twa
```

---

## Полный деплой всех инстансов
```bash
cd /root/LabDoctorM/projects/myrmex-control
./scripts/deploy.sh --all
```

---

## Myrmex Command (dashboard)
```bash
npm run build && cp -r dist/* /var/www/html/dashboard-react/ && cp favicon.svg /var/www/html/dashboard-react/
```

## СнабЛаб (snablab.shtab-ai.ru)

### Frontend
```bash
cd /root/LabDoctorM/projects/snablab/frontend
npm run build && cp -r dist/* /var/www/snablab/
```

### Backend
```bash
cd /root/LabDoctorM/projects/snablab/backend
systemctl restart snablab
```

### Проверка
```bash
curl -s -o /dev/null -w "%{http_code}" https://snablab.shtab-ai.ru/
curl -s http://127.0.0.1:8200/openapi.json | python3 -c "import sys,json; d=json.load(sys.stdin); print([p for p in d.get('paths',{}) if 'tech' in p])"
```

## SNZK (интерактивный сериал)
```bash
cp /root/LabDoctorM/projects/SNZK/index.html /var/www/snzk.shtab-ai.ru/index.html
```
