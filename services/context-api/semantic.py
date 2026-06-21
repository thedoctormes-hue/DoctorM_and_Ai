"""Семантический слой Context API.

Эмбеддинги через Ollama (bge-m3), косинусный поиск по артефактам лаборатории.
Индекс — JSON-файл (id, source, title, type, file, vector). На старте без FAISS:
артефактов ~сотни, линейный косинус на 1024-dim укладывается в единицы мс.

Выбор bge-m3 обоснован бенчмарком (2026-06-16): precision@1=1.0, margin 0.13,
~1.2с/запрос на 4 vCPU CPU-only. См. memory/2026-06-16.md.
"""
import json
import math
import os
import time
from pathlib import Path
from typing import Optional

import httpx

LAB_ROOT = Path("/root/LabDoctorM")
INDEX_PATH = Path(__file__).parent / "semantic_index.json"
MYRMEX_JSON = LAB_ROOT / "projects/myrmex-control/myrmex.json"
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
EMBED_MODEL = os.environ.get("EMBED_MODEL", "bge-m3")

# Источники артефактов: центральный реестр лаборатории.
# type определяется по папке.
ARTIFACT_DIRS = {
    "adr": LAB_ROOT / "adr",
    "pattern": LAB_ROOT / "patterns",
    "rule": LAB_ROOT / "rules",
    "spec": LAB_ROOT / "specs",
    "incident": LAB_ROOT / "incidents",
    "metric": LAB_ROOT / "metrics",
    "docs": LAB_ROOT / "docs",
}

# Корневые файлы лаборатории — индексируются напрямую по типам.
ROOT_ARTIFACTS = [
    ("lab_passport",    LAB_ROOT / "LAB_PASSPORT.md"),
    ("identity",        LAB_ROOT / "IDENTITY.md"),
    ("soul",            LAB_ROOT / "SOUL-compact.md"),
    ("incidents_log",   LAB_ROOT / "INCIDENTS.md"),
    ("changelog",       LAB_ROOT / "CHANGELOG.md"),
    ("readme",          LAB_ROOT / "README.md"),
    ("projects_list",   LAB_ROOT / "projects.md"),
    ("artifacts",       LAB_ROOT / "ARTIFACTS.md"),
    ("qwencore",        LAB_ROOT / "QWEN-core.md"),
    ("qwens",           LAB_ROOT / "QWEN-staff.md"),
    ("qweprojects",     LAB_ROOT / "QWEN-projects.md"),
    ("security",        LAB_ROOT / "SECURITY.md"),
    ("checkpoint",      LAB_ROOT / "CHECKPOINT.md"),
    ("zavlab",          LAB_ROOT / "ZAVLAB_DOSSIER.md"),
    ("session_handoff", LAB_ROOT / "SESSION_HANDOFF.md"),
]

# Анти-паттерн: исключаемые директории (мусор).
EXCLUDE_DIRS = {
    ".git", "node_modules", "__pycache__", ".pytest_cache",
    "venv", ".venv", "dist", "build", ".next", "coverage",
    ".turbo", ".cache", "target", "vendor", ".github",
    ".archive", "_backups", ".qwen", ".worktrees",
    "worktrees", "data", "logs", "backups",
}
# Анти-паттерн: исключаемые файлы (шаблоны, служебные).
EXCLUDE_FILES = {
    "README.md", "UPGRADE_PROMPT.md", "HANDOFF_TO_BESTIA.md",
    "INTEGRATION.md", "SECURITY_AUDIT.md", "TOKEN_AUDIT_REQUEST.md",
    "IDENTITY-template.md", "SOUL-template.md",
    "SKILL_ Consilium_iraai.md", "regen_audits.py",
}
EXCLUDE_SUFFIXES = ("-template.md", "_template.md")


# ── Эмбеддинги ─────────────────────────────────────
def embed(text: str, *, is_query: bool, timeout: float = 120.0) -> list[float]:
    """Получить эмбеддинг через Ollama. bge-m3 не требует префиксов."""
    resp = httpx.post(
        f"{OLLAMA_URL}/api/embeddings",
        json={"model": EMBED_MODEL, "prompt": text},
        timeout=timeout,
    )
    resp.raise_for_status()
    return resp.json()["embedding"]


