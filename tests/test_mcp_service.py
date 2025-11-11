#!/usr/bin/env python3
"""Acceptance tests for the MCP service automation assets."""

from __future__ import annotations

import os
from pathlib import Path
import unittest

PROJECT_ROOT = Path(__file__).resolve().parent.parent


class TestMcpServiceAssets(unittest.TestCase):
    """Validate the MCP server deliverables required by the implementation plan."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.config_path = PROJECT_ROOT / "config" / "versions.conf"
        cls.install_script = PROJECT_ROOT / "scripts" / "install_mcp.sh"
        cls.run_script = PROJECT_ROOT / "scripts" / "run_mcp.sh"
        cls.watchdog_script = PROJECT_ROOT / "scripts" / "watchdog_mcp.sh"
        cls.systemd_unit = PROJECT_ROOT / "systemd" / "mcp.service"
        cls.bootstrap_script = PROJECT_ROOT / "bootstrap.sh"
        cls.docs_index = PROJECT_ROOT / "docs" / "index.md"
        cls.readme = PROJECT_ROOT / "README.md"
        cls.plan = PROJECT_ROOT / "docs" / "mcp_server_plan.md"
        cls.tests_runner = PROJECT_ROOT / "scripts" / "run_tests.sh"

    def test_versions_conf_declares_mcp_configuration(self) -> None:
        """The MCP specific configuration knobs must be documented."""
        content = self.config_path.read_text(encoding="utf-8")
        self.assertIn("# MCP Service Configuration", content)
        required_variables = [
            "MCP_SERVICE_NAME",
            "MCP_DEFAULT_PORT",
            "MCP_USER",
            "MCP_GROUP",
            "MCP_INSTALL_DIR",
            "MCP_DATA_DIR",
            "MCP_LOG_DIR",
            "MCP_ENV_FILE",
            "MCP_CERT_DIR",
            "MCP_BIN_PATH",
            "MCP_LOGROTATE_CONFIG",
        ]
        for variable in required_variables:
            with self.subTest(variable=variable):
                self.assertIn(f"{variable}=", content)

    def test_versions_conf_declares_runtime_toolchain(self) -> None:
        """Runtime toolchain definitions must exist for mise provisioning."""
        content = self.config_path.read_text(encoding="utf-8")
        self.assertIn("MCP_RUNTIME_TOOLCHAIN=(", content)
        for token in ("python", "node", "ruby", "rust", "go", "swift", "php"):
            with self.subTest(token=token):
                self.assertIn(token, content)

    def test_install_script_exists_and_is_executable(self) -> None:
        """Installation script should source helpers and enforce strict modes."""
        self.assertTrue(self.install_script.exists(), "install_mcp.sh must exist")
        self.assertTrue(os.access(self.install_script, os.X_OK), "install_mcp.sh must be executable")
        content = self.install_script.read_text(encoding="utf-8")
        self.assertTrue(content.startswith("#!/bin/bash"))
        self.assertIn("set -euo pipefail", content)
        self.assertIn("utils/common.sh", content)
        self.assertIn("create_directory", content)
        self.assertIn("install_packages", content)

    def test_install_script_configures_language_runtimes(self) -> None:
        """Installer should delegate runtime provisioning to mise helper."""
        content = self.install_script.read_text(encoding="utf-8")
        self.assertIn("configure_language_runtimes", content)
        self.assertIn("Configuring language runtimes", content)
        self.assertIn(".config/mise/config.toml", content)

    def test_install_script_installs_code_search_tooling(self) -> None:
        """The MCP host must provide ripgrep for repository search operations."""
        content = self.install_script.read_text(encoding="utf-8")
        self.assertIn("ripgrep", content)

    def test_run_script_wraps_service_binary(self) -> None:
        """Runtime wrapper should load environment, log output and exec the binary."""
        self.assertTrue(self.run_script.exists(), "run_mcp.sh must exist")
        self.assertTrue(os.access(self.run_script, os.X_OK), "run_mcp.sh must be executable")
        content = self.run_script.read_text(encoding="utf-8")
        self.assertTrue(content.startswith("#!/bin/bash"))
        self.assertIn("set -euo pipefail", content)
        self.assertIn("MCP_LOG_FILE", content)
        self.assertIn("MCP_ENV_FILE", content)
        self.assertIn("exec \"$MCP_BIN\"", content)

    def test_watchdog_script_performs_health_checks(self) -> None:
        """Watchdog should validate the MCP port and emit structured logs."""
        self.assertTrue(self.watchdog_script.exists(), "watchdog_mcp.sh must exist")
        self.assertTrue(os.access(self.watchdog_script, os.X_OK), "watchdog_mcp.sh must be executable")
        content = self.watchdog_script.read_text(encoding="utf-8")
        self.assertIn("#!/bin/bash", content)
        self.assertIn("set -euo pipefail", content)
        self.assertRegex(content, r"nc\s+-z")
        self.assertIn("log_section \"MCP Watchdog\"", content)

    def test_systemd_unit_targets_wrapper_script(self) -> None:
        """Unit file must describe a managed service with sensible defaults."""
        text = self.systemd_unit.read_text(encoding="utf-8")
        self.assertIn("[Unit]", text)
        self.assertIn("Description=MCP Server", text)
        self.assertIn("After=network-online.target", text)
        self.assertIn("ExecStart=/usr/local/bin/run_mcp.sh", text)
        self.assertIn("Restart=on-failure", text)

    def test_bootstrap_exposes_mcp_flag(self) -> None:
        """Bootstrap should route --mcp to the installer workflow."""
        content = self.bootstrap_script.read_text(encoding="utf-8")
        self.assertIn("--mcp", content)
        self.assertIn("install_mcp.sh", content)
        self.assertIn('case "${1:-}" in', content)
        self.assertIn("--mcp)", content)

    def test_documentation_mentions_mcp_service(self) -> None:
        """README and docs index should document the new server."""
        readme_text = self.readme.read_text(encoding="utf-8")
        docs_text = self.docs_index.read_text(encoding="utf-8")
        self.assertIn("MCP", readme_text)
        self.assertIn("MCP", docs_text)
        self.assertIn("run_mcp.sh", docs_text)

    def test_plan_tasks_marked_complete(self) -> None:
        """The MCP plan checkboxes should reflect the completed work."""
        plan_text = self.plan.read_text(encoding="utf-8")
        self.assertIn("- [x] Documentar", plan_text)
        self.assertIn("- [x] Crear `scripts/install_mcp.sh`", plan_text)
        self.assertIn("- [x] Escribir `systemd/mcp.service`", plan_text)
        self.assertIn("- [x] Incorporar `tests/test_mcp_service.py`", plan_text)

    def test_local_test_runner_exists(self) -> None:
        """A composite test runner should orchestrate coverage locally."""
        self.assertTrue(self.tests_runner.exists(), "scripts/run_tests.sh must exist")
        self.assertTrue(os.access(self.tests_runner, os.X_OK), "run_tests.sh should be executable")
        text = self.tests_runner.read_text(encoding="utf-8")
        self.assertIn("coverage", text)
        self.assertIn("pytest", text)
        self.assertIn("xml", text)
        self.assertIn("fail-under=80", text)


if __name__ == "__main__":
    unittest.main()
