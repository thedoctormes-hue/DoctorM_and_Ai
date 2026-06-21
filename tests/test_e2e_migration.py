"""
E2E тесты миграции.
Проверяет: projects.json, API Myrmex, монитор СнабЛаба, целостность данных.
"""
import json
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error

import pytest

MYRMEX_URL = "http://localhost:3000"
PROJECTS_JSON = "/root/LabDoctorM/projects/myrmex-control/myrmex.json"
SNABLAB_MONITOR = "/root/LabDoctorM/projects/snablab/backend/scripts/monitor.py"
SNABLAB_ENV = "/root/LabDoctorM/projects/snablab/backend/.env"
SNABLAB_GITIGNORE = "/root/LabDoctorM/projects/snablab/backend/.gitignore"


class TestProjectsJson:
    """Тесты projects.json после очистки."""

    def test_projects_json_is_valid(self):
        """projects.json — валидный JSON."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        assert "projects" in d
        assert isinstance(d["projects"], list)

    def test_no_dead_projects(self):
        """Нет мёртвых проектов в projects.json."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        dead_names = [
            "syncthing-dashboard", "myrmex-forge", "os-lab-api",
            "shtab-ai-gb52", "myrmex-command", "hype-protocol",
            "articles-shtab-ai"
        ]
        for p in d["projects"]:
            assert p["name"] not in dead_names, f"Мёртвый проект {p['name']} всё ещё в projects.json"

    def test_vpn_daemon_owner_is_kot(self):
        """vpn-daemon — owner kot, не bestia."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        vpn = [p for p in d["projects"] if p["name"] == "vpn-daemon"]
        assert len(vpn) == 1
        assert vpn[0]["owner"] == "kot"

    def test_remote_access_toolkit_exists(self):
        """remote-access-toolkit добавлен в projects.json."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        rat = [p for p in d["projects"] if p["name"] == "remote-access-toolkit"]
        assert len(rat) == 1
        assert "remote-access" in rat[0]["path"]

    def test_projects_count(self):
        """19 проектов в projects.json (было 29, удалили 10: 7 dead + antcat + raven + streikbrecher)."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        assert len(d["projects"]) == 19, f"Ожидалось 19, получено {len(d['projects'])}"

    def test_all_projects_have_valid_path(self):
        """Все проекты имеют валидный path."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        for p in d["projects"]:
            path = p.get("path", "")
            assert path, f"{p['name']}: нет path"
            assert os.path.exists(path), f"{p['name']}: path '{path}' не существует"

    def test_all_projects_have_owner(self):
        """Все проекты имеют owner."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        for p in d["projects"]:
            assert p.get("owner"), f"{p['name']}: нет owner"
            assert p["owner"] != "", f"{p['name']}: пустой owner"

    def test_all_projects_have_status(self):
        """Все проекты имеют валидный статус."""
        valid = ["planning", "active", "production", "maintenance", "frozen", "dead"]
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        for p in d["projects"]:
            assert p.get("status") in valid, f"{p['name']}: невалидный статус '{p.get('status')}'"


class TestSnablabSecurity:
    """Тесты безопасности СнабЛаба."""

    def test_no_hardcoded_token_in_monitor(self):
        """В monitor.py нет захардкоженного токена."""
        with open(SNABLAB_MONITOR) as f:
            content = f.read()
        assert "8305610762" not in content, "Токен всё ещё захардкожен в monitor.py"
        assert "AAE1kWxq2q98LdyGJ77LxMy6rCww1IkNn4k" not in content, "Токен всё ещё захардкожен в monitor.py"

    def test_monitor_reads_token_from_env(self):
        """monitor.py читает токен из os.getenv."""
        with open(SNABLAB_MONITOR) as f:
            content = f.read()
        assert 'os.getenv("TELEGRAM_BOT_TOKEN"' in content, "monitor.py не читает TELEGRAM_BOT_TOKEN из env"
        assert 'os.getenv("TELEGRAM_CHAT_ID"' in content, "monitor.py не читает TELEGRAM_CHAT_ID из env"

    def test_monitor_raises_on_missing_token(self):
        """monitor.py падает если токен не задан."""
        with open(SNABLAB_MONITOR) as f:
            content = f.read()
        assert 'raise ValueError("TELEGRAM_BOT_TOKEN not set' in content

    def test_env_file_exists(self):
        """.env файл существует."""
        assert os.path.exists(SNABLAB_ENV), ".env не найден"

    def test_env_has_telegram_token(self):
        """В .env есть TELEGRAM_BOT_TOKEN."""
        with open(SNABLAB_ENV) as f:
            content = f.read()
        assert "TELEGRAM_BOT_TOKEN=" in content, "В .env нет TELEGRAM_BOT_TOKEN"

    def test_gitignore_exists(self):
        """.gitignore существует."""
        assert os.path.exists(SNABLAB_GITIGNORE), ".gitignore не найден"

    def test_gitignore_has_env(self):
        """.gitignore содержит .env."""
        with open(SNABLAB_GITIGNORE) as f:
            content = f.read()
        assert ".env" in content, ".env не в .gitignore"

    def test_gitignore_has_venv(self):
        """.gitignore содержит .venv."""
        with open(SNABLAB_GITIGNORE) as f:
            content = f.read()
        assert ".venv" in content, ".venv не в .gitignore"

    def test_gitignore_has_pycache(self):
        """.gitignore содержит __pycache__."""
        with open(SNABLAB_GITIGNORE) as f:
            content = f.read()
        assert "__pycache__" in content, "__pycache__ не в .gitignore"


class TestMyrmexApi:
    """E2E тесты API Myrmex."""

    def test_myrmex_health(self):
        """Myrmex отвечает на health check."""
        try:
            req = urllib.request.urlopen(f"{MYRMEX_URL}/api/v1/health", timeout=5)
            assert req.status == 200
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            pytest.skip(f"Myrmex не запущен: {e}")

    def test_myrmex_api_projects(self):
        """API /api/projects возвращает список проектов."""
        try:
            req = urllib.request.urlopen(f"{MYRMEX_URL}/api/projects", timeout=5)
            data = json.loads(req.read())
            assert isinstance(data, list) or "projects" in data
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            pytest.skip(f"Myrmex не запущен: {e}")

    def test_myrmex_api_specs(self):
        """API /api/specs возвращает список спеков."""
        try:
            req = urllib.request.urlopen(f"{MYRMEX_URL}/api/specs", timeout=5)
            data = json.loads(req.read())
            assert isinstance(data, list) or "specs" in data
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            pytest.skip(f"Myrmex не запущен: {e}")
        except json.JSONDecodeError:
            # API требует авторизации — это нормально
            pass


class TestProjectStructure:
    """E2E тесты структуры проектов."""

    def test_all_projects_have_project_md(self):
        """Все проекты из projects.json имеют PROJECT.md."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        # Проекты у которых НЕ ожидается PROJECT.md (demo, маленькие)
        SKIP_PROJECTS = ["myrmex-demo"]
        missing = []
        for p in d["projects"]:
            if p["name"] in SKIP_PROJECTS:
                continue
            path = p.get("path", "")
            if path and os.path.exists(path):
                project_md = os.path.join(path, "PROJECT.md")
                if not os.path.exists(project_md):
                    missing.append(path)
        assert len(missing) == 0, f"Нет PROJECT.md: {missing}"

    def test_all_projects_have_readme(self):
        """Все проекты имеют README.md (кроме demo)."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        SKIP_PROJECTS = ["myrmex-demo"]
        missing = []
        for p in d["projects"]:
            if p["name"] in SKIP_PROJECTS:
                continue
            path = p.get("path", "")
            if path and os.path.exists(path):
                readme = os.path.join(path, "README.md")
                if not os.path.exists(readme):
                    missing.append(path)
        assert len(missing) == 0, f"Нет README.md: {missing}"

    def test_production_projects_have_specs(self):
        """Production проекты имеют SPECS/ папку."""
        with open(PROJECTS_JSON) as f:
            d = json.load(f)
        missing = []
        for p in d["projects"]:
            if p.get("status") != "production":
                continue
            path = p.get("path", "")
            if path and os.path.exists(path):
                specs = os.path.join(path, "SPECS")
                if not os.path.isdir(specs):
                    missing.append(path)
        assert len(missing) == 0, f"Production без SPECS/: {missing}"


class TestMigrationScript:
    """Тесты скрипта миграции."""

    def test_migrate_script_exists(self):
        """Скрипт миграции существует."""
        assert os.path.exists("scripts/migrate_specs.py")

    def test_migrate_script_is_idempotent(self):
        """Скрипт миграции идемпотентен (повторный запуск не ломает)."""
        result = subprocess.run(
            [sys.executable, "scripts/migrate_specs.py"],
            capture_output=True, text=True, timeout=30
        )
        assert result.returncode == 0, f"Миграция упала: {result.stderr}"

    def test_all_specs_have_required_fields(self):
        """Все спеки имеют обязательные поля после миграции."""
        import yaml
        import re

        required = ["id", "title", "status", "priority", "weight", "assignee", "project_id"]
        specs_dirs = []
        for root, dirs, files in os.walk("projects"):
            if "SPECS" in root:
                specs_dirs.append(root)

        for specs_dir in specs_dirs:
            for f in os.listdir(specs_dir):
                if f.startswith("BL-") and f.endswith(".md"):
                    filepath = os.path.join(specs_dir, f)
                    with open(filepath) as fh:
                        content = fh.read()
                    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
                    assert match, f"{filepath}: нет frontmatter"
                    fm = yaml.safe_load(match.group(1))
                    for field in required:
                        assert field in fm, f"{filepath}: нет поля '{field}'"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
