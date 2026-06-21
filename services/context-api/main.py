"""
Context API v1.2.0 — сервис выдачи контекста для лаборантов.

Запуск:  uvicorn main:app --host 127.0.0.1 --port 8100
Тесты:   pytest tests/ -v
Метрики: curl http://127.0.0.1:8100/metrics
"""
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from common import cache, log_request, logger, metrics, rate_limiter
from routers.health import router as health_router
from routers.context import router as context_router
from routers.adr import router as adr_router
from routers.patterns import router as patterns_router
from routers.identity import router as identity_router
from routers.sessions import router as sessions_router
from routers.myrmex_proxy import router as myrmex_proxy_router
from routers.semantic import router as semantic_router

# ── API Key ────────────────────────────────────────
API_KEY = os.environ.get("CONTEXT_API_KEY", "lab-internal-change-me")


# ── Lifespan ───────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Context API v1.2.0 started on 127.0.0.1:8100 (auth={'enabled' if API_KEY else 'disabled'})")
    yield
    logger.info("Context API stopped")


# ── App ────────────────────────────────────────────
app = FastAPI(
    title="LabDoctorM Context API",
    version="1.2.0",
    description="Контекст для лаборантов: файлы, проекты, память, ADR, паттерны, сессии",
    lifespan=lifespan,
)

# ── Middleware ──────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:3000", "http://localhost:3000", "http://127.0.0.1:8100", "http://localhost:8100"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


@app.middleware("http")
async def track_requests(request: Request, call_next):
    """Tracks all requests: metrics, logging, timing. Catches errors."""
    start = time.time()
    status_code = 200
    try:
        response: Response = await call_next(request)
        status_code = response.status_code
    except Exception:
        status_code = 500
        raise
    finally:
        duration = (time.time() - start) * 1000
        path = request.url.path
        metrics.increment(path)
        metrics.record_time(path, duration)
        log_request(request, status_code, duration)

    response.headers["X-Response-Time-Ms"] = f"{duration:.1f}"
    response.headers["X-Request-Count"] = str(metrics.total_requests)
    response.headers["X-Cache-Hit-Rate"] = f"{cache.stats['hit_rate']:.2f}"

    return response


# ── Подключение роутеров ───────────────────────────
app.include_router(health_router)
app.include_router(context_router, prefix="/api/v1")
app.include_router(adr_router, prefix="/api/v1")
app.include_router(patterns_router, prefix="/api/v1")
app.include_router(identity_router, prefix="/api/v1")
app.include_router(sessions_router, prefix="/api/v1")
app.include_router(myrmex_proxy_router, prefix="/api/v1")
app.include_router(semantic_router, prefix="/api/v1")

# ── Metrics endpoint ───────────────────────────────
@app.get("/metrics", tags=["metrics"])
async def get_metrics():
    """Получить метрики сервиса."""
    return {
        "total_requests": metrics.total_requests,
        "endpoints": metrics.get_summary(),
        "cache": cache.stats,
        "rate_limiter": {
            "max_requests": rate_limiter._max_requests,
            "window_seconds": rate_limiter._window,
        },
    }


# ── Запуск ─────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8100, log_level="info")
