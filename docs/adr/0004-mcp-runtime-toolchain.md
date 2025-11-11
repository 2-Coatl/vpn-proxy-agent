# ADR 0004: Gestión de runtimes MCP con mise

## Estado
Aceptado

## Contexto
Durante la provisión del servidor MCP observamos que el flujo de bootstrap no reproducía la preparación del "toolchain" de lenguajes que muestra la infraestructura de referencia. Las bitácoras de Vagrant evidenciaban que no se generaba ninguna configuración para `mise` ni se dejaban trazas de las versiones esperadas de Python, Node.js, Ruby u otros lenguajes. Esto ocasionaba confusión al validar el entorno y dificultaba documentar qué intérpretes debían estar disponibles para ejecutar los agentes y herramientas asociadas.

## Decisión
Centralizamos las versiones requeridas en `config/versions.conf` bajo la variable `MCP_RUNTIME_TOOLCHAIN` y añadimos el helper `configure_language_runtimes` en `utils/common.sh`. El instalador `scripts/install_mcp.sh` invoca este helper para escribir `~/.config/mise/config.toml`, registrar cada lenguaje con su versión objetivo y, cuando `mise` está disponible, dejar preparado el entorno global. Todo el flujo reutiliza las utilidades de logging para producir salidas auditables.

## Consecuencias
- El equipo dispone de un punto único para ajustar versiones de los lenguajes soportados por el servidor MCP.
- Las ejecuciones de bootstrap generan evidencia explícita de la preparación del toolchain, alineando las bitácoras con las expectativas operativas.
- La instalación puede ejecutarse incluso si `mise` no está presente; en ese caso se generan los comandos sugeridos y se conserva la configuración para una aplicación manual posterior.
