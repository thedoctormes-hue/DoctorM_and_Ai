#!/usr/bin/env bash
# safe-config-edit.sh — безопасное редактирование openclaw.json
# Предотвращает clobber конфига при конкурентной записи от gateway.
#
# Использование:
#   ./safe-config-edit.sh          # открыть редактор (по умолчанию nano)
#   ./safe-config-edit.sh vim      # открыть конкретный редактор
#   ./safe-config-edit.sh --check  # только проверить конфиг (без редактирования)
#
# Алгоритм:
#   1. Проверить что конфиг валиден сейчас
#   2. Остановить gateway
#   3. Сделать бэкап с меткой времени
#   4. Открыть редактор
#   5. После редактирования — валидация JSON
#   6. Запустить gateway

set -euo pipefail

CONFIG="$HOME/.openclaw/openclaw.json"
BACKUP_DIR="$HOME/.openclaw/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/openclaw.json.bak-$TIMESTAMP"
EDITOR="${1:-nano}"

# ── Цвета ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; }

# ── Проверка JSON ────────────────────────────────────────────────────────────
validate_json() {
    if python3 -m json.tool "$CONFIG" > /dev/null 2>&1; then
        ok "Конфиг валиден: $CONFIG"
        return 0
    else
        fail "Конфиг НЕвалиден: $CONFIG"
        return 1
    fi
}

# ── Только проверка ──────────────────────────────────────────────────────────
if [[ "$EDITOR" == "--check" ]]; then
    validate_json
    exit $?
fi

# ── Шаг 1: Предварительная проверка ──────────────────────────────────────────
echo ""
info "=== Безопасное редактирование openclaw.json ==="
echo ""

info "Шаг 1/5: Проверка текущего конфига..."
if ! validate_json; then
    fail "Текущий конфиг повреждён. Редактирование отменено."
    warn "Восстановите из бэкапа: cp $BACKUP_FILE $CONFIG"
    exit 1
fi

# ── Шаг 2: Остановка gateway ────────────────────────────────────────────────
echo ""
info "Шаг 2/5: Остановка OpenClaw gateway..."
if openclaw gateway status 2>&1 | grep -q "running"; then
    openclaw gateway stop 2>&1
    # Ждём полной остановки
    for i in $(seq 1 10); do
        if ! openclaw gateway status 2>&1 | grep -q "running"; then
            break
        fi
        sleep 1
    done
    if openclaw gateway status 2>&1 | grep -q "running"; then
        fail "Gateway не остановился за 10 секунд. Прерывание."
        exit 1
    fi
    ok "Gateway остановлен."
else
    warn "Gateway уже остановлен или не запущен."
fi

# ── Шаг 3: Бэкап ─────────────────────────────────────────────────────────────
echo ""
info "Шаг 3/5: Создание бэкапа..."
mkdir -p "$BACKUP_DIR"
cp -p "$CONFIG" "$BACKUP_FILE"
ok "Бэкап создан: $BACKUP_FILE"

# Также обновляем .bak для совместимости
cp -p "$CONFIG" "$HOME/.openclaw/openclaw.json.bak"

# ── Шаг 4: Редактирование ────────────────────────────────────────────────────
echo ""
info "Шаг 4/5: Открытие редактора ($EDITOR)..."
info "Файл: $CONFIG"
echo ""

# Сохраняем контрольную сумму для проверки изменений
BEFORE_HASH="$(md5sum "$CONFIG" | awk '{print $1}')"

$EDITOR "$CONFIG"

AFTER_HASH="$(md5sum "$CONFIG" | awk '{print $1}')"

if [[ "$BEFORE_HASH" == "$AFTER_HASH" ]]; then
    warn "Конфиг не изменён. Запуск gateway..."
    openclaw gateway start 2>&1
    ok "Gateway запущен."
    ok "=== Готово (без изменений) ==="
    exit 0
fi

# ── Шаг 5: Валидация и запуск ────────────────────────────────────────────────
echo ""
info "Шаг 5/5: Валидация изменённого конфига..."
if validate_json; then
    ok "Конфиг валиден. Запуск gateway..."
    openclaw gateway start 2>&1

    # Проверячто поднялся
    sleep 2
    if openclaw gateway status 2>&1 | grep -q "running"; then
        ok "Gateway запущен и работает."
        ok "=== Готово ==="
    else
        warn "Gateway запущен, но статус неясен. Проверьте: openclaw gateway status"
    fi
else
    fail "Конфиг НЕвалиден после редактирования!"
    warn "Восстановление из бэкапа..."
    cp "$BACKUP_FILE" "$CONFIG"
    ok "Восстановлено из: $BACKUP_FILE"
    openclaw gateway start 2>&1
    ok "Gateway запущен с восстановленным конфигом."
    fail "=== Редактирование отменено (конфиг невалиден) ==="
    exit 1
fi
