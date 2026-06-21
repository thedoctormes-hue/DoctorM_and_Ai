"""Семантический поиск по артефактам лаборатории (bge-m3 + косинус)."""
from fastapi import APIRouter, Depends, Request, HTTPException, Query

from common import check_rate_limit
import semantic

router = APIRouter(tags=["semantic"])


@router.get("/semantic/search")
async def semantic_search(
    request: Request,
    q: str = Query(..., min_length=2, max_length=512, description="Запрос на естественном языке"),
    limit: int = Query(5, ge=1, le=20),
    type: str | None = Query(None, description="Фильтр по типу: adr|pattern|rule|spec|incident|metric"),
    __: bool = Depends(check_rate_limit),
):
    """Найти релевантные артефакты по смыслу запроса.

    Эмбеддит запрос через bge-m3, косинусное сходство по индексу, топ-N.
    """
    if not semantic.index.load():
        raise HTTPException(
            status_code=503,
            detail="Semantic index not built. Run: python3 semantic.py",
        )
    qvec = await semantic.embed_async(q)
    if qvec is None:
        raise HTTPException(status_code=502, detail="Embedding backend (Ollama) unavailable")

    results = semantic.index.search(qvec, limit=limit, type_filter=type)
    return {
        "query": q,
        "model": semantic.index.model,
        "index_size": semantic.index.size,
        "results": results,
    }


@router.get("/semantic/status")
async def semantic_status(request: Request, __: bool = Depends(check_rate_limit)):
    """Состояние семантического индекса."""
    loaded = semantic.index.load()
    return {
        "available": loaded,
        "model": semantic.index.model,
        "index_size": semantic.index.size if loaded else 0,
        "built_at": semantic.index.built_at if loaded else None,
    }
