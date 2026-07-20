#!/usr/bin/env bash
# nc.sh — обёртка для Nextcloud (WebDAV + CalDAV + CardDAV + Talk + Notes + Deck), GyxerCloud.
# Единая точка для агентов OpenClaw и ЗавЛаба. Аналог yandex.sh, но для
# выделенного инстанса https://cloud.gyxer.com/
# Каждый вызов логируется в .ops/logs/nc-usage.log.
#
# Использование:
#   Файлы (WebDAV):
#     nc.sh ls [path]              # список (от корня WebDAV; рекомендуется colony/...)
#     nc.sh get <remote> <local>   # скачать
#     nc.sh put <local> <remote>   # залить (промежуточные папки создаются авто)
#     nc.sh del <remote>           # удалить
#     nc.sh mkdir <remote>         # создать папку
#   Календарь (CalDAV):
#     nc.sh cal ls                 # список календарей
#     nc.sh cal add <calId> <startUTC> <endUTC> <summary>
#     nc.sh cal rm <calId> <uid>   # удалить событие
#   Контакты (CardDAV):
#     nc.sh contacts ls            # список адресных книг/контактов
#   Talk (OCS):
#     nc.sh talk ls                # список комнат
#     nc.sh talk send <token> <msg>
#   Notes (REST):
#     nc.sh notes ls
#     nc.sh notes add <title> [content] [category]
#     nc.sh notes rm <id>
#   Deck (REST канбан):
#     nc.sh deck ls               # список досок
#     nc.sh deck add <boardId> <stackId> <title>
#   nc.sh usage                  # сводка лога
#
# Логин/пароль (Nextcloud app-password) — ИЗ ФАЙЛОВ, не из git:
#   ~/.config/nextcloud/.nc-user
#   ~/.config/nextcloud/.nc-pass
# Можно переопределить через env: NC_USER / NC_PASS.
# Для тестов/импорта функций: NC_SH_LIB=1 source nc.sh (не запускает main).
set -uo pipefail

LOG=/root/LabDoctorM/.ops/logs/nc-usage.log
WEBDAV="https://cloud.gyxer.com/remote.php/webdav"
DAV="https://cloud.gyxer.com/remote.php/dav"
OCS="https://cloud.gyxer.com/ocs/v2.php"
API="https://cloud.gyxer.com"

nc_user() { cat ~/.config/nextcloud/.nc-user 2>/dev/null || echo "${NC_USER:-mrBaristo}"; }
nc_pass() { cat ~/.config/nextcloud/.nc-pass 2>/dev/null || echo "${NC_PASS:-}"; }

log() { # service action result
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$1" "$2" "$3" "$4" >> "$LOG"
}

# Резолвит путь от корня WebDAV: /* -> без слэша, "" -> colony, иначе как есть
resolve() {
  local p="$1"
  case "$p" in
    /*) printf '%s' "${p#/}" ;;
    "") printf '%s' "colony" ;;
    *)  printf '%s' "$p" ;;
  esac
}

# ---------- FILES (WebDAV) ----------
disk_ls() {
  local U P path code
  U=$(nc_user); P=$(nc_pass)
  path=$(resolve "${1:-}")
  code=$(curl -s -m 30 -X PROPFIND -u "$U:$P" -H "Depth: 1" "$WEBDAV/$path" -o /tmp/.ncls -w '%{http_code}')
  sed -E 's/(<\/?)[a-zA-Z_-]+:/\1/g' /tmp/.ncls | \
    grep -o '<href>[^<]*</href>' | \
    sed -E 's#.*webdav/##; s#</?href>##g; s#/$##' | sort || true
  rm -f /tmp/.ncls
  log disk "ls $path" "$U" "http:$code"
}

disk_get() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 120 -u "$U:$P" "$WEBDAV/$(resolve "$1")" -o "$2" -w '%{http_code}')
  echo "get $1 -> $2 (HTTP $code)"
  log disk "get $1" "$U" "http:$code"
}

disk_put() {
  local U P remote dir seg built code
  U=$(nc_user); P=$(nc_pass)
  remote=$(resolve "$2")
  dir=$(dirname "$remote")
  if [ "$dir" != "." ] && [ "$dir" != "/" ]; then
    built=""
    IFS='/'; for seg in $dir; do
      [ -z "$seg" ] && continue
      built="$built/$seg"
      curl -s -m 30 -X MKCOL -u "$U:$P" "$WEBDAV$built" -o /dev/null
    done
    unset IFS
  fi
  code=$(curl -s -m 300 -T "$1" -u "$U:$P" "$WEBDAV/$remote" -o /dev/null -w '%{http_code}')
  echo "put $1 -> $remote (HTTP $code)"
  log disk "put $remote" "$U" "http:$code"
}

disk_del() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -X DELETE -u "$U:$P" "$WEBDAV/$(resolve "$1")" -o /dev/null -w '%{http_code}')
  echo "del $1 (HTTP $code)"
  log disk "del $1" "$U" "http:$code"
}

disk_mkdir() {
  local U P code remote
  U=$(nc_user); P=$(nc_pass)
  remote=$(resolve "$1")
  code=$(curl -s -m 30 -X MKCOL -u "$U:$P" "$WEBDAV/$remote" -o /dev/null -w '%{http_code}')
  echo "mkdir $remote (HTTP $code)"
  log disk "mkdir $remote" "$U" "http:$code"
}

# ---------- CALENDAR (CalDAV) ----------
cal_ls() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -X PROPFIND -u "$U:$P" -H "Depth: 1" "$DAV/calendars/$U/" -o /tmp/.nccal -w '%{http_code}')
  sed -E 's/(<\/?)[a-zA-Z_-]+:/\1/g' /tmp/.nccal | grep -o '<href>[^<]*</href>' | \
    sed -E "s#.*/calendars/$U/##; s#</?href>##g; s#/\$##" | sort
  rm -f /tmp/.nccal
  log cal "ls" "$U" "http:$code"
}

