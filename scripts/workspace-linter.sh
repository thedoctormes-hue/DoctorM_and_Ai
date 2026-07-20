#!/usr/bin/env bash
# workspace-linter.sh — проверка чистоты воркспейсов агентов.
# Канон: WORKSPACE_POLICY.md / ADR-0060.
#   секреты/ключи        -> vault/
#   бэкапы/логи          -> .ops/
#   кэши/бинарники/чужой код/вложенный .git -> запрещены в воркспейсе
# Только чтение. Возвращает exit 1 при наличии нарушений (для крона/гейта).
set -u

LAB=/root/LabDoctorM
WS="$LAB/workspaces"
TOTAL=0

echo "=== ЛИНТЕР ВОРКСПЕЙСОВ (ADR-0060) ==="

for a in "$WS"/*/; do
  [ -d "$a" ] || continue
  agent=$(basename "$a")
  issues=()

  # Секреты: .env, *secret*, папки secrets
  while IFS= read -r f; do
    [ -n "$f" ] && issues+=("СЕКРЕТ: $f")
  done < <(find "$a" -type f \( -name '.env' -o -name '*.env' -o -iname '*secret*' \) -not -path '*/.git/*' 2>/dev/null)

  # Бэкапы
  while IFS= read -r f; do
    [ -n "$f" ] && issues+=("БЭКАП: $f")
  done < <(find "$a" \( -type d -name 'backups' -o -name '*.bak' -o -name '*.bak.*' \) -not -path '*/.git/*' 2>/dev/null)

  # Логи
  while IFS= read -r f; do
    [ -n "$f" ] && issues+=("ЛОГ: $f")
  done < <(find "$a" \( -type d -name 'logs' -o -name '*.log' \) -not -path '*/.git/*' 2>/dev/null)

  # Кэши
  while IFS= read -r f; do
    [ -n "$f" ] && issues+=("КЭШ: $f")
  done < <(find "$a" -type d \( -name '__pycache__' -o -name 'node_modules' -o -name '.cache' -o -name '.pytest_cache' \) -not -path '*/.git/*' 2>/dev/null)

  # Вложенный .git
  while IFS= read -r f; do
    [ -n "$f" ] && issues+=("ВЛОЖЕННЫЙ .git: $f")
  done < <(find "$a" -type d -name '.git' 2>/dev/null)

  # Бинарники / build-выходы
  while IFS= read -r f; do
    [ -n "$f" ] && issues+=("БИНАРНИК/BUILD: $f")
  done < <(find "$a" -type d \( -name 'dist' -o -name 'build' -o -name 'target' \) -not -path '*/.git/*' 2>/dev/null)

  if [ ${#issues[@]} -gt 0 ]; then
    echo ""
    echo "🔴 $agent — нарушений: ${#issues[@]}"
    for i in "${issues[@]}"; do echo "   - $i"; done
    TOTAL=$((TOTAL + ${#issues[@]}))
  else
    echo "✅ $agent — чисто"
  fi
done

echo ""
if [ "$TOTAL" -gt 0 ]; then
  echo "ИТОГО НАРУШЕНИЙ: $TOTAL — требуется уборка"
  exit 1
else
  echo "ИТОГО: все воркспейсы чисты"
  exit 0
fi
