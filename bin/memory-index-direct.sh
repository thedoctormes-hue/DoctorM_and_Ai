#!/bin/bash
# memory-index-direct.sh v2 — прямая индексация через ONNX embedder
# Использование: ./memory-index-direct.sh <agent_id>

set -euo pipefail

AGENT="${1:?Usage: memory-index-direct.sh <agent_id>}"
DB="$HOME/.openclaw/agents/$AGENT/agent/openclaw-agent.sqlite"
EMBED_URL="http://127.0.0.1:8082/v1/embeddings"
EMBED_MODEL="qwen3-embedding-0.6b"
CHUNK_TOKENS=400
CHUNK_OVERLAP=80
VECTOR_DIMS=1024
BATCH_SIZE=16

echo "=== Memory Index Direct v2: $AGENT ==="
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) — Начало"

if [ ! -f "$DB" ]; then echo "База не найдена: $DB"; exit 1; fi

# Проверяем embedder
TEST_RESP=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 \
  "$EMBED_URL" -H "Content-Type: application/json" \
  -H "Authorization: Bearer ***" \
  -d '{"input":"test"}' 2>/dev/null)
if [ "$TEST_RESP" != "200" ]; then
  echo "Embedder недоступен (HTTP $TEST_RESP)"; exit 1
fi
echo "Проверки OK"

# Очистка
echo "=== Очистка ==="
for tbl in memory_index_chunks memory_index_sources memory_embedding_cache \
          memory_index_chunks_fts memory_index_chunks_vec_chunks \
          memory_index_chunks_vec_info memory_index_chunks_vec_rowids \
          memory_index_chunks_vec_vector_chunks00; do
  sqlite3 "$DB" "DELETE FROM $tbl;" 2>/dev/null || true
done
echo "Очищено"

