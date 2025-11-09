# Repository Overview

This page records the current footprint of the VPN Proxy Agent repository and highlights the automation flows that tie the scripts together.

## Current Inventory

| Metric | Value | Notes |
| --- | --- | --- |
| Tracked files | 53 | `git ls-files` (excludes generated assets such as `site/`). |
| Total lines of code | 5,857 | Aggregated with `git ls-files | xargs wc -l`. |
| Bash entrypoints | 21 | Located under `scripts/`, supplemented by reusable helpers in `utils/`. |
| PowerShell scripts | 3 | Mirrored diagnostics and environment tooling under `scripts/windows/`. |
| Systemd service units | 2 | `systemd/ssh-tunnel.service` and `systemd/tunnel-watchdog.service`. |
| Test suites | 4 | `tests/test_utilities.sh` plus three Python suites totalling 913 lines. |

### Directory Breakdown

| Directory | Files | Lines | Highlights |
| --- | --- | --- | --- |
| `bootstrap.sh` | 1 | 581 | Master orchestrator with staged provisioning hooks and outstanding `TODO` markers. |
| `scripts/` | 21 | 1,069 | Backup, diagnostic, tunneling, Docker, CPython feature, and monitoring scripts. |
| `utils/` | 4 | 1,325 | Core Bash libraries: `env.sh`, `common.sh`, `logging.sh`, `validation.sh`. |
| `tests/` | 4 | 913 | Bash regression coverage and Python verifiers for syntax, build, and feature logic. |
| `installer/` | 3 | 367 | Dev Container feature definition, install wrapper, and supporting docs. |
| `docs/` | 8 | 364 | MkDocs content, including repository overview, tutorials, and checklists. |
| `systemd/` | 2 | 28 | Unit files for the SSH tunnel and watchdog. |
| `docs/mkdocs.yml` | 1 | 11 | MkDocs site configuration with navigation and theme selection. |

## Automation Workflows

1. **Environment Normalization**
   - `utils/env.sh` resolves configuration defaults from `config/versions.conf` and ensures log, backup, and data directories are writable.
   - `utils/common.sh`, `utils/logging.sh`, and `utils/validation.sh` supply argument parsing, logging, and integrity checks that the entrypoint scripts rely on.

2. **Provisioning & Operations**
   - `bootstrap.sh` coordinates host preparation, invoking role-specific scripts for SSH, Docker, tunnel configuration, backups, and optional WireGuard support.
   - Backup, monitoring, and diagnostic workflows live in dedicated scripts (`backup_daily.sh`, `watchdog_tunnel.sh`, `diagnose_all.sh`, etc.), allowing targeted execution.

3. **Packaging & Distribution**
   - `installer/install.sh` wraps platform detection while `installer/devcontainer_feature.json` packages the automation as a Dev Container feature.
   - System services in `systemd/` provide ready-to-enable units for long-lived tunnel supervision.

4. **Validation**
   - The Bash test suite covers logging and validation helpers.
   - Python test suites lint scripts, verify CPython build automation, and ensure Dev Container feature metadata remains consistent.

## Outstanding Tasks

- **SSH provisioning hook** – `install_ssh` in `bootstrap.sh` still references a future dedicated script.
- **Backup scheduling** – `setup_backups` outlines the intent but does not stage cron jobs or copy backup assets.
- **WireGuard enablement** – the "complete" orchestration path concludes with a placeholder comment rather than executing deployment steps.

Use these checkpoints when scoping future work so documentation claims stay aligned with the actual automation.
