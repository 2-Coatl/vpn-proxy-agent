import re
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
USE_CASE_DIR = REPO_ROOT / "docs" / "use_cases"

EXPECTED_USE_CASES = {
    "uc01_bootstrap_standard_install.md": "bootstrap automation without manual intervention",
    "uc02_master_setup_pipeline.md": "orchestrating master setup across provisioning steps",
    "uc03_install_mcp_runtime.md": "installing the MCP runtime and toolchain",
    "uc04_run_mcp_service.md": "launching the MCP server under supervision",
    "uc05_watchdog_mcp_recovery.md": "recovering the MCP server when health checks fail",
    "uc06_setup_ssh_service.md": "configuring OpenSSH for dual listener tunnel access",
    "uc07_setup_tunnel_listener.md": "establishing the secondary SSH listener tunnel",
    "uc08_watchdog_tunnel_continuity.md": "maintaining the SSH tunnel availability",
    "uc09_setup_wireguard_gateway.md": "preparing the WireGuard secure channel",
    "uc10_setup_docker_runtime.md": "installing and configuring Docker services",
    "uc11_backup_daily_rotations.md": "running the lightweight daily backup rotation",
    "uc12_backup_system_snapshot.md": "performing comprehensive system backups",
    "uc13_safe_update_stack.md": "executing safe rolling updates",
    "uc14_health_check_monitoring.md": "capturing health telemetry across services",
    "uc15_diagnose_all_tooling.md": "running the full diagnostics suite",
    "uc16_dashboard_status_board.md": "rendering operational dashboard summaries",
    "uc17_run_tests_pipeline.md": "triggering the validation test harness",
    "uc18_validate_build_artifacts.md": "validating build deliverables",
    "uc19_validate_wrapper_entrypoint.md": "wrapping validation with environment preparation",
    "uc20_build_docs_pipeline.md": "building and publishing documentation",
    "uc21_build_cpython_from_source.md": "building CPython from upstream sources",
    "uc22_build_wrapper_ci_integration.md": "integrating builds with the wrapper tooling",
    "uc23_feature_install_customization.md": "installing optional feature bundles",
    "uc24_restart_services_recovery.md": "recovering core services via restart",
    "uc25_run_mcp_wrapper.md": "bridging MCP execution through wrapper scripts",
    "uc26_backup_windows_diagnostics.md": "running Windows diagnostics from PowerShell",
    "uc27_windows_start_environment.md": "starting the Windows development environment",
    "uc28_windows_stop_environment.md": "stopping the Windows development environment",
}

REQUIRED_SECTIONS = [
    "# ",
    "## Overview",
    "## Actors",
    "## Preconditions",
    "## Postconditions",
    "## High-Level Flow",
    "## Low-Level Flow",
    "## UML Activity Diagram",
    "## UML Sequence Diagram",
]


@pytest.mark.parametrize("filename", sorted(EXPECTED_USE_CASES))
def test_use_case_document_exists(filename):
    use_case_path = USE_CASE_DIR / filename
    assert use_case_path.exists(), f"Missing use case documentation: {filename}"

    content = use_case_path.read_text(encoding="utf-8")
    for section in REQUIRED_SECTIONS:
        assert section in content, f"Use case {filename} missing section {section}"

    # Ensure overview mentions the expected intent snippet to guard against mismatched copies
    snippet = EXPECTED_USE_CASES[filename]
    assert re.search(re.escape(snippet), content, flags=re.IGNORECASE), (
        f"Use case {filename} should describe intent: {snippet}"
    )

    assert content.count("```plantuml") >= 2, (
        f"Use case {filename} must include PlantUML diagrams for activity and sequence views"
    )
    assert "@startuml" in content, f"Use case {filename} should define PlantUML diagrams"
    assert "mermaid" not in content, f"Use case {filename} should no longer use Mermaid"


def test_use_case_navigation_registered():
    mkdocs_yml = (REPO_ROOT / "docs" / "mkdocs.yml").read_text(encoding="utf-8")
    assert "use_cases" in mkdocs_yml, "Use case documentation must be registered in MkDocs navigation"

