#!/usr/bin/env python3
"""
runtime_state_builder.py — индексатор runtime_state для myrmex.json.

Собирает живое состояние лаборатории и пишет в myrmex.json
через writeState() API Myrmex Control.

Запускается systemd-таймером каждые 15 минут.
"""
import json
import subprocess
import sys
import os
import glob
import time
from datetime import datetime, timezone

LAB_ROOT = "/root/LabDoctorM"
MYRMEX_JSON = "/root/LabDoctorM/projects/myrmex-control/myrmex.json"
MYRMEX_API = "http://127.0.0.1:3000"
INCIDENTS_DIR = os.path.join(LAB_ROOT, "incidents")
PROJECTS_DIR = os.path.join(LAB_ROOT, "projects")

# Читаем API key из .env
def get_api_key() -> str | None:
    env_file = os.path.join(LAB_ROOT, "projects/myrmex-control/.env")
    if not os.path.exists(env_file):
        return None
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line.startswith("MYRMEX_API_KEY="):
                return line.split("=", 1)[1].strip()
    return None


def _fm_field(filepath: str, field: str) -> str | None:
    """Извлечь поле из frontmatter YAML (между первым и вторым '---')."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            in_fm = False
            for line in f:
                line = line.strip()
                if line == "---":
                    in_fm = not in_fm
                    continue
                if in_fm and line.lower().startswith(field.lower() + ":"):
                    return line.split(":", 1)[1].strip().strip('"').strip("'")
    except (IOError, OSError):
        pass
    return None


def get_openclaw_status() -> dict:
    """Статус процесса OpenClaw."""
    r = subprocess.run(
        ["systemctl", "is-active", "openclaw-gateway"],
        capture_output=True, text=True, timeout=5,
    )
    status = r.stdout.strip()
    if status not in ("active", "inactive", "failed"):
        status = "unknown"

    # PID и uptime
    pid = None
    uptime_sec = None
    try:
        r2 = subprocess.run(
            ["pgrep", "-f", "openclaw"],
            capture_output=True, text=True, timeout=5,
        )
        if r2.stdout.strip():
            pid = int(r2.stdout.strip().split("\n")[0])
            # uptime из /proc
            stat_file = f"/proc/{pid}/stat"
            if os.path.exists(stat_file):
                with open(stat_file) as f:
                    stat = f.read().split()
                # starttime — поле 22 (индекс 21)
                starttime = int(stat[21])
                with open("/proc/uptime") as f:
                    sys_uptime = float(f.read().split()[0])
                clk_tck = os.sysconf(os.sysconf_names['SC_CLK_TCK'])
                uptime_sec = int(sys_uptime - (starttime / clk_tck))
    except (ValueError, IndexError, OSError):
        pass

    return {"status": status, "pid": pid, "uptime_sec": uptime_sec}


def get_git_state() -> dict:
    """Состояние git-репозитория."""
    def git(*args) -> str:
        r = subprocess.run(
            ["git", "-C", LAB_ROOT] + list(args),
            capture_output=True, text=True, timeout=10,
        )
        return r.stdout.strip()

    ahead = git("rev-list", "--count", "origin/main..HEAD")
    behind = git("rev-list", "--count", "HEAD..origin/main")
    dirty_raw = git("status", "--porcelain")
    dirty = len([l for l in dirty_raw.split("\n") if l.strip()]) if dirty_raw else 0

    # Время последнего fetch
    fetch_head = os.path.join(LAB_ROOT, ".git", "FETCH_HEAD")
    if os.path.exists(fetch_head):
        fetch_mtime = os.path.getmtime(fetch_head)
        fetch_age_h = int((time.time() - fetch_mtime) / 3600)
        last_fetch = f"{fetch_age_h}ч назад"
    else:
        last_fetch = "никогда"

    return {
        "ahead": int(ahead) if ahead.isdigit() else 0,
        "behind": int(behind) if behind.isdigit() else 0,
        "dirty": dirty,
        "last_fetch": last_fetch,
    }


def get_incidents() -> dict:
    """Незакрытые инциденты."""
    items = []
    for f in sorted(glob.glob(os.path.join(INCIDENTS_DIR, "INC-*.md"))):
        if "INC-000-template" in f:
            continue
        status = _fm_field(f, "status")
        if status not in ("open", "mitigated"):
            continue
        inc_id = _fm_field(f, "id") or os.path.basename(f)
        severity = _fm_field(f, "severity") or "unknown"
        title = _fm_field(f, "title") or ""
        items.append({
            "id": inc_id,
            "title": title[:120],
            "status": status,
            "severity": severity,
        })

    open_count = sum(1 for i in items if i["status"] == "open")
    mitigated_count = sum(1 for i in items if i["status"] == "mitigated")

    return {
        "open": open_count,
        "mitigated": mitigated_count,
        "total": len(items),
        "items": items,
    }


def get_failed_units() -> list[str]:
    """Упавшие systemd-юниты."""
    r = subprocess.run(
        ["systemctl", "list-units", "--type=service", "--state=failed",
         "--no-legend", "--plain"],
        capture_output=True, text=True, timeout=10,
    )
    units = []
    for line in r.stdout.strip().split("\n"):
        line = line.strip()
        if line:
            parts = line.split()
            if parts:
                units.append(parts[0])
    return units


def get_handoffs() -> dict:
    """Последние HANDOFF от каждого агента."""
    handoffs = {}
    if not os.path.isdir(PROJECTS_DIR):
        return handoffs

    for agent_dir in sorted(os.listdir(PROJECTS_DIR)):
        hf = os.path.join(PROJECTS_DIR, agent_dir, "SESSION_HANDOFF.md")
        if not os.path.isfile(hf):
            continue
        status = _fm_field(hf, "status") or "unknown"
        last_reviewed = _fm_field(hf, "last_reviewed") or ""

        # TL;DR — первый абзац после "## 📊 TL;DR"
        tldr = ""
        try:
            with open(hf, "r", encoding="utf-8") as f:
                in_tldr = False
                for line in f:
                    if "## 📊 TL;DR" in line:
                        in_tldr = True
                        continue
                    if in_tldr:
                        line = line.strip()
                        if line.startswith("##"):
                            break
                        if line:
                            tldr = line[:200]
                            break
        except (IOError, OSError):
            pass

        handoffs[agent_dir] = {
            "status": status,
            "last_reviewed": last_reviewed,
            "tldr": tldr,
        }
    return handoffs


def build_runtime_state() -> dict:
    """Собрать полную runtime-сводку."""
    return {
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "openclaw": get_openclaw_status(),
        "git": get_git_state(),
        "incidents": get_incidents(),
        "failedUnits": get_failed_units(),
        "handoffs": get_handoffs(),
    }


def write_to_myrmex(runtime_state: dict, api_key: str) -> bool:
    """Записать runtime_state в myrmex.json через API."""
    import urllib.request
    import urllib.error

    payload = json.dumps({"runtime_state": runtime_state}).encode("utf-8")
    req = urllib.request.Request(
        f"{MYRMEX_API}/api/state/runtime",
        data=payload,
        headers={
            "Content-Type": "application/json",
            "X-API-Key": api_key,
        },
        method="PUT",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status == 200
    except urllib.error.HTTPError as e:
        print(f"  ❌ HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}", file=sys.stderr)
        return False


def main():
    api_key = get_api_key()
    if not api_key:
        print("❌ MYRMEX_API_KEY не найден", file=sys.stderr)
        sys.exit(1)

    state = build_runtime_state()

    # Выводим в stdout для логов
    print(f"  OpenClaw: {state['openclaw']['status']} (pid={state['openclaw']['pid']})")
    print(f"  Git: ahead={state['git']['ahead']} behind={state['git']['behind']} dirty={state['git']['dirty']}")
    print(f"  Incidents: {state['incidents']['open']} open, {state['incidents']['mitigated']} mitigated")
    print(f"  Failed units: {len(state['failedUnits'])}")
    print(f"  Handoffs: {len(state['handoffs'])}")

    if write_to_myrmex(state, api_key):
        print("  ✅ runtime_state → myrmex.json")
    else:
        print("  ❌ Не удалось записать", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
