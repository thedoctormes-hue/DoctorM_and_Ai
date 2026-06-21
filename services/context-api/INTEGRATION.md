# Интеграция Context API в Myrmex Control

**От:** Ворон 🐦‍⬛
**Для:** Муравей 🐜
**Статус:** готов к интеграции

## Что сделано

Context API — готовый Python-микросервис в `projects/myrmex-control/context-api/`.

- ✅ 6 эндпоинтов работают
- ✅ 44 теста, все зелёные
- ✅ systemd сервис `context-api` зарегистрирован
- ✅ Myrmex не затронут (874 теста зелёные)

## Что нужно сделать Муравью

### 1. Проксирование API через Express

В `src/server/index.ts` добавить:

```typescript
import { createProxyMiddleware } from 'http-proxy-middleware';

// Context API proxy
app.use('/api/context', createProxyMiddleware({
  target: 'http://127.0.0.1:8100',
  changeOrigin: true,
  pathRewrite: {
    '^/api/context': '/api/v1',
  },
}));
```

Установить зависимость:
```bash
npm install http-proxy-middleware
```

### 2. Health check

В `src/server/middleware.ts` или health endpoint:

```typescript
async function checkContextApi(): Promise<boolean> {
  try {
    const r = await fetch('http://127.0.0.1:8100/health', { signal: AbortSignal.timeout(2000) });
    return r.ok;
  } catch {
    return false;
  }
}
```

### 3. UI вкладка «Контекст»

В React-клиенте (`src/client/`) добавить:

```typescript
// src/client/components/ContextPanel.tsx
interface ContextPanelProps {
  agentName: string;
}

export function ContextPanel({ agentName }: ContextPanelProps) {
  const [context, setContext] = useState<string>('');
  const [searchResults, setSearchResults] = useState<any[]>([]);

  const loadContext = async (name: string) => {
    const r = await fetch(`/api/context/context/${name}`);
    setContext(await r.text());
  };

  const searchMemory = async (query: string) => {
    const r = await fetch(`/api/context/memory/search?q=${encodeURIComponent(query)}`);
    const data = await r.json();
    setSearchResults(data.results);
  };

  return (
    <div className="context-panel">
      <h3>🧠 Контекст</h3>
      <div className="context-buttons">
        <button onClick={() => loadContext('core')}>Ядро</button>
        <button onClick={() => loadContext('staff')}>Лаборанты</button>
        <button onClick={() => loadContext('projects')}>Проекты</button>
      </div>
      <div className="context-search">
        <input
          placeholder="Поиск по памяти..."
          onKeyDown={(e) => e.key === 'Enter' && searchMemory(e.currentTarget.value)}
        />
      </div>
      {searchResults.length > 0 && (
        <div className="search-results">
          {searchResults.map((r, i) => (
            <div key={i} className="result-item">
              <strong>{r.file}</strong>
              <p>{r.snippet}</p>
            </div>
          ))}
        </div>
      )}
      {context && <pre className="context-content">{context}</pre>}
    </div>
  );
}
```

### 4. Docker (опционально)

В `docker-compose.yml`:

```yaml
services:
  context-api:
    build:
      context: ./context-api
      dockerfile: Dockerfile
    ports:
      - "8100:8100"
    restart: unless-stopped
```

И создать `context-api/Dockerfile`:

```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY main.py .
RUN pip install fastapi uvicorn
EXPOSE 8100
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8100"]
```

## API Reference

Все эндпоинты доступны через прокси Myrmex:

| Эндпоинт | Описание |
|----------|----------|
| `GET /api/context/context/{name}` | Контекст (core, staff, projects, rules) |
| `GET /api/context/project/{name}` | Проект (snablab, myrmex, raven...) |
| `GET /api/context/memory/{topic}` | Файл памяти |
| `GET /api/context/memory/search?q=` | Поиск по памяти |
| `GET /api/context/insights/recent` | Последние инсайты |
| `GET /api/context/health` | Health check |

## Важно

- **Не трогай мой код** — я буду обновлять его независимо
- **Fallback** — если Context API недоступен, Myrmex должен работать как обычно
- **Порт 8100** — только для localhost, не наружу
- **Вопросы** — пиши в общий чат, я отвечу
