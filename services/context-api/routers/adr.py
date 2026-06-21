"""ADR эндпоинты — центральные + проектные ADR."""
import time
from pathlib import Path

from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import PlainTextResponse

from common import check_rate_limit, parse_frontmatter, read_file_cached, validate_id

LAB_ROOT = Path("/root/LabDoctorM")

# Все источники ADR: центральные + проектные
ADR_SOURCES = [
    {"dir": LAB_ROOT / "adr", "label": "central"},
    {"dir": LAB_ROOT / "projects" / "snablab" / "docs" / "architecture", "label": "snablab"},
    {"dir": LAB_ROOT / "projects" / "myrmex-control" / "docs" / "adr", "label": "myrmex-control"},
    {"dir": LAB_ROOT / "projects" / "streikbrecher" / "docs", "label": "streikbrecher"},
    {"dir": LAB_ROOT / "projects" / "lab-monitoring" / "docs" / "ADR", "label": "lab-monitoring"},
    {"dir": LAB_ROOT / "projects" / "lab-playwright-expert" / "docs" / "ADR", "label": "lab-playwright-expert"},
]


def _collect_adr_files():
    """Собрать все ADR .md файлы из всех источников."""
    files = []
    for src in ADR_SOURCES:
        d = src["dir"]
        if not d.exists():
            continue
        if src["label"] == "streikbrecher":
            pattern = "ADR_*.md"
        else:
            pattern = "*.md"
        for md_file in sorted(d.glob(pattern)):
            files.append((md_file, src["label"]))
    return files


router = APIRouter(tags=["adr"])


@router.get("/adr")
async def list_adrs(request: Request, __: bool = Depends(check_rate_limit)):
    """Список всех ADR с frontmatter (центральные + проектные)."""
    adrs = []
    for md_file, source in _collect_adr_files():
        try:
            content = read_file_cached(md_file)
            if not content:
                continue
            fm = parse_frontmatter(content)
            # title: из frontmatter → из заголовка md → из имени файла
            title = fm.get("title", "")
            if not title:
                for line in content.split("\n"):
                    if line.startswith("# "):
                        title = line[2:].strip()
                        break
            if not title:
                title = md_file.stem
            status = fm.get("status", "unknown")
            date = fm.get("date", "") or fm.get("created", "")[:10]
            adrs.append({
                "id": md_file.stem,
                "title": title,
                "status": status,
                "date": date,
                "source": source,
                "file": str(md_file.relative_to(LAB_ROOT)),
            })
        except Exception:
            continue

    return {"adrs": adrs, "total": len(adrs)}


@router.get("/adr/{adr_id}", response_class=PlainTextResponse)
async def get_adr(adr_id: str, request: Request, __: bool = Depends(check_rate_limit)):
    """Получить полный текст ADR по ID (поиск по всем источникам)."""
    adr_id = validate_id(adr_id, "adr_id")
    all_files = _collect_adr_files()
    candidates = [f for f, _ in all_files if f.stem == adr_id]
    if not candidates:
        candidates = [f for f, _ in all_files if f.stem.startswith(adr_id)]
    if not candidates:
        raise HTTPException(status_code=404, detail=f"ADR not found: {adr_id}")

    content = read_file_cached(candidates[0])
    if content is None:
        raise HTTPException(status_code=500, detail="Failed to read ADR file")

    return content
