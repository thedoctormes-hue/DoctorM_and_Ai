# INC-20260709-1610 — Диск 99%: утечка логами от mcp-apikeys crash-loop

Дата: 2026-07-09 13:00–13:15 UTC | Сервер: 197784.com

## Симптомы
- Диск /dev/vda1 заполнен 99% (734M free)
- postgresql@16-main и nginx в failed (No space left on device)
- /var/log/syslog и /var/log/kern.log по 7.7G каждый

## Коренные причины (root-cause-archaeologist)
### Корень А (главный): mcp-apikeys.service crash-loop
- apikeys-server.py — MCP stdio-сервер (mcp.run(transport="stdio")), задеплоен как
  standalone systemd Type=simple с Restart=always. Под systemd stdin мёртвый →
  сервер выходит через ~1с с кодом 0 ("Deactivated successfully").
  Restart=always воскрешает → петля ~1 раз в 6с, 81 740 рестартов (до ребута).
  Каждый цикл = 4–5 строк в journald→rsyslog → syslog 7.7G.
### Корень B (вторичный, инертен): drop_caches-шторм
- В kern.log шквал "sh (PID): drop_caches: 3" — транзитный runaway-цикл
  echo 3 > /proc/sys/vm/drop_caches (футильная реакция на мнимое RAM-давление; RAM 5.3G free).
  Постоянного триггера на диске НЕТ (субагент проверил systemd/cron/скрипты/бинари). Сейчас инертен.
### Усилитель: logrotate без лимита размера
- /etc/logrotate.d/rsyslog: weekly + rotate 4, без size → шторм 2.3 ГБ/ч игнорировал ротацию.
  Плюс logrotate скипал ротацию из-за небезопасных прав /var/log, пока не добавлен su root adm.

## Исправление
1. systemctl disable --now mcp-apikeys.service (петля остановлена, NRestarts=0)
2. truncate -s 0 /var/log/syslog /var/log/kern.log → диск 99% → 72% (16G free)
3. systemctl start postgresql@16-main nginx (оба active, psql 16.14 отвечает)
4. /etc/logrotate.d/rsyslog: weekly→daily, rotate 4→7, +size 100M, +su root adm (ротейшн exit 0)
5. /etc/rsyslog.d/50-default.conf: +$RepeatedMsgReduction on (защита kern.log)

## Статус: ЗАКРЫТ
Диск стабилен (72%), сервисы активны, mcp-петля мертва, drop_caches инертен.
Рекомендация: если drop_caches вернётся — auditctl -w /proc/sys/vm/drop_caches -p w -k drop_caches.

## Авторы
- Диагностика: research-скилл (deep_research+verify) + root-cause-archaeologist (5 Whys)
- Исправление: raven, режим ЕБШ, по согласованию ЗавЛаба
- Субагент drop_caches_hunter: read-only поиск триггера drop_caches (нейтрализовать нечего)
