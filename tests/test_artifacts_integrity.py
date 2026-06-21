"""
Тесты целостности артефактов миграции.
Проверяет: наличие файлов, frontmatter, ссылки, актуальность данных.
"""
import os
import re
import json
import pytest
import yaml

LAB_ROOT = "/root/LabDoctorM"
INSIGHTS_DIR = os.path.join(LAB_ROOT, "docs/insights")
PROCESSES_DIR = os.path.join(LAB_ROOT, "docs/processes")
SCRIPTS_DIR = os.path.join(LAB_ROOT, "scripts")
AUTHORS_JSON = os.path.join(LAB_ROOT, ".qwen/git-authors.json")
WORKTREES_DIR = os.path.join(LAB_ROOT, ".worktrees")


def parse_frontmatter(filepath):
    """Парсит YAML frontmatter из .md файла."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return None
    return yaml.safe_load(match.group(1))


# ═══════════════════════════════════════════════════════════════
# 1. Тесты инсайтов
# ═══════════════════════════════════════════════════════════════

class TestInsights:
    """Тесты файлов инсайтов в docs/insights/."""

    REQUIRED_INSIGHT_FIELDS = ["name", "description", "type", "status", "verified"]

    @pytest.fixture
    def insight_files(self):
        """Список всех INSIGHT-файлов."""
        files = []
        for f in os.listdir(INSIGHTS_DIR):
            if f.startswith("INSIGHT-") and f.endswith(".md"):
                files.append(os.path.join(INSIGHTS_DIR, f))
        return files

    @pytest.fixture
    def insight_data(self, insight_files):
        """Парсит frontmatter всех инсайтов."""
        data = {}
        for filepath in insight_files:
            fm = parse_frontmatter(filepath)
            name = os.path.basename(filepath)
            data[name] = fm
        return data

    def test_insights_directory_exists(self):
        """Директория insights существует и не пуста."""
        assert os.path.isdir(INSIGHTS_DIR), f"Директория {INSIGHTS_DIR} не существует"
        files = [f for f in os.listdir(INSIGHTS_DIR) if f.endswith(".md")]
        assert len(files) > 0, "Нет .md файлов в insights/"

    def test_all_insights_have_frontmatter(self, insight_files):
        """Все инсайты имеют валидный frontmatter."""
        for filepath in insight_files:
            fm = parse_frontmatter(filepath)
            assert fm is not None, f"{filepath}: отсутствует frontmatter"

    def test_insights_required_fields(self, insight_data):
        """Все инсайты содержат обязательные поля."""
        for name, fm in insight_data.items():
            for field in self.REQUIRED_INSIGHT_FIELDS:
                assert field in fm, f"{name}: отсутствует поле '{field}'"

    def test_insights_status_active(self, insight_data):
        """Все инсайты имеют статус active."""
        for name, fm in insight_data.items():
            assert fm.get("status") == "active", f"{name}: статус не 'active'"

    def test_insights_verified_date(self, insight_data):
        """Все инсайты имеют дату верификации."""
        for name, fm in insight_data.items():
            verified = fm.get("verified")
            assert verified is not None, f"{name}: отсутствует дата верификации"
            # Проверяем формат даты YYYY-MM-DD
            assert re.match(r"\d{4}-\d{2}-\d{2}", str(verified)), \
                f"{name}: некорректный формат даты верификации: {verified}"

    def test_insights_type_is_insight(self, insight_data):
        """Все инсайты имеют type='insight'."""
        for name, fm in insight_data.items():
            assert fm.get("type") == "insight", f"{name}: type не 'insight'"

    def test_insights_have_source(self, insight_data):
        """Все инсайты ссылаются на источник."""
        for name, fm in insight_data.items():
            assert "source" in fm, f"{name}: отсутствует поле 'source'"


# ═══════════════════════════════════════════════════════════════
# 2. Тесты процессов
# ═══════════════════════════════════════════════════════════════

class TestProcesses:
    """Тесты файлов процессов в docs/processes/."""

    REQUIRED_PROCESS_FIELDS = ["name", "description", "type", "status", "verified"]

    @pytest.fixture
    def process_files(self):
        """Список всех PROCESS-файлов."""
        files = []
        for f in os.listdir(PROCESSES_DIR):
            if f.startswith("PROTOCOL-") and f.endswith(".md"):
                files.append(os.path.join(PROCESSES_DIR, f))
        return files

    @pytest.fixture
    def process_data(self, process_files):
        """Парсит frontmatter всех процессов."""
        data = {}
        for filepath in process_files:
            fm = parse_frontmatter(filepath)
            name = os.path.basename(filepath)
            data[name] = fm
        return data

    def test_processes_directory_exists(self):
        """Директория processes существует."""
        assert os.path.isdir(PROCESSES_DIR), f"Директория {PROCESSES_DIR} не существует"

    def test_all_processes_have_frontmatter(self, process_files):
        """Все процессы имеют валидный frontmatter."""
        for filepath in process_files:
            fm = parse_frontmatter(filepath)
            assert fm is not None, f"{filepath}: отсутствует frontmatter"

    def test_processes_required_fields(self, process_data):
        """Все процессы содержат обязательные поля."""
        for name, fm in process_data.items():
            for field in self.REQUIRED_PROCESS_FIELDS:
                assert field in fm, f"{name}: отсутствует поле '{field}'"

    def test_processes_status_active(self, process_data):
        """Все процессы имеют статус active."""
        for name, fm in process_data.items():
            assert fm.get("status") == "active", f"{name}: статус не 'active'"

    def test_processes_type_is_process(self, process_data):
        """Все процессы имеют type='process'."""
        for name, fm in process_data.items():
            assert fm.get("type") == "process", f"{name}: type не 'process'"


# ═══════════════════════════════════════════════════════════════
# 3. Тесты git identity (lab-commit.sh + git-authors.json)
# ═══════════════════════════════════════════════════════════════

class TestGitIdentity:
    """Тесты git identity системы."""

    def test_git_authors_json_exists(self):
        """git-authors.json существует и валиден."""
        assert os.path.isfile(AUTHORS_JSON), f"{AUTHORS_JSON} не существует"
        with open(AUTHORS_JSON) as f:
            data = json.load(f)
        assert isinstance(data, dict), "git-authors.json — не JSON object"

    def test_git_authors_has_all_agents(self):
        """Все 8 агентов присутствуют в git-authors.json."""
        with open(AUTHORS_JSON) as f:
            data = json.load(f)
        expected_agents = [
            "antcat", "bestia", "dominika", "kotolizator",
            "mangust", "owl", "raven", "streikbrecher"
        ]
        for agent in expected_agents:
            assert agent in data, f"Агент '{agent}' отсутствует в git-authors.json"

    def test_git_authors_have_name_and_email(self):
        """Каждый агент имеет name и email."""
        with open(AUTHORS_JSON) as f:
            data = json.load(f)
        for agent, info in data.items():
            assert "name" in info, f"{agent}: отсутствует 'name'"
            assert "email" in info, f"{agent}: отсутствует 'email'"
            assert "@" in info["email"], f"{agent}: некорректный email"

    def test_lab_commit_script_exists(self):
        """lab-commit.sh существует и исполняем."""
        lab_commit = os.path.join(SCRIPTS_DIR, "lab-commit.sh")
        assert os.path.isfile(lab_commit), "lab-commit.sh не существует"
        assert os.access(lab_commit, os.X_OK), "lab-commit.sh не исполняем"

    def test_precommit_hook_exists(self):
        """pre-commit hook существует."""
        hook = os.path.join(LAB_ROOT, ".githooks/pre-commit")
        assert os.path.isfile(hook), "pre-commit hook не существует"
        assert os.access(hook, os.X_OK), "pre-commit hook не исполняем"


# ═══════════════════════════════════════════════════════════════
# 4. Тесты worktree изоляции
# ═══════════════════════════════════════════════════════════════

class TestWorktreeIsolation:
    """Тесты worktree изоляции агентов."""

    def test_worktrees_directory_exists(self):
        """Директория .worktrees существует."""
        assert os.path.isdir(WORKTREES_DIR), f"{WORKTREES_DIR} не существует"

    def test_agent_worktrees_exist(self):
        """Worktree для каждого агента существует."""
        expected_worktrees = ["antcat", "bestia", "kotolizator", "owl", "raven", "streikbrecher"]
        for wt in expected_worktrees:
            wt_path = os.path.join(WORKTREES_DIR, wt)
            assert os.path.isdir(wt_path), f"Worktree '{wt}' не существует: {wt_path}"

    def test_worktrees_have_git_config(self):
        """Каждый worktree имеет свой .git файл."""
        for wt in os.listdir(WORKTREES_DIR):
            wt_path = os.path.join(WORKTREES_DIR, wt)
            if os.path.isdir(wt_path):
                git_file = os.path.join(wt_path, ".git")
                assert os.path.isfile(git_file), f"Worktree '{wt}': отсутствует .git файл"


# ═══════════════════════════════════════════════════════════════
# 5. Тесты структуры проектов
# ═══════════════════════════════════════════════════════════════

class TestProjectStructure:
    """Тесты структуры проектов."""

    def test_projects_directory_exists(self):
        """Директория projects существует."""
        projects_dir = os.path.join(LAB_ROOT, "projects")
        assert os.path.isdir(projects_dir), "Директория projects/ не существует"

    def test_key_projects_exist(self):
        """Ключевые проекты существуют."""
        projects_dir = os.path.join(LAB_ROOT, "projects")
        key_projects = ["snablab", "autoexpert", "hype-pilot", "lab-playwright-expert", "zprr-tracker"]
        for project in key_projects:
            project_path = os.path.join(projects_dir, project)
            assert os.path.isdir(project_path), f"Проект '{project}' не существует"

    def test_docs_directory_structure(self):
        """Структура docs/ содержит ключевые директории."""
        docs_dir = os.path.join(LAB_ROOT, "docs")
        assert os.path.isdir(docs_dir), "Директория docs/ не существует"
        # insights и processes — новые директории
        assert os.path.isdir(os.path.join(docs_dir, "insights")), "docs/insights/ не существует"
        assert os.path.isdir(os.path.join(docs_dir, "processes")), "docs/processes/ не существует"


# ═══════════════════════════════════════════════════════════════
# 6. Тесты systemd timers
# ═══════════════════════════════════════════════════════════════

class TestSystemdTimers:
    """Тесты systemd timers (cron → systemd migration)."""

    def test_crontab_empty(self):
        """crontab пуст (миграция на systemd завершена)."""
        result = os.popen("crontab -l 2>/dev/null").read().strip()
        assert result == "" or result == "no crontab for root", \
            f"crontab не пуст: {result}"

    def test_systemd_timers_active(self):
        """Systemd timers активны."""
        result = os.popen("systemctl list-timers --no-pager 2>/dev/null | head -20").read()
        assert "timer" in result.lower() or "Timer" in result, \
            "Systemd timers не найдены"


# ═══════════════════════════════════════════════════════════════
# 7. Тесты Service Worker cache
# ═══════════════════════════════════════════════════════════════

class TestServiceWorkerCache:
    """Тесты Service Worker cache (snablab)."""

    def test_sw_js_exists(self):
        """sw.js существует в snablab."""
        sw_path = os.path.join(LAB_ROOT, "projects/snablab/frontend/public/sw.js")
        assert os.path.isfile(sw_path), "sw.js не существует"

    def test_sw_cache_name_defined(self):
        """CACHE_NAME определён в sw.js."""
        sw_path = os.path.join(LAB_ROOT, "projects/snablab/frontend/public/sw.js")
        with open(sw_path) as f:
            content = f.read()
        assert "CACHE_NAME" in content, "CACHE_NAME не определён в sw.js"
        # Проверяем формат: 'snablab-vN'
        match = re.search(r"CACHE_NAME\s*=\s*['\"]([^'\"]+)['\"]", content)
        assert match, "CACHE_NAME имеет некорректный формат"
        assert match.group(1).startswith("snablab-v"), \
            f"CACHE_NAME должен начинаться с 'snablab-v': {match.group(1)}"


# ═══════════════════════════════════════════════════════════════
# 8. Тесты INSIGHTS.md индекса
# ═══════════════════════════════════════════════════════════════

class TestInsightsIndex:
    """Тесты индекса INSIGHTS.md."""

    def test_insights_md_exists(self):
        """INSIGHTS.md существует."""
        insights_md = os.path.join(LAB_ROOT, "docs/INSIGHTS.md")
        assert os.path.isfile(insights_md), "INSIGHTS.md не существует"

    def test_insights_md_has_current_section(self):
        """INSIGHTS.md содержит раздел 'Текущие инсайты'."""
        insights_md = os.path.join(LAB_ROOT, "docs/INSIGHTS.md")
        with open(insights_md) as f:
            content = f.read()
        assert "Текущие инсайты" in content or "Current Insights" in content, \
            "INSIGHTS.md не содержит раздел 'Текущие инсайты'"

    def test_insights_md_lists_new_insights(self):
        """INSIGHTS.md ссылается на новые инсайты."""
        insights_md = os.path.join(LAB_ROOT, "docs/INSIGHTS.md")
        with open(insights_md) as f:
            content = f.read()
        # Проверяем что хотя бы 3 новых инсайта упоминаются
        new_insights = [
            "INSIGHT-git-identity-race",
            "INSIGHT-worktree-isolation",
            "INSIGHT-branch-discipline"
        ]
        found = sum(1 for insight in new_insights if insight in content)
        assert found >= 3, f"INSIGHTS.md не содержит новых инсайтов (найдено {found}/3)"
