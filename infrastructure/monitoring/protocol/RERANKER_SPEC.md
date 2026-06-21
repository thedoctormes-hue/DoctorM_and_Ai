---
description: "Reranker Endpoint Specification"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-08
status: active
---
# Reranker Endpoint Specification

## `/rerank` - FTS5 + Cohere/Fireworks reranker

### Цель
Улучшить релевантность поиска через reranker после FTS5.

### Алгоритм
```
1. FTS5 поиск → кандидаты (top-K)
2. Reranker (Cohere v3 или Fireworks) → переранжировка
3. Финальный список с confidence scores
```

### API
```
POST /rerank
{
  "query": "строка поиска",
  "documents": ["doc1", "doc2", ...],  // из FTS5
  "top_n": 5,
  "provider": "cohere" || "fireworks"
}

→ {"results": [{"index": 0, "score": 0.95}, ...]}
```

### Провайдеры
- **Cohere**: `rerank-english-v3.0`, $0.0015/1K docs
- **Fireworks**: `rerank-v3`, $0.001/1K docs

### Интеграция
- FTS5 → `/search` endpoint
- Reranker → фильтр top results
- Кеширование rerank results 1 час