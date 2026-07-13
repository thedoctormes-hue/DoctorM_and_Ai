#!/usr/bin/env bash
#
# infra-drift-check.sh — страж инфраструктуры лаборатории.
#
# Ловит то, из-за чего мы уже теряли сервисы:
#   1) упавшие юниты (failed)
#   2) осиротевшие таймеры (таймер ссылается на удалённый/отсутствующий сервис)
#   3) публично слушающие порты (0.0.0.0 / [::]) — для ревью
#
# Выход: 0 — чисто, 1 — найдены критические расхождения.
# Можно завесить в cron / systemd.timer раз в сутки с алертом в Telegram.
#
set -u

CRIT=0
echo "=== INFRA DRIFT CHECK $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

# --- [1] Упавшие юниты ---
echo; echo "[1] Упавшие юниты (failed):"
failed=$(systemctl list-units --state=failed --no-legend --no-pager 2>/dev/null | sed 's/^● //' | awk '{print $1}')
if [ -z "$failed" ]; then
  echo "  OK: нет"
else
  echo "$failed" | sed 's/^/  ⚠️ /'
  CRIT=1
fi

# --- [2] Осиротевшие таймеры ---
# Таймер ссылается на сервис через Activates=. Если сервис не загружается
# (LoadState=not-found) — это осиротевший юнит (классический crash-loop после
# удаления проекта без `systemctl disable --now`).
echo; echo "[2] Таймеры с осиротевшим/упавшим сервисом:"
orphans=""
while read -r t; do
  [ -z "$t" ] && continue
  svc=$(systemctl show -p Activates --value "$t" 2>/dev/null)
  [ -z "$svc" ] && continue
  load=$(systemctl show -p LoadState --value "$svc" 2>/dev/null)
  active=$(systemctl show -p ActiveState --value "$svc" 2>/dev/null)
  if [ "$load" = "not-found" ]; then
    echo "  ⚠️ $t -> $svc [LoadState=not-found] (осиротевший таймер!)"
    orphans="$orphans $t"
  elif [ "$active" = "failed" ]; then
    echo "  ⚠️ $t -> $svc [ActiveState=failed]"
    orphans="$orphans $t"
  fi
done < <(systemctl list-timers --all --no-legend --no-pager 2>/dev/null | awk '{print $(NF-1)}')
if [ -z "$orphans" ]; then
  echo "  OK: все таймеры указывают на живые сервисы"
else
  CRIT=1
fi

# --- [3] Публично слушающие порты ---
echo; echo "[3] Порты на 0.0.0.0 / [::] (публично доступны):"
ss -tulpn 2>/dev/null | awk '
  /LISTEN|UNCONN/ {
    addr=$5
    # публично = всё, что не loopback (127.0.0.1 / [::1])
    if (addr !~ /^127\.0\.0\.1:/ && addr !~ /^\[::1\]:/) {
      n=split(addr, parts, ":")
      print parts[n]
    }
  }' | sort -un | sed 's/^/  /'
echo "  (сверить с PORT_REGISTRY.md; не-loopback = доступно из сети)"

echo; echo "=== DONE (crit=$CRIT) ==="
exit $CRIT