async def embed_async(text: str, *, timeout: float = 30.0) -> Optional[list[float]]:
    """Асинхронный эмбеддинг запроса. None при ошибке."""
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.post(
                f"{OLLAMA_URL}/api/embeddings",
                json={"model": EMBED_MODEL, "prompt": text},
            )
            resp.raise_for_status()
            return resp.json()["embedding"]
    except Exception:
        return None


def cosine(a: list[float], b: list[float]) -> float:
    s = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return s / (na * nb) if na and nb else 0.0


# ── Frontmatter (локальная копия, без зависимости от common) ──
import re as _re

def _parse_frontmatter(content: str) -> dict:
    if not content.startswith("---"):
        return {}
    end = _re.search(r"\n---\s*\n", content)
    if end is None:
        return {}
    block = content[: end.start()]
    result = {}
    for line in block.split("\n")[1:]:
        line = line.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            result[key] = value
    return result


def _title_of(content: str, fm: dict, fallback: str) -> str:
    title = fm.get("title", "")
    if not title:
        for line in content.split("\n"):
            if line.startswith("# "):
                return line[2:].strip()
    return title or fallback


def _embed_text(title: str, body: str, limit: int = 2000) -> str:
    """Текст для эмбеддинга: заголовок усиливает сигнал + начало тела."""
    body = body.strip()[:limit]
    return f"{title}\n\n{body}" if title else body


# ── Индекс ─────────────────────────────────────────
class SemanticIndex:
    """In-memory индекс, грузится из JSON. Потокобезопасно для чтения."""

    def __init__(self, path: Path = INDEX_PATH):
        self.path = path
        self.entries: list[dict] = []
        self.model: str = EMBED_MODEL
        self.built_at: Optional[str] = None
        self._mtime: float = 0.0

    def load(self) -> bool:
        if not self.path.exists():
            return False
        mtime = self.path.stat().st_mtime
        if mtime == self._mtime and self.entries:
            return True
        data = json.loads(self.path.read_text(encoding="utf-8"))
        self.entries = data.get("entries", [])
        self.model = data.get("model", EMBED_MODEL)
        self.built_at = data.get("built_at")
        self._mtime = mtime
        return True

    def search(self, query_vec: list[float], limit: int = 5,
               type_filter: Optional[str] = None) -> list[dict]:
        scored = []
        for e in self.entries:
            if type_filter and e.get("type") != type_filter:
                continue
            score = cosine(query_vec, e["vector"])
            scored.append((score, e))
        scored.sort(key=lambda x: x[0], reverse=True)
        out = []
        for score, e in scored[:limit]:
            out.append({
                "id": e["id"],
                "type": e["type"],
                "title": e["title"],
                "file": e["file"],
                "score": round(score, 4),
            })
        return out

    @property
    def size(self) -> int:
        return len(self.entries)


# Глобальный индекс для роутера
index = SemanticIndex()



# ── Myrmex JSON индексация ──────────────────────────
MYRMEX_INDEX_TYPES = {
    "task":     ("myrmex_task",     lambda t: f'{t.get("title", "")} — {t.get("description", "")}'),
    "project":  ("myrmex_project",  lambda p: f'{p.get("name", "")}: {p.get("description", "")}'),
    "agent":    ("myrmex_agent",    lambda a: f'{a.get("name", "")} — {a.get("role", "")}'),
    "skill":   ("myrmex_skill",   lambda s: f'{s.get("name", "")}: {s.get("description", "")}'),
    "staff":   ("myrmex_staff",   lambda s: f'{s.get("name", "")} — {s.get("role", "")}'),
    "artifact": ("myrmex_artifact", lambda a: f'{a.get("name", "")}: {a.get("description", "")}'),
}

