#!/usr/bin/env python3
"""lab_search — семантический поиск по артефактам лаборатории.

Дёргает context-api /api/v1/semantic/search (bge-m3 + Ollama).
Холодный запрос к Ollama ~12с, поэтому таймаут по умолчанию 35с + один повтор.

Usage:
    python3 lab_search.py "как агент выбирает LLM модель"
    python3 lab_search.py "что делать при 429" --limit 5 --type spec
    python3 lab_search.py --status
"""
import argparse
import json
import sys
import urllib.parse
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8100/api/v1/semantic"


def _is_transient_error(e: urllib.error.HTTPError) -> bool:
    """502 Bad Gateway, 504 Gateway Timeout часто означают холодный старт Ollama."""
    return e.code in (502, 504)


def _get(path: str, params: dict | None = None, timeout: float = 35.0) -> dict:
    url = f"{BASE}/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def _get_with_retry(path: str, params: dict | None = None,
                    timeout: float = 35.0, retries: int = 2) -> dict:
    last_err = None
    for attempt in range(retries):
        try:
            return _get(path, params, timeout=timeout)
        except urllib.error.HTTPError as e:
            last_err = e
            if not _is_transient_error(e) or attempt == retries - 1:
                raise
            # иначе повторяем запрос (прогрели Ollama)
        except urllib.error.URLError as e:
            last_err = e
            if attempt == retries - 1:
                raise
    raise last_err


def status() -> int:
    try:
        d = _get_with_retry("status", timeout=5)
    except Exception as e:
        print(f"❌ context-api недоступен: {e}", file=sys.stderr)
        return 2
    if not d.get("available"):
        print("⚠️  индекс не построен. Собрать: "
              "python3 /root/LabDoctorM/services/context-api/semantic.py")
        return 1
    print(f"✅ индекс: {d['index_size']} артефактов, модель {d['model']}, "
          f"собран {d.get('built_at')}")
    return 0


def search(query: str, limit: int, type_filter: str | None,
           timeout: float, as_json: bool) -> int:
    params = {"q": query, "limit": limit}
    if type_filter:
        params["type"] = type_filter
    try:
        d = _get_with_retry("search", params, timeout=timeout)
    except urllib.error.HTTPError as e:
        if _is_transient_error(e):
            print(f"❌ Ollama холодный старт, пробуем ещё раз...", file=sys.stderr)
            try:
                d = _get_with_retry("search", params, timeout=timeout)
            except Exception as e2:
                print(f"❌ второй запрос тоже не прошёл: {e2}", file=sys.stderr)
                return 2
        else:
            print(f"❌ запрос не прошёл (HTTP {e.code}): {e.reason}", file=sys.stderr)
            return 2
    except urllib.error.URLError as e:
        print(f"❌ сетевая ошибка: {e.reason}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"❌ неизвестная ошибка: {e}", file=sys.stderr)
        return 2

    results = d.get("results", [])
    if as_json:
        print(json.dumps(d, ensure_ascii=False, indent=2))
        return 0
    if not results:
        print("Ничего не найдено.")
        return 0
    print(f"🔎 «{query}»  (индекс {d.get('index_size')}, {d.get('model')})\n")
    for i, r in enumerate(results, 1):
        print(f"{i}. [{r['score']}] {r['type']:9} {r['id']}")
        print(f"   {r['title']}")
        print(f"   {r['file']}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Семантический поиск по артефактам лаборатории")
    ap.add_argument("query", nargs="?", help="запрос на естественном языке")
    ap.add_argument("--limit", type=int, default=5)
    ap.add_argument("--type", dest="type_filter",
                    help="фильтр: adr|pattern|rule|spec|incident|metric")
    ap.add_argument("--timeout", type=float, default=35.0)
    ap.add_argument("--json", action="store_true", help="сырой JSON")
    ap.add_argument("--status", action="store_true", help="состояние индекса")
    a = ap.parse_args()
    if a.status:
        return status()
    if not a.query:
        ap.error("нужен запрос или --status")
    return search(a.query, a.limit, a.type_filter, a.timeout, a.json)


if __name__ == "__main__":
    sys.exit(main())

