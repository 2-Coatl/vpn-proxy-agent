# VPN Proxy Agent Knowledge Base

Welcome to the engineering handbook for the VPN Proxy Agent. This site aggregates the operational context, automation gaps, and authoring workflow for the repository so that new contributors can become productive quickly.

## Quick Start

1. **Clone and inspect the project**
   ```bash
   git clone https://example.com/vpn-proxy-agent.git
   cd vpn-proxy-agent
   ```
2. **Review shared helpers first** – the reusable Bash libraries inside `utils/` (`env.sh`, `common.sh`, `logging.sh`, and `validation.sh`) define most of the conventions referenced by the scripts.
3. **Run the shell regression suite** – validates logging, validation, and environment helpers before you iterate on automation logic.
   ```bash
   bash tests/test_utilities.sh
   ```
4. **Provision the Vagrant VM (optional)** – `vagrant up` now runs `bootstrap.sh` automatically in automation mode. Inspect progress with `vagrant up --debug` or SSH in afterwards to rerun `BOOTSTRAP_AUTO=1 ./bootstrap.sh` if you need to reset the guest state.
5. **Review post-provisioning checks** – after Vagrant finishes, connect with `vagrant ssh`, read `~/logs/bootstrap_latest.log`, and run `bash tests/test_bootstrap.sh` to confirm the unattended helpers still pass.
6. **Preview the documentation** – install MkDocs (`pip install mkdocs`) and run `mkdocs serve --config-file docs/mkdocs.yml` to review this site locally with live reloading.

## MCP Server Playbook

1. **Configura parámetros** – edita `config/versions.conf` y actualiza la sección *MCP Service Configuration* con puertos y rutas adecuadas.
2. **Instalación directa** – ejecuta `./scripts/install_mcp.sh` para crear el usuario `mcp`, carpetas (`/var/lib/mcp`, `/var/log/mcp`), generar `~/.config/mise/config.toml` y desplegar `systemd/mcp.service`.
3. **Bootstrap dedicado** – utiliza `./bootstrap.sh --mcp` para orquestar la instalación completa desde el orquestador principal.
4. **Ejecución** – `./scripts/run_mcp.sh` carga `/etc/mcp/mcp.env`, envía logs a `logs/mcp-server.log` y lanza el binario configurado.
5. **Supervisión** – valida disponibilidad con `./scripts/watchdog_mcp.sh` o `sudo systemctl status mcp.service`.
6. **Calidad continua** – corre `./scripts/run_tests.sh` para generar reportes de cobertura ≥80 % y validar el watchdog.

## Project at a Glance

| Area | Highlights |
| --- | --- |
| `bootstrap.sh` | Central orchestrator (581 lines) with staged provisioning hooks for SSH, Docker, backups, and WireGuard. Several sections remain tagged with `TODO` markers for SSH hardening, scheduled backups, and WireGuard enablement. |
| `scripts/` | 21 Bash entrypoints plus 3 Windows PowerShell companions covering backups, diagnostics, tunneling, and CPython feature builds. |
| `installer/` | Dev Container feature definition, installation wrapper, and README that describe packaging flows. |
| `systemd/` | Service units for the SSH tunnel and watchdog supervisor. |
| `tests/` | One Bash suite and three Python suites totaling 913 lines of tests that lint scripts and validate CPython automation. |
| `docs/` | MkDocs content (this site) that documents onboarding and reference material. |

## Known Follow-ups

- **Finalize SSH provisioning:** `bootstrap.sh` still defers to a future `install_ssh` implementation.
- **Connect backup scheduling:** The `setup_backups` stub does not yet stage cron entries or copy backup scripts.
- **Complete WireGuard path:** The "complete" workflow ends with a placeholder note rather than triggering WireGuard deployment.

Tracking these items before declaring the project production-ready will prevent gaps between documentation claims and actual behavior.

## Documentation Workflow

MkDocs powers this knowledge base. Edit pages under `docs/`, adjust navigation or themes in `docs/mkdocs.yml`, and rely on the live server for feedback:

```bash
pip install mkdocs
mkdocs serve --config-file docs/mkdocs.yml   # live preview at http://127.0.0.1:8000/
mkdocs build --config-file docs/mkdocs.yml   # render static assets into the site/ directory
```

Need a refresher on MkDocs itself? See [MkDocs Tutorial](mkdocs_tutorial.md) for a step-by-step walkthrough tailored to this repository.
