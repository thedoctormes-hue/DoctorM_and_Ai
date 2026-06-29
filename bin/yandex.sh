#!/usr/bin/env bash
# yandex.sh — единая обёртка для Яндекс-сервисов с автологированием использования.
# Каждый вызов пишет строку в logs/yandex-usage.log.
# Назначение: через 2 недели ревью — какими сервисами реально пользуемся.
#
# Использование:
#   yandex.sh mail <himalaya-args...>     # почта (DoctorMandAi)
#   yandex.sh disk ls [path]              # список на Диске (moscowskiymichi)
#   yandex.sh disk get <remote> <local>   # скачать с Диска
#   yandex.sh disk put <local> <remote>   # залить на Диск
#   yandex.sh disk del <remote>           # удалить с Диска
#   yandex.sh disk mkdir <remote>         # создать папку
#   yandex.sh cal ls                      # календари (DoctorMandAi)
#   yandex.sh contacts ls                 # контакты (DoctorMandAi)
#   yandex.sh usage                       # показать сводку лога
set -uo pipefail

LOG=/root/LabDoctorM/.ops/logs/yandex-usage.log
MAIL_ACC="DoctorMandAi@yandex.com"
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
    P=$(cal_pass)
    code=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 1" \
      --data '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:displayname/></d:prop></d:propfind>' \
      "$CALDAV" -o /tmp/.ydcal -w '%{http_code}')
    grep -oiP '(?<=displayname>)[^<]+' /tmp/.ydcal 2>/dev/null || true; rm -f /tmp/.ydcal
    log calendar "${1:-ls}" "$MAIL_ACC" "http:$code"
    ;;
  contacts)
    P=$(contacts_pass)
    code=$(curl -s -m 30 -X PROPFIND -u "$MAIL_ACC:$P" -H "Depth: 1" \
      --data '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:displayname/></d:prop></d:propfind>' \
      "$CARDDAV" -o /tmp/.ydcon -w '%{http_code}')
    grep -oiP '(?<=displayname>)[^<]+' /tmp/.ydcon 2>/dev/null || true; rm -f /tmp/.ydcon
    log contacts "${1:-ls}" "$MAIL_ACC" "http:$code"
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
