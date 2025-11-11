# Plan Maestro para el Servidor MCP sin Docker

Este plan integra todas las tareas y subtareas necesarias para implementar y operar un servidor MCP sin depender de Docker ni de GitHub Actions. Cada sección sigue el flujo TDD (Red → Green → Refactor) y alinea los entregables con la infraestructura existente del repositorio.

## Tareas Principales

### 1. Definir parámetros y dependencias
- [x] Documentar en `config/versions.conf` los puertos, rutas y flags del servicio MCP.
- [x] Inventariar dependencias de sistema (Python, bibliotecas MCP, herramientas de red) y validarlas con `utils/validation.sh`.
- [x] Diseñar plantillas de configuración bajo `/etc/mcp` reutilizando helpers de `utils/common.sh`.

### 2. Implementar scripts de instalación y operación
- [x] Crear `scripts/install_mcp.sh` con logging consistente (`utils/logging.sh`).
  - [x] Instalar paquetes idempotentemente con `install_packages`.
  - [x] Crear usuario/grupo de servicio y directorios (`/var/lib/mcp`, `/var/log/mcp`).
  - [x] Gestionar certificados y llaves en una ruta parametrizable.
  - [x] Preparar runtimes con `mise` tomando versiones de `config/versions.conf`.
  - [x] Configurar Git para usar el túnel SOCKS5 aplicando `MCP_GIT_PROXY` desde `config/versions.conf`.
- [x] Elaborar `scripts/run_mcp.sh` como wrapper del binario o entrypoint Python.
  - [x] Incluir soporte para variables de entorno y archivo `.env` opcional.
  - [x] Redirigir logs a `logs/mcp-server.log` con rotación basada en `logrotate`.

### 3. Integración con systemd
- [x] Escribir `systemd/mcp.service` con `ExecStart=/usr/local/bin/run_mcp.sh`.
  - [x] Configurar `Restart=on-failure` y límites de recursos.
  - [x] Añadir dependencia opcional a `network-online.target`.
- [x] Diseñar un watchdog `scripts/watchdog_mcp.sh` para chequeos de salud.
  - [x] Implementar validación de puerto con `nc`/`ss` y alertas en logs.

### 4. Extender bootstrap
- [x] Añadir flag `--mcp` en `bootstrap.sh` para activar el flujo.
  - [x] Integrar el instalador MCP en la orquestación existente.
  - [x] Registrar cada paso con `log_section` y `log_step`.
- [x] Actualizar documentación de uso (`docs/index.md` y `README.md`).
- [x] Crear ejemplos de inventarios o playbooks si se integra con otras herramientas.

### 5. Pruebas y calidad continua
- [x] Incorporar `tests/test_mcp_service.py` replicando el enfoque de TDD.
  - [x] Validar existencia, permisos y `shellcheck` para scripts nuevos.
  - [x] Simular escenarios de fallo (puerto ocupado, dependencia ausente).
- [x] Configurar métricas de cobertura ≥ 80 % y reportes en `artifacts/`.
- [x] Automatizar pruebas locales con `scripts/run_tests.sh` (sin CI externo).

## Backlog Proactivo
- [ ] Observabilidad: instrumentar métricas y dashboards (Prometheus/Grafana).
- [ ] Seguridad: endurecer permisos, rotación de credenciales y escaneo SAST.
- [ ] Capacitación: preparar workshops internos y runbooks operativos.
- [ ] Documentación continua: mantener ADRs y changelog del servicio MCP.
- [ ] Gestión de incidentes: definir procedimientos de respuesta y simulacros.

## Prompt Engineering de referencia
- [ ] **Briefing inicial**: "Actúa como ingeniero de plataforma. Dame riesgos y prerequisitos antes de tocar código MCP sin Docker."
- [ ] **Revisión de scripts**: "Evalúa \\`scripts/install_mcp.sh\\` buscando comandos no idempotentes ni dependencias ocultas."
- [ ] **Validación de operatividad**: "Simula la ejecución de \\`systemd/mcp.service\\` y describe logs esperados ante fallos del binario."
- [ ] **Aseguramiento continuo**: "Genera casos de prueba adicionales para cubrir rutas de error en \\`scripts/run_mcp.sh\\`."

Estas guías de prompt refuerzan el trabajo colaborativo entre agentes y humanos, asegurando que cada iteración mantenga foco en calidad, seguridad y trazabilidad.
