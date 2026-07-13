#!/bin/bash
# rotate-vault-keys.sh - Скрипт ротации ключей в vault для Free API Hunter
# Запускать раз в 90 дней через cron

set -euo pipefail

VAULT_BASE="/root/LabDoctorM/vault"
HUNTER_VAULT="$VAULT_BASE/free-api-hunter"
LOG_FILE="/var/log/free-api-hunter/vault-rotation.log"
BACKUP_DIR="$VAULT_BASE/backups/$(date +%Y-%m-%d)"

log() {
    echo "[$(date -u +'%Y-%m-%d %H:%M:%S UTC')] $*" | tee -a "$LOG_FILE"
}

# Проверяем что запустили от root
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен от root"
   exit 1
fi

# Создаём резервную копию текущего vault
mkdir -p "$BACKUP_DIR"
cp -r "$HUNTER_VAULT" "$BACKUP_DIR/"
log "Создана резервная копия в $BACKUP_DIR"

# Список провайдеров для которых нужно сгенерировать новые ключи
# В реальности здесь должен быть запрос к Yandex 360 или другому источнику
# Для демонстрации - просто перегенерируем заглушки
declare -a PROVIDERS=(
    "opencanvas"
    "pollinations"
    "zhipuai"
    "glhmate"
    # добавьте реальных провайдеров из вашего vault
)

log "Начинаем ротацию ключей для ${#PROVIDERS[@]} провайдеров"

for provider in "${PROVIDERS[@]}"; do
    provider_dir="$HUNTER_VAULT/$provider"
    if [[ ! -d "$provider_dir" ]]; then
        log "Пропускаем $provider - директория не существует"
        continue
    fi

    log "Обрабатываем провайдер: $provider"

    # Удаляем старые ключи (оставляем только структуру)
    rm -f "$provider_dir"/*.key

    # Генерируем новые заглушки (в реальности здесь будет вызов Yandex 360 API)
    echo "NEW_KEY_FOR_${provider}_1" > "$provider_dir/key1.key"
    echo "NEW_KEY_FOR_${provider}_2" > "$provider_dir/key2.key"
    echo "NEW_KEY_FOR_${provider}_3" > "$provider_dir/key3.key"

    # Устанавливаем права
    chmod 600 "$provider_dir"/*.key

    log "Сгенерированы новые ключи для $provider"
done

log "Ротация ключей завершена"
log "Следующая ротация запланирована на $(date -d '+90 days' -u +'%Y-%m-%d')"

# Отправляем уведомление в Telegram если настроено
if [[ -f "$VAULT_BASE/free-api-hunter/telegram_bot_token.key" && \
      -f "$VAULT_BASE/free-api-hunter/telegram_chat_id.key" ]]; then
    BOT_TOKEN=$(cat "$VAULT_BASE/free-api-hunter/telegram_bot_token.key")
    CHAT_ID=$(cat "$VAULT_BASE/free-api-hunter/telegram_chat_id.key")

    MESSAGE="🔐 <b>Free API Hunter — Vault Key Rotation</b>\n\n"
    MESSAGE+="Выполнена плановая ротация ключей для $((${#PROVIDERS[@]})) провайдеров.\n"
    MESSAGE+="Резервная копия: <code>$BACKUP_DIR</code>\n"
    MESSAGE+="Следующая ротация: $(date -d '+90 days' -u +'%Y-%m-%d')"

    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
         -d "chat_id=$CHAT_ID" \
         -d "text=$MESSAGE" \
         -d "parse_mode=HTML" >/dev/null || log "Не удалось отправить уведомление в Telegram"
fi

exit 0
