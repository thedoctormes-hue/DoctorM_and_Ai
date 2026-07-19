#!/usr/bin/env bash
# Guard: блокирует push в чужие агентские ветки (PAT-019 I-03 / ADR-0059).
# Устанавливается как git-hooks/pre-push (core.hooksPath указывает на git-hooks/).
# Ловит эксплойт worktree-изоляции на клиенте: агент не может запушить
# коммиты в ветку, принадлежащую другому агенту.
#
# Контекст: агент работает в worktree DoctorM_and_Ai-wt-<agent> (или <repo>-wt-<agent>).
# Ветка refs/heads/<agent>/... принадлежит <agent>. Push разрешён только:
#   - из своего worktree (CURRENT_AGENT == <agent>), ИЛИ
#   - привилегированным лицом (ЗавЛаб / инфра), ИЛИ
#   - когда все НОВЫЕ коммиты пуша авторства <agent> (branch-author consistency).
#
# Не-owned префиксы (main, develop, feat/*, fix/* ...) не контролируются.
# ADR-0057 (неавторизованные мутации инцидентов/паттернов) — WARN, не блок (v1).
#
# Самодостаточен: не ссылается на файлы вне git-hooks/ (работает для любого репо
# через глобальный core.hooksPath).

set -u

ZEROS="0000000000000000000000000000000000000000"

prefix_owner() {
  case "$1" in
    antcat)        echo antcat ;;
    owl)           echo owl ;;
    kotolizator)   echo kotolizator ;;
    kot)           echo kotolizator ;;
    dominika)      echo dominika ;;
    raven)         echo raven ;;
    streikbrecher) echo streikbrecher ;;
    mangust)       echo mangust ;;
    bestia)        echo bestia ;;
    builder)       echo antcat ;;
    spike)         echo spike ;;
    t-w1n)         echo t-w1n ;;
    *)             echo "" ;;
  esac
}

is_priv() {
  case "$1" in
    thedoctormes|labdoctor|root) return 0 ;;
    *) return 1 ;;
  esac
}

# current agent from worktree path or env
CURRENT_AGENT=""
if [ -n "${AGENT_ID:-}" ]; then
  CURRENT_AGENT="$AGENT_ID"
else
  TOP="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  BASE="$(basename "$TOP" 2>/dev/null || echo "")"
  if echo "$BASE" | grep -q -- '-wt-'; then
    CURRENT_AGENT="$(echo "$BASE" | sed -E 's/.*-wt-([a-zA-Z0-9_-]+).*/\1/' | cut -d- -f1)"
  fi
fi

AUTHOR_LOCAL="$(git var GIT_AUTHOR_IDENT 2>/dev/null | sed -E 's/.*<([^>]+)>.*/\1/' | cut -d@ -f1)"
[ "$AUTHOR_LOCAL" = "agents" ] && AUTHOR_LOCAL=""

# range of introduced commits: new branch -> not on origin; update -> rsha..lsha
range_args() {
  if [ "$2" = "$ZEROS" ]; then
    echo "$1 --not --remotes=origin"
  else
    echo "$2..$1"
  fi
}

refs="$(cat)"   # capture once; feed both loops below

BLOCKED=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  set -- $line
  lref=$1; lsha=$2; rref=$3; rsha=$4
  [ -z "$lref" ] && continue
  case "$rref" in
    refs/heads/*) ;;
    *) continue ;;
  esac
  branch="${rref#refs/heads/}"
  prefix="${branch%%/*}"
  owner="$(prefix_owner "$prefix")"

  # Защита главных веток (master/main): push/force-push только привилегированным
  case "$branch" in
    master|main)
      if is_priv "$CURRENT_AGENT" || { [ -n "$AUTHOR_LOCAL" ] && is_priv "$AUTHOR_LOCAL"; }; then
        : # привилегированным разрешено
      else
        BLOCKED=1
        {
          echo "BLOCKED by branch-ownership guard (ADR-0059 / protected main):"
          echo "  ветка '$branch' — защищённая главная ветка"
          echo "  push инициирован: agent='${CURRENT_AGENT:-<unknown>}' (worktree/AGENT_ID), author-ident='${AUTHOR_LOCAL:-<none>}'"
          echo "  Разрешено только привилегированным (thedoctormes/labdoctor/root)."
        } >&2
      fi
      continue
      ;;
  esac

  [ -z "$owner" ] && continue
  [ "$lsha" = "$ZEROS" ] && continue   # delete -> skip

  RANGE="$(range_args "$lsha" "$rsha")"
  AUTHORS="$(git log --format='%ae' $RANGE 2>/dev/null | sort -u | cut -d@ -f1 | grep -v '^$')"

  ALLOW=0
  is_priv "$CURRENT_AGENT" && ALLOW=1
  [ "$CURRENT_AGENT" = "$owner" ] && ALLOW=1
  [ -n "$AUTHOR_LOCAL" ] && [ "$AUTHOR_LOCAL" = "$owner" ] && ALLOW=1

  if [ -n "$AUTHORS" ]; then
    all_match=1
    for a in $AUTHORS; do
      if ! is_priv "$a"; then
        [ "$a" != "$owner" ] && all_match=0
      fi
    done
    [ "$all_match" = "1" ] && ALLOW=1
  fi

  if [ "$ALLOW" = "0" ]; then
    BLOCKED=1
    {
      echo "BLOCKED by branch-ownership guard (ADR-0059 / PAT-019 I-03):"
      echo "  ветка '$branch' принадлежит агенту '$owner'"
      echo "  push инициирован: agent='${CURRENT_AGENT:-<unknown>}' (worktree/AGENT_ID), author-ident='${AUTHOR_LOCAL:-<none>}'"
      echo "  author(s) в пуше: ${AUTHORS:-<none>}"
      echo "  Разрешено: свой worktree ($owner), привилегированный, либо все коммиты за автором '$owner'."
    } >&2
  fi
done <<<"$refs"

# ADR-0057 WARN: неавторизованные мутации инцидентов/паттернов (non-blocking)
while IFS= read -r line; do
  [ -z "$line" ] && continue
  set -- $line
  lref=$1; lsha=$2; rref=$3; rsha=$4
  [ -z "$lref" ] && continue
  case "$rref" in
    refs/heads/*) ;;
    *) continue ;;
  esac
  [ "$lsha" = "$ZEROS" ] && continue
  git diff --name-only --diff-filter=AM "$rsha" "$lsha" 2>/dev/null | while read -r f; do
    case "$f" in
      incidents/INC-*.md|patterns/PAT-*.md)
        adiff="$(git diff "$rsha" "$lsha" -- "$f" 2>/dev/null)"
        fa="$(printf '%s\n' "$adiff" | grep -E '^\+author:' | head -1 | sed -E 's/.*author:[[:space:]]*"?([^"[:space:]]+).*/\1/' | tr '[:upper:]' '[:lower:]')"
        if printf '%s\n' "$adiff" | grep -E '^\+verified_by:' >/dev/null; then
          vb="$(printf '%s\n' "$adiff" | grep -E '^\+verified_by:' | head -1 | sed -E 's/.*verified_by:[[:space:]]*"?([^"[:space:]]+).*/\1/' | tr '[:upper:]' '[:lower:]')"
          if [ -n "$fa" ] && [ "$vb" = "$fa" ]; then
            echo "WARN (ADR-0057): '$f' — self-verify (verified_by == author '$fa'). Требуется verifier != author." >&2
          fi
        fi
        ;;
    esac
  done
done <<<"$refs"

[ "$BLOCKED" = "1" ] && exit 1
exit 0
