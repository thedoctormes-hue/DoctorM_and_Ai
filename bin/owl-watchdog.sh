#!/usr/bin/env bash
# owl-watchdog.sh — сторож дисциплины.
# Отделяет ЖИВУЮ работу агентов от БРОШЕННОЙ (сиротской).
# Вывод — по-человечески, без путей/хэшей/техники (для ЗавЛаба-вайбкодера).
set -u

NOW=$(date +%s)
THRESH=86400        # 24 часа — порог "брошено"
ONLINE=21600        # 6 часов — считаем агента "в деле", если сессия свежее
LAB=/root/LabDoctorM
AGENTS="antcat bestia streikbrecher kotolizator mangust raven dominika owl"

# --- собрать, кто сейчас в деле (по свежести сессий) ---
declare -A IS_LIVE
for a in $AGENTS; do
  newest=0
  for f in "$LAB"/.openclaw/agents/"$a"/sessions/*.jsonl; do
    [ -f "$f" ] || continue
    mt=$(stat -c %Y "$f" 2>/dev/null || echo 0)
    [ -n "$mt" ] && [ "$mt" -gt "$newest" ] && newest=$mt
  done
  if [ "$newest" -gt 0 ]; then
    age=$((NOW - newest))
    if [ "$age" -lt "$ONLINE" ]; then IS_LIVE["$a"]=1; fi
  fi
done

# --- для каждого агента: последняя активность + несохранённая работа ---
WORKING=()
ORPHAN=()
for a in $AGENTS; do
  last=0
  # свежесть файлов в workspace
  ws="$LAB/workspaces/$a"
  if [ -d "$ws" ]; then
    f=$(find "$ws" -type f -not -path '*/.git/*' -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
    [ -n "$f" ] && last=$f
  fi
  # несохранённая работа по проектам (грязное дерево + незапушенные ветки owner/*)
  orphan_items=()
  for d in "$LAB"/projects/*/; do
    [ -d "$d/.git" ] || continue
    proj=$(basename "$d")
    ( cd "$d" 2>/dev/null
      if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "DIRTY:$proj"
      fi
      for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null | grep "^$a/"); do
        ahead=$(git rev-list --count origin/main.."$b" 2>/dev/null | cut -d. -f1)
        [ -n "$ahead" ] && [ "$ahead" -gt 0 ] && echo "BRANCH:$proj:$b:+$ahead"
      done
    )
  done | while read -r line; do
    orphan_items+=("$line")
  done
  # (подобрать последнюю активность из коммитов owner-веток)
  for d in "$LAB"/projects/*/; do
    [ -d "$d/.git" ] || continue
    ( cd "$d" 2>/dev/null
      for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null | grep "^$a/"); do
        ct=$(git log -1 --format='%ct' "$b" 2>/dev/null | cut -d. -f1)
        [ -n "$ct" ] && [ "$ct" -gt "$last" ] && echo "CT:$ct"
      done
    )
  done | while read -r ctline; do
    ct=${ctline#CT:}
    [ "$ct" -gt "$last" ] && last=$ct
  done

  if [ "$last" -gt 0 ]; then
    age=$((NOW - last))
    if [ "$age" -lt "$THRESH" ]; then
      WORKING+=("$a")
      continue
    fi
    # старше 24ч — брошено только если ЕСТЬ несохранённая работа и агент не в деле
    if [ "${#orphan_items[@]}" -gt 0 ] && [ -z "${IS_LIVE[$a]:-}" ]; then
      days=$((age / 86400))
      ORPHAN+=("$a:$days:${orphan_items[*]}")
    fi
  fi
done

# --- вывод по-человечески ---
echo "=== СТОРОЖ: живое против брошенного ==="
echo ""
if [ "${#WORKING[@]}" -gt 0 ]; then
  echo "КТО СЕЙЧАС РАБОТАЕТ:"
  for a in "${WORKING[@]}"; do
    if [ -n "${IS_LIVE[$a]:-}" ]; then
      echo "  - $a (в деле прямо сейчас)"
    else
      echo "  - $a (свежая активность)"
    fi
  done
else
  echo "КТО СЕЙЧАС РАБОТАЕТ: никто"
fi
echo ""
if [ "${#ORPHAN[@]}" -gt 0 ]; then
  echo "БРОШЕНО ДОЛЬШЕ СУТОК (разберись):"
  for o in "${ORPHAN[@]}"; do
    name=${o%%:*}
    rest=${o#*:}
    days=${rest%%:*}
    items=${rest#*:}
    echo "  - $name (не трогал $days дн) — осталось: $items"
  done
else
  echo "БРОШЕНО ДОЛЬШЕ СУТОК: ничего, всё чисто"
fi
echo ""
echo "=== конец ==="
