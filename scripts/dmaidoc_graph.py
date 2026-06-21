#!/usr/bin/env python3
"""
dmaidoc-graph — Knowledge Graph для документации LabDoctorM.

Граф зависимостей «документ ↔ код ↔ другие документы»:
  - Узлы: документы, модули, API endpoints, функции
  - Рёбра: references, imports, mentions, describes
  - Метрики: PageRank, stale propagation, connected components

Использование:
    python -m dmaidoc_graph build --root /root/LabDoctorM --output graph.json
    python -m dmaidoc_graph graph --stale --format table
    python -m dmaidoc_graph graph --stale --format d3 --output viz.html
    python -m dmaidoc_graph analyze --metrics pagerank,components,orphans
    python -m dmaidoc_graph export --format graphviz --output graph.dot

Зависимости: networkx, click (опционально: graphviz, jinja2)
"""

from __future__ import annotations

import ast
import json
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Any, Optional

try:
    import networkx as nx
except ImportError:
    print("❌ networkx не установлен. Установите: pip install networkx", file=sys.stderr)
    sys.exit(1)

# ─── Модели данных ────────────────────────────────────────────────────────────

class NodeType(Enum):
    """Тип узла в графе знаний."""
    DOCUMENT = "document"       # .md файлы: README, ADR, specs, docs/
    MODULE = "module"           # Python-модули: .py файлы
    COMPONENT = "component"     # React-компоненты: .tsx/.ts файлы
    API_ENDPOINT = "api_endpoint"  # API endpoints: @app.get("/api/...")
    FUNCTION = "function"       # Функции/методы внутри модулей
    CONFIG = "config"           # Конфигурационные файлы: .json, .yaml, .toml
    SKILL = "skill"             # LLM-скиллы: SKILL.md
    HOOK = "hook"               # Git hooks: *.sh в .qwen/hooks/

class EdgeType(Enum):
    """Тип ребра в графе знаний."""
    REFERENCES = "references"   # Документ ссылается на код (через имя файла/функции)
    IMPORTS = "imports"         # Модуль импортирует другой модуль
    MENTIONS = "mentions"       # Документ упоминает другой документ
    DESCRIBES = "describes"     # Документ описывает модуль/компонент
    IMPLEMENTS = "implements"   # Модуль реализует спецификацию (spec → code)
    CALLS = "calls"             # Функция вызывает другую функцию
    CONFIGURES = "configures"   # Конфигурация настраивает модуль
    EXTENDS = "extends"         # Скилл/хук расширяет функциональность

@dataclass
class Node:
    """Узел графа знаний."""
    id: str                     # Уникальный идентификатор (путь или каноническое имя)
    type: NodeType
    label: str                  # Человекочитаемое имя
    path: Optional[Path] = None # Путь к файлу (если применимо)
    last_modified: Optional[float] = None  # timestamp последнего изменения
    metadata: dict = field(default_factory=dict)
    stale: bool = False         # Флаг устаревания
    stale_score: float = 0.0    # 0.0 = свежий, 1.0 = полностью устарел

    def to_dict(self) -> dict:
        d = asdict(self)
        d["type"] = self.type.value
        d["path"] = str(self.path) if self.path else None
        return d

    @staticmethod
    def from_dict(d: dict) -> Node:
        d["type"] = NodeType(d["type"])
        d["path"] = Path(d["path"]) if d.get("path") else None
        return Node(**{k: v for k, v in d.items() if k in Node.__dataclass_fields__})

@dataclass
class Edge:
    """Ребро графа знаний."""
    source: str                 # ID исходного узла
    target: str                 # ID целевого узла
    type: EdgeType
    weight: float = 1.0         # Вес ребра (сила связи)
    metadata: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        d = asdict(self)
        d["type"] = self.type.value
        return d

    @staticmethod
    def from_dict(d: dict) -> Edge:
        d["type"] = EdgeType(d["type"])
        return Edge(**{k: v for k, v in d.items() if k in Edge.__dataclass_fields__})


# ─── Парсеры исходного кода ──────────────────────────────────────────────────

