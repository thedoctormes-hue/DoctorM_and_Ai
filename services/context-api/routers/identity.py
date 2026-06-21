"""Identity эндпоинты — файлы идентичности лаборантов.

Алиасы агентов загружаются динамически из myrmex.json (единственный источник истины).
compact=true → SOUL-compact.md (экономия ~40% токенов на душе).
"""
import json
from pathlib import Path

from fastapi import APIRouter, Depends, Query, Request, HTTPException

from common import check_rate_limit, read_file_cached

LAB_ROOT = Path("/root/LabDoctorM")
IDENTITIES_DIR = LAB_ROOT / "projects"
MYRMEX_JSON = LAB_ROOT / "projects/myrmex-control/server-dist/myrmex.json"

_alias_cache: dict = {"mtime": 0, "map": {}}


def _load_agent_aliases() -> dict:
    """Загрузить алиасы из myrmex.json. Возвращает {alias: dir_name}."""
    try:
        mtime = MYRMEX_JSON.stat().st_mtime
        if mtime == _alias_cache["mtime"] and _alias_cache["map"]:
            return _alias_cache["map"]

        data = json.loads(MYRMEX_JSON.read_text(encoding="utf-8"))
        alias_map: dict = {}
        for agent in data.get("agents", []):
            agent_id = agent["id"]
            agent_dir = agent.get("dir", agent_id)
            alias_map[agent_id] = agent_dir
            for alias in agent.get("aliases", []):
                alias_map[alias] = agent_dir

        _alias_cache["mtime"] = mtime
        _alias_cache["map"] = alias_map
        return alias_map
    except Exception:
        return _alias_cache.get("map", {})


router = APIRouter(tags=["identity"])


@router.get("/identity/{agent}")
async def get_identity(
    agent: str,
    request: Request,
    compact: bool = Query(True, description="compact=true → SOUL-compact.md, compact=false → SOUL.md + доп. файлы"),
    __: bool = Depends(check_rate_limit),
):
    """Получить файлы идентичности лаборанта.

    compact=true (по умолчанию): IDENTITY.md + SOUL-compact.md — быстрый старт, меньше токенов.
    compact=false: IDENTITY.md + SOUL.md + SOUL-deep.md + CHECKPOINT.md + SESSION_HANDOFF.md.
    """
    alias_map = _load_agent_aliases()
    dir_name = alias_map.get(agent)
    if dir_name is None:
        raise HTTPException(status_code=404, detail=f"Unknown agent alias: {agent}")

    agent_dir = IDENTITIES_DIR / dir_name
    if not agent_dir.exists():
        raise HTTPException(status_code=404, detail=f"Agent directory not found: {dir_name}")

    identity_files = {}

    if compact:
        # Быстрый старт: IDENTITY.md + SOUL-compact.md
        for fname in ["IDENTITY.md", "SOUL-compact.md"]:
            content = read_file_cached(agent_dir / fname)
            if content:
                identity_files[fname] = content
    else:
        # Полная загрузка: все файлы идентичности
        for fname in ["IDENTITY.md", "SOUL.md", "SOUL-deep.md", "CHECKPOINT.md", "SESSION_HANDOFF.md"]:
            content = read_file_cached(agent_dir / fname)
            if content:
                identity_files[fname] = content

    if not identity_files:
        raise HTTPException(status_code=404, detail=f"No identity files for: {agent}")

    return {
        "agent": dir_name,
        "files": list(identity_files.keys()),
        "content": identity_files,
        "compact": compact,
    }
