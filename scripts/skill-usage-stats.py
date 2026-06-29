#!/usr/bin/env python3
"""
skill-usage-stats.py — мониторинг частоты использования скилов.

Парсит JSONL-файлы сессий всех агентов, считает упоминания скилов.

Использование:
  python3 skill-usage-stats.py [--top N] [--agent AGENT_ID] [--days N] [--json]

Вывод:
  - Топ-N самых используемых скилов
  - Разбивка по агентам
  - Данные за последние N дней
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

# === Configuration ===

OPENCLAW_JSON = Path.home() / ".openclaw/openclaw.json"
AGENTS_DIR = Path.home() / ".openclaw/agents"

# === Helpers ===

def load_known_skills() -> list[str]:
    """Загрузить список скилов из openclaw.json"""
    if not OPENCLAW_JSON.exists():
        print(f"[WARN] {OPENCLAW_JSON} не найден", file=sys.stderr)
        return []
    cfg = json.loads(OPENCLAW_JSON.read_text())
    entries = cfg.get("skills", {}).get("entries", {})
    agent_skills = []
    for a in cfg.get("agents", {}).get("list", []):
        agent_skills.extend(a.get("skills", []))
    all_skills = sorted(set(list(entries.keys()) + agent_skills))
    return all_skills


def build_skill_pattern(skills: list[str]) -> re.Pattern:
    """Скомпилировать regex для поиска упоминаний скилов."""
    # Экранируем спецсимволы в именах скилов
    escaped = [re.escape(s) for s in skills]
    # Ищем точное совпадение слова + варианты "примени скил X", "скил X"
    pattern = (
        r"(?:примени[а-я]*\s+)?скил[а-я]*\s+(" + "|".join(escaped) + r")"
        r"|(?<!\w)(" + "|".join(escaped) + r")(?!\w)"
    )
    return re.compile(pattern, re.IGNORECASE)


def parse_session_file(
    path: Path,
    pattern: re.Pattern,
    cutoff_ts: str | None,
) -> list[dict]:
    """Парсить один JSONL-файл сессии, вернуть список найденных упоминаний."""
    results = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if obj.get("type") != "message":
                    continue
                msg = obj.get("message", {})
                content = msg.get("content", "")
                if isinstance(content, list):
                    # Берём только text элементы от assistant
                    if msg.get("role") != "assistant":
                        continue
                    texts = [
                        item.get("text", "")
                        for item in content
                        if isinstance(item, dict) and item.get("type") == "text"
                    ]
                    content = "\n".join(texts)
                if not isinstance(content, str) or not content:
                    continue
                # Проверяем timestamp
                ts = obj.get("timestamp") or msg.get("timestamp")
                if cutoff_ts and ts and ts < cutoff_ts:
                    continue
                # Ищем упоминания скилов
                for match in pattern.finditer(content):
                    skill = (match.group(1) or match.group(2)).lower()
                    results.append({
                        "ts": ts or "",
                        "skill": skill,
                        "session": "",
                        "agent": "",
                    })
    except (OSError, PermissionError):
        pass
    return results


def get_session_metadata(path: Path) -> dict:
    """Прочитать metadata из первой строки JSONL (session)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            first = json.loads(f.readline())
            if first.get("type") == "session":
                sid = first.get("id", "")
                return {"session_id": sid, "agent": "unknown"}
    except Exception:
        pass
    return {"session_id": "", "agent": "unknown"}


def discover_sessions() -> list[tuple[Path, str, str]]:
    """Найти все JSONL-файлы сессий, вернуть (path, agent, session_id)."""
    sessions = []
    if not AGENTS_DIR.exists():
        return sessions
    for agent_dir in sorted(AGENTS_DIR.iterdir()):
        if not agent_dir.is_dir():
            continue
        agent = agent_dir.name
        sessions_dir = agent_dir / "sessions"
        if not sessions_dir.exists():
            continue
        for jf in sorted(sessions_dir.glob("*.jsonl")):
            if jf.name.endswith(".reset") or ".reset." in jf.name:
                continue
            meta = get_session_metadata(jf)
            sessions.append((jf, agent, meta["session_id"]))
    return sessions