class PythonParser:
    """Парсер Python-файлов: извлекает импорты, функции, API endpoints."""

    # Паттерны для обнаружения API endpoints (FastAPI / Flask / aiogram)
    ENDPOINT_PATTERNS = [
        re.compile(r'@(?:app|router|bp)\.(?:get|post|put|delete|patch|head|options)\s*\(\s*["\']([^"\']+)["\']'),
        re.compile(r'@(?:app|router|bp)\.route\s*\(\s*["\']([^"\']+)["\']'),
    ]

    def __init__(self, file_path: Path, root: Path):
        self.file_path = file_path
        self.root = root
        self.module_name = self._module_name()

    def _module_name(self) -> str:
        """Каноническое имя модуля относительно root."""
        try:
            rel = self.file_path.relative_to(self.root)
        except ValueError:
            return str(self.file_path)
        parts = list(rel.parts)
        if parts[-1] == "__init__.py":
            parts = parts[:-1]
        else:
            parts[-1] = parts[-1].replace(".py", "")
        return ".".join(parts)

    def parse(self) -> tuple[list[Node], list[Edge]]:
        """Парсит Python-файл и возвращает узлы + рёбра."""
        nodes: list[Node] = []
        edges: list[Edge] = []

        try:
            source = self.file_path.read_text(encoding="utf-8", errors="replace")
            tree = ast.parse(source, filename=str(self.file_path))
        except (SyntaxError, UnicodeDecodeError):
            return nodes, edges

        mtime = self.file_path.stat().st_mtime

        # Узел модуля
        module_node = Node(
            id=f"module:{self.module_name}",
            type=NodeType.MODULE,
            label=self.module_name,
            path=self.file_path,
            last_modified=mtime,
            metadata={"lines": len(source.splitlines())},
        )
        nodes.append(module_node)

        # Импорты → рёбра IMPORTS
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    target_module = self._resolve_import(alias.name)
                    if target_module:
                        edges.append(Edge(
                            source=module_node.id,
                            target=f"module:{target_module}",
                            type=EdgeType.IMPORTS,
                            weight=1.0,
                        ))
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    target_module = self._resolve_import(node.module)
                    if target_module:
                        edges.append(Edge(
                            source=module_node.id,
                            target=f"module:{target_module}",
                            type=EdgeType.IMPORTS,
                            weight=1.0,
                        ))

        # Функции → узлы FUNCTION + рёбра DESCRIBES
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                func_id = f"function:{self.module_name}.{node.name}"
                func_node = Node(
                    id=func_id,
                    type=NodeType.FUNCTION,
                    label=node.name,
                    path=self.file_path,
                    last_modified=mtime,
                    metadata={
                        "line": node.lineno,
                        "args": [a.arg for a in node.args.args],
                        "is_async": isinstance(node, ast.AsyncFunctionDef),
                    },
                )
                nodes.append(func_node)
                edges.append(Edge(
                    source=module_node.id,
                    target=func_id,
                    type=EdgeType.DESCRIBES,
                    weight=0.5,
                ))

        # API endpoints → узлы API_ENDPOINT
        for pattern in self.ENDPOINT_PATTERNS:
            for match in pattern.finditer(source):
                path = match.group(1)
                endpoint_id = f"api:{path}"
                endpoint_node = Node(
                    id=endpoint_id,
                    type=NodeType.API_ENDPOINT,
                    label=path,
                    path=self.file_path,
                    last_modified=mtime,
                    metadata={"line": source[:match.start()].count("\n") + 1},
                )
                nodes.append(endpoint_node)
                edges.append(Edge(
                    source=module_node.id,
                    target=endpoint_id,
                    type=EdgeType.DESCRIBES,
                    weight=1.0,
                ))

        return nodes, edges

    def _resolve_import(self, import_name: str) -> Optional[str]:
        """Резолвит имя импорта в каноническое имя модуля проекта."""
        # Фильтруем внешние зависимости
        external_prefixes = (
            "fastapi", "pydantic", "sqlalchemy", "httpx", "aiohttp",
            "aiogram", "click", "jinja2", "networkx", "pytest",
            "numpy", "pandas", "requests", "flask", "django",
            "starlette", "uvicorn", "typing", "abc", "collections",
            "dataclasses", "pathlib", "datetime", "json", "re",
            "os", "sys", "subprocess", "tempfile", "shutil",
            "functools", "itertools", "hashlib", "secrets",
            "logging", "argparse", "configparser", "io",
        )
        if any(import_name == p or import_name.startswith(p + ".") for p in external_prefixes):
            return None

        # Проверяем, есть ли такой модуль в проекте
        parts = import_name.split(".")
        for i in range(len(parts), 0, -1):
            candidate = ".".join(parts[:i])
            # Проверяем как файл
            for base in [self.root / "projects", self.root / "shared", self.root / "scripts"]:
                if (base / Path(*parts[:i])).with_suffix(".py").exists():
                    return candidate
                if (base / Path(*parts[:i]) / "__init__.py").exists():
                    return candidate
        return None


class MarkdownParser:
    """Парсер Markdown-документов: извлекает ссылки, упоминания кода, заголовки."""

    # Паттерн для обнаружения ссылок на код
    CODE_REF_PATTERNS = [
        re.compile(r'`([a-zA-Z_][\w./]+\.py)`'),              # `module/file.py`
        re.compile(r'`([a-zA-Z_][\w.]+\.[a-zA-Z_]\w*)`'),      # `module.function`
        re.compile(r'\[.*?\]\(([\w./]+\.py)\)')               # [link](file.py)
    ]

    # Паттерн для обнаружения ссылок на другие документы
    DOC_REF_PATTERNS = [
        re.compile(r'\[.*?\]\(([\w./-]+\.md)\)'),              # [link](doc.md)
        re.compile(r'\[.*?\]\(([\w./-]+/README\.md)\)'),       # [link](dir/README.md)
    ]

    # Паттерн для обнаружения упоминаний API endpoints
    API_REF_PATTERN = re.compile(r'(GET|POST|PUT|DELETE|PATCH)\s+(/[\w/{}-]+)')

    def __init__(self, file_path: Path, root: Path):
        self.file_path = file_path
        self.root = root

    def parse(self) -> tuple[list[Node], list[Edge]]:
        """Парсит Markdown-файл и возвращает узлы + рёбра."""
        nodes: list[Node] = []
        edges: list[Edge] = []

        try:
            source = self.file_path.read_text(encoding="utf-8", errors="replace")
        except (UnicodeDecodeError, OSError):
            return nodes, edges

        mtime = self.file_path.stat().st_mtime
        doc_id = self._doc_id()

        # Определяем тип документа
        doc_type = self._classify_doc()

        doc_node = Node(
            id=doc_id,
            type=doc_type,
            label=self.file_path.stem,
            path=self.file_path,
            last_modified=mtime,
            metadata={
                "lines": len(source.splitlines()),
                "title": self._extract_title(source),
                "doc_type": doc_type.value,
            },
        )
        nodes.append(doc_node)

        # Ссылки на код → рёбра REFERENCES
        for pattern in self.CODE_REF_PATTERNS:
            for match in pattern.finditer(source):
                ref = match.group(1)
                target_id = self._resolve_code_ref(ref)
                if target_id:
                    edges.append(Edge(
                        source=doc_id,
                        target=target_id,
                        type=EdgeType.REFERENCES,
                        weight=1.0,
                    ))

        # Ссылки на другие документы → рёбра MENTIONS
        for pattern in self.DOC_REF_PATTERNS:
            for match in pattern.finditer(source):
                ref = match.group(1)
                target_id = self._resolve_doc_ref(ref)
                if target_id and target_id != doc_id:
                    edges.append(Edge(
                        source=doc_id,
                        target=target_id,
                        type=EdgeType.MENTIONS,
                        weight=0.8,
                    ))

        # Упоминания API endpoints → рёбра REFERENCES
        for match in self.API_REF_PATTERN.finditer(source):
            method, path = match.groups()
            endpoint_id = f"api:{path}"
            edges.append(Edge(
                source=doc_id,
                target=endpoint_id,
                type=EdgeType.REFERENCES,
                weight=1.0,
                metadata={"method": method},
            ))

        # Если документ описывает конкретный модуль → ребро DESCRIBES
        describes_target = self._detect_describes_target(source)
        if describes_target:
            edges.append(Edge(
                source=doc_id,
                target=describes_target,
                type=EdgeType.DESCRIBES,
                weight=1.5,
            ))

        return nodes, edges

    def _doc_id(self) -> str:
        try:
            rel = self.file_path.relative_to(self.root)
        except ValueError:
            return f"doc:{self.file_path}"
        return f"doc:{rel}"

    def _classify_doc(self) -> NodeType:
        """Классифицирует тип документа по пути."""
        path_str = str(self.file_path)
        if "/adr/" in path_str or "/ADR" in path_str:
            return NodeType.DOCUMENT
        if "/specs/" in path_str or "/spec" in path_str:
            return NodeType.DOCUMENT
        if "/docs/" in path_str:
            return NodeType.DOCUMENT
        if self.file_path.name == "README.md":
            return NodeType.DOCUMENT
        if self.file_path.name == "SKILL.md":
            return NodeType.SKILL
        return NodeType.DOCUMENT

    def _extract_title(self, source: str) -> str:
        """Извлекает заголовок документа (первый # heading)."""
        for line in source.splitlines():
            if line.startswith("# "):
                return line[2:].strip()
        return self.file_path.stem

    def _resolve_code_ref(self, ref: str) -> Optional[str]:
        """Резолвит ссылку на код в ID узла."""
        if ref.endswith(".py"):
            # Это модуль
            return f"module:{ref.replace('/', '.').replace('.py', '')}"
        elif "." in ref:
            # Это функция: module.function
            return f"function:{ref}"
        return None

    def _resolve_doc_ref(self, ref: str) -> Optional[str]:
        """Резолвит ссылку на документ в ID узла."""
        if ref.startswith("/"):
            return f"doc:{ref.lstrip('/')}"
        # Относительный путь — резолвим относительно текущего документа
        try:
            resolved = (self.file_path.parent / ref).resolve()
            rel = resolved.relative_to(self.root)
            return f"doc:{rel}"
        except (ValueError, RuntimeError):
            return f"doc:{ref}"

    def _detect_describes_target(self, source: str) -> Optional[str]:
        """Определяет, описывает ли документ конкретный модуль/компонент."""
        # Ищем frontmatter с полем 'module' или 'component'
        frontmatter_match = re.match(r'^---\s*\n(.*?)\n---', source, re.DOTALL)
        if frontmatter_match:
            fm = frontmatter_match.group(1)
            module_match = re.search(r'(?:module|component|target):\s*(.+)', fm)
            if module_match:
                target = module_match.group(1).strip()
                if target.endswith(".py"):
                    return f"module:{target.replace('/', '.').replace('.py', '')}"
                return f"module:{target}"
        return None


