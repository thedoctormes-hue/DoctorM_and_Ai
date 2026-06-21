"""Общие утилиты Context API: кеш, метрики, логирование, rate limiting."""
import json
import logging
import time
from collections import defaultdict
from functools import wraps
from pathlib import Path
from threading import Lock
from typing import Optional

from fastapi import Request, HTTPException

# ── Логирование ────────────────────────────────────
logger = logging.getLogger("context-api")
logger.setLevel(logging.INFO)

_handler = logging.StreamHandler()
_handler.setFormatter(logging.Formatter(
    "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
))
logger.addHandler(_handler)


def log_request(request: Request, status_code: int, duration_ms: float):
    """Логирование запроса."""
    logger.info(
        f"{request.method} {request.url.path} "
        f"status={status_code} "
        f"duration={duration_ms:.1f}ms "
        f"client={request.client.host if request.client else 'unknown'}"
    )


# ── Простой in-memory кеш ──────────────────────────
class TTLCache:
    """TTL кеш с максимальным размером."""

    def __init__(self, maxsize: int = 128, ttl: int = 60):
        self._cache: dict[str, tuple[float, str]] = {}
        self._maxsize = maxsize
        self._ttl = ttl
        self._lock = Lock()
        self._hits = 0
        self._misses = 0

    def get(self, key: str) -> Optional[str]:
        with self._lock:
            if key in self._cache:
                ts, value = self._cache[key]
                if time.time() - ts < self._ttl:
                    self._hits += 1
                    return value
                else:
                    del self._cache[key]
            self._misses += 1
            return None

    def set(self, key: str, value: str):
        with self._lock:
            if len(self._cache) >= self._maxsize:
                # Удаляем самый старый
                oldest = min(self._cache, key=lambda k: self._cache[k][0])
                del self._cache[oldest]
            self._cache[key] = (time.time(), value)

    def invalidate(self, key: str):
        with self._lock:
            self._cache.pop(key, None)

    def clear(self):
        with self._lock:
            self._cache.clear()

    @property
    def stats(self) -> dict:
        return {
            "size": len(self._cache),
            "maxsize": self._maxsize,
            "ttl": self._ttl,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": self._hits / max(1, self._hits + self._misses),
        }


# Глобальный кеш
cache = TTLCache(maxsize=256, ttl=120)


# ── Метрики ────────────────────────────────────────
class Metrics:
    """Простые in-memory метрики."""

    def __init__(self):
        self._counters: dict[str, int] = defaultdict(int)
        self._timers: dict[str, list[float]] = defaultdict(list)
        self._lock = Lock()

    def increment(self, endpoint: str):
        with self._lock:
            self._counters[endpoint] += 1

    def record_time(self, endpoint: str, duration_ms: float):
        with self._lock:
            self._timers[endpoint].append(duration_ms)
            # Храним последние 1000 замеров
            if len(self._timers[endpoint]) > 1000:
                self._timers[endpoint] = self._timers[endpoint][-1000:]

    def get_summary(self) -> dict:
        with self._lock:
            summary = {}
            for endpoint, count in sorted(self._counters.items(), key=lambda x: -x[1]):
                times = self._timers.get(endpoint, [])
                summary[endpoint] = {
                    "requests": count,
                    "avg_ms": sum(times) / max(1, len(times)),
                    "p95_ms": sorted(times)[int(len(times) * 0.95)] if times else 0,
                    "max_ms": max(times) if times else 0,
                }
            return summary

    @property
    def total_requests(self) -> int:
        with self._lock:
            return sum(self._counters.values())


metrics = Metrics()


# ── Rate Limiting ──────────────────────────────────
class RateLimiter:
    """Простой sliding window rate limiter."""

    def __init__(self, max_requests: int = 60, window_seconds: int = 60):
        self._max_requests = max_requests
        self._window = window_seconds
        self._requests: dict[str, list[float]] = defaultdict(list)
        self._lock = Lock()

    def is_allowed(self, client_id: str) -> bool:
        now = time.time()
        with self._lock:
            # Очищаем старые
            self._requests[client_id] = [
                t for t in self._requests[client_id]
                if now - t < self._window
            ]
            if len(self._requests[client_id]) >= self._max_requests:
                return False
            self._requests[client_id].append(now)
            return True

    def get_remaining(self, client_id: str) -> int:
        now = time.time()
        with self._lock:
            active = len([
                t for t in self._requests[client_id]
                if now - t < self._window
            ])
            return max(0, self._max_requests - active)


