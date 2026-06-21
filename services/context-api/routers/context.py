"""Контекстные эндпоинты: базовые файлы, проекты, память, инсайты."""
import json
import time
from pathlib import Path

from fastapi import APIRouter, Depends, Query, Request, HTTPException

from common import cache, check_rate_limit, paginate_text, parse_frontmatter, read_file_cached

router = APIRouter(tags=["context"])

LAB_ROOT = Path("/root/LabDoctorM")
QWEN_DIR = LAB_ROOT
MEMORY_DIR = Path("/root/.qwen/projects/-root-LabDoctorM/memory")
INSIGHTS_GRAPH = MEMORY_DIR / "insights_graph.json"

# Контекстные файлы: базовые (всегда) + операционные (по необходимости)
CONTEXT_FILES = {
    # Базовые — загружаются всегда
    "core": QWEN_DIR / "QWEN-core.md",
    "staff": QWEN_DIR / "QWEN-staff.md",
    "projects": QWEN_DIR / "QWEN-projects.md",
    # Правила: base (всегда) + operational (по необходимости)
    "rules": Path("/root/.qwen/rules.md"),
    "rules-base": LAB_ROOT / "docs/rules-base.md",
    "rules-operational": LAB_ROOT / "docs/rules-operational.md",
}

# Проекты: секции из QWEN-projects.md
# Ключ → ключевое слово для поиска секции (## Ключ ... )
# Единственный источник правды: QWEN-projects.md. Только реальные секции.
PROJECT_SECTIONS = {
    "snablab": "СнабЛаб",
    "myrmex": "Myrmex Control",
    "hype": "Hype Pilot",
    "autoexpert": "AutoExpert",
    "cheque": "Cheque Bot",
    "stenographer": "Stenographer",
    "mail-daemon": "Mail Daemon",
    "zprr": "ZPRR Tracker",
    "monitoring": "Lab Monitoring",
    "artifact": "Artifact Pulse",
    "consilium": "Consilium",
    "vpn": "VPN Daemon",
    "vault": "Lab Vault",
    "gastro": "MSK Gastro Digest Bot",
    "remote": "Remote Access",
    "snablab-bot": "Snablab Bot",
    "snzk": "SNZK",
}


@router.get("/context/{name}")
async def get_context(
    name: str,
    request: Request,
    offset: int = Query(0, ge=0, description="Line offset for pagination"),
    limit: int = Query(500, ge=1, le=2000, description="Max lines to return"),
    __: bool = Depends(check_rate_limit),
):
    """Получить контекст по имени.

    Базовые: core, staff, projects, rules-base.
    По необходимости: rules-operational.
    """
    if name not in CONTEXT_FILES:
        raise HTTPException(status_code=404, detail=f"Unknown context: {name}. Available: {list(CONTEXT_FILES.keys())}")

    content = read_file_cached(CONTEXT_FILES[name])
    if content is None:
        raise HTTPException(status_code=404, detail=f"File not found: {name}")

    result = paginate_text(content, offset, limit)
    result["context"] = name

    return result


@router.get("/project/{name}")
async def get_project(
    name: str,
    request: Request,
    __: bool = Depends(check_rate_limit),
):
    """Получить информацию о проекте — секция из QWEN-projects.md."""
    if name not in PROJECT_SECTIONS:
        raise HTTPException(status_code=404, detail=f"Unknown project: {name}. Available: {list(PROJECT_SECTIONS.keys())}")

    section_keyword = PROJECT_SECTIONS[name]
    projects_file = QWEN_DIR / "QWEN-projects.md"
    content = read_file_cached(projects_file)
    if content is None:
        raise HTTPException(status_code=404, detail="Projects file not found")

    # Парсим секцию: ищем ## Ключ ... (начинается с ключевого слова)
    lines = content.split("\n")
    in_section = False
    section_lines = []
    for line in lines:
        if line.startswith("## "):
            header_text = line[3:].strip().lower()
            # Точное совпадение: начинается с ключевого слова
            if header_text.startswith(section_keyword.lower()):
                in_section = True
                section_lines.append(line)
                continue
            elif in_section:
                break
        elif in_section:
            section_lines.append(line)

    result_text = "\n".join(section_lines) if section_lines else ""
    if not result_text:
        raise HTTPException(status_code=404, detail=f"Section not found for: {name}")

    return {
        "name": name,
        "section": section_lines[0] if section_lines else None,
        "content": result_text,
    }