class ConfigParser:
    """Парсер конфигурационных файлов: myrmex.json, settings.json, projects.json."""

    def __init__(self, file_path: Path, root: Path):
        self.file_path = file_path
        self.root = root

    def parse(self) -> tuple[list[Node], list[Edge]]:
        nodes: list[Node] = []
        edges: list[Edge] = []

        try:
            source = self.file_path.read_text(encoding="utf-8", errors="replace")
            mtime = self.file_path.stat().st_mtime
        except (OSError, UnicodeDecodeError):
            return nodes, edges

        try:
            data = json.loads(source)
        except json.JSONDecodeError:
            return nodes, edges

        try:
            rel = self.file_path.relative_to(self.root)
        except ValueError:
            rel = self.file_path

        config_id = f"config:{rel}"
        config_node = Node(
            id=config_id,
            type=NodeType.CONFIG,
            label=self.file_path.name,
            path=self.file_path,
            last_modified=mtime,
            metadata={"keys": list(data.keys()) if isinstance(data, dict) else []},
        )
        nodes.append(config_node)

        # Ищем ссылки на модули/проекты в конфигурации
        self._extract_refs(data, config_id, edges)

        return nodes, edges

    def _extract_refs(self, data: Any, config_id: str, edges: list[Edge], prefix: str = ""):
        """Рекурсивно извлекает ссылки из JSON-конфигурации."""
        if isinstance(data, dict):
            for key, value in data.items():
                if key in ("module", "entry", "main", "script", "handler"):
                    if isinstance(value, str) and (".py" in value or "/" in value):
                        target = value.replace("/", ".").replace(".py", "")
                        edges.append(Edge(
                            source=config_id,
                            target=f"module:{target}",
                            type=EdgeType.CONFIGURES,
                            weight=1.0,
                        ))
                self._extract_refs(value, config_id, edges, f"{prefix}.{key}")
        elif isinstance(data, list):
            for i, item in enumerate(data):
                self._extract_refs(item, config_id, edges, f"{prefix}[{i}]")


# ─── Строитель графа ─────────────────────────────────────────────────────────

