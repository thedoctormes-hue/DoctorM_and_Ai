"""Myrmex Proxy — проксирование запросов к Myrmex Control API.

Вместо чтения из файловой системы, Context API проксирует запросы к Myrmex,
который является единым источником структурированных данных.

Myrmex должен быть доступен на http://127.0.0.1:3000
"""
import os
import httpx
from fastapi import APIRouter, Depends, Request, HTTPException
from common import check_rate_limit, http_get, logger

MYRMEX_URL = os.environ.get("MYRMEX_URL", "http://127.0.0.1:3000")
# Ключ для меж-сервисной авторизации в Myrmex (X-API-Key). Должен совпадать с MYRMEX_API_KEY в Myrmex .env.
MYRMEX_API_KEY = os.environ.get("MYRMEX_API_KEY", "")

router = APIRouter(tags=["myrmex-proxy"])


def _myrmex_headers() -> dict | None:
    """Заголовки для запроса к Myrmex (X-API-Key, если ключ задан)."""
    if MYRMEX_API_KEY:
        return {"X-API-Key": MYRMEX_API_KEY}
    return None


async def _proxy_to_myrmex(path: str, params: dict | None = None) -> dict:
    """Проксировать GET запрос к Myrmex."""
    url = f"{MYRMEX_URL}{path}"
    try:
        result = await http_get(url, params=params, headers=_myrmex_headers())
        if result is None:
            raise HTTPException(status_code=503, detail="Myrmex unavailable")
        return result
    except HTTPException:
        raise
    except httpx.HTTPStatusError as e:
        # Пробрасываем реальный upstream-статус вместо маскирующего 503.
        status = e.response.status_code
        if status == 401:
            detail = "Myrmex auth failed (X-API-Key invalid or missing)"
        elif status == 404:
            detail = "Not found in Myrmex"
        else:
            detail = f"Myrmex upstream error (HTTP {status})"
        logger.error(f"Myrmex proxy upstream {status} for {url}: {detail}")
        raise HTTPException(status_code=status, detail=detail)
    except Exception as e:
        logger.error(f"Myrmex proxy error: {e}")
        raise HTTPException(status_code=502, detail=f"Myrmex proxy error: {e}")


@router.get("/context-index")
async def get_context_index(request: Request, __: bool = Depends(check_rate_limit)):
    """Полный context_index из Myrmex (прокси)."""
    return await _proxy_to_myrmex("/api/v1/context-index")


@router.get("/context-index/adr")
async def get_adr_index(request: Request, __: bool = Depends(check_rate_limit)):
    """ADR индекс из Myrmex (прокси)."""
    params = {}
    if request.query_params.get("project"):
        params["project"] = request.query_params["project"]
    if request.query_params.get("status"):
        params["status"] = request.query_params["status"]
    return await _proxy_to_myrmex("/api/v1/context-index/adr", params)


@router.get("/context-index/specs")
async def get_specs_index(request: Request, __: bool = Depends(check_rate_limit)):
    """Specs индекс из Myrmex (прокси)."""
    params = {}
    if request.query_params.get("project"):
        params["project"] = request.query_params["project"]
    if request.query_params.get("status"):
        params["status"] = request.query_params["status"]
    return await _proxy_to_myrmex("/api/v1/context-index/specs", params)


@router.get("/context-index/patterns")
async def get_patterns_index(request: Request, __: bool = Depends(check_rate_limit)):
    """Patterns индекс из Myrmex (прокси)."""
    return await _proxy_to_myrmex("/api/v1/context-index/patterns")


@router.get("/context-index/sessions")
async def get_sessions_index(request: Request, __: bool = Depends(check_rate_limit)):
    """Sessions индекс из Myrmex (прокси)."""
    return await _proxy_to_myrmex("/api/v1/context-index/sessions")


@router.get("/context-index/memory")
async def get_memory_index(request: Request, __: bool = Depends(check_rate_limit)):
    """Memory индекс из Myrmex (прокси)."""
    return await _proxy_to_myrmex("/api/v1/context-index/memory")


@router.get("/agents/{agent_id}/context-profile")
async def get_agent_context_profile(
    agent_id: str,
    request: Request,
    __: bool = Depends(check_rate_limit),
):
    """Профиль контекста агента из Myrmex (прокси)."""
    return await _proxy_to_myrmex(f"/api/v1/agents/{agent_id}/context-profile")
