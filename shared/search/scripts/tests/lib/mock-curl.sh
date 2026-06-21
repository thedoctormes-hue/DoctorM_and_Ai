#!/bin/bash
# mock-curl.sh — Мок-слой для curl в тестах
# Использование: source mock-curl.sh
# Перехватывает curl-запросы и возвращает предсказуемые ответы
# вместо реальных API-вызовов.

# Счётчик вызовов
MOCK_CALL_COUNT=0
MOCK_CALLS=()

# Регистрация мок-ответа
# mock_register "pattern" "response_file_or_string"
mock_register() {
    local pattern="$1"
    local response="$2"
    MOCK_RESPONSES["$pattern"]="$response"
}

# Очистка моков
mock_reset() {
    MOCK_CALL_COUNT=0
    MOCK_CALLS=()
    declare -gA MOCK_RESPONSES=()
}

# Мок-версия curl
mock_curl() {
    MOCK_CALL_COUNT=$((MOCK_CALL_COUNT + 1))
    
    # Собираем все аргументы в строку для поиска по паттерну
    local args="$*"
    MOCK_CALLS+=("$args")
    
    # Проверяем паттерны
    for pattern in "${!MOCK_RESPONSES[@]}"; do
        if echo "$args" | grep -q "$pattern"; then
            echo "${MOCK_RESPONSES[$pattern]}"
            return 0
        fi
    done
    
    # По умолчанию — пустой ответ
    echo ""
    return 0
}

# Получить количество вызовов
mock_get_call_count() {
    echo "$MOCK_CALL_COUNT"
}

# Получить все вызовы
mock_get_calls() {
    printf '%s\n' "${MOCK_CALLS[@]}"
}

# Проверить что curl был вызван с определённым паттерном
mock_was_called_with() {
    local pattern="$1"
    for call in "${MOCK_CALLS[@]}"; do
        if echo "$call" | grep -q "$pattern"; then
            return 0
        fi
    done
    return 1
}

# Экспорт для использования в других скриптах
export -f mock_curl mock_register mock_reset mock_get_call_count mock_get_calls mock_was_called_with
export MOCK_CALL_COUNT MOCK_CALLS