class GraphBuilder:
    """Строит knowledge graph из файлов проекта."""

    # Игнорируемые директории
    IGNORE_DIRS = {
        ".git", "node_modules", "venv", "venv311", ".venv",
        "__pycache__", ".pytest_cache", ".mypy_cache",
        ".tox", "dist", "build", ".eggs", "*.egg-info",
        ".github", ".vale", ".qwen",
    }

    def __init__(self, root: Path):
        self.root = root
        self.graph = nx.DiGraph()
        self.nodes: dict[str, Node] = {}
        self.edges: list[Edge] = []

    def build(self) -> nx.DiGraph:
        """Строит полный граф знаний из проекта."""
        self._scan_files()
        self._compute_stale_scores()
        self._populate_networkx()
        return self.graph

    def _scan_files(self):
        """Сканирует файлы проекта и строит узлы + рёбра."""
        for file_path in self._iter_files():
            file_path = Path(file_path)
            suffix = file_path.suffix.lower()

            all_nodes: list[Node] = []
            all_edges: list[Edge] = []

            if suffix == ".py":
                parser = PythonParser(file_path, self.root)
                all_nodes, all_edges = parser.parse()
            elif suffix == ".md":
                parser = MarkdownParser(file_path, self.root)
                all_nodes, all_edges = parser.parse()
            elif suffix in (".json", ".yaml", ".yml", ".toml"):
                parser = ConfigParser(file_path, self.root)
                all_nodes, all_edges = parser.parse()

            for node in all_nodes:
                if node.id in self.nodes:
                    # Обновляем существующий узел (берём более свежий)
                    if node.last_modified and self.nodes[node.id].last_modified:
                        if node.last_modified > self.nodes[node.id].last_modified:
                            self.nodes[node.id] = node
                else:
                    self.nodes[node.id] = node

            self.edges.extend(all_edges)

    def _iter_files(self):
        """Итерирует по релевантным файлам проекта."""
        for dirpath, dirnames, filenames in os.walk(self.root):
            # Фильтруем игнорируемые директории
            dirnames[:] = [
                d for d in dirnames
                if d not in self.IGNORE_DIRS and not d.startswith(".")
            ]

            for filename in filenames:
                suffix = Path(filename).suffix.lower()
                if suffix in (".py", ".md", ".json", ".yaml", ".yml", ".toml"):
                    yield Path(dirpath) / filename

    def _compute_stale_scores(self):
        """Вычисляет stale score для каждого узла."""
        now = datetime.now(timezone.utc).timestamp()
        max_age_days = 90  # Документы старше 90 дней считаются потенциально устаревшими

        for node_id, node in self.nodes.items():
            if node.last_modified is None:
                node.stale_score = 0.5
                continue

            age_days = (now - node.last_modified) / 86400

            # Базовый stale score на основе возраста
            base_score = min(age_days / max_age_days, 1.0)

            # Проверяем, существуют ли ещё связанные узлы
            connected_targets = [
                e.target for e in self.edges if e.source == node_id
            ]
            missing_targets = sum(
                1 for t in connected_targets if t not in self.nodes
            )

            if connected_targets:
                missing_ratio = missing_targets / len(connected_targets)
            else:
                missing_ratio = 0.0

            # Итоговый stale score
            node.stale_score = min(base_score * 0.6 + missing_ratio * 0.4, 1.0)
            node.stale = node.stale_score > 0.5

    def _populate_networkx(self):
        """Заполняет networkx граф из узлов и рёбер."""
        for node_id, node in self.nodes.items():
            self.graph.add_node(node_id, **node.to_dict())

        for edge in self.edges:
            if edge.source in self.nodes and edge.target in self.nodes:
                self.graph.add_edge(
                    edge.source, edge.target,
                    **edge.to_dict(),
                )

    def save(self, output_path: Path):
        """Сохраняет граф в JSON."""
        data = {
            "metadata": {
                "generated_at": datetime.now(timezone.utc).isoformat(),
                "root": str(self.root),
                "total_nodes": len(self.nodes),
                "total_edges": len(self.edges),
            },
            "nodes": {nid: n.to_dict() for nid, n in self.nodes.items()},
            "edges": [e.to_dict() for e in self.edges],
        }
        output_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

    @staticmethod
    def load(input_path: Path) -> "GraphBuilder":
        """Загружает граф из JSON."""
        data = json.loads(input_path.read_text(encoding="utf-8"))
        builder = GraphBuilder(Path(data["metadata"]["root"]))
        for nid, ndata in data["nodes"].items():
            builder.nodes[nid] = Node.from_dict(ndata)
        for edata in data["edges"]:
            builder.edges.append(Edge.from_dict(edata))
        builder._populate_networkx()
        return builder


# ─── Анализатор графа ────────────────────────────────────────────────────────

class GraphAnalyzer:
    """Анализирует knowledge graph: PageRank, stale propagation, orphans."""

    def __init__(self, graph: nx.DiGraph):
        self.graph = graph

    def pagerank(self, alpha: float = 0.85) -> dict[str, float]:
        """Вычисляет PageRank для всех узлов графа."""
        if len(self.graph) == 0:
            return {}
        try:
            return nx.pagerank(self.graph, alpha=alpha)
        except nx.NetworkXError:
            return {n: 0.0 for n in self.graph.nodes}

    def find_orphans(self) -> list[Node]:
        """Находит «осиротевшие» документы — описывают несуществующий код."""
        orphans = []
        for node_id in self.graph.nodes:
            node_data = self.graph.nodes[node_id]
            if node_data.get("type") not in (NodeType.DOCUMENT.value, NodeType.SKILL.value):
                continue

            # Проверяем, все ли связанные узлы существуют
            successors = list(self.graph.successors(node_id))
            if not successors:
                orphans.append(Node.from_dict(node_data))
                continue

            # Проверяем, есть ли рёбра к несуществующим узлам (missing refs)
            missing_count = 0
            for succ_id in successors:
                edge_data = self.graph.edges.get((node_id, succ_id), {})
                if edge_data.get("type") == EdgeType.REFERENCES.value:
                    if not self.graph.nodes[succ_id].get("path"):
                        missing_count += 1

            if missing_count > 0:
                orphans.append(Node.from_dict(node_data))

        return orphans

    def stale_propagation(self, iterations: int = 3) -> dict[str, float]:
        """Распространяет stale score по графу: если код устарел → связанные документы тоже."""
        stale_scores: dict[str, float] = {}

        # Инициализация: берём stale_score из узлов
        for node_id in self.graph.nodes:
            node_data = self.graph.nodes[node_id]
            stale_scores[node_id] = node_data.get("stale_score", 0.0)

        # Итеративное распространение
        for _ in range(iterations):
            new_scores = dict(stale_scores)
            for node_id in self.graph.nodes:
                predecessors = list(self.graph.predecessors(node_id))
                if not predecessors:
                    continue

                # Средний stale score предков, взвешенный по весу рёбер
                total_weight = 0.0
                weighted_sum = 0.0
                for pred_id in predecessors:
                    edge_data = self.graph.edges.get((pred_id, node_id), {})
                    weight = edge_data.get("weight", 1.0)
                    weighted_sum += stale_scores.get(pred_id, 0.0) * weight
                    total_weight += weight

                if total_weight > 0:
                    propagated = weighted_sum / total_weight
                    # Смешиваем: 70% текущий score + 30% распространённый
                    new_scores[node_id] = stale_scores[node_id] * 0.7 + propagated * 0.3

            stale_scores = new_scores

        return stale_scores

    def connected_components(self) -> list[set[str]]:
        """Находит связные компоненты графа (для неориентированной версии)."""
        undirected = self.graph.to_undirected()
        return list(nx.connected_components(undirected))

    def stale_subgraphs(self) -> list[set[str]]:
        """Находит изолированные кластеры устаревших документов."""
        stale_nodes = {
            n for n in self.graph.nodes
            if self.graph.nodes[n].get("stale", False)
        }
        if not stale_nodes:
            return []

        # Подграф только из устаревших узлов
        stale_subgraph = self.graph.subgraph(stale_nodes).to_undirected()
        return list(nx.connected_components(stale_subgraph))

    def find_missing_refs(self) -> list[dict]:
        """Находит ссылки на несуществующие узлы (broken references)."""
        missing = []
        for edge in self.graph.edges:
            source_id, target_id = edge
            target_data = self.graph.nodes.get(target_id, {})
            target_path = target_data.get("path")

            if target_path and not Path(target_path).exists():
                source_data = self.graph.nodes.get(source_id, {})
                missing.append({
                    "source": source_id,
                    "source_label": source_data.get("label", source_id),
                    "target": target_id,
                    "target_label": target_data.get("label", target_id),
                    "edge_type": self.graph.edges[edge].get("type", "unknown"),
                })

        return missing

    def summary(self) -> dict:
        """Сводная статистика графа."""
        type_counts = defaultdict(int)
        for node_id in self.graph.nodes:
            node_type = self.graph.nodes[node_id].get("type", "unknown")
            type_counts[node_type] += 1

        stale_count = sum(
            1 for n in self.graph.nodes
            if self.graph.nodes[n].get("stale", False)
        )

        return {
            "total_nodes": self.graph.number_of_nodes(),
            "total_edges": self.graph.number_of_edges(),
            "node_types": dict(type_counts),
            "stale_nodes": stale_count,
            "orphan_docs": len(self.find_orphans()),
            "connected_components": len(self.connected_components()),
            "stale_subgraphs": len(self.stale_subgraphs()),
            "missing_refs": len(self.find_missing_refs()),
        }


