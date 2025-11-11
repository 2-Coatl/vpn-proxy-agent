# Use Case Catalogue Overview

El repositorio **vpn-proxy-agent** abarca flujos de aprovisionamiento, operación, mantenimiento y herramientas de desarrollo. Para facilitar la navegación se documentó cada caso de uso en un artefacto individual dentro de `docs/use_cases/` con información de actores, precondiciones, flujos y diagramas UML.

## Cómo leer este catálogo

- El siguiente cuadro resume los casos de uso identificados y enlaza a la documentación detallada.
- Cada documento incluye diagramas de actividad (alto nivel) y de secuencia (bajo nivel) generados con Mermaid.
- Los identificadores mantienen el prefijo `UCxx` para conservar trazabilidad con los scripts o componentes que implementan el flujo.

## Resumen de casos de uso

| ID | Título | Script(s) principal(es) |
| --- | --- | --- |
| [UC01](use_cases/uc01_bootstrap_standard_install.md) | Bootstrap Standard Install | `bootstrap.sh` |
| [UC02](use_cases/uc02_master_setup_pipeline.md) | Master Setup Pipeline | `scripts/master_setup.sh` |
| [UC03](use_cases/uc03_install_mcp_runtime.md) | Install MCP Runtime | `scripts/install_mcp.sh` |
| [UC04](use_cases/uc04_run_mcp_service.md) | Run MCP Service | `scripts/run_mcp.sh` |
| [UC05](use_cases/uc05_watchdog_mcp_recovery.md) | Watchdog MCP Recovery | `scripts/watchdog_mcp.sh` |
| [UC06](use_cases/uc06_setup_ssh_service.md) | Setup SSH Service | `scripts/setup_ssh.sh` |
| [UC07](use_cases/uc07_setup_tunnel_listener.md) | Setup Tunnel Listener | `scripts/setup_tunnel.sh` |
| [UC08](use_cases/uc08_watchdog_tunnel_continuity.md) | Watchdog Tunnel Continuity | `scripts/watchdog_tunnel.sh` |
| [UC09](use_cases/uc09_setup_wireguard_gateway.md) | Setup WireGuard Gateway | `scripts/setup_wireguard.sh` |
| [UC10](use_cases/uc10_setup_docker_runtime.md) | Setup Docker Runtime | `scripts/setup_docker.sh` |
| [UC11](use_cases/uc11_backup_daily_rotations.md) | Backup Daily Rotations | `scripts/backup_daily.sh` |
| [UC12](use_cases/uc12_backup_system_snapshot.md) | Backup System Snapshot | `scripts/backup_system.sh` |
| [UC13](use_cases/uc13_safe_update_stack.md) | Safe Update Stack | `scripts/safe_update.sh` |
| [UC14](use_cases/uc14_health_check_monitoring.md) | Health Check Monitoring | `scripts/health_check.sh` |
| [UC15](use_cases/uc15_diagnose_all_tooling.md) | Diagnose All Tooling | `scripts/diagnose_all.sh` |
| [UC16](use_cases/uc16_dashboard_status_board.md) | Dashboard Status Board | `scripts/dashboard.sh` |
| [UC17](use_cases/uc17_run_tests_pipeline.md) | Run Tests Pipeline | `scripts/run_tests.sh` |
| [UC18](use_cases/uc18_validate_build_artifacts.md) | Validate Build Artifacts | `scripts/validate_build.sh` |
| [UC19](use_cases/uc19_validate_wrapper_entrypoint.md) | Validate Wrapper Entrypoint | `scripts/validate_wrapper.sh` |
| [UC20](use_cases/uc20_build_docs_pipeline.md) | Build Docs Pipeline | `scripts/build_docs.sh` |
| [UC21](use_cases/uc21_build_cpython_from_source.md) | Build CPython from Source | `scripts/build_cpython.sh` |
| [UC22](use_cases/uc22_build_wrapper_ci_integration.md) | Build Wrapper CI Integration | `scripts/build_wrapper.sh` |
| [UC23](use_cases/uc23_feature_install_customization.md) | Feature Install Customization | `scripts/feature_install.sh` |
| [UC24](use_cases/uc24_restart_services_recovery.md) | Restart Services Recovery | `scripts/restart_services.sh` |
| [UC25](use_cases/uc25_run_mcp_wrapper.md) | Run MCP Wrapper | `scripts/run_mcp.sh` |
| [UC26](use_cases/uc26_backup_windows_diagnostics.md) | Backup Windows Diagnostics | `scripts/windows/diagnose-windows.ps1` |
| [UC27](use_cases/uc27_windows_start_environment.md) | Windows Start Environment | `scripts/windows/start-dev-environment.ps1` |
| [UC28](use_cases/uc28_windows_stop_environment.md) | Windows Stop Environment | `scripts/windows/stop-dev-environment.ps1` |

## Actualización

Cada vez que se agregue o modifique un flujo en `scripts/` o en los orquestadores principales, documenta el nuevo caso de uso replicando la estructura de los archivos existentes y actualiza esta tabla junto con la navegación de MkDocs.