cal_add() {
  local U P cal start end sum uid ms ms2 body code
  U=$(nc_user); P=$(nc_pass)
  cal="$1"; start="$2"; end="$3"; sum="$4"
  uid="nc-$(date -u +%s)-$RANDOM"
  ms=$(date -d "$start" +"%Y%m%dT%H%M%S" 2>/dev/null)
  ms2=$(date -d "$end" +"%Y%m%dT%H%M%S" 2>/dev/null)
  body="BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//LabDoctorM//nc.sh//EN
BEGIN:VEVENT
UID:$uid
DTSTAMP:$(date -u +%Y%m%dT%H%M%SZ)
DTSTART;TZID=Europe/Moscow:$ms
DTEND;TZID=Europe/Moscow:$ms2
SUMMARY:$sum
END:VEVENT
END:VCALENDAR"
  code=$(curl -s -m 30 -X PUT -u "$U:$P" -H "Content-Type: text/calendar; charset=utf-8" \
    --data-binary "$body" "$DAV/calendars/$U/$cal/$uid.ics" -o /dev/null -w '%{http_code}')
  echo "cal add -> $cal/$uid.ics (HTTP $code)"
  log cal "add $sum" "$U" "http:$code"
}

cal_rm() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -X DELETE -u "$U:$P" "$DAV/calendars/$U/$1/$2.ics" -o /dev/null -w '%{http_code}')
  echo "cal rm $1/$2 (HTTP $code)"
  log cal "rm $2" "$U" "http:$code"
}

# ---------- CONTACTS (CardDAV) ----------
contacts_ls() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -X PROPFIND -u "$U:$P" -H "Depth: 1" "$DAV/addressbooks/users/$U/" -o /tmp/.nccard -w '%{http_code}')
  sed -E 's/(<\/?)[a-zA-Z_-]+:/\1/g' /tmp/.nccard | grep -o '<href>[^<]*</href>' | \
    sed -E "s#.*/addressbooks/users/$U/##; s#</?href>##g; s#/\$##" | sort
  rm -f /tmp/.nccard
  log contacts "ls" "$U" "http:$code"
}

# ---------- TALK (OCS) ----------
talk_ls() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -u "$U:$P" -H "OCS-APIRequest: true" -H "Accept: application/json" \
    "$OCS/apps/spreed/api/v4/room?format=json" -o /tmp/.nctalk -w '%{http_code}')
  python3 -c "import sys,json; d=json.load(open('/tmp/.nctalk')); [print(r.get('token'),'\t',r.get('displayName')) for r in d['ocs']['data']]" 2>/dev/null || cat /tmp/.nctalk
  rm -f /tmp/.nctalk
  log talk "ls" "$U" "http:$code"
}

talk_send() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -u "$U:$P" -H "OCS-APIRequest: true" -H "Content-Type: application/json" \
    -d "{\"message\":\"$2\"}" "$OCS/apps/spreed/api/v4/room/$1/chat?format=json" -o /dev/null -w '%{http_code}')
  echo "talk send -> $1 (HTTP $code)"
  log talk "send" "$U" "http:$code"
}

# ---------- NOTES (REST) ----------
notes_ls() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -u "$U:$P" -H "OCS-APIRequest: true" \
    "$API/apps/notes/api/v1/notes" -o /tmp/.ncnotes -w '%{http_code}')
  python3 -c "import sys,json; d=json.load(open('/tmp/.ncnotes')); [print(n.get('id'),'\t',n.get('title')) for n in d]" 2>/dev/null || cat /tmp/.ncnotes
  rm -f /tmp/.ncnotes
  log notes "ls" "$U" "http:$code"
}