# ─── Визуализация ────────────────────────────────────────────────────────────

class GraphVisualizer:
    """Визуализация knowledge graph: D3.js, Graphviz."""

    # Цвета для типов узлов
    NODE_COLORS = {
        NodeType.DOCUMENT.value: "#4A90D9",     # Синий
        NodeType.MODULE.value: "#7CB342",        # Зелёный
        NodeType.COMPONENT.value: "#FF8A65",     # Оранжевый
        NodeType.API_ENDPOINT.value: "#AB47BC",  # Фиолетовый
        NodeType.FUNCTION.value: "#26C6DA",      # Бирюзовый
        NodeType.CONFIG.value: "#FFD54F",        # Жёлтый
        NodeType.SKILL.value: "#EF5350",         # Красный
        NodeType.HOOK.value: "#78909C",          # Серый
    }

    # Цвета для stale узлов
    STALE_COLOR = "#D32F2F"

    @staticmethod
    def to_d3_json(graph: nx.DiGraph, stale_scores: Optional[dict] = None) -> dict:
        """Конвертирует граф в формат D3.js force-directed graph."""
        nodes = []
        for node_id in graph.nodes:
            node_data = graph.nodes[node_id]
            node_type = node_data.get("type", "unknown")
            is_stale = node_data.get("stale", False)

            color = GraphVisualizer.STALE_COLOR if is_stale else GraphVisualizer.NODE_COLORS.get(node_type, "#999")

            # Размер узла зависит от количества связей
            degree = graph.degree(node_id)
            size = max(5, min(20, degree * 2))

            nodes.append({
                "id": node_id,
                "label": node_data.get("label", node_id),
                "type": node_type,
                "color": color,
                "size": size,
                "stale": is_stale,
                "stale_score": stale_scores.get(node_id, node_data.get("stale_score", 0.0)) if stale_scores else node_data.get("stale_score", 0.0),
                "path": str(node_data.get("path", "")),
            })

        links = []
        for source, target, edge_data in graph.edges(data=True):
            links.append({
                "source": source,
                "target": target,
                "type": edge_data.get("type", "unknown"),
                "weight": edge_data.get("weight", 1.0),
            })

        return {"nodes": nodes, "links": links}

    @staticmethod
    def to_graphviz(graph: nx.Di.Graph, stale_scores: Optional[dict] = None) -> str:
        """Генерирует DOT-формат для Graphviz."""
        lines = ["digraph KnowledgeGraph {"]
        lines.append('    rankdir=LR;')
        lines.append('    node [shape=box, style="rounded,filled", fontname="Helvetica"];')
        lines.append('    edge [fontname="Helvetica", fontsize=10];')
        lines.append("")

        # Узлы
        for node_id in graph.nodes:
            node_data = graph.nodes[node_id]
            node_type = node_data.get("type", "unknown")
            is_stale = node_data.get("stale", False)
            label = node_data.get("label", node_id)

            color = GraphVisualizer.STALE_COLOR if is_stale else GraphVisualizer.NODE_COLORS.get(node_type, "#999")

            # Экранируем кавычки
            safe_id = node_id.replace('"', '\\"')
            safe_label = label.replace('"', '\\"')

            lines.append(f'    "{safe_id}" [label="{safe_label}", fillcolor="{color}"];')

        lines.append("")

        # Рёбра
        for source, target, edge_data in graph.edges(data=True):
            edge_type = edge_data.get("type", "unknown")
            weight = edge_data.get("weight", 1.0)
            safe_source = source.replace('"', '\\"')
            safe_target = target.replace('"', '\\"')

            style = "dashed" if edge_type == EdgeType.REFERENCES.value else "solid"
            lines.append(f'    "{safe_source}" -> "{safe_target}" [label="{edge_type}", style={style}, weight={weight}];')

        lines.append("}")
        return "\n".join(lines)

    @staticmethod
    def generate_d3_html(d3_data: dict, title: str = "Knowledge Graph") -> str:
        """Генерирует полную HTML-страницу с D3.js визуализацией."""
        json_data = json.dumps(d3_data, ensure_ascii=False)

        return f"""<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>{title}</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body {{ margin: 0; font-family: 'Segoe UI', sans-serif; background: #1a1a2e; }}
        #graph {{ width: 100vw; height: 100vh; }}
        .node {{ stroke: #fff; stroke-width: 1.5px; cursor: pointer; }}
        .node.stale {{ stroke: #ff0000; stroke-width: 3px; animation: pulse 2s infinite; }}
        .link {{ stroke: #444; stroke-opacity: 0.6; }}
        .link.references {{ stroke-dasharray: 5,5; }}
        .label {{ fill: #eee; font-size: 10px; pointer-events: none; }}
        #tooltip {{
            position: absolute; padding: 10px; background: rgba(0,0,0,0.85);
            color: #fff; border-radius: 6px; font-size: 12px; pointer-events: none;
            max-width: 300px; display: none; z-index: 1000;
        }}
        #legend {{
            position: absolute; top: 10px; right: 10px; background: rgba(0,0,0,0.7);
            color: #fff; padding: 15px; border-radius: 8px; font-size: 12px;
        }}
        #legend .item {{ display: flex; align-items: center; margin: 4px 0; }}
        #legend .color {{ width: 14px; height: 14px; border-radius: 50%; margin-right: 8px; }}
        #controls {{
            position: absolute; top: 10px; left: 10px; background: rgba(0,0,0,0.7);
            color: #fff; padding: 15px; border-radius: 8px; font-size: 12px;
        }}
        #controls button {{
            background: #4A90D9; color: #fff; border: none; padding: 6px 12px;
            border-radius: 4px; cursor: pointer; margin: 2px;
        }}
        #controls button:hover {{ background: #357ABD; }}
        #controls button.active {{ background: #EF5350; }}
        @keyframes pulse {{
            0% {{ stroke-width: 2px; }}
            50% {{ stroke-width: 5px; }}
            100% {{ stroke-width: 2px; }}
        }}
    </style>
</head>
<body>
    <div id="graph"></div>
    <div id="tooltip"></div>
    <div id="controls">
        <div><b>🔍 Фильтры</b></div>
        <button onclick="filterType('all')" id="btn-all" class="active">Все</button>
        <button onclick="filterType('document')" id="btn-document">Документы</button>
        <button onclick="filterType('module')" id="btn-module">Модули</button>
        <button onclick="filterType('api_endpoint')" id="btn-api_endpoint">API</button>
        <button onclick="filterType('stale')" id="btn-stale">⚠️ Устаревшие</button>
        <hr style="border-color: #444; margin: 8px 0;">
        <div>Узлов: <span id="node-count">0</span></div>
        <div>Рёбер: <span id="edge-count">0</span></div>
        <div>Устаревших: <span id="stale-count">0</span></div>
    </div>
    <div id="legend">
        <div><b>📋 Легенда</b></div>
        <div class="item"><div class="color" style="background:#4A90D9"></div>Документ</div>
        <div class="item"><div class="color" style="background:#7CB342"></div>Модуль</div>
        <div class="item"><div class="color" style="background:#FF8A65"></div>Компонент</div>
        <div class="item"><div class="color" style="background:#AB47BC"></div>API Endpoint</div>
        <div class="item"><div class="color" style="background:#26C6DA"></div>Функция</div>
        <div class="item"><div class="color" style="background:#FFD54F"></div>Конфиг</div>
        <div class="item"><div class="color" style="background:#EF5350"></div>Скилл</div>
        <div class="item"><div class="color" style="background:#D32F2F"></div>⚠️ Устарел</div>
    </div>

    <script>
        const data = {json_data};

        const svg = d3.select("#graph").append("svg")
            .attr("width", "100%")
            .attr("height", "100%")
            .call(d3.zoom().on("zoom", (event) => container.attr("transform", event.transform)));

        const container = svg.append("g");

        const tooltip = d3.select("#tooltip");

        // Статистика
        document.getElementById("node-count").textContent = data.nodes.length;
        document.getElementById("edge-count").textContent = data.links.length;
        document.getElementById("stale-count").textContent = data.nodes.filter(n => n.stale).length;

        const simulation = d3.forceSimulation(data.nodes)
            .force("link", d3.forceLink(data.links).id(d => d.id).distance(80))
            .force("charge", d3.forceManyBody().strength(-200))
            .force("center", d3.forceCenter(window.innerWidth / 2, window.innerHeight / 2))
            .force("collision", d3.forceCollide().radius(d => d.size + 5));

        const link = container.append("g")
            .selectAll("line")
            .data(data.links)
            .enter().append("line")
            .attr("class", d => "link " + d.type)
            .attr("stroke-width", d => Math.sqrt(d.weight) * 1.5);

        const node = container.append("g")
            .selectAll("circle")
            .data(data.nodes)
            .enter().append("circle")
            .attr("class", d => "node" + (d.stale ? " stale" : ""))
            .attr("r", d => d.size)
            .attr("fill", d => d.color)
            .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended))
            .on("mouseover", (event, d) => {{
                tooltip.style("display", "block")
                    .html(`<b>${{d.label}}</b><br/>
                           Тип: ${{d.type}}<br/>
                           ID: ${{d.id}}<br/>
                           Stale: ${{(d.stale_score * 100).toFixed(0)}}%<br/>
                           ${{d.path ? 'Путь: ' + d.path : ''}}`)
                    .style("left", (event.pageX + 15) + "px")
                    .style("top", (event.pageY - 10) + "px");
            }})
            .on("mouseout", () => tooltip.style("display", "none"));

        const label = container.append("g")
            .selectAll("text")
            .data(data.nodes)
            .enter().append("text")
            .attr("class", "label")
            .attr("dx", d => d.size + 3)
            .attr("dy", 4)
            .text(d => d.label.length > 25 ? d.label.slice(0, 25) + "…" : d.label);

        simulation.on("tick", () => {{
            link.attr("x1", d => d.source.x).attr("y1", d => d.source.y)
                .attr("x2", d => d.target.x).attr("y2", d => d.target.y);
            node.attr("cx", d => d.x).attr("cy", d => d.y);
            label.attr("x", d => d.x).attr("y", d => d.y);
        }});

        function dragstarted(event, d) {{
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x; d.fy = d.y;
        }}
        function dragged(event, d) {{
            d.fx = event.x; d.fy = event.y;
        }}
        function dragended(event, d) {{
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null; d.fy = null;
        }}

        // Фильтрация
        function filterType(type) {{
            document.querySelectorAll("#controls button").forEach(b => b.classList.remove("active"));
            document.getElementById("btn-" + type).classList.add("active");

            if (type === "all") {{
                node.style("opacity", 1); link.style("opacity", 0.6); label.style("opacity", 1);
            }} else if (type === "stale") {{
                node.style("opacity", d => d.stale ? 1 : 0.1);
                link.style("opacity", 0.1);
                label.style("opacity", d => d.stale ? 1 : 0.1);
            }} else {{
                node.style("opacity", d => d.type === type ? 1 : 0.1);
                link.style("opacity", 0.1);
                label.style("opacity", d => d.type === type ? 1 : 0.1);
            }}
        }}
    </script>
</body>
</html>"""


