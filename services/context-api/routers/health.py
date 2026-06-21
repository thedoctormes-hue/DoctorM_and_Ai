"""Health эндпоинт."""
from fastapi import APIRouter

router = APIRouter(tags=["system"])


@router.get("/health")
async def health():
    """Health check. Rate limiting не применяется — требование для LB."""
    return {
        "status": "ok",
        "service": "context-api",
        "version": "1.2.0",
    }