@router.get("/memory/search")
async def search_memory(
    request: Request,
    q: str = Query(..., min_length=2, max_length=200, description="Search query"),
    __: bool = Depends(check_rate_limit),
):
    """Поиск по файлам памяти."""
    cache_key = f"search:{q}"
    cached_result = cache.get(cache_key)
    if cached_result is not None:
        return json.loads(cached_result)

    results = []
    query_lower = q.lower()

    for md_file in MEMORY_DIR.rglob("*.md"):
        try:
            if not md_file.exists():
                continue
            content = md_file.read_text(encoding="utf-8")
            if query_lower in content.lower():
                idx = content.lower().find(query_lower)
                start_ctx = max(0, idx - 100)
                end_ctx = min(len(content), idx + len(q) + 200)
                snippet = content[start_ctx:end_ctx].strip()
                results.append({
                    "file": str(md_file.relative_to(MEMORY_DIR)),
                    "snippet": snippet,
                })
        except Exception:
            continue

    results.sort(key=lambda r: r["snippet"].lower().count(query_lower), reverse=True)

    result = {
        "query": q,
        "results": results[:10],
        "total": len(results),
    }
    cache.set(cache_key, json.dumps(result))

    return result


@router.get("/memory/{topic}")
async def get_memory(
    topic: str,
    request: Request,
    offset: int = Query(0, ge=0),
    limit: int = Query(500, ge=1, le=2000),
    __: bool = Depends(check_rate_limit),
):
    """Получить файл памяти по теме."""
    candidates = list(MEMORY_DIR.glob(f"*{topic}*.md"))
    if not candidates:
        candidates = list(MEMORY_DIR.rglob(f"*{topic}*.md"))
    if not candidates:
        raise HTTPException(status_code=404, detail=f"No memory files for: {topic}")

    best = min(candidates, key=lambda p: len(p.name))
    content = read_file_cached(best)
    if content is None:
        raise HTTPException(status_code=500, detail="Failed to read memory file")

    result = paginate_text(content, offset, limit)
    result["file"] = str(best.relative_to(MEMORY_DIR))

    return result


@router.get("/insights/recent")
async def get_recent_insights(
    request: Request,
    limit: int = Query(5, ge=1, le=20),
    __: bool = Depends(check_rate_limit),
):
    """Получить последние инсайты из memory/insights/ с frontmatter."""
    insights_dir = MEMORY_DIR / "insights"
    if not insights_dir.exists():
        return {"insights": [], "total": 0}

    insights = []
    for md_file in sorted(insights_dir.glob("insight_*.md"), reverse=True):
        try:
            content = read_file_cached(md_file)
            if not content:
                continue
            fm = parse_frontmatter(content)
            title = fm.get("title", "") or md_file.stem
            summary = fm.get("summary", "")
            if not summary:
                after_fm = content.split("---", 2)
                if len(after_fm) >= 3:
                    body_lines = [l.strip() for l in after_fm[2].split("\n") if l.strip()][:3]
                    summary = " ".join(body_lines)[:300]
            date = fm.get("date", "") or fm.get("created", "")[:10]
            insights.append({
                "id": md_file.stem,
                "title": title,
                "summary": summary,
                "date": date,
                "file": str(md_file.relative_to(MEMORY_DIR)),
            })
        except Exception:
            continue

    return {"insights": insights[:limit], "total": len(insights)}