def main():
    parser = argparse.ArgumentParser(description="Skill usage statistics")
    parser.add_argument("--top", type=int, default=20, help="Top N skills to show")
    parser.add_argument("--agent", type=str, default=None, help="Filter by agent ID")
    parser.add_argument("--days", type=int, default=30, help="Days to look back")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    # Init
    skills = load_known_skills()
    if not skills:
        print("No skills found in openclaw.json", file=sys.stderr)
        sys.exit(1)

    pattern = build_skill_pattern(skills)
    cutoff = (datetime.utcnow() - timedelta(days=args.days)).isoformat() + "Z"
    sessions = discover_sessions()

    # Collect
    # skill -> total count
    skill_total = defaultdict(int)
    # skill -> agent -> count
    skill_by_agent = defaultdict(lambda: defaultdict(int))
    # skill -> date -> count
    skill_by_date = defaultdict(lambda: defaultdict(int))
    # agent -> total messages with skill mentions
    agent_total = defaultdict(int)

    total_mentions = 0
    total_sessions_scanned = 0

    for path, agent, sid in sessions:
        if args.agent and agent != args.agent:
            continue
        total_sessions_scanned += 1
        mentions = parse_session_file(path, pattern, cutoff)
        for m in mentions:
            skill = m["skill"]
            if skill not in skills:
                continue
            skill_total[skill] += 1
            skill_by_agent[skill][agent] += 1
            agent_total[agent] += 1
            total_mentions += 1
            if m["ts"]:
                date = m["ts"][:10]
                skill_by_date[skill][date] += 1

    # Output
    if args.json:
        output = {
            "meta": {
                "total_skills": len(skills),
                "total_sessions_scanned": total_sessions_scanned,
                "total_mentions": total_mentions,
                "days": args.days,
                "generated_at": datetime.utcnow().isoformat() + "Z",
            },
            "top_skills": [
                {"skill": s, "count": c}
                for s, c in sorted(skill_total.items(), key=lambda x: -x[1])[:args.top]
            ],
            "by_agent": {
                a: {"total": c, "skills": dict(skill_by_agent)}
                for a, c in sorted(agent_total.items(), key=lambda x: -x[1])
            },
            "by_date": {
                s: dict(dates)
                for s, dates in skill_by_date.items()
            },
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))
        return

    # Text output
    print(f"=== Skill Usage Stats (last {args.days}d) ===")
    print(f"Skills tracked: {len(skills)}")
    print(f"Sessions scanned: {total_sessions_scanned}")
    print(f"Total mentions: {total_mentions}")
    print()

    print(f"--- Top {args.top} Skills ---")
    for i, (skill, count) in enumerate(
        sorted(skill_total.items(), key=lambda x: -x[1])[:args.top], 1
    ):
        agents_str = ", ".join(
            f"{a}:{c}" for a, c in sorted(skill_by_agent[skill].items(), key=lambda x: -x[1])[:3]
        )
        print(f"  {i:2}. {skill:<30} {count:>5}  ({agents_str})")

    print()
    print("--- By Agent ---")
    for agent, total in sorted(agent_total.items(), key=lambda x: -x[1]):
        top_skills = sorted(skill_by_agent.items(), key=lambda x: -x[1][agent])[:5]
        skills_str = ", ".join(f"{s}:{c[agent]}" for s, c in top_skills)
        print(f"  {agent:<20} {total:>5} mentions  top: {skills_str}")

    # Dead skills
    dead = [s for s in skills if skill_total[s] == 0]
    if dead:
        print()
        print(f"--- Dead Skills ({len(dead)} never mentioned) ---")
        for s in dead[:10]:
            print(f"  - {s}")
        if len(dead) > 10:
            print(f"  ... and {len(dead) - 10} more")


if __name__ == "__main__":
    main()
