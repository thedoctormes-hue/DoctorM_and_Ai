#!/usr/bin/env bash
# gen-port-timer-map.sh — генератор сырых сканов портов/таймеров (ADR-0047)
# Пишет docs/PORT_SCAN.md и docs/TIMER_SCAN.md (перезаписываются) и выводит drift.
# НЕ трогает кураторские PORT_REGISTRY.md / TIMER_REGISTRY.md (в них — ручные метаданные).
set -u
REPO="/root/LabDoctorM/projects/DoctorM_and_Ai"
PORTS_SCAN="$REPO/docs/PORT_SCAN.md"
TIMERS_SCAN="$REPO/docs/TIMER_SCAN.md"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

gen_ports() {
  {
    echo "# PORT_SCAN.md — авто-скан"
    echo ""
    echo "> Сгенерировано: $NOW"
    echo "> Источник: \`ss -tlnp\` / \`ss -ulnp\`. Файл перезаписывается генератором; не редактировать вручную."
    echo ""
    echo "| Адрес:Порт | Протокол | Процесс (pid) |"
    echo "|-----------|----------|----------------|"
    ss -tlnp 2>/dev/null | awk 'NR>1 && $4 != "" {
      addr=$4; proto="tcp";
      proc=""; for(i=1;i<=NF;i++) if($i ~ /users:/) {proc=$(i+1)};
      gsub(/users:|\(/,"",proc); gsub(/\)/,"",proc);
      print "| " addr " | " proto " | " proc " |";
    }'
    ss -ulnp 2>/dev/null | awk 'NR>1 && $4 != "" {
      addr=$4; proto="udp";
      proc=""; for(i=1;i<=NF;i++) if($i ~ /users:/) {proc=$(i+1)};
      gsub(/users:|\(/,"",proc); gsub(/\)/,"",proc);
      print "| " addr " | " proto " | " proc " |";
    }'
  } > "$PORTS_SCAN"
}

gen_timers() {
  {
    echo "# TIMER_SCAN.md — авто-скан"
    echo ""
    echo "> Сгенерировано: $NOW"
    echo "> Источник: \`systemctl list-timers --all\` + системный cron. Перезаписывается генератором."
    echo ""
    echo "## systemd timers (list-timers --all)"
    echo ""
    systemctl list-timers --all --no-pager 2>/dev/null
    echo ""
    echo "## enabled/active state (lab timers)"
    echo ""
    for u in myrmex-healthcheck disk-monitor openclaw-cf-rotate free-api-hunter free-api-hunter-scan backup-myrmex pg-backup dpkg-db-backup logrotate-myrmex reindex-full backup-projects snablab-price-snapshot krv-notify cleanup-tmp cleanup-go-cache mskgastrodigestbot docker-prune lab-memory-healthcheck reindex-incremental update-notifier-download; do
      printf "%s -> enabled=%s active=%s\n" "$u.timer" "$(systemctl is-enabled "$u.timer" 2>/dev/null)" "$(systemctl is-active "$u.timer" 2>/dev/null)"
    done
    echo ""
    echo "## system cron"
    echo ""
    echo "### /etc/cron.d"
    ls /etc/cron.d/ 2>/dev/null
    echo "### root crontab"
    crontab -l 2>/dev/null || echo "(empty)"
  } > "$TIMERS_SCAN"
}

drift_check() {
  echo "=== DRIFT CHECK (live vs PORT_REGISTRY.md) ==="
  reg_ports="$(grep -oE '^\| [0-9]+ ' "$REPO/docs/PORT_REGISTRY.md" 2>/dev/null | grep -oE '[0-9]+' | sort -n | uniq)"
  live_ports="$(ss -tlnp 2>/dev/null | grep -oE ':[0-9]+ ' | grep -oE '[0-9]+'; ss -ulnp 2>/dev/null | grep -oE ':[0-9]+ ' | grep -oE '[0-9]+')"
  live_sorted="$(echo "$live_ports" | sort -n | uniq)"
  for p in $reg_ports; do
    echo "$live_sorted" | grep -qx "$p" || echo "  [REGISTRY ONLY] port $p registered but not listening now (service down?)"
  done
  for p in $live_sorted; do
    echo "$reg_ports" | grep -qx "$p" || echo "  [LIVE ONLY] port $p listening but not in registry (unregistered? investigate)"
  done
  echo "=== END DRIFT CHECK ==="
}

gen_ports
gen_timers
drift_check
echo "OK: wrote $PORTS_SCAN and $TIMERS_SCAN"
