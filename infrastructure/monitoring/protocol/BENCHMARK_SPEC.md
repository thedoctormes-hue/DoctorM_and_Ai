---
description: "Benchmark Endpoint Specification"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-08
status: active
---
# Benchmark Endpoint Specification

## `/benchmark` - Сравнение моделей

### Цель
Сравнение LLM моделей по:
- **Tokens/s** - скорость токенов в секунду
- **Latency** - время отклика (сек)
- **Quality** - качество ответа (1-10)
- **Cost** - стоимость за 1K токенов ($)

### Метрики
| Модель | Tokens/s | Latency | Quality | Cost |
|--------|----------|---------|---------|------|
| openai/gpt-4o | 85 | 0.45s | 9.2 | $0.0085 |
| google/gemini-pro | 120 | 0.32s | 8.8 | $0.0068 |
| anthropic/claude-3-opus | 75 | 0.52s | 9.5 | $0.0125 |
| meta-llama/llama-3-70b | 210 | 0.18s | 8.5 | $0.0008 |

### API
```
GET /benchmark?task=summarization&tokens=1000
POST /benchmark/test {prompt, models: []}
```

### Рекомендации
- **Экономия**: llama-3-70b для простых задач
- **Качество**: claude-3-opus для сложных
- **Баланс**: gemini-pro для среднего