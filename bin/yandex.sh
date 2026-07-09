#!/usr/bin/env bash
# yandex.sh — единая обёртка для Яндекс-сервисов с автологированием использования.
# Каждый вызов пишет строку в logs/yandex-usage.log.
# Назначение: через 2 недели ревью — какими сервисами реально пользуемся.
#
# Использование:
#   yandex.sh mail <himalaya-args...>          # почта (DoctorMandAi)
#   yandex.sh disk ls [path]                   # список на Диске (moscowskiymichi)
#   yandex.sh disk get <remote> <local>        # скачать с Диска
#   yandex.sh disk put <local> <remote>        # залить на Диск
#   yandex.sh disk del <remote>                # удалить с Диска
#   yandex.sh disk mkdir <remote>              # создать папку
#   yandex.sh cal ls                           # календари (DoctorMandAi, CalDAV)
#   yandex.sh cal events <cal_id>              # события календаря
#   yandex.sh cal add <cal_id> <start> <end> <summary>   # создать событие
#   yandex.sh cal del <cal_id> <event_uid>     # удалить событие
#   yandex.sh cal task <cal_id> add <summary> <due YYYY-MM-DD[THH:MM:SSZ]> [desc]  # создать задачу (VTODO)
#   yandex.sh cal task <cal_id> list            # список задач
#   yandex.sh contacts ls                       # контакты (DoctorMandAi, CardDAV)
#   yandex.sh usage                             # показать сводку лога
#
# cal_id — либо полный href (https://... или /...), либо имя календаря (из `cal ls`).
# Даты событий — в формате ISO8601 UTC, напр. 2026-07-10T15:00:00Z.
# Для тестов/импорта функций: YANDEX_SH_LIB=1 source yandex.sh (не запускает main).
set -uo pipefail

LOG=/root/LabDoctorM/.ops/logs/yandex-usage.log
MAIL_ACC="moscowskiymichi@yandex.ru"
DISK_ACC="moscowskiymichi@yandex.ru"
WEBDAV="https://webdav.yandex.ru"
CALDAV="https://caldav.yandex.ru/"
CARDDAV="https://carddav.yandex.ru/"

log() { # service action result
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$1" "$2" "$3" "$4" >> "$LOG"
}

disk_pass()     { cat ~/.config/yandex/.disk-pass; }
cal_pass()      { cat ~/.config/yandex/.calendar-pass; }
contacts_pass() { cat ~/.config/yandex/.contacts-pass; }

# namespace-agnostic: <d:href> -> <href> (Яндекс может менять префиксы)
norm() { sed -E 's/(<\/?)[a-zA-Z_-]+:/\1/g'; }

