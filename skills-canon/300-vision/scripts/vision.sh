#!/bin/bash
# 300 Vision — Cohere Vision API wrapper with counter and key rotation
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE_FILE="$SKILL_DIR/references/vision-state.json"

# ---------- helpers ----------
load_keys() {
  local cohere_dir="/root/LabDoctorM/vault/free-api-hunter/cohere"
  KEYS=()
  # Primary: per-provider key files (current lab layout after key migration)
  if [[ -d "$cohere_dir" ]]; then
    for f in "$cohere_dir/api.key" "$cohere_dir/api.key.2" "$cohere_dir/api.key.3" "$cohere_dir/api.key.4"; do
      if [[ -f "$f" ]]; then
        local k
        k=$(cat "$f" | tr -d '[:space:]')
        [[ -n "$k" ]] && KEYS+=("$k")
      fi
    done
  fi
  # Fallback: legacy combined backup (if restored)
  local backup="/root/LabDoctorM/vault/free-api-hunter/secrets-backup.json"
  if [[ ${#KEYS[@]} -eq 0 && -f "$backup" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && KEYS+=("$line")
    done < <(python3 -c "
import json
with open('$backup') as f:
    d = json.load(f)
for i in ['', '.2', '.3', '.4']:
    k = d.get(f'cohere/apiKey{i}', '')
    if k:
        print(k)
")
  fi
  if [[ ${#KEYS[@]} -eq 0 ]]; then
    echo "ERROR: No keys loaded (checked $cohere_dir/api.key* and legacy secrets-backup.json)" >&2
    exit 1
  fi
}

load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    echo '{"current_key_index":0,"remaining":300,"total_used":0,"total_success":0,"total_fail":0,"key_usage":[0,0,0,0],"key_errors":[0,0,0,0]}'
  fi
}

save_state() {
  echo "$1" > "$STATE_FILE"
}

# ---------- main ----------
do_vision() {
  local image_path="$1"
  local custom_prompt="${2:-}"
  local lang="${3:-auto}"
  load_keys
  local state
  state=$(load_state)

  local remaining
  remaining=$(echo "$state" | python3 -c "import sys,json; print(json.load(sys.stdin)['remaining'])")
  if [[ "$remaining" -le 0 ]]; then
    echo "LIMIT_EXHAUSTED"
    return 1
  fi

  if [[ ! -f "$image_path" ]]; then
    echo "ERROR: File not found: $image_path" >&2
    return 1
  fi

  local img_b64
  img_b64=$(base64 -w0 "$image_path")

  local max_retries=${#KEYS[@]}
  local key_idx
  key_idx=$(echo "$state" | python3 -c "import sys,json; print(json.load(sys.stdin)['current_key_index'])")
  local attempt=0
  local result=""

  # Build prompt
  local prompt
  if [[ -n "$custom_prompt" ]]; then
    prompt="$custom_prompt"
  else
    case "$lang" in
      ru|russian)
        prompt="Подробно опиши что на этом изображении. Если есть текст — распознай и перепиши его. Если есть диаграмма — объясни. Если есть код — прочитай. Отвечай на русском."
        ;;
      en|english)
        prompt="Describe in detail what is in this image. If there is text — recognize and transcribe it. If there is a diagram — explain it. If there is code — read it. Answer in English."
        ;;
      *)
        prompt="Describe in detail what is in this image. If there is text — recognize and transcribe it. If there is a diagram — explain it. If there is code — read it. Answer in the same language as the user's request."
        ;;
    esac
  fi

  while [[ $attempt -lt $max_retries ]]; do
    local key="${KEYS[$key_idx]}"

    # Generate request body via python (reads image file directly, no shell escaping issues)
    local body_file="/tmp/vision_body_$$.json"
    python3 << PYEOF
import json, base64, sys

image_path = "$image_path"
prompt = """$prompt"""

with open(image_path, "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode()

data = {
    "model": "command-a-plus-05-2026",
    "messages": [{
        "role": "user",
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{img_b64}"}}
        ]
    }],
    "max_tokens": 2000
}

with open("$body_file", "w") as f:
    json.dump(data, f)
PYEOF

    local http_code
    http_code=$(curl -s -o /tmp/vision_resp.json -w "%{http_code}" \
      -X POST "https://api.cohere.com/v2/chat" \
      -H "Authorization: Bearer $key" \
      -H "Content-Type: application/json" \
      -d "@$body_file")
    rm -f "$body_file"

    if [[ "$http_code" == "200" ]]; then
      result=$(python3 -c "
import json
with open('/tmp/vision_resp.json') as f:
    d = json.load(f)
for item in d.get('message', {}).get('content', []):
    if item.get('type') == 'text':
        print(item['text'])
        break
" 2>/dev/null)
      if [[ -n "$result" && "$result" != "" ]]; then
        state=$(python3 - "$state" "$key_idx" << 'PYEOF'
import json, sys
state_str, key_idx = sys.argv[1], int(sys.argv[2])
s = json.loads(state_str)
s['remaining'] = max(0, s['remaining'] - 1)
s['total_used'] += 1
s['total_success'] += 1
s['key_usage'][key_idx] += 1
print(json.dumps(s, ensure_ascii=False))
PYEOF
)
        save_state "$state"
        echo "VISION_SUCCESS"
        echo "$result"
        return 0
      fi
    fi

    # Failed — rotate to next key
    key_idx=$(( (key_idx + 1) % max_retries ))
    state=$(python3 - "$state" "$key_idx" << 'PYEOF'
import json, sys
state_str, key_idx = sys.argv[1], int(sys.argv[2])
s = json.loads(state_str)
s['current_key_index'] = key_idx
s['key_errors'][key_idx] += 1 if 'key_errors' in s else 0
print(json.dumps(s, ensure_ascii=False))
PYEOF
)
    save_state "$state"
    attempt=$((attempt + 1))
  done

  echo "ERROR: All $max_retries keys failed" >&2
  return 1
}

show_status() {
  local state
  state=$(load_state)
  python3 - "$state" << 'PYEOF'
import json, sys
s = json.loads(sys.argv[1])
print(f"Remaining: {s['remaining']}/300")
print(f"Used: {s['total_used']} (success: {s['total_success']}, fail: {s['total_fail']})")
print(f"Current key: {s['current_key_index']+1}/4")
print(f"Key usage: {s['key_usage']}")
print(f"Key errors: {s['key_errors']}")
PYEOF
}

# ---------- CLI ----------
case "${1:-}" in
  --status) show_status ;;
  --reset)
    save_state '{"current_key_index":0,"remaining":300,"total_used":0,"total_success":0,"total_fail":0,"key_usage":[0,0,0,0],"key_errors":[0,0,0,0]}'
    echo "RESET_OK"
    ;;
  "")
    echo "ERROR: Usage: vision.sh <image_path> [--lang ru|en|auto] | vision.sh --status | vision.sh --reset" >&2
    exit 1
    ;;
  *)
    do_vision "$1" "${2:-}" "${3:-auto}"
    ;;
esac