def _index_myrmex_json(verbose: bool = True) -> list[dict]:
    """Проиндексировать ВСЮ важную информацию из myrmex.json:
    проекты, задачи, агенты, скиллы, артефакты, staff,
    инциденты, handoff-отчёты, changelog, runtime_state.
    """
    if not MYRMEX_JSON.exists():
        return []
    try:
        data = json.loads(MYRMEX_JSON.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, IOError):
        return []

    entries = []

    # 1. Основные сущности из myrmex.json
    for json_key, (prefix, text_fn) in MYRMEX_INDEX_TYPES.items():
        items = data.get(json_key, [])
        if not items:
            continue
        for item in items:
            aid = item.get("id") or item.get("name") or "?"
            title = item.get("title") or item.get("name") or str(aid)
            try:
                text = text_fn(item)
            except Exception:
                text = title
            if not text.strip():
                continue
            try:
                vec = embed(text, is_query=False)
            except Exception as e:
                if verbose:
                    print(f"  ! {prefix} {aid} embed fail: {e}")
                continue
            entries.append({
                "id": f"{prefix}:{aid}",
                "type": prefix,
                "title": title[:200],
                "file": f"myrmex.json#{json_key}[{aid}]",
                "vector": vec,
            })
            if verbose:
                print(f"  + {prefix:16} {aid}")

    # 2. Инциденты из runtime_state
    rs = data.get("runtime_state", {})
    for inc in rs.get("incidents", {}).get("items", []):
        aid = inc.get("id", "?")
        title = inc.get("title", "")
        text = f'{inc.get("id", "")}: {title} [{inc.get("status", "")}] severity={inc.get("severity", "")}'
        if not text.strip():
            continue
        try:
            vec = embed(text, is_query=False)
        except Exception:
            continue
        entries.append({
            "id": f"myrmex_incident:{aid}",
            "type": "myrmex_incident",
            "title": title[:200],
            "file": f"myrmex.json#runtime_state.incidents[{aid}]",
            "vector": vec,
        })
        if verbose:
            print(f"  + {'myrmex_incident':16} {aid}")

    # 3. Handoff-отчёты агентов
    for agent_name, info in rs.get("handoffs", {}).items():
        tldr = info.get("tldr", "")
        status = info.get("status", "")
        text = f'Handoff {agent_name}: {status}. {tldr}'
        if not text.strip():
            continue
        try:
            vec = embed(text, is_query=False)
        except Exception:
            continue
        entries.append({
            "id": f"myrmex_handoff:{agent_name}",
            "type": "myrmex_handoff",
            "title": f"Handoff: {agent_name} ({status})",
            "file": f"myrmex.json#runtime_state.handoffs[{agent_name}]",
            "vector": vec,
        })
        if verbose:
            print(f"  + {'myrmex_handoff':16} {agent_name}")

    # 4. Changelog (последние 50 записей — чтобы не раздувать индекс)
    changelog = data.get("changelog", [])
    for entry in changelog[-50:]:
        aid = entry.get("id", "?")
        action = entry.get("action", "")
        entity = entry.get("entity_type", "")
        source = entry.get("source", "")
        text = f'Changelog: {action} {entity} by {source}'
        if not text.strip():
            continue
        try:
            vec = embed(text, is_query=False)
        except Exception:
            continue
        entries.append({
            "id": f"myrmex_changelog:{aid}",
            "type": "myrmex_changelog",
            "title": f"{action} {entity}",
            "file": f"myrmex.json#changelog[{aid}]",
            "vector": vec,
        })
        if verbose:
            print(f"  + {'myrmex_changelog':16} {aid}")

    # 5. Runtime state summary
    git_info = rs.get("git", {})
    oc_info = rs.get("openclaw", {})
    failed = rs.get("failedUnits", [])
    summary = (
        f"Runtime: OpenClaw {oc_info.get('status', '?')} "
        f"git ahead={git_info.get('ahead', 0)} behind={git_info.get('behind', 0)} "
        f"dirty={git_info.get('dirty', 0)} "
        f"failed_units={len(failed)} "
        f"incidents_open={rs.get('incidents', {}).get('open', 0)}"
    )
    try:
        vec = embed(summary, is_query=False)
        entries.append({
            "id": "myrmex_runtime_summary",
            "type": "myrmex_runtime",
            "title": summary[:200],
            "file": "myrmex.json#runtime_state",
            "vector": vec,
        })
        if verbose:
            print(f"  + {'myrmex_runtime':16} summary")
    except Exception:
        pass

    return entries