# Meta
echo "=== Meta ==="
python3 -c "
import json, sqlite3
conn = sqlite3.connect('$DB')
c = conn.cursor()
meta = {
    'model': '$EMBED_MODEL',
    'provider': 'openai-compatible',
    'providerKey': 'local',
    'sources': ['memory'],
    'scopeHash': 'direct-v2-2026-06-23',
    'chunkTokens': $CHUNK_TOKENS,
    'chunkOverlap': $CHUNK_OVERLAP,
    'ftsTokenizer': 'unicode61',
    'vectorDims': $VECTOR_DIMS
}
c.execute(\"INSERT OR REPLACE INTO memory_index_meta (key, value) VALUES ('memory_index_meta_v1', ?)\", (json.dumps(meta),))
conn.commit()
conn.close()
print('Meta OK')
"

# Сбор файлов
echo "=== Файлы ==="
WORKSPACE="/root/LabDoctorM/workspaces/$AGENT"
FILES=$(find "$WORKSPACE/memory" -name "*.md" -type f 2>/dev/null | sort)
FILE_COUNT=$(echo "$FILES" | grep -c "." 2>/dev/null || echo "0")
echo "Найдено: $FILE_COUNT файлов в $WORKSPACE/memory"

if [ "$FILE_COUNT" -eq 0 ]; then echo "Нет файлов"; exit 1; fi

# Индексация
echo "=== Индексация ==="

# Передаём параметры через переменные окружения
export IDX_DB="$DB"
export IDX_EMBED_URL="$EMBED_URL"
export IDX_EMBED_MODEL="$EMBED_MODEL"
export IDX_CHUNK_TOKENS="$CHUNK_TOKENS"
export IDX_CHUNK_OVERLAP="$CHUNK_OVERLAP"
export IDX_BATCH_SIZE="$BATCH_SIZE"

echo "$FILES" | python3 -c '
import sys, os, json, time, struct, sqlite3
import urllib.request, urllib.error

DB = os.environ["IDX_DB"]
EMBED_URL = os.environ["IDX_EMBED_URL"]
EMBED_MODEL = os.environ["IDX_EMBED_MODEL"]
CHUNK_TOKENS = int(os.environ["IDX_CHUNK_TOKENS"])
CHUNK_OVERLAP = int(os.environ["IDX_CHUNK_OVERLAP"])
BATCH_SIZE = int(os.environ["IDX_BATCH_SIZE"])
EMBED_KEY = "***"

files = [f.strip() for f in sys.stdin if f.strip()]
print(f"Файлов: {len(files)}")

conn = sqlite3.connect(DB)
c = conn.cursor()

def get_embeddings_batch(texts):
    payload = json.dumps({"input": texts, "model": EMBED_MODEL}).encode()
    req = urllib.request.Request(
        EMBED_URL, data=payload,
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {EMBED_KEY}"},
        method="POST"
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read())
                results = data.get("data", [])
                return [r.get("embedding", []) for r in results]
        except Exception as e:
            if attempt < 2:
                print(f"  retry {attempt+1}: {e}")
                time.sleep(2)
            else:
                raise

chunk_id_counter = 0
chunk_count = 0
source_count = 0
error_count = 0

for file_path in files:
    rel_path = os.path.relpath(file_path, "/root/LabDoctorM")
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            text = f.read()
    except:
        continue
    if not text.strip():
        continue

    words = text.split()
    chunks = []
    i = 0
    while i < len(words):
        ct = " ".join(words[i:i + CHUNK_TOKENS])
        if ct.strip():
            chunks.append(ct)
        i += (CHUNK_TOKENS - CHUNK_OVERLAP)

    if not chunks:
        continue

    try:
        c.execute("INSERT OR IGNORE INTO memory_index_sources (path, mtime) VALUES (?, ?)",
                  (rel_path, int(os.path.getmtime(file_path))))
        source_count += 1
    except:
        pass

    for batch_start in range(0, len(chunks), BATCH_SIZE):
        batch = chunks[batch_start:batch_start + BATCH_SIZE]
        try:
            embeddings = get_embeddings_batch(batch)
        except Exception as e:
            print(f"  FAIL {rel_path}: {e}")
            error_count += len(batch)
            continue

        for idx, embedding in enumerate(embeddings):
            if idx >= len(batch) or not embedding:
                continue
            chunk_id_counter += 1
            chunk_text = batch[idx]

            try:
                c.execute(
                    "INSERT INTO memory_index_chunks (id, source_path, chunk_index, content, chunk_hash) VALUES (?, ?, ?, ?, ?)",
                    (chunk_id_counter, rel_path, batch_start + idx, chunk_text, str(chunk_id_counter))
                )
            except:
                continue

            try:
                vec_blob = struct.pack(f"{len(embedding)}f", *embedding)
                validity = b"\xff" * ((len(embedding) + 7) // 8)
                rowid_data = struct.pack("q", chunk_id_counter)
                c.execute(
                    "INSERT INTO memory_index_chunks_vec_chunks (chunk_id, size, validity, rowids) VALUES (?, ?, ?, ?)",
                    (chunk_id_counter, len(embedding), validity, rowid_data)
                )
            except:
                pass

            chunk_count += 1

        if chunk_count % 50 == 0 and chunk_count > 0:
            print(f"  {chunk_count} чанков...")

    conn.commit()

conn.close()

print(f"\nИндексация завершена")
print(f"  Источников: {source_count}")
print(f"  Чанков: {chunk_count}")
print(f"  Ошибок: {error_count}")
'

# Проверка
echo ""
echo "=== Проверка ==="
CHUNKS=$(sqlite3 "$DB" "SELECT count(*) FROM memory_index_chunks;" 2>/dev/null)
SOURCES=$(sqlite3 "$DB" "SELECT count(*) FROM memory_index_sources;" 2>/dev/null)
VEC=$(sqlite3 "$DB" "SELECT count(*) FROM memory_index_chunks_vec_chunks;" 2>/dev/null)
echo "  Чанков: $CHUNKS"
echo "  Источников: $SOURCES"
echo "  Векторов: $VEC"

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) — Завершено"
echo "=== Готово ==="
