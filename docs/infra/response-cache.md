---
name: response-cache
description: "Кеширование ответов OpenRouter для экономии токенов: TTL, поддержка Redis или in-memory. Use when: нужна экономия токенов при повторяющихся запросах, настройка response-кеша для LLM. NOT for: кеширование статических файлов, проксирование запросов, офлайн-режим."
owner: "LabDoctorM"
last-reviewed: "2026-05-25"
version: 1.0.0
category: development
location: user
---

# response-cache


Кеширование OpenRouter ответов для экономии $2.5/M токенов. TTL настраиваемый, поддержка Redis/оперативка.

## Triggers

- "кешируй openrouter ответы"
- "экономь токены"
- "response cache"
- "openrouter cache"

## Steps

1. Установить зависимости:
   ```bash
   pip install redis pyjwt
   ```

2. Создать `cache/openrouter_cache.py`:
   ```python
   import hashlib
   import json
   from datetime import datetime, timedelta
   import redis

   class ResponseCache:
       def __init__(self, ttl=3600, backend='memory'):
           self.ttl = ttl
           self.backend = backend
           if backend == 'redis':
               self.store = redis.Redis()

       def get_key(self, messages, model):
           data = json.dumps({'messages': messages, 'model': model}, sort_keys=True)
           return hashlib.sha256(data.encode()).hexdigest()

       def get(self, messages, model):
           key = self.get_key(messages, model)
           cached = self.store.get(key) if self.backend == 'redis' else None
           # fallback to memory
           if not cached and hasattr(self, '_memory'):
               cached = self._memory.get(key)
           return json.loads(cached) if cached else None

       def set(self, messages, model, response):
           key = self.get_key(messages, model)
           value = json.dumps({'data': response, 'timestamp': datetime.now().isoformat()})
           if self.backend == 'redis':
               self.store.setex(key, self.ttl, value)
           else:
               if not hasattr(self, '_memory'):
                   self._memory = {}
               self._memory[key] = value
   ```

3. Обернуть вызов OpenRouter:
   ```python
   cache = ResponseCache(ttl=3600, backend='redis')

   def cached_chat(messages, model='openrouter/auto'):
       cached = cache.get(messages, model)
       if cached and not is_expired(cached['timestamp']):
           return cached['data']
       response = openrouter.chat(messages, model)
       cache.set(messages, model, response)
       return response
   ```

4. Настроить Redis:
   ```yaml
   # docker-compose.yml
   redis:
     image: redis:7-alpine
     ports: ["6379:6379"]
   ```

5. Добавить метрики:
   ```python
   metrics = {'hits': 0, 'misses': 0, 'tokens_saved': 0}
   ```

## Tools

- `redis.Redis()` — хранилище
- `hashlib.sha256()` — ключ кеша
- `datetime.timedelta` — TTL


## 🔮 Маркировка инсайтов

При обнаружении инсайта в процессе работы, в конце вывода добавляй маркер:

```
[INSIGHT: <тип>] <краткое описание>
[layer: <rules|memory|skills|backlog|agents>]
[source: <откуда инсайт>]
```

## Why

Экономит $2500 на 1B токенов. Критично при работе с дорогими моделями (Claude-3.5-Sonnet, GPT-4).
