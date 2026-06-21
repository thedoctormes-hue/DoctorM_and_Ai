"""
Тесты: аудит workspace после очистки (2026-06-17)

ADR-025 (updated): workspace = workspaces/<agent>/, projects/<agent>/ = legacy.

Запуск:  cd /root/LabDoctorM && python3 -m pytest tests/test_workspace_cleanup.py -v
"""
from pathlib import Path

BASE = Path("/root/LabDoctorM")
WORKSPACES = BASE / "workspaces"
PROJECTS = BASE / "projects"
AGENTS = ["antcat", "bestia", "dominika", "kotolizator", "mangust", "owl", "raven", "streikbrecher"]
BOOTSTRAP_FILES = ["AGENTS.md", "SOUL.md", "IDENTITY.md", "TOOLS.md", "USER.md", "HEARTBEAT.md", "MEMORY.md"]

# ── ADR-025 ───────────────────────────────────────────────────────────────────

def test_adr_025_mentions_workspace():
    adr = BASE / "adr" / "ADR-025-agent-cwd-standard.md"
    content = adr.read_text()
    assert "рабочее пространство агента" in content, "ADR-025: нет упоминания рабочего пространства"
    assert "workspaces/<agent_id>" in content, "ADR-025: нет пути workspaces/<agent_id>"

def test_adr_025_lists_bootstrap_files():
    adr = BASE / "adr" / "ADR-025-agent-cwd-standard.md"
    content = adr.read_text()
    assert "AGENTS.md" in content, "ADR-025: нет AGENTS.md"
    assert "TOOLS.md" in content, "ADR-025: нет TOOLS.md"
    assert "MEMORY.md" in content, "ADR-025: нет MEMORY.md"

def test_adr_025_mentions_legacy():
    adr = BASE / "adr" / "ADR-025-agent-cwd-standard.md"
    content = adr.read_text()
    assert "legacy" in content or "маркер" in content, "ADR-025: нет упоминания legacy/маркер"

# ── Bootstrap files: no tables ────────────────────────────────────────────────

def test_no_tables_in_bootstrap_files():
    """Ни один bootstrap-файл не содержит строк, начинающихся с | (таблицы)."""
    for agent in AGENTS:
        ws = WORKSPACES / agent
        if not ws.is_dir():
            continue
        for fname in BOOTSTRAP_FILES:
            fpath = ws / fname
            if not fpath.is_file():
                continue
            lines = fpath.read_text().splitlines()
            table_lines = [l for l in lines if l.strip().startswith("|")]
            assert not table_lines, f"Таблица найдена в {agent}/{fname}: {table_lines[:3]}"

# ── projects/<agent>/ removed ────────────────────────────────────────────────

def test_projects_agent_dirs_removed():
    """Папки projects/<agent>/ для агентов должны быть удалены."""
    for agent in AGENTS:
        assert not (PROJECTS / agent).is_dir(), f"projects/{agent}/ всё ещё существует"

# ── Trash files removed from mangust ─────────────────────────────────────────

def test_trash_files_removed():
    trash = ["embed_bench.py", "IDENTITY.md.bak", "mangust-reply.ogg", "mangust-test.ogg"]
    ws = WORKSPACES / "mangust"
    for name in trash:
        assert not (ws / name).exists(), f"Мусор не удалён: {name}"

# ── MEMORY.md: grablis migrated ───────────────────────────────────────────────

def test_mangust_memory_has_grablis():
    memory = (WORKSPACES / "mangust" / "MEMORY.md").read_text()
    assert "Известные грабли" in memory, "MEMORY.md: нет раздела Известные грабли"
    assert "Таймаут turn" in memory, "MEMORY.md: нет записи о таймауте turn"
    assert "Холодный старт Ollama" in memory, "MEMORY.md: нет записи о Ollama"

def test_mangust_memory_has_verification():
    memory = (WORKSPACES / "mangust" / "MEMORY.md").read_text()
    assert "Верификация очистки workspace" in memory, "MEMORY.md: нет раздела верификации"

# ── Git procedures ───────────────────────────────────────────────────────────

def test_lab_commit_script_exists():
    script = BASE / "shared" / "git-rules" / "lab-commit.sh"
    assert script.is_file(), "shared/git-rules/lab-commit.sh не найден"
    assert script.stat().st_mode & 0o111, "lab-commit.sh не исполняемый"

def test_git_authors_json_valid():
    import json
    path = BASE / ".qwen" / "git-authors.json"
    assert path.is_file(), ".qwen/git-authors.json не найден"
    data = json.loads(path.read_text())
    for agent in AGENTS:
        assert agent in data, f"{agent} нет в git-authors.json"
        assert "name" in data[agent], f"{agent}: нет name"
        assert "email" in data[agent], f"{agent}: нет email"