rate_limiter = RateLimiter(max_requests=120, window_seconds=60)


def check_rate_limit(request: Request):
    """Dependency для rate limiting. Вызывает HTTP 429 при превышении лимита."""
    client_id = request.client.host if request.client else "unknown"
    if not rate_limiter.is_allowed(client_id):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Try again later.",
            headers={"Retry-After": "60"},
        )
    return True


# ── Валидация ID ───────────────────────────────────
import re

def validate_id(value: str, param_name: str = "id") -> str:
    """Валидация ID — только буквы, цифры, дефисы и подчёркивания."""
    if not re.match(r'^[a-zA-Z0-9_.-]+$', value):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {param_name} format: only alphanumeric, dots, hyphens, underscores allowed",
        )
    return value


# ── Безопасное чтение файла с кешем ────────────────
def read_file_cached(path: Path, use_cache: bool = True) -> Optional[str]:
    """Чтение файла с кешированием.

    Returns:
        str — содержимое файла
        None — файл не существует, пустой, или ошибка чтения
    """
    key = str(path)
    if use_cache:
        cached = cache.get(key)
        if cached is not None:
            return cached
    try:
        if path.exists():
            content = path.read_text(encoding="utf-8")
            # Игнорируем пустые файлы — они бесполезны как контекст
            if not content.strip():
                logger.warning(f"Empty file: {path}")
                return None
            cache.set(key, content)
            return content
    except UnicodeDecodeError as e:
        logger.error(f"Invalid UTF-8 in {path}: {e}")
    except PermissionError as e:
        logger.error(f"Permission denied: {path}: {e}")
    except OSError as e:
        logger.error(f"OS error reading {path}: {e}")
    except Exception as e:
        logger.error(f"Failed to read {path}: {e}")
    return None


# ── Парсинг YAML frontmatter ───────────────────────
import re as _re

def parse_frontmatter(content: str) -> dict:
    """Извлечь YAML frontmatter из .md файла.

    Парсит блок между первыми двумя строками '---'.
    Поддерживает только простые пары key: value (без вложенных структур).

    Returns:
        dict — словарь {key: value} из frontmatter
    """
    if not content.startswith("---"):
        return {}

    # Находим второй разделитель '---'
    end = _re.search(r'\n---\s*\n', content)
    if end is None:
        end = _re.search(r'\n---\s*$', content)
    if end is None:
        return {}

    block = content[:end.start()]
    # Убираем первую строку '---'
    lines = block.split("\n")[1:]

    result = {}
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            key, _, value = line.partition(":")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key:
                result[key] = value
    return result


# ── HTTP клиент ────────────────────────────────────
import httpx

async def http_get(
    url: str,
    params: dict | None = None,
    timeout: float = 5.0,
    headers: dict | None = None,
) -> dict | None:
    """Асинхронный GET запрос. Возвращает dict, либо None при ошибке соединения.

    При HTTP-ошибке (4xx/5xx) пробрасывает httpx.HTTPStatusError, чтобы
    вызывающий код мог отразить реальный upstream-статус, а не маскировать его.
    """
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.get(url, params=params, headers=headers)
            resp.raise_for_status()
            return resp.json()
    except httpx.HTTPStatusError:
        # Пробрасываем — вызывающий решает, как отразить upstream-статус.
        raise
    except Exception as e:
        logger.error(f"HTTP GET {url} failed: {e}")
        return None


# ── Пагинация ──────────────────────────────────────
def paginate_text(text: str, offset: int = 0, limit: int = 500) -> dict:
    """Пагинация текста по строкам."""
    lines = text.split("\n")
    total = len(lines)
    page = lines[offset:offset + limit]
    return {
        "content": "\n".join(page),
        "total_lines": total,
        "offset": offset,
        "limit": limit,
        "has_more": offset + limit < total,
    }
