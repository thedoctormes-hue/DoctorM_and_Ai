#!/usr/bin/env python3
"""Переиндексация семантического индекса, только если артефакты менялись.

Сравнивает max(mtime) артефактов с built_at индекса. Если новее — пересобирает.
Запускается systemd-таймером ночью. Идемпотентно: вхолостую почти ничего не стоит.
"""
import json
import sys
import time
from pathlib import Path

import semantic

INDEX = semantic.INDEX_PATH


def newest_artifact_mtime() -> float:
    newest = 0.0
    for d in semantic.ARTIFACT_DIRS.values():
        if not d.exists():
            continue
        for md in d.glob("*.md"):
            newest = max(newest, md.stat().st_mtime)
    return newest


def index_built_epoch() -> float:
    if not INDEX.exists():
        return 0.0
    try:
        data = json.loads(INDEX.read_text(encoding="utf-8"))
        built = data.get("built_at")
        if not built:
            return 0.0
        return time.mktime(time.strptime(built, "%Y-%m-%dT%H:%M:%SZ"))
    except Exception:
        return 0.0


def main() -> int:
    art = newest_artifact_mtime()
    idx = index_built_epoch()
    if idx and art <= idx:
        print(f"[reindex] skip: индекс свежий (built {time.ctime(idx)}, "
              f"артефакты {time.ctime(art)})")
        return 0
    print(f"[reindex] пересборка: артефакты новее индекса "
          f"(art={time.ctime(art)}, idx={time.ctime(idx) if idx else 'нет'})")
    out = semantic.build_index(verbose=False)
    print(f"[reindex] готово: {out['count']} артефактов, dim={out['dim']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