# ─── CLI ─────────────────────────────────────────────────────────────────────

def format_table(headers: list[str], rows: list[list[str]]) -> str:
    """Форматирует данные в ASCII-таблицу."""
    if not rows:
        return "  (нет данных)"

    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            if i < len(col_widths):
                col_widths[i] = max(col_widths[i], len(str(cell)))

    separator = "+" + "+".join("-" * (w + 2) for w in col_widths) + "+"
    header_row = "|" + "|".join(f" {h:<{col_widths[i]}} " for i, h in enumerate(headers)) + "|"

    lines = [separator, header_row, separator]
    for row in rows:
        lines.append("|" + "|".join(f" {str(cell):<{col_widths[i]}} " for i, cell in enumerate(row)) + "|")
    lines.append(separator)

    return "\n".join(lines)


def cmd_build(root: str, output: str):
    """Команда: построить граф."""
    root_path = Path(root).resolve()
    output_path = Path(output).resolve()

    if not root_path.exists():
        print(f"❌ Путь не существует: {root_path}", file=sys.stderr)
        sys.exit(1)

    print(f"🔨 Строю knowledge graph для: {root_path}")
    builder = GraphBuilder(root_path)
    graph = builder.build()
    builder.save(output_path)

    analyzer = GraphAnalyzer(graph)
    summary = analyzer.summary()

    print(f"\n✅ Граф построен и сохранён: {output_path}")
    print(f"\n📊 Статистика:")
    print(f"   Узлов: {summary['total_nodes']}")
    print(f"   Рёбер: {summary['total_edges']}")
    print(f"   Устаревших узлов: {summary['stale_nodes']}")
    print(f"   Осиротевших документов: {summary['orphan_docs']}")
    print(f"   Связных компонент: {summary['connected_components']}")
    print(f"   Кластеров устаревших: {summary['stale_subgraphs']}")
    print(f"   Битых ссылок: {summary['missing_refs']}")

    print(f"\n   По типам:")
    for ntype, count in sorted(summary['node_types'].items(), key=lambda x: -x[1]):
        print(f"     {ntype}: {count}")


