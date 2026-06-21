"""
Тесты структуры проектов и спеков.
Проверяет: PROJECT.md, SPECS, валидацию frontmatter, целостность ссылок.
"""
import os
import re
import yaml
import pytest

PROJECTS_ROOT = "/root/LabDoctorM/projects"
SPECS_ROOT = "/root/LabDoctorM/specs"

REQUIRED_PROJECT_FIELDS = ["id", "name", "owner", "status", "priority", "path"]
REQUIRED_SPEC_FIELDS = ["id", "title", "status", "priority", "weight", "assignee"]

VALID_STATUSES = ["planning", "active", "production", "maintenance", "frozen", "dead", "done", "pending", "blocked"]
VALID_PRIORITIES = ["critical", "high", "medium", "low"]
VALID_OWNERS = ["ant", "bestia", "kot", "raven", "streik", "owl", "unassigned"]


def parse_frontmatter(filepath):
    """Парсит YAML frontmatter из .md файла."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return None
    return yaml.safe_load(match.group(1))


def discover_projects():
    """Находит все PROJECT.md в projects/."""
    projects = []
    for root, dirs, files in os.walk(PROJECTS_ROOT):
        # Пропускаем cwd лаборантов (они не содержат SPECS/)
        if "PROJECT.md" in files:
            projects.append(os.path.join(root, "PROJECT.md"))
    return projects


def discover_specs():
    """Находит все BL-*.md в projects/*/SPECS/ и specs/unassigned/."""
    specs = []
    # Спеки в проектах
    for root, dirs, files in os.walk(PROJECTS_ROOT):
        if "SPECS" in root:
            for f in files:
                if f.startswith("BL-") and f.endswith(".md"):
                    specs.append(os.path.join(root, f))
    # Неназначенные спеки
    unassigned = os.path.join(SPECS_ROOT, "unassigned")
    if os.path.exists(unassigned):
        for f in os.listdir(unassigned):
            if f.startswith("BL-") and f.endswith(".md"):
                specs.append(os.path.join(unassigned, f))
    return specs


class TestProjectStructure:
    """Тесты структуры проектов."""

    def test_all_projects_have_project_md(self):
        """Каждый проект имеет PROJECT.md."""
        projects = discover_projects()
        assert len(projects) >= 15, f"Ожидалось >= 15 проектов, найдено {len(projects)}"

    def test_project_md_has_valid_frontmatter(self):
        """Каждый PROJECT.md имеет валидный YAML frontmatter."""
        projects = discover_projects()
        for p in projects:
            fm = parse_frontmatter(p)
            assert fm is not None, f"{p}: нет frontmatter"
            assert isinstance(fm, dict), f"{p}: frontmatter не dict"

    def test_project_required_fields(self):
        """Все обязательные поля заполнены в PROJECT.md."""
        projects = discover_projects()
        for p in projects:
            fm = parse_frontmatter(p)
            for field in REQUIRED_PROJECT_FIELDS:
                assert field in fm, f"{p}: отсутствует поле '{field}'"
                assert fm[field] is not None, f"{p}: поле '{field}' = None"
                assert str(fm[field]).strip() != "", f"{p}: поле '{field}' пустое"

    def test_project_status_valid(self):
        """Статус проекта — допустимое значение."""
        projects = discover_projects()
        for p in projects:
            fm = parse_frontmatter(p)
            status = fm.get("status", "")
            assert status in VALID_STATUSES, f"{p}: невалидный статус '{status}'"

    def test_project_priority_valid(self):
        """Приоритет проекта — допустимое значение."""
        projects = discover_projects()
        for p in projects:
            fm = parse_frontmatter(p)
            priority = fm.get("priority", "")
            assert priority in VALID_PRIORITIES, f"{p}: невалидный приоритет '{priority}'"

    def test_project_owner_valid(self):
        """Владелец проекта — допустимое значение."""
        projects = discover_projects()
        for p in projects:
            fm = parse_frontmatter(p)
            owner = fm.get("owner", "")
            assert owner in VALID_OWNERS, f"{p}: невалидный владелец '{owner}'"

    def test_project_path_exists(self):
        """Путь проекта существует на диске."""
        projects = discover_projects()
        for p in projects:
            fm = parse_frontmatter(p)
            path = fm.get("path", "")
            assert os.path.exists(path), f"{p}: path '{path}' не существует"

    def test_project_id_unique(self):
        """ID проектов уникальны."""
        projects = discover_projects()
        ids = []
        for p in projects:
            fm = parse_frontmatter(p)
            pid = fm.get("id", "")
            assert pid not in ids, f"{p}: дубль ID '{pid}'"
            ids.append(pid)

    def test_project_has_readme(self):
        """Каждый проект имеет README.md (кроме demo-подпапок)."""
        projects = discover_projects()
        for p in projects:
            project_dir = os.path.dirname(p)
            # Пропускаем demo-подпапки
            if project_dir.endswith("/demo"):
                continue
            readme = os.path.join(project_dir, "README.md")
            assert os.path.exists(readme), f"{project_dir}: нет README.md"

    def test_project_has_specs_or_is_small(self):
        """Каждый проект имеет SPECS/ или это маленький проект."""
        projects = discover_projects()
        for p in projects:
            project_dir = os.path.dirname(p)
            specs_dir = os.path.join(project_dir, "SPECS")
            has_specs = os.path.isdir(specs_dir)
            # Маленькие проекты могут не иметь SPECS
            if not has_specs:
                # Проверяем что это не production-проект
                fm = parse_frontmatter(p)
                status = fm.get("status", "")
                assert status != "production", f"{project_dir}: production без SPECS/"


class TestSpecsStructure:
    """Тесты структуры спеков."""

    def test_all_specs_have_valid_frontmatter(self):
        """Каждый спек имеет валидный YAML frontmatter."""
        specs = discover_specs()
        for s in specs:
            fm = parse_frontmatter(s)
            assert fm is not None, f"{s}: нет frontmatter"

    def test_spec_required_fields(self):
        """Все обязательные поля заполнены в спеке."""
        specs = discover_specs()
        for s in specs:
            fm = parse_frontmatter(s)
            for field in REQUIRED_SPEC_FIELDS:
                assert field in fm, f"{s}: отсутствует поле '{field}'"

    def test_spec_status_valid(self):
        """Статус спека — допустимое значение."""
        specs = discover_specs()
        for s in specs:
            fm = parse_frontmatter(s)
            status = fm.get("status", "")
            assert status in VALID_STATUSES, f"{s}: невалидный статус '{status}'"

    def test_spec_priority_valid(self):
        """Приоритет спека — допустимое значение."""
        specs = discover_specs()
        for s in specs:
            fm = parse_frontmatter(s)
            priority = fm.get("priority", "")
            assert priority in VALID_PRIORITIES, f"{s}: невалидный приоритет '{priority}'"

    def test_spec_weight_in_range(self):
        """Вес спека — от 1 до 5."""
        specs = discover_specs()
        for s in specs:
            fm = parse_frontmatter(s)
            weight = fm.get("weight", 0)
            assert 1 <= weight <= 5, f"{s}: вес {weight} вне диапазона 1-5"

    def test_spec_assignee_valid(self):
        """Исполнитель спека — допустимое значение."""
        specs = discover_specs()
        for s in specs:
            fm = parse_frontmatter(s)
            assignee = fm.get("assignee", "")
            assert assignee in VALID_OWNERS, f"{s}: невалидный исполнитель '{assignee}'"

    def test_spec_id_unique(self):
        """ID спеков уникальны."""
        specs = discover_specs()
        ids = []
        for s in specs:
            fm = parse_frontmatter(s)
            sid = fm.get("id", "")
            assert sid not in ids, f"{s}: дубль ID '{sid}'"
            ids.append(sid)

    def test_spec_project_exists(self):
        """Проект, указанный в спеке, существует."""
        specs = discover_specs()
        project_ids = set()
        for p in discover_projects():
            fm = parse_frontmatter(p)
            project_ids.add(fm.get("id", ""))

        for s in specs:
            fm = parse_frontmatter(s)
            project_id = fm.get("project_id", "")
            if project_id:
                assert project_id in project_ids, f"{s}: проект '{project_id}' не найден"


class TestNoOrphanFiles:
    """Тесты на отсутствие мусора."""

    def test_no_old_specs_in_root(self):
        """В корне specs/ нет старых BL-файлов (все распределены)."""
        old_specs = []
        for f in os.listdir(SPECS_ROOT):
            if f.startswith("BL-") and f.endswith(".md"):
                old_specs.append(f)
        assert len(old_specs) == 0, f"Старые спеки в specs/: {old_specs}"

    def test_no_empty_spec_folders(self):
        """Нет пустых папок SPECS/ (кроме только что созданных)."""
        # Проекты которые пока без спеков — это нормально
        ALLOWED_EMPTY_SPECS = [
            "llm-evangelist",  # только создана
        ]
        for root, dirs, files in os.walk(PROJECTS_ROOT):
            if root.endswith("SPECS"):
                bl_files = [f for f in files if f.startswith("BL-") and f.endswith(".md")]
                if len(bl_files) == 0:
                    # Проверяем что это разрешённый пустой SPECS
                    allowed = any(a in root for a in ALLOWED_EMPTY_SPECS)
                    assert allowed, f"{root}: пустая папка SPECS/"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
