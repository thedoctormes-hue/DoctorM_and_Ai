"""Sessions эндпоинты — файлы сессий (insights_session_*.md)."""
import time
from pathlib import Path

from fastapi import APIRouter, Depends, Query, Request, HTTPException

from common import check_rate_limit, read_file_cached, validate_id

MEMORY_DIR = Path("/root/.qwen/projects/-root-LabDoctorM/memory")
# Файлы сессий лежат напрямую в memory/ (не в memory/sessions/)
SESSIONS_GLOB = "insights_session_*.md"

router = APIRouter(tags=["sessions"])


@router.get("/sessions/recent")
async def get_recent_sessions(
    request: Request,
    limit: int = Query(5, ge=1, le=20),
    __: bool = Depends(check_rate_limit),
):
    """Получить последние сессии (insights_session_*.md)."""
    sessions = []
    if not MEMORY_DIR.exists():
        return {"sessions": [], "total": 0}

    session_files = sorted(MEMORY_DIR.glob(SESSIONS_GLOB), reverse=True)

    for md_file in session_files[:limit]:
        try:
            content = read_file_cached(md_file)
            if not content:
                continue
            title = md_file.stem
            for line in content.split("\n")[:5]:
                if line.startswith("# "):
                    title = line[2:].strip()
                    break
            sessions.append({
                "id": md_file.stem,
                "title": title,
                "file": str(md_file.relative_to(MEMORY_DIR)),
                "size": len(content),
            })
        except Exception:
            continue

    return {"sessions": sessions, "total": len(session_files)}


@router.get("/sessions/{session_id}")
async def get_session(session_id: str, request: Request, __: bool = Depends(check_rate_limit)):
    """Получить содержимое сессии по ID."""
    session_id = validate_id(session_id, "session_id")
    if not MEMORY_DIR.exists():
        raise HTTPException(status_code=404, detail="Memory directory not found")

    # Точное совпадение
    candidates = list(MEMORY_DIR.glob(f"{session_id}.md"))
    # Префиксное совпадение среди session-файлов
    if not candidates:
        candidates = [f for f in MEMORY_DIR.glob(SESSIONS_GLOB) if f.stem.startswith(session_id)]
    if not candidates:
        raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")

    content = read_file_cached(candidates[0])
    if content is None:
        raise HTTPException(status_code=500, detail="Failed to read session file")

    return content
