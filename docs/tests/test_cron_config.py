#!/usr/bin/env python3
"""
Тесты конфигурации cron-заданий лаборатории.
Проверяет: наличие критичных заданий, failureAlert, расписания, дублирование.
"""

import json
import subprocess
import sys
import unittest
from pathlib import Path


def get_cron_jobs():
    """Получить список cron-заданий через openclaw CLI."""
    result = subprocess.run(
        ["openclaw", "cron", "list", "--json"],
        capture_output=True, text=True, timeout=30
    )
    # Пропустить строки до первого { (config warnings)
    raw = result.stdout
    idx = raw.find('{')
    if idx < 0:
        raise RuntimeError(f"No JSON in output: {raw[:200]}")
    return json.loads(raw[idx:])['jobs']


def get_disabled_cron_jobs():
    """Получить отключённые задания (требуют отдельного запроса)."""
    disabled = []
    # artifact-insights-consolidate
    for job_id in [
        "d1e7f989-7468-4139-abb9-84ac11719c70",
        "76fb61ff-6c10-4935-8fa6-0f0bbe83806a",
    ]:
        result = subprocess.run(
            ["openclaw", "cron", "get", job_id],
            capture_output=True, text=True, timeout=15
        )
        raw = result.stdout
        idx = raw.find('{')
        if idx >= 0:
            job = json.loads(raw[idx:])
            disabled.append(job)
    return disabled


class TestCronJobsExist(unittest.TestCase):
    """Проверка наличия всех ожидаемых cron-заданий."""

    @classmethod
    def setUpClass(cls):
        cls.jobs = get_cron_jobs()
        cls.job_names = {j['name'] for j in cls.jobs}

    def test_tavily_report_exists(self):
        self.assertIn("Tavily Daily Usage Report", self.job_names)

    def test_weekly_audit_exists(self):
        self.assertIn("weekly-automation-audit", self.job_names)

    def test_bestia_health_check_exists(self):
        self.assertIn("bestia-health-check", self.job_names)

    def test_dominika_cve_scan_exists(self):
        self.assertIn("dominika-cve-scan", self.job_names)

    def test_streikbrecher_dep_check_exists(self):
        self.assertIn("streikbrecher-dep-check", self.job_names)

    def test_raven_tech_radar_exists(self):
        self.assertIn("raven-tech-radar", self.job_names)

    def test_artifact_refresh_exists(self):
        self.assertIn("artifact_refresh_daily", self.job_names)

    def test_factcheck_daily_exists(self):
        self.assertIn("factcheck_all_daily", self.job_names)

    def test_free_api_hunter_exists(self):
        self.assertIn("free-api-hunter-scan", self.job_names)

    def test_filter_free_models_exists(self):
        self.assertIn("filter-free-models-12h", self.job_names)


class TestFailureAlerts(unittest.TestCase):
    """Проверка наличия failureAlert для критичных заданий."""

    @classmethod
    def setUpClass(cls):
        cls.jobs = get_cron_jobs()

    def _get_job(self, name):
        for j in self.jobs:
            if j['name'] == name:
                return j
        self.fail(f"Job '{name}' not found")

    def test_streikbrecher_dep_check_has_failure_alert(self):
        job = self._get_job("streikbrecher-dep-check")
        self.assertIsNotNone(job.get('failureAlert'),
                             "streikbrecher-dep-check must have failureAlert")

    def test_bestia_health_check_has_failure_alert(self):
        job = self._get_job("bestia-health-check")
        self.assertIsNotNone(job.get('failureAlert'),
                             "bestia-health-check must have failureAlert")

    def test_dominika_cve_scan_has_failure_alert(self):
        job = self._get_job("dominika-cve-scan")
        self.assertIsNotNone(job.get('failureAlert'),
                             "dominika-cve-scan must have failureAlert")

    def test_failure_alert_after_2_errors(self):
        """Все failureAlert должны срабатывать после 2 ошибок."""
        for j in self.jobs:
            fa = j.get('failureAlert')
            if fa:
                self.assertEqual(fa.get('after'), 2,
                                 f"{j['name']}: failureAlert.after should be 2")

    def test_failure_alert_cooldown_1h(self):
        """Все failureAlert должны иметь cooldown 1 час."""
        for j in self.jobs:
            fa = j.get('failureAlert')
            if fa:
                self.assertEqual(fa.get('cooldownMs'), 3600000,
                                 f"{j['name']}: failureAlert.cooldownMs should be 3600000")