notes_add() {
  local U P code title content cat
  U=$(nc_user); P=$(nc_pass)
  title="$1"; content="${2:-}"; cat="${3:-}"
  code=$(curl -s -m 30 -u "$U:$P" -H "OCS-APIRequest: true" -H "Content-Type: application/json" \
    -d "{\"title\":\"$title\",\"content\":\"$content\",\"category\":\"$cat\"}" \
    "$API/apps/notes/api/v1/notes" -o /tmp/.ncnoteadd -w '%{http_code}')
  python3 -c "import sys,json; d=json.load(open('/tmp/.ncnoteadd')); print('created id', d.get('id'))" 2>/dev/null
  rm -f /tmp/.ncnoteadd
  log notes "add $title" "$U" "http:$code"
}

notes_rm() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -X DELETE -u "$U:$P" -H "OCS-APIRequest: true" \
    "$API/apps/notes/api/v1/notes/$1" -o /dev/null -w '%{http_code}')
  echo "notes rm $1 (HTTP $code)"
  log notes "rm $1" "$U" "http:$code"
}

# ---------- DECK (REST канбан) ----------
deck_ls() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -u "$U:$P" -H "OCS-APIRequest: true" \
    "$API/apps/deck/api/v1.0/boards" -o /tmp/.ncdeck -w '%{http_code}')
  python3 -c "import sys,json; d=json.load(open('/tmp/.ncdeck')); [print(b.get('id'),'\t',b.get('title')) for b in d]" 2>/dev/null || cat /tmp/.ncdeck
  rm -f /tmp/.ncdeck
  log deck "ls" "$U" "http:$code"
}

deck_add_card() {
  local U P code
  U=$(nc_user); P=$(nc_pass)
  code=$(curl -s -m 30 -u "$U:$P" -H "OCS-APIRequest: true" -H "Content-Type: application/json" \
    -d "{\"title\":\"$3\"}" "$API/apps/deck/api/v1.0/boards/$1/stacks/$2/cards" -o /dev/null -w '%{http_code}')
  echo "deck add card -> board $1 stack $2 (HTTP $code)"
  log deck "add $3" "$U" "http:$code"
}

# --- main ---
if [ "${NC_SH_LIB:-}" != "1" ]; then
  svc="${1:-}"; shift || true
  case "$svc" in
    ls)    disk_ls "$@" ;;
    get)   disk_get "$@" ;;
    put)   disk_put "$@" ;;
    del)   disk_del "$@" ;;
    mkdir) disk_mkdir "$@" ;;
    cal)   sub="${1:-}"; shift || true; case "$sub" in
            ls)  cal_ls "$@" ;;
            add) cal_add "$@" ;;
            rm)  cal_rm "$@" ;;
            *) echo "Использование: nc.sh cal {ls|add <calId> <start> <end> <summary>|rm <calId> <uid>}" ;;
          esac ;;
    contacts) sub="${1:-}"; shift || true; case "$sub" in
            ls) contacts_ls "$@" ;;
            *) echo "Использование: nc.sh contacts ls" ;;
          esac ;;
    talk)  sub="${1:-}"; shift || true; case "$sub" in
            ls)   talk_ls "$@" ;;
            send) talk_send "$@" ;;
            *) echo "Использование: nc.sh talk {ls|send <token> <msg>}" ;;
          esac ;;
    notes) sub="${1:-}"; shift || true; case "$sub" in
            ls)  notes_ls "$@" ;;
            add) notes_add "$@" ;;
            rm)  notes_rm "$@" ;;
            *) echo "Использование: nc.sh notes {ls|add <title> [content] [cat]|rm <id>}" ;;
          esac ;;
    deck)  sub="${1:-}"; shift || true; case "$sub" in
            ls)  deck_ls "$@" ;;
            add) deck_add_card "$@" ;;
            *) echo "Использование: nc.sh deck {ls|add <boardId> <stackId> <title>}" ;;
          esac ;;
    usage)
      echo "=== Сводка использования nc.sh ==="
      tail -n +3 "$LOG" 2>/dev/null | awk -F'\t' '{c[$2]++} END{for(s in c) printf "%-10s %d\n", s, c[s]}'
      echo "--- Последние 10 событий ---"
      tail -n 10 "$LOG" 2>/dev/null
      ;;
    *) echo "Использование: nc.sh {ls|get|put|del|mkdir|cal|contacts|talk|notes|deck|usage} ..."; exit 2 ;;
  esac
fi