def cmd_graph(graph_path: str, stale: bool = False, fmt: str = "table", output: Optional[str] = None):
    """Команда: показать граф / устаревшие подграфы."""
    graph_path = Path(graph_path).resolve()
    if not graph_path.exists():
        print(f"❌ Файл графа не найден: {graph_path}", file=sys.stderr)
        sys.exit(1)

    builder = GraphBuilder.load(graph_path)
    graph = builder.graph
    analyzer = GraphAnalyzer(graph)

    if stale:
        print("🔍 Анализ устаревших подграфов...\n")

        # Stale propagation
        stale_scores = analyzer.stale_propagation()

        # Устаревшие узлы
        stale_nodes = {
            n: graph.nodes[n]
            for n in graph.nodes
            if stale_scores.get(n, 0) > 0.4
        }

        if not stale_nodes:
            print("✅ Устаревших узлов не обнаружено.")
            return

        # Топ устаревших
        sorted_stale = sorted(stale_nodes.items(), key=lambda x: -stale_scores.get(x[0], 0))

        if fmt == "table":
            print("📋 Устаревшие узлы (по stale score):\n")
            rows = []
            for node_id, node_data in sorted_stale[:30]:
                score = stale_scores.get(node_id, 0)
                stale_bar = "█" * int(score * 10) + "░" * (10 - int(score * 10))
                rows.append([
                    node_data.get("label", node_id)[:40],
                    node_data.get("type", "?"),
                    f"{stale_bar} {score:.0%}",
                    str(node_data.get("path", ""))[:50],
                ])

            print(format_table(["Узел", "Тип", "Stale", "Путь"], rows))

        # Stale subgraphs
        stale_components = analyzer.stale_subgraphs()
        if stale_components:
            print(f"\n📦 Кластеры устаревших документов ({len(stale_components)}):\n")
            for i, component in enumerate(stale_components, 1):
                print(f"  Кластер {i} ({len(component)} узлов):")
                for node_id in sorted(component):
                    node_data = graph.nodes[node_id]
                    score = stale_scores.get(node_id, 0)
                    print(f"    • {node_data.get('label', node_id)} ({score:.0%})")
                print()

        # Orphans
        orphans = analyzer.find_orphans()
        if orphans:
            print(f"\n👻 Осиротевшие документы ({len(orphans)}):\n")
            for orphan in orphans:
                print(f"  ⚠️  {orphan.label} ({orphan.id})")
                print(f"     Путь: {orphan.path}")
                print()

        # Missing refs
        missing = analyzer.find_missing_refs()
        if missing:
            print(f"\n💔 Битые ссылки ({len(missing)}):\n")
            for m in missing[:20]:
                print(f"  {m['source_label']} → {m['target_label']} [{m['edge_type']}]")
            print()

        # D3.js визуализация
        if fmt == "d3":
            d3_data = GraphVisualizer.to_d3_json(graph, stale_scores)
            html = GraphVisualizer.generate_d3_html(d3_data)
            if output:
                Path(output).write_text(html, encoding="utf-8")
                print(f"🌐 D3.js визуализация сохранена: {output}")
            else:
                print(html)

        # Graphviz
        if fmt == "graphviz":
            dot = GraphVisualizer.to_graphviz(graph, stale_scores)
            if output:
                Path(output).write_text(dot, encoding="utf-8")
                print(f"📊 Graphviz DOT сохранён: {output}")
            else:
                print(dot)

    else:
        # Общая статистика
        summary = analyzer.summary()
        print(f"📊 Knowledge Graph: {graph_path}")
        print(f"   Узлов: {summary['total_nodes']}")
        print(f"   Рёбер: {summary['total_edges']}")
        print(f"   Устаревших: {summary['stale_nodes']}")
        print(f"   Осиротевших: {summary['orphan_docs']}")
        print(f"   Компонент: {summary['connected_components']}")