class TestDisabledJobs(unittest.TestCase):
    """Проверка что мёртвые задания отключены."""

    @classmethod
    def setUpClass(cls):
        cls.disabled = get_disabled_cron_jobs()

    def test_artifact_insights_consolidate_disabled(self):
        for j in self.disabled:
            if j['name'] == 'artifact-insights-consolidate':
                self.assertFalse(j['enabled'],
                                 "artifact-insights-consolidate must be disabled")
                return
        self.fail("artifact-insights-consolidate not found")

    def test_artifact_factcheck_disabled(self):
        for j in self.disabled:
            if j['name'] == 'artifact-factcheck':
                self.assertFalse(j['enabled'],
                                 "artifact-factcheck must be disabled")
                return
        self.fail("artifact-factcheck not found")


class TestScheduleConfig(unittest.TestCase):
    """Проверка корректности расписаний."""

    @classmethod
    def setUpClass(cls):
        cls.jobs = get_cron_jobs()

    def _get_job(self, name):
        for j in self.jobs:
            if j['name'] == name:
                return j
        self.fail(f"Job '{name}' not found")

    def test_tavily_report_schedule(self):
        job = self._get_job("Tavily Daily Usage Report")
        sched = job['schedule']
        self.assertEqual(sched['kind'], 'cron')
        self.assertIn('8', sched['expr'])  # 0 8 * * *

    def test_weekly_audit_monday(self):
        job = self._get_job("weekly-automation-audit")
        sched = job['schedule']
        self.assertEqual(sched['kind'], 'cron')
        self.assertIn('* * 1', sched['expr'])  # понедельник

    def test_free_api_hunter_not_too_frequent(self):
        """free-api-hunter-scan должен быть не чаще чем раз в 2 часа."""
        job = self._get_job("free-api-hunter-scan")
        sched = job['schedule']
        if sched['kind'] == 'every':
            self.assertGreaterEqual(sched['everyMs'], 7200000,
                                    "free-api-hunter-scan should be >= 2h")

    def test_all_enabled_jobs_have_delivery(self):
        """Все активные задания должны иметь настроенную доставку."""
        for j in self.jobs:
            if j['enabled']:
                delivery = j.get('delivery', {})
                self.assertEqual(delivery.get('mode'), 'announce',
                                 f"{j['name']}: delivery mode should be 'announce'")
                self.assertIn('telegram', delivery.get('to', ''),
                              f"{j['name']}: delivery should target telegram")


class TestCronRegistryDoc(unittest.TestCase):
    """Проверка наличия и актуальности CRON_REGISTRY.md."""

    def test_registry_exists(self):
        registry = Path("/root/LabDoctorM/docs/CRON_REGISTRY.md")
        self.assertTrue(registry.exists(), "CRON_REGISTRY.md must exist")

    def test_registry_not_empty(self):
        registry = Path("/root/LabDoctorM/docs/CRON_REGISTRY.md")
        content = registry.read_text()
        self.assertGreater(len(content), 1000,
                           "CRON_REGISTRY.md should have substantial content")

    def test_registry_mentions_all_agents(self):
        registry = Path("/root/LabDoctorM/docs/CRON_REGISTRY.md")
        content = registry.read_text()
        for agent in ['mangust', 'dominika', 'raven', 'bestia', 'owl', 'antcat', 'kotolizator', 'streikbrecher']:
            self.assertIn(agent, content,
                          f"CRON_REGISTRY.md should mention agent '{agent}'")


class TestIncidentFixed(unittest.TestCase):
    """Проверка что инцидент зафиксирован."""

    def test_incident_exists(self):
        incident = Path("/root/LabDoctorM/incidents/INC-20260619171500.md")
        self.assertTrue(incident.exists(), "Incident file must exist")

    def test_incident_has_lessons(self):
        incident = Path("/root/LabDoctorM/incidents/INC-20260619171500.md")
        content = incident.read_text()
        self.assertIn('Уроки', content, "Incident must have lessons section")


if __name__ == '__main__':
    unittest.main(verbosity=2)