def _should_exclude_dir(dir_name: str) -> bool:
    return dir_name in EXCLUDE_DIRS or dir_name.startswith(".")


def _should_exclude_file(file_name: str) -> bool:
    if file_name in EXCLUDE_FILES:
        return True
    return any(file_name.endswith(s) for s in EXCLUDE_SUFFIXES)


def _collect_md_files(root: Path, art_type: str) -> list[Path]:
    """Рекурсивно собрать .md из директории, фильтруя мусор."""
    results = []
    if not root.exists():
        return results
    for p in sorted(root.rglob("*.md")):
        # Проверяем все части пути на EXCLUDE_DIRS
        parts = set(p.relative_to(root).parts)
        if parts & EXCLUDE_DIRS:
            continue
        if _should_exclude_file(p.name):
            continue
        results.append(p)
    return results


# ── Построение индекса (offline) ───────────────────
def build_index(verbose: bool = True) -> dict:
    """Прочитать артефакты, сгенерировать векторы, записать JSON-индекс."""
    entries = []
    skipped = []
    t0 = time.time()

    # 1) Артефакты из директорий (adr, specs, docs, ...)
    for art_type, d in ARTIFACT_DIRS.items():
        if not d.exists():
            continue
        md_files = _collect_md_files(d, art_type)
        for md in md_files:
            content = md.read_text(encoding="utf-8", errors="replace")
            if not content.strip():
                continue
            fm = _parse_frontmatter(content)
            aid = fm.get("id") or md.stem
            title = _title_of(content, fm, md.stem)
            text = _embed_text(title, content)
            try:
                vec = embed(text, is_query=False)
            except Exception as e:
                skipped.append(f"{md.name} (embed fail: {e})")
                continue
            entries.append({
                "id": aid,
                "type": art_type,
                "title": title,
                "file": str(md.relative_to(LAB_ROOT)),
                "vector": vec,
            })
            if verbose:
                print(f"  + {art_type:9} {aid}")

    # 2) Корневые файлы лаборатории
    for art_type, fpath in ROOT_ARTIFACTS:
        if not fpath.exists():
            continue
        content = fpath.read_text(encoding="utf-8", errors="replace")
        if not content.strip():
            continue
        title = _title_of(content, {}, fpath.stem)
        text = _embed_text(title, content)
        try:
            vec = embed(text, is_query=False)
        except Exception as e:
            skipped.append(f"{fpath.name} (embed fail: {e})")
            continue
        entries.append({
            "id": fpath.stem,
            "type": art_type,
            "title": title,
            "file": str(fpath.relative_to(LAB_ROOT)),
            "vector": vec,
        })
        if verbose:
            print(f"  + {art_type:9} {fpath.stem}")

    # 3) Данные из myrmex.json
    myrmex_entries = _index_myrmex_json(verbose=verbose)
    entries.extend(myrmex_entries)

    out = {
        "model": EMBED_MODEL,
        "dim": len(entries[0]["vector"]) if entries else 0,
        "built_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "count": len(entries),
        "entries": entries,
    }
    INDEX_PATH.write_text(json.dumps(out, ensure_ascii=False), encoding="utf-8")
    dt = time.time() - t0
    if verbose:
        print(f"\nИндекс: {len(entries)} артефактов, dim={out['dim']}, "
              f"{dt:.1f}с → {INDEX_PATH}")
        if skipped:
            print(f"Пропущено {len(skipped)}: {', '.join(skipped[:10])}"
                  + (" ..." if len(skipped) > 10 else ""))
    return out


if __name__ == "__main__":
    build_index(verbose=True)