def cmd_analyze(graph_path: str, metrics: str = "all"):
    """Команда: анализ графа с метриками."""
    graph_path = Path(graph_path).resolve()
    if not graph_path.exists():
        print(f"❌ Файл графа не найден: {graph_path}", file=sys.stderr)
        sys.exit(1)

    builder = GraphBuilder.load(graph_path)
    graph = builder.graph
    analyzer = GraphAnalyzer(graph)

    metric_list = [m.strip() for m in metrics.split(",")]

    if "all" in metric_list or "pagerank" in metric_list:
        print("\n📈 PageRank (топ-20):\n")
        pr = analyzer.pagerank()
        sorted_pr = sorted(pr.items(), key=lambda x: -x[1])
        rows = []
        for node_id, score in sorted_pr[:20]:
            node_data = graph.nodes[node_id]
            bar = "█" * int(score * 100)
            rows.append([
                node_data.get("label", node_id)[:40],
                node_data.get("type", "?"),
                f"{bar} {score:.4f}",
            ])
        print(format_table(["Узел", "Тип", "PageRank"], rows))

    if "all" in metric_list or "components" in metric_list:
        print("\n🔗 Связные компоненты:\n")
        components = analyzer.connected_components()
        for i, comp in enumerate(sorted(components, key=len, reverse=True)[:10], 1):
            types = defaultdict(int)
            for node_id in comp:
                ntype = graph.nodes[node_id].get("type", "unknown")
                types[ntype] += 1
            type_str = ", ".join(f"{t}: {c}" for t, c in sorted(types.items()))
            print(f"  Компонента {i}: {len(comp)} узлов ({type_str})")

    if "all" in metric_list or "orphans" in metric_list:
        print("\n👻 Осиротевшие документы:\n")
        orphans = analyzer.find_orphans()
        if not orphans:
            print("  (нет)")
        for orphan in orphans:
            print(f"  • {orphan.label} [{orphan.type.value}]")
            print(f"    {orphan.path}")

    if "all" in metric_list or "stale" in metric_list:
        print("\n⚠️  Stale propagation:\n")
        stale_scores = analyzer.stale_propagation()
        sorted_stale = sorted(stale_scores.items(), key=lambda x: -x[1])
        rows = []
        for node_id, score in sorted_stale[:20]:
            if score < 0.1:
                break
            node_data = graph.nodes[node_id]
            bar = "█" * int(score * 20) + "░" * (20 - int(score * 20))
            rows.append([
                node_data.get("label", node_id)[:40],
                node_data.get("type", "?"),
                f"{bar} {score:.1%}",
            ])
        print(format_table(["Узел", "Тип", "Stale Score"], rows))


def cmd_export(graph_path: str, fmt: str = "d3", output: str = "graph.html"):
    """Команда: экспорт графа в различных форматах."""
    graph_path = Path(graph_path).resolve()
    if not graph_path.exists():
        print(f"❌ Файл графа не найден: {graph_path}", file=sys.stderr)
        sys.exit(1)

    builder = GraphBuilder.load(graph_path)
    graph = builder.graph
    analyzer = GraphAnalyzer(graph)
    stale_scores = analyzer.stale_propagation()

    output_path = Path(output).resolve()

    if fmt == "d3":
        d3_data = GraphVisualizer.to_d3_json(graph, stale_scores)
        html = GraphVisualizer.generate_d3_html(d3_data)
        output_path.write_text(html, encoding="utf-8")
        print(f"🌐 D3.js визуализация: {output_path}")

    elif fmt == "graphviz":
        dot = GraphVisualizer.to_graphviz(graph, stale_scores)
        output_path.write_text(dot, encoding="utf-8")
        print(f"📊 Graphviz DOT: {output_path}")
        print(f"   Для рендера: dot -Tpng {output_path} -o graph.png")

    elif fmt == "json":
        d3_data = GraphVisualizer.to_d3_json(graph, stale_scores)
        output_path.write_text(json.dumps(d3_data, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"📄 JSON: {output_path}")

    else:
        print(f"❌ Неизвестный формат: {fmt}", file=sys.stderr)
        sys.exit(1)


# ─── CLI entry point ─────────────────────────────────────────────────────────

def main():
    """CLI entry point без внешних зависимостей (кроме networkx)."""
    if len(sys.argv) < 2:
        _print_help()
        sys.exit(0)

    command = sys.argv[1]

    if command == "build":
        root = _get_arg("--root", default="/root/LabDoctorM")
        output = _get_arg("--output", default="/tmp/dmaidoc_graph.json")
        cmd_build(root, output)

    elif command == "graph":
        graph_path = _get_arg("--graph", default="/tmp/dmaidoc_graph.json")
        stale = "--stale" in sys.argv
        fmt = _get_arg("--format", default="table")
        output = _get_arg("--output", default=None)
        cmd_graph(graph_path, stale=stale, fmt=fmt, output=output)

    elif command == "analyze":
        graph_path = _get_arg("--graph", default="/tmp/dmaidoc_graph.json")
        metrics = _get_arg("--metrics", default="all")
        cmd_analyze(graph_path, metrics)

    elif command == "export":
        graph_path = _get_arg("--graph", default="/tmp/dmaidoc_graph.json")
        fmt = _get_arg("--format", default="d3")
        output = _get_arg("--output", default="/tmp/graph.html")
        cmd_export(graph_path, fmt, output)

    elif command in ("help", "--help", "-h"):
        _print_help()

    else:
        print(f"❌ Неизвестная команда: {command}", file=sys.stderr)
        _print_help()
        sys.exit(1)


def _get_arg(flag: str, default: Optional[str] = None) -> str:
    """Извлекает значение аргумента из командной строки."""
    for i, arg in enumerate(sys.argv):
        if arg == flag and i + 1 < len(sys.argv):
            return sys.argv[i + 1]
        if arg.startswith(flag + "="):
            return arg[len(flag) + 1:]
    if default is not None:
        return default
    print(f"❌ Отсутствует обязательный аргумент: {flag}", file=sys.stderr)
    sys.exit(1)


def _print_help():
    print("""
📊 dmaidoc-graph — Knowledge Graph для документации

Использование:
    python -m dmaidoc_graph build   [--root PATH] [--output PATH]
    python -m dmaidoc_graph graph   [--graph PATH] [--stale] [--format table|d3|graphviz] [--output PATH]
    python -m dmaidoc_graph analyze [--graph PATH] [--metrics pagerank,components,orphans,stale]
    python -m dmaidoc_graph export  [--graph PATH] [--format d3|graphviz|json] [--output PATH]

Команды:
    build    Построить граф из файлов проекта
    graph    Показать граф / устаревшие подграфы
    analyze  Анализ: PageRank, компоненты, осиротевшие, stale propagation
    export   Экспорт в D3.js / Graphviz / JSON

Примеры:
    python -m dmaidoc_graph build --root /root/LabDoctorM
    python -m dmaidoc_graph graph --stale --format table
    python -m dmaidoc_graph graph --stale --format d3 --output /tmp/graph.html
    python -m dmaidoc_graph analyze --metrics pagerank,orphans
    python -m dmaidoc_graph export --format graphviz --output /tmp/graph.dot
""")


if __name__ == "__main__":
    main()
