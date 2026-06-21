"""Patterns эндпоинты — центральные паттерны."""
import time
from pathlib import Path

from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import PlainTextResponse

from common import check_rate_limit, parse_frontmatter, read_file_cached, validate_id

LAB_ROOT = Path("/root/LabDoctorM")
PATTERNS_DIR = LAB_ROOT / "patterns"

router = APIRouter(tags=["patterns"])


@router.get("/patterns")
async def list_patterns(request: Request, __: bool = Depends(check_rate_limit)):
    """Список всех паттернов с frontmatter."""
    patterns = []
    if not PATTERNS_DIR.exists():
        return {"patterns": [], "total": 0}

    for md_file in sorted(PATTERNS_DIR.glob("*.md")):
        try:
            content = read_file_cached(md_file)
            if not content:
                continue
            fm = parse_frontmatter(content)
            title = fm.get("title", "")
            if not title:
                for line in content.split("\n"):
                    if line.startswith("# "):
                        title = line[2:].strip()
                        break
            if not title:
                title = md_file.stem
            status = fm.get("status", "")
            patterns.append({
                "id": md_file.stem,
                "title": title,
                "status": status,
                "file": str(md_file.relative_to(LAB_ROOT)),
            })
        except Exception:
            continue

    return {"patterns": patterns, "total": len(patterns)}


@router.get("/patterns/{pattern_id}", response_class=PlainTextResponse)
async def get_pattern(pattern_id: str, request: Request, __: bool = Depends(check_rate_limit)):
    """Получить полный текст паттерна по ID."""
    pattern_id = validate_id(pattern_id, "pattern_id")
    if not PATTERNS_DIR.exists():
        raise HTTPException(status_code=404, detail="Patterns directory not found")

    candidates = list(PATTERNS_DIR.glob(f"{pattern_id}.md"))
    if not candidates:
        candidates = [f for f in PATTERNS_DIR.glob("*.md") if f.stem.startswith(pattern_id)]
    if not candidates:
        raise HTTPException(status_code=404, detail=f"Pattern not found: {pattern_id}")

    content = read_file_cached(candidates[0])
    if content is None:
        raise HTTPException(status_code=500, detail="Failed to read pattern file")

    return content
