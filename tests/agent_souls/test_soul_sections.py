#!/usr/bin/env python3
"""pytest test suite for SOUL.md section validation.

Ensures each agent's SOUL.md contains the required Goal and Tool Policy sections.
"""

import os
import re

WORKSPACE = "/root/LabDoctorM/workspaces"
AGENTS = [
    "antcat",
    "bestia",
    "dominika",
    "kotolizator",
    "mangust",
    "owl",
    "raven",
    "streikbrecher",
]


def _load_soul(agent: str) -> str:
    path = os.path.join(WORKSPACE, agent, "SOUL.md")
    assert os.path.exists(path), f"SOUL.md not found for {agent}"
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _has_section(content: str, title: str) -> bool:
    pattern = rf"##\s*{re.escape(title)}"
    return bool(re.search(pattern, content, re.IGNORECASE))


def test_soul_contains_goal_and_tool_policy():
    """All agents must have both Goal and Tool Policy sections."""
    missing = []
    for agent in AGENTS:
        content = _load_soul(agent)
        if not _has_section(content, "Goal"):
            missing.append(f"{agent}: Goal")
        if not _has_section(content, "Tool Policy"):
            missing.append(f"{agent}: Tool Policy")
    assert not missing, f"Missing sections: {', '.join(missing)}"