# --- CalDAV helpers ---
# Возвращает calendar-home URL через principal -> calendar-home-set discovery.
cal_home() {
  local P="$1" principal puhref home hhref
  principal=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 0" \
    --data '<d:propfind xmlns:d="DAV:"><d:prop><d:current-user-principal/></d:prop></d:propfind>' \
    "$CALDAV")
  puhref=$(echo "$principal" | norm | grep -oP '(?<=<href>)[^<]+' | head -1); puhref="${puhref%/}"
  [ -n "$puhref" ] || return 1
  case "$puhref" in
    http*) home_base="$puhref" ;;
    /*)    home_base="${CALDAV%/}$puhref" ;;
    *)     home_base="${CALDAV%/}/$puhref" ;;
  esac
  home=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 0" \
    --data '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><c:calendar-home-set/></d:prop></d:propfind>' \
    "$home_base")
  hhref=$(echo "$home" | norm | grep -oP '(?<=<href>)[^<]+' | head -1); hhref="${hhref%/}"
  [ -n "$hhref" ] || return 1
  case "$hhref" in
    http*) printf '%s' "$hhref" ;;
    /*)    printf '%s%s' "${CALDAV%/}" "$hhref" ;;
    *)     printf '%s/%s' "${CALDAV%/}" "$hhref" ;;
  esac
}

# Резолвит cal_id (href или имя) в абсолютный URL календаря.
cal_resolve() {
  local P="$1" cid="$2" home resp href
  case "$cid" in
    http*) printf '%s' "${cid%/}"; return 0 ;;
    /*)    printf '%s%s' "${CALDAV%/}" "${cid%/}"; return 0 ;;
  esac
  home=$(cal_home "$P") || return 1
  resp=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 1" \
    --data '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><d:resourcetype/><d:displayname/></d:prop></d:propfind>' \
    "$home")
  href=$(echo "$resp" | norm | tr -d '\n' | grep -oP '<response>.*?</response>' | \
    while IFS= read -r r; do
      name=$(echo "$r" | grep -oP '(?<=<displayname>)[^<]+')
      [ "$name" = "$cid" ] && { echo "$r" | grep -oP '<href[^>]*>\K[^<]+' | head -1; break; }
    done | head -1); href="${href%/}"
  [ -n "$href" ] || { echo "cal_resolve: календарь '$cid' не найден" >&2; return 1; }
  case "$href" in
    http*) printf '%s' "${href%/}" ;;
    /*)    printf '%s%s' "${CALDAV%/}" "$href" ;;
    *)     printf '%s/%s' "${CALDAV%/}" "$href" ;;
  esac
}

cal_ls() {
  local P; P=$(cal_pass)
  local home; home=$(cal_home "$P") || { echo "cal ls: не удалось получить calendar-home (проверь ~/.config/yandex/.calendar-pass и активацию app-пароля Яндекс)" >&2; return 1; }
  local resp; resp=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 1" \
    --data '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><d:resourcetype/><d:displayname/></d:prop></d:propfind>' \
    "$home")
  echo "Доступные календари (home: $home):"
  echo "$resp" | norm | tr -d '\n' | grep -oP '<response>.*?</response>' | \
  while IFS= read -r r; do
    h=$(echo "$r" | grep -oP '<href[^>]*>\K[^<]+'); n=$(echo "$r" | grep -oP '(?<=<displayname>)[^<]+')
    if echo "$r" | grep -qE '<calendar' && echo "$r" | grep -qE '<collection'; then printf '  %s\t%s\n' "${n:-$h}" "$h"; fi
  done
  log calendar "ls" "$MAIL_ACC" ok
}

cal_events() {
  local P cid url resp
  P=$(cal_pass); cid="${1:-}"
  [ -n "$cid" ] || { echo "usage: cal events <cal_id>"; return 2; }
  url=$(cal_resolve "$P" "$cid") || return 1
  resp=$(curl -s -m 30 -X REPORT -u "$MAIL_ACC:$P" -H "Depth: 1" -H "Content-Type: application/xml; charset=utf-8" \
    --data '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><c:calendar-data/></d:prop></c:calendar-query>' \
    "$url")
  echo "$resp" | norm > /tmp/.ydcal_resp
  perl -0ne 'while(/<response>(.*?)<\/response>/sg){ my $r=$1; if($r=~/<calendar-data>(.*?)<\/calendar-data>/s){ my $c=$1; my ($u)=($c=~/UID:([^\r\n]+)/); my ($s)=($c=~/SUMMARY:([^\r\n]+)/); my ($ds)=($c=~/DTSTART[^:]*:([^\r\n]+)/); my ($de)=($c=~/DTEND[^:]*:([^\r\n]+)/); printf "UID: %s | %s | %s -> %s\n", $u//"-", $s//"-", $ds//"-", $de//"-"; } }' /tmp/.ydcal_resp
  log calendar "events $cid" "$MAIL_ACC" ok
}

cal_add() {
  local P cid start end summary url uid ics code
  P=$(cal_pass); cid="$1"; start="$2"; end="$3"; summary="$4"
  [ -n "$summary" ] || { echo "usage: cal add <cal_id> <start> <end> <summary>"; return 2; }
  url=$(cal_resolve "$P" "$cid") || return 1
  uid="$(date +%s)-$(head -c4 /dev/urandom | xxd -p)"
  ics_body=$(cat <<EOF
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//LabDoctorM//yandex.sh//RU
BEGIN:VEVENT
UID:${uid}.labdoctorm
DTSTAMP:$(date -u +%Y%m%dT%H%M%SZ)
DTSTART:${start}
DTEND:${end}
SUMMARY:${summary}
END:VEVENT
END:VCALENDAR
EOF
)
  code=$(curl -s -m 30 -X PUT -u "$MAIL_ACC:$P" -H "Content-Type: text/calendar; charset=utf-8" --data-binary "$ics_body" \
    "$url/${uid}.labdoctorm.ics" -o /dev/null -w '%{http_code}')
  echo "add event -> $url/${uid}.labdoctorm.ics (HTTP $code)"
  echo "UID: ${uid}.labdoctorm"
  log calendar "add $cid ($uid)" "$MAIL_ACC" "http:$code"
}

cal_del() {
  local P cid uid clean url code
  P=$(cal_pass); cid="$1"; uid="$2"
  [ -n "$uid" ] || { echo "usage: cal del <cal_id> <event_uid>"; return 2; }
  url=$(cal_resolve "$P" "$cid") || return 1
  clean=$(echo "$uid" | sed 's/\.ics$//; s/\.labdoctorm$//')
  code=$(curl -s -m 30 -X DELETE -u "$MAIL_ACC:$P" "$url/${clean}.labdoctorm.ics" -o /dev/null -w '%{http_code}')
  echo "del $clean (HTTP $code)"
  log calendar "del $cid ($clean)" "$MAIL_ACC" "http:$code"
}

# Задачи (VTODO) — для календарей-списков задач («Не забыть»).
cal_task() {
  local P cid url
  P=$(cal_pass); cid="${1:-}"; shift || true
  local act="${1:-ls}"; shift || true
  [ -n "$cid" ] || { echo "usage: cal task <cal_id> add|list ..."; return 2; }
  url=$(cal_resolve "$P" "$cid") || return 1
  case "$act" in
    add)
      local summary="$1" due="$2" desc="${3:-}" uid due_fmt ics_body code
      [ -n "$summary" ] || { echo "usage: cal task <cal_id> add <summary> <due YYYY-MM-DD[THH:MM:SSZ]> [desc]"; return 2; }
      summary=$(echo "$summary" | sed 's/,/\\,/g'); desc=$(echo "$desc" | sed 's/,/\\,/g')
      uid="$(date +%s)-$(head -c4 /dev/urandom | xxd -p)"
      due_fmt=$(echo "$due" | tr -d ':-')
      ics_body=$(cat <<EOF
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//LabDoctorM//yandex.sh//RU
BEGIN:VTODO
UID:${uid}.labdoctorm
DTSTAMP:$(date -u +%Y%m%dT%H%M%SZ)
SUMMARY:${summary}
DUE:${due_fmt}
DESCRIPTION:${desc}
END:VTODO
END:VCALENDAR
EOF
)
      code=$(curl -s -m 30 -X PUT -u "$MAIL_ACC:$P" -H "Content-Type: text/calendar; charset=utf-8" --data-binary "$ics_body" \
        "$url/${uid}.labdoctorm.ics" -o /dev/null -w '%{http_code}')
      echo "add task -> $url/${uid}.labdoctorm.ics (HTTP $code)"
      echo "UID: ${uid}.labdoctorm"
      log calendar "task-add $cid ($uid)" "$MAIL_ACC" "http:$code"
      ;;
    list)
      local resp
      resp=$(curl -s -m 30 -X REPORT -u "$MAIL_ACC:$P" -H "Depth: 1" -H "Content-Type: application/xml; charset=utf-8" \
        --data '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><c:calendar-data/></d:prop></c:calendar-query>' \
        "$url")
      echo "$resp" | norm > /tmp/.ydtask_resp
      perl -0ne 'while(/<response>(.*?)<\/response>/sg){ my $r=$1; if($r=~/BEGIN:VTODO/s){ my ($u)=($r=~/UID:([^\r\n]+)/); my ($s)=($r=~/SUMMARY:([^\r\n]+)/); my ($d)=($r=~/DUE[^:]*:([^\r\n]+)/); my ($st)=($r=~/STATUS:([^\r\n]+)/); printf "UID: %s | %s | DUE %s | %s\n", $u//"-", $s//"-", $d//"-", $st//"-"; } }' /tmp/.ydtask_resp
      log calendar "task-list $cid" "$MAIL_ACC" ok
      ;;
    *) echo "cal task: add|list"; return 2;;
  esac
}

# --- main ---
if [ "${YANDEX_SH_LIB:-}" != "1" ]; then
svc="${1:-}"; shift || true
case "$svc" in
  mail)
    himalaya "$@"; rc=$?
    if [ $rc -eq 0 ]; then log mail "$*" "$MAIL_ACC" ok; else log mail "$*" "$MAIL_ACC" "fail:$rc"; fi
    exit $rc
    ;;
  disk)
    act="${1:-}"; shift || true
    P=$(disk_pass)
    case "$act" in
      ls)
        path="${1:-/}"
        code=$(curl -s -m 30 -X PROPFIND -u "$DISK_ACC:$P" -H "Depth: 1" "$WEBDAV$path" -o /tmp/.ydls -w '%{http_code}')
        grep -oiP '(?<=<d:href>)[^<]+' /tmp/.ydls 2>/dev/null | sed 's|^/disk||' || true
        rm -f /tmp/.ydls
        log disk "ls $path" "$DISK_ACC" "http:$code"
        ;;
      get)
        code=$(curl -s -m 120 -u "$DISK_ACC:$P" "$WEBDAV/$1" -o "$2" -w '%{http_code}'); echo "get $1 -> $2 (HTTP $code)"
        log disk "get $1" "$DISK_ACC" "http:$code"
        ;;
      put)
        code=$(curl -s -m 300 -T "$1" -u "$DISK_ACC:$P" "$WEBDAV/$2" -o /dev/null -w '%{http_code}'); echo "put $1 -> $2 (HTTP $code)"
        log disk "put $2" "$DISK_ACC" "http:$code"
        ;;
      del)
        code=$(curl -s -m 30 -X DELETE -u "$DISK_ACC:$P" "$WEBDAV/$1" -o /dev/null -w '%{http_code}'); echo "del $1 (HTTP $code)"
        log disk "del $1" "$DISK_ACC" "http:$code"
        ;;
      mkdir)
        code=$(curl -s -m 30 -X MKCOL -u "$DISK_ACC:$P" "$WEBDAV/$1" -o /dev/null -w '%{http_code}'); echo "mkdir $1 (HTTP $code)"
        log disk "mkdir $1" "$DISK_ACC" "http:$code"
        ;;
      *) echo "disk: ls|get|put|del|mkdir"; exit 2;;
    esac
    ;;
  cal)
    case "${1:-ls}" in
      ls) shift || true; cal_ls "$@" ;;
      events) shift || true; cal_events "$@" ;;
      add) shift || true; cal_add "$@" ;;
      del) shift || true; cal_del "$@" ;;
      task) shift || true; cal_task "$@" ;;
      *) echo "cal: ls|events|add|del|task"; exit 2;;
    esac
    ;;
  contacts)
    P=$(contacts_pass)
    principal=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 0" \
      --data '<d:propfind xmlns:d="DAV:"><d:prop><d:current-user-principal/></d:prop></d:propfind>' "$CARDDAV")
    puhref=$(echo "$principal" | norm | grep -oP '(?<=<href>)[^<]+' | head -1); puhref="${puhref%/}"
    case "$puhref" in
      http*) ab_base="$puhref" ;;
      /*)    ab_base="${CARDDAV%/}$puhref" ;;
      *)      ab_base="${CARDDAV%/}/$puhref" ;;
    esac
    home=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 0" \
      --data '<d:propfind xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav"><d:prop><card:addressbook-home-set/></d:prop></d:propfind>' "$ab_base")
    hhref=$(echo "$home" | norm | grep -oP '(?<=<href>)[^<]+' | head -1); hhref="${hhref%/}"
    case "$hhref" in
      http*) ab_home="$hhref" ;;
      /*)    ab_home="${CARDDAV%/}$hhref" ;;
      *)      ab_home="${CARDDAV%/}/$hhref" ;;
    esac
    echo "Адресные книги (home: $ab_home):"
    resp=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 1" \
      --data '<d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/><d:displayname/></d:prop></d:propfind>' "$ab_home")
    echo "$resp" | norm | tr -d '\n' | grep -oP '<response>.*?</response>' | \
      while IFS= read -r r; do
        h=$(echo "$r" | grep -oP '<href[^>]*>\K[^<]+'); n=$(echo "$r" | grep -oP '(?<=<displayname>)[^<]+')
        if echo "$r" | grep -qE '<addressbook' && echo "$r" | grep -qE '<collection'; then printf '  %s\t%s\n' "${n:-$h}" "$h"; fi
      done
    log contacts "ls" "$MAIL_ACC" ok
    ;;
  usage)
    echo "=== Сводка использования (за всё время) ==="
    tail -n +3 "$LOG" | awk -F'\t' '{c[$2]++} END{for(s in c) printf "%-10s %d\n", s, c[s]}'
    echo "--- Последние 10 событий ---"
    tail -n 10 "$LOG"
    ;;
  *)
    echo "Использование: yandex.sh {mail|disk|cal|contacts|usage} ..."
    exit 2
    ;;
esac
fi
