#!/bin/bash
# Тест: конфигурация heartbeat для всех агентов
# Запуск: bash tests/test_heartbeat_config.sh

set -e

CONFIG="/root/.openclaw/openclaw.json"
PASS=0
FAIL=0

assert() {
    local desc="$1"
    local condition="$2"
    if eval "$condition"; then
        echo "✅ PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Тесты heartbeat конфигурации ==="
echo ""

# 1. JSON валиден
assert "openclaw.json валиден" "python3 -c \"import json; json.load(open('$CONFIG'))\" 2>/dev/null"

# 2. Каждый агент имеет heartbeat (кроме main)
assert "bestia имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='bestia'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "mangust имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='mangust'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "dominika имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='dominika'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "raven имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='raven'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "antcat имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='antcat'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "streikbrecher имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='streikbrecher'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "kotolizator имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='kotolizator'][0]; assert 'heartbeat' in a\" 2>/dev/null"
assert "owl имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='owl'][0]; assert 'heartbeat' in a\" 2>/dev/null"

# 3. main НЕ имеет heartbeat
assert "main НЕ имеет heartbeat" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='main'][0]; assert 'heartbeat' not in a\" 2>/dev/null"

# 4. Интервалы корректны
assert "bestia: 30m" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='bestia'][0]; assert a['heartbeat']['every']=='30m'\" 2>/dev/null"
assert "mangust: 60m" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='mangust'][0]; assert a['heartbeat']['every']=='60m'\" 2>/dev/null"
assert "antcat: 120m" "python3 -c \"import json; d=json.load(open('$CONFIG')); a=[x for x in d['agents']['list'] if x['id']=='antcat'][0]; assert a['heartbeat']['every']=='120m'\" 2>/dev/null"

# 5. target = telegram для всех
assert "Все heartbeat имеют target=telegram" "python3 -c \"
import json
d=json.load(open('$CONFIG'))
for a in d['agents']['list']:
    if a['id'] == 'main':
        continue
    hb = a.get('heartbeat', {})
    assert hb.get('target') == 'telegram', f'{a[\"id\"]}: target={hb.get(\"target\")}'
\" 2>/dev/null"

# 6. directPolicy = allow для всех
assert "Все heartbeat имеют directPolicy=allow" "python3 -c \"
import json
d=json.load(open('$CONFIG'))
for a in d['agents']['list']:
    if a['id'] == 'main':
        continue
    hb = a.get('heartbeat', {})
    assert hb.get('directPolicy') == 'allow', f'{a[\"id\"]}: directPolicy={hb.get(\"directPolicy\")}'
\" 2>/dev/null"

# 7. HEARTBEAT.md существуют и не пустые
for agent in bestia mangust dominika kotolizator owl raven antcat streikbrecher; do
    f="/root/LabDoctorM/workspaces/$agent/HEARTBEAT.md"
    assert "$agent: HEARTBEAT.md существует" "[ -f '$f' ]"
    assert "$agent: HEARTBEAT.md не пустой" "[ \$(wc -c < '$f') -gt 100 ]"
done

# 8. Gateway запущен
assert "Gateway процесс запущен" "pgrep -x openclaw > /dev/null"
assert "Gateway порт 18789 слушает" "ss -tlnp | grep -q 18789"

echo ""
echo "=== Итого: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
