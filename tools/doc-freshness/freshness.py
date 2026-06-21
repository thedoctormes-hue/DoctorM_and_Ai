#!/usr/bin/env python3
"""
freshness.py — Слой 1 (Возраст) + Слой 2 (Зависимости) + Слой 3 (Структура)

Сканирует .md файлы, вычисляет freshness score (0-100).
Score на основе:
  - Возраста документа относительно изменений в связанном коде (Слой 1)
  - Зависимостей от других документов (Слой 2)
  - Целостности внутренних ссылок (Слой 3)

Использование:
    python3 freshness.py scan /root/LabDoctorM
    python3 freshness.py check /root/LabDoctorM/README.md
    python3 freshness.py report /root/LabDoctorM
    python3 freshness.py migrate /root/LabDoctorM
"""

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

import yaml

# ─── Конфигурация ──────────────────────────────────────────────

CONFIG_PATH = Path(__file__).parent / "config.yaml"
REPO_ROOT = Path("/root/LabDoctorM")


def load_config() -> dict:
    with open(CONFIG_PATH) as f:
        return yaml.safe_load(f)


# ─── Git-утилиты ────────────────────────────────────────────────

def git_last_change(path: str, repo: str = ".") -> Optional[datetime]:
    """Дата последнего git-коммита, затронувшего файл или директорию."""
    try:
        result = subprocess.run(
            ["git", "-C", repo, "log", "-1", "--format=%at", "--", path],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            return datetime.fromtimestamp(int(result.stdout.strip()))
    except (subprocess.TimeoutExpired, ValueError):
        pass
    return None


def git_commits_since(path: str, days: int = 30, repo: str = ".") -> int:
    """Количество коммитов за последние N дней."""
    try:
        result = subprocess.run(
            ["git", "-C", repo, "log", f"--since={days} days ago",
             "--oneline", "--", path],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            return len([l for l in result.stdout.strip().split("\n") if l])
    except subprocess.TimeoutExpired:
        pass
    return 0


# ─── Слой 1: Возраст ───────────────────────────────────────────

def resolve_code_dir(code_dir: str, repo: str = ".") -> Optional[str]:
    """
    Проверяет существование code_dir. Если директория не существует или
    git не находит изменений — поднимается на уровень вверх.
    Возвращает рабочий путь или None.
    """
    repo_path = Path(repo)
    current = repo_path / code_dir

    # Пробуем текущую директорию, потом родительскую
    for _ in range(3):  # максимум 3 уровня вверх
        if current.is_dir():
            # Проверяем что git видит изменения
            git_result = subprocess.run(
                ["git", "-C", repo, "log", "-1", "--format=%at", "--", str(current.relative_to(repo_path))],
                capture_output=True, text=True, timeout=10
            )
            if git_result.returncode == 0 and git_result.stdout.strip():
                return str(current.relative_to(repo_path))
        # Поднимаемся на уровень
        parent = current.parent
        if parent == current:  # корень
            break
        current = parent

    return None


def calc_age_score(doc_path: str, code_dir: str, config: dict, repo: str = ".") -> tuple[float, dict]:
    """
    Вычисляет age score (0-100) на основе возраста документа
    относительно изменений в связанном коде.

    Returns: (score, details)
    """
    age_cfg = config["age"]
    half_life = age_cfg["half_life_days"]

    # Дата последнего изменения документа
    doc_change = git_last_change(doc_path, repo)
    if doc_change is None:
        # doc_path может быть относительным — резолвим через repo
        abs_doc_path = str(Path(repo) / doc_path)
        doc_change = datetime.fromtimestamp(os.path.getmtime(abs_doc_path))

    # Проверяем, является ли директория нетехнической (non_code_dirs)
    non_code_dirs = config.get("non_code_dirs", [])
    is_non_code = any(code_dir.startswith(ncd) for ncd in non_code_dirs)
    if is_non_code:
        return 100.0, {"note": "non-code directory, age neutral", "code_dir": code_dir, "doc_change": doc_change.isoformat()}

    # Резолвим code_dir (с fallback на родительские директории)
    resolved_dir = resolve_code_dir(code_dir, repo)

    # Если код не найден — нейтральный score
    if resolved_dir is None:
        return 50.0, {"note": "no code changes found", "code_dir": code_dir, "doc_change": doc_change.isoformat()}

    # Дата последнего изменения связанного кода
    code_change = git_last_change(resolved_dir, repo)

    # Дней с последнего обновления документа после последнего изменения кода
    delta_days = (code_change - doc_change).total_seconds() / 86400

    if delta_days <= 0:
        # Документ новее кода — отлично
        return 100.0, {"delta_days": 0, "doc_change": doc_change.isoformat()}

    # Экспоненциальный распад
    import math
    score = 100.0 * math.exp(-math.log(2) / half_life * delta_days)

    # Дополнительный штраф за количество изменений кода без обновления доков
    code_commits_30d = git_commits_since(resolved_dir, days=30, repo=repo)
    activity_penalty = min(code_commits_30d * 2, 20)  # макс -20 за активность

    score = max(0, score - activity_penalty)

    details = {
        "delta_days": round(delta_days, 1),
        "doc_change": doc_change.isoformat(),
        "code_change": code_change.isoformat(),
        "code_commits_30d": code_commits_30d,
        "activity_penalty": activity_penalty,
        "resolved_dir": resolved_dir,
    }

    return round(score, 1), details


# ─── Слой 3: Структура ─────────────────────────────────────────

def extract_links(content: str) -> dict:
    """Извлекает все ссылки из Markdown-контента."""
    links = {"internal": [], "anchors": [], "external": []}

    # Убираем code blocks (```...``` и инлайн `...`) чтобы не парсить regex/код как ссылки
    content_no_code = re.sub(r'```[\s\S]*?```', '', content)
    content_no_code = re.sub(r'`[^`]+`', '', content_no_code)

    # Внутренние ссылки: [text](file.md) или [text](file.md#anchor)
    for m in re.finditer(r'\[([^\]]*)\]\(([^)#]+)(?:#([^\)]*))?\)', content_no_code):
        target_file = m.group(2)
        anchor = m.group(3)
        if not target_file.startswith("http"):
            links["internal"].append({"file": target_file, "anchor": anchor})

    # Якорные ссылки: [text](#anchor)
    for m in re.finditer(r'\[([^\]]*)\]\(#([^\)]*)\)', content_no_code):
        links["anchors"].append(m.group(2))

    return links


def check_link(link: str, doc_path: Path, root: Path) -> bool:
    """Проверяет, существует ли внутренняя ссылка."""
    # Убираем anchor
    link_clean = link.split("#")[0]
    if not link_clean:
        return True  # anchor-only проверяется отдельно

    # Относительно документа
    target = (doc_path.parent / link_clean).resolve()
    if target.exists():
        return True

    # Относительно корня
    target = (root / link_clean).resolve()
    if target.exists():
        return True

    # Пробуем с .md
    if not link_clean.endswith(".md"):
        target = (doc_path.parent / (link_clean + ".md")).resolve()
        if target.exists():
            return True
        target = (root / (link_clean + ".md")).resolve()
        if target.exists():
            return True

    return False


def heading_to_anchor(heading: str) -> str:
    r"""
    Конвертирует заголовок в якорь по правилам GitHub.
    GitHub: lowercase, пробелы→дефисы, убираем всё кроме [\w\s-] (Unicode-aware).
    Эмодзи, скобки, точки, запятые — удаляются.
    """
    # Убираем всё кроме букв (Unicode), цифр, пробелов, дефисов
    clean = re.sub(r'[^\w\s\-]', '', heading, flags=re.UNICODE)
    # Lowercase, пробелы → дефисы
    anchor = clean.lower().strip().replace(' ', '-')
    # Убираем множественные дефисы
    anchor = re.sub(r'-+', '-', anchor)
    # Убираем leading/trailing дефисы
    anchor = anchor.strip('-')
    return anchor


def check_anchor(anchor: str, content: str) -> bool:
    """Проверяет, существует ли якорь в документе (GitHub-style matching)."""
    anchor_normalized = heading_to_anchor(anchor)
    heading_pattern = re.compile(r'^#{1,6}\s+(.+)$', re.MULTILINE)
    for m in heading_pattern.finditer(content):
        heading_text = m.group(1).strip()
        if heading_to_anchor(heading_text) == anchor_normalized:
            return True
    return False


def calc_structure_score(doc_path: Path, content: str, root: Path, config: dict) -> tuple[float, dict]:
    """
    Вычисляет structure score (0-100) на основе целостности ссылок.

    Returns: (score, details)
    """
    struct_cfg = config["structure"]
    broken_link_penalty = struct_cfg["broken_link_penalty"]
    max_penalty = struct_cfg["max_structure_penalty"]

    links = extract_links(content)
    broken = []
    total = 0

    # Проверяем внутренние ссылки
    for link in links["internal"]:
        total += 1
        if not check_link(link["file"], doc_path, root):
            broken.append(f"file:{link['file']}")
        elif link["anchor"]:
            # Проверяем anchor в целевом файле
            target_path = (doc_path.parent / link["file"]).resolve()
            if not target_path.exists():
                target_path = (root / link["file"]).resolve()
            if target_path.exists():
                target_content = target_path.read_text(encoding="utf-8", errors="ignore")
                if not check_anchor(link["anchor"], target_content):
                    broken.append(f"anchor:{link['file']}#{link['anchor']}")

    # Проверяем якоря в самом документе
    for anchor in links["anchors"]:
        total += 1
        if not check_anchor(anchor, content):
            broken.append(f"anchor:#{anchor}")

    if total == 0:
        return 100.0, {"total_links": 0, "broken": []}

    penalty = min(len(broken) * broken_link_penalty, max_penalty)
    score = max(0, 100 - penalty)

    return round(score, 1), {
        "total_links": total,
        "broken_count": len(broken),
        "broken": broken[:10],  # максимум 10 для отчёта
    }


# ─── Слой 2: Зависимости (каскадное устаревание) ────────────────

def build_dependency_graph(all_doc_paths: list[Path], root: Path) -> dict[str, list[str]]:
    """
    Строит граф зависимостей: doc_path → [зависимые документы].
    Анализирует внутренние ссылки между .md файлами.
    """
    graph = {}
    # Маппинг: относительный путь → Path
    doc_map = {}
    for dp in all_doc_paths:
        rel = str(dp.relative_to(root))
        doc_map[rel] = dp
        # Также без расширения
        doc_map[rel.replace('.md', '')] = dp

    for dp in all_doc_paths:
        rel = str(dp.relative_to(root))
        graph[rel] = []
        try:
            content = dp.read_text(encoding='utf-8', errors='ignore')
        except Exception:
            continue

        links = extract_links(content)
        for link in links['internal']:
            target_file = link['file']
            # Резолвим путь
            target_abs = (dp.parent / target_file).resolve()
            if not target_file.endswith('.md') and not target_abs.exists():
                target_abs = (dp.parent / (target_file + '.md')).resolve()
            if not target_abs.exists():
                target_abs = (root / target_file).resolve()
            if not target_file.endswith('.md') and not target_abs.exists():
                target_abs = (root / (target_file + '.md')).resolve()

            if target_abs.exists():
                target_rel = str(target_abs.relative_to(root))
                graph[rel].append(target_rel)

    return graph


def calc_dependency_score(doc_rel: str, dep_graph: dict, results_map: dict,
                          config: dict) -> tuple[float, dict]:
    """
    Вычисляет dependency score (0-100).
    Если документ зависит от expired/stale документов — штраф.

    Returns: (score, details)
    """
    deps = dep_graph.get(doc_rel, [])
    if not deps:
        return 100.0, {"deps_count": 0, "expired_deps": [], "stale_deps": []}

    expired_deps = []
    stale_deps = []

    for dep_path in deps:
        dep_result = results_map.get(dep_path)
        if dep_result is None:
            continue
        status = dep_result.get('status')
        if status == 'expired':
            expired_deps.append(dep_path)
        elif status == 'stale':
            stale_deps.append(dep_path)

    # Штраф: -20 за expired dependency, -10 за stale
    penalty = len(expired_deps) * 20 + len(stale_deps) * 10
    penalty = min(penalty, 60)  # макс -60

    score = max(0, 100 - penalty)

    return round(score, 1), {
        "deps_count": len(deps),
        "expired_deps": expired_deps,
        "stale_deps": stale_deps,
        "penalty": penalty,
    }


# ─── Композитный score ─────────────────────────────────────────

def compute_freshness(doc_path: Path, config: dict, root: Path,
                      dep_graph: dict = None, results_map: dict = None) -> dict:
    """Вычисляет композитный freshness score для документа."""
    content = doc_path.read_text(encoding="utf-8", errors="ignore")
    rel_path = str(doc_path.relative_to(root))

    # Определяем связанный код
    code_dir = None
    for code_pattern, doc_patterns in config.get("code_doc_mapping", {}).items():
        if rel_path in doc_patterns or any(rel_path.startswith(d.replace("**", "").replace("*", ""))
                                            for d in doc_patterns):
            code_dir = code_pattern
            break

    # Если нет маппинга — используем директорию документа
    if code_dir is None:
        code_dir = str(doc_path.parent.relative_to(root))

    # Проверяем существование code_dir из маппинга; если нет — fallback на родительскую директорию документа
    if code_dir and not (root / code_dir).exists():
        code_dir = str(doc_path.parent.relative_to(root))

    # Слой 1: Возраст
    age_score, age_details = calc_age_score(rel_path, code_dir, config, str(root))

    # Слой 2: Зависимости (если передан граф)
    dep_score = 100.0
    dep_details = {"deps_count": 0, "expired_deps": [], "stale_deps": []}
    if dep_graph is not None and results_map is not None:
        dep_score, dep_details = calc_dependency_score(rel_path, dep_graph, results_map, config)

    # Слой 3: Структура
    struct_score, struct_details = calc_structure_score(doc_path, content, root, config)

    # Композитный score: 50% возраст + 20% зависимости + 30% структура
    composite = round(0.5 * age_score + 0.2 * dep_score + 0.3 * struct_score, 1)

    # Определяем статус
    thresholds = config["thresholds"]
    if composite >= thresholds["fresh"]:
        status = "fresh"
        emoji = "🟢"
    elif composite >= thresholds["stale"]:
        status = "stale"
        emoji = "🟡"
    else:
        status = "expired"
        emoji = "🔴"

    return {
        "path": rel_path,
        "score": composite,
        "status": status,
        "emoji": emoji,
        "layers": {
            "age": {"score": age_score, "details": age_details},
            "dependencies": {"score": dep_score, "details": dep_details},
            "structure": {"score": struct_score, "details": struct_details},
        },
        "code_dir": code_dir,
        "scanned_at": datetime.now().isoformat(),
    }


# ─── Сканирование ───────────────────────────────────────────────

def find_md_files(root: Path, config: dict) -> list[Path]:
    """Находит все .md файлы с учётом include/exclude."""
    import fnmatch

    include = config["scan"].get("include", ["**/*.md"])
    exclude = config["scan"].get("exclude", [])

    files = []
    for pattern in include:
        for f in root.glob(pattern):
            rel = str(f.relative_to(root))
            skip = False
            for excl in exclude:
                if fnmatch.fnmatch(rel, excl):
                    skip = True
                    break
            if not skip:
                files.append(f)

    return sorted(set(files))


def scan_project(root: Path, config: dict, max_iterations: int = 10) -> dict:
    """Полное сканирование проекта.

    Слой 2 (зависимости): итерация до сходимости.
    На каждой итерации пересчитываем все документы с обновлённым results_map.
    Останавливаемся когда ни один статус не изменился или достигнут лимит итераций.
    """
    files = find_md_files(root, config)

    # Слой 2: строим граф зависимостей
    dep_graph = build_dependency_graph(files, root)

    # Первый проход: вычисляем score без зависимостей (age + structure)
    results = []
    errors = []
    for f in files:
        try:
            result = compute_freshness(f, config, root)
            results.append(result)
        except Exception as e:
            errors.append({"path": str(f.relative_to(root)), "error": str(e)})

    # Итерация до сходимости для Слоя 2
    if dep_graph:
        results_map = {r["path"]: r for r in results}

        for iteration in range(max_iterations):
            changed = False
            new_results = []

            for r in results:
                try:
                    f = root / r["path"]
                    updated = compute_freshness(f, config, root, dep_graph, results_map)
                except Exception:
                    updated = r

                # Проверяем изменился ли статус или score
                if updated["status"] != r["status"] or abs(updated["score"] - r["score"]) > 0.01:
                    changed = True

                new_results.append(updated)

            results = new_results
            # Обновляем results_map для следующей итерации
            results_map = {r["path"]: r for r in results}

            if not changed:
                break  # Сходимость достигнута

    # Сводка
    total = len(results)
    fresh = sum(1 for r in results if r["status"] == "fresh")
    stale = sum(1 for r in results if r["status"] == "stale")
    expired = sum(1 for r in results if r["status"] == "expired")
    avg_score = round(sum(r["score"] for r in results) / total, 1) if total else 0

    return {
        "scan_time": datetime.now().isoformat(),
        "root": str(root),
        "summary": {
            "total": total,
            "fresh": fresh,
            "stale": stale,
            "expired": expired,
            "avg_score": avg_score,
        },
        "documents": sorted(results, key=lambda x: x["score"]),
        "errors": errors,
    }


# ─── Frontmatter migrate ────────────────────────────────────────

def migrate_frontmatter(root: Path, config: dict) -> dict:
    """Добавляет frontmatter в .md файлы, где его нет."""
    files = find_md_files(root, config)
    migrated = 0
    skipped = 0
    errors = []

    for f in files:
        try:
            content = f.read_text(encoding="utf-8", errors="ignore")

            # Проверяем, есть ли frontmatter
            if content.strip().startswith("---"):
                skipped += 1
                continue

            # Определяем тип из пути
            rel = str(f.relative_to(root))
            doc_type = "guide"
            if "specs/" in rel or rel.startswith("BL-"):
                doc_type = "spec"
            elif "adr/" in rel or "ADR-" in rel:
                doc_type = "adr"
            elif "incidents/" in rel or "INC-" in rel:
                doc_type = "incident"
            elif "patterns/" in rel:
                doc_type = "pattern"
            elif "rules/" in rel:
                doc_type = "rule"
            elif "README" in rel:
                doc_type = "readme"

            # Извлекаем description из первого заголовка
            description = ""
            for line in content.split("\n"):
                line = line.strip()
                if line.startswith("# "):
                    description = line[2:].strip()[:120]
                    break
            if not description:
                description = f"Документ {f.stem}"

            # Даты
            last_change = git_last_change(rel, str(root))
            last_reviewed = last_change.strftime("%Y-%m-%d") if last_change else datetime.now().strftime("%Y-%m-%d")

            # last_code_change — дата последнего изменения связанного кода
            code_dir = None
            for code_pattern, doc_patterns in config.get("code_doc_mapping", {}).items():
                if rel in doc_patterns or any(rel.startswith(d.replace("**", "").replace("*", ""))
                                                for d in doc_patterns):
                    code_dir = code_pattern
                    break
            if code_dir is None:
                code_dir = str(Path(rel).parent)
            code_change = git_last_change(code_dir, str(root))
            last_code_change = code_change.strftime("%Y-%m-%d") if code_change else last_reviewed

            # Генерируем frontmatter
            fm_lines = [
                "---",
                f'description: "{description}"',
                f"type: {doc_type}",
                f"last_reviewed: {last_reviewed}",
                f"last_code_change: {last_code_change}",
                "status: active",
                "---",
                "",
            ]

            new_content = "\n".join(fm_lines) + content
            f.write_text(new_content, encoding="utf-8")
            migrated += 1

        except Exception as e:
            errors.append({"path": str(f.relative_to(root)), "error": str(e)})

    return {
        "migrated": migrated,
        "skipped": skipped,
        "errors": errors,
    }


# ─── CLI ────────────────────────────────────────────────────────

def print_report(report: dict):
    """Красивый отчёт в терминал."""
    s = report["summary"]
    print()
    print("=" * 60)
    print("  📊 DOC FRESHNESS REPORT")
    print(f"  {report['scan_time']}")
    print("=" * 60)
    print()
    print(f"  Всего документов:  {s['total']}")
    print(f"  🟢 Свежих:         {s['fresh']}")
    print(f"  🟡 Устаревающих:   {s['stale']}")
    print(f"  🔴 Устаревших:     {s['expired']}")
    print(f"  Средний score:     {s['avg_score']}/100")
    print()

    # Топ-10 самых устаревших
    expired_docs = [d for d in report["documents"] if d["status"] == "expired"]
    if expired_docs:
        print("─" * 60)
        print("  🔴 УСТАРЕВШИЕ ДОКУМЕНТЫ (score < 40):")
        print("─" * 60)
        for d in expired_docs[:10]:
            print(f"  {d['score']:5.1f}  {d['path']}")
            age_details = d["layers"]["age"]["details"]
            if "delta_days" in age_details:
                print(f"        код менялся {age_details['delta_days']}д назад, док не обновлялся")
            struct_details = d["layers"]["structure"]["details"]
            if struct_details["broken"]:
                print(f"        битых ссылок: {struct_details['broken_count']}")
            dep_details = d["layers"]["dependencies"]["details"]
            if dep_details.get("expired_deps"):
                print(f"        expired deps: {len(dep_details['expired_deps'])}")
            if dep_details.get("stale_deps"):
                print(f"        stale deps: {len(dep_details['stale_deps'])}")
        if len(expired_docs) > 10:
            print(f"  ... и ещё {len(expired_docs) - 10}")
        print()

    if report["errors"]:
        print(f"  ⚠️ Ошибок сканирования: {len(report['errors'])}")
        print()

    print("=" * 60)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Doc Freshness — Слой 1 + Слой 2 + Слой 3")
    sub = parser.add_subparsers(dest="command", help="Команда")

    # scan
    p_scan = sub.add_parser("scan", help="Полное сканирование проекта")
    p_scan.add_argument("root", nargs="?", default=".", help="Корень проекта")
    p_scan.add_argument("--output", "-o", help="Сохранить JSON-отчёт")
    p_scan.add_argument("--json", action="store_true", help="Только JSON в stdout")

    # check
    p_check = sub.add_parser("check", help="Проверить один файл")
    p_check.add_argument("file", help="Путь к .md файлу")

    # migrate
    p_migrate = sub.add_parser("migrate", help="Добавить frontmatter во все .md")
    p_migrate.add_argument("root", nargs="?", default=".", help="Корень проекта")

    args = parser.parse_args()
    config = load_config()

    if args.command == "scan":
        root = Path(args.root).resolve()
        report = scan_project(root, config)

        if args.json:
            print(json.dumps(report, indent=2, ensure_ascii=False))
        else:
            print_report(report)

        if args.output:
            Path(args.output).write_text(
                json.dumps(report, indent=2, ensure_ascii=False),
                encoding="utf-8"
            )
            print(f"  📄 Отчёт сохранён: {args.output}")

        # Exit code для CI
        sys.exit(1 if report["summary"]["expired"] > 0 else 0)

    elif args.command == "check":
        file_path = Path(args.file).resolve()
        root = REPO_ROOT
        result = compute_freshness(file_path, config, root)
        print(json.dumps(result, indent=2, ensure_ascii=False))

    elif args.command == "migrate":
        root = Path(args.root).resolve()
        result = migrate_frontmatter(root, config)
        print(f"  ✅ Миграция: {result['migrated']} файлов обновлено, {result['skipped']} уже имеют frontmatter")
        if result["errors"]:
            print(f"  ⚠️ Ошибок: {len(result['errors'])}")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
