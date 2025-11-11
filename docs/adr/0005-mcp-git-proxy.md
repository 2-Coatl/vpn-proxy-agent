# ADR 0005: Configurar Git del servidor MCP para usar el túnel SOCKS5

## Status
Accepted

## Contexto

Durante la provisión del servidor MCP observamos fallos recurrentes al ejecutar `git fetch` y otros comandos HTTPS contra GitHub. El entorno corporativo exige un proxy autenticado que responde con `CONNECT tunnel failed, response 403`, bloqueando la sincronización de repositorios incluso cuando el proyecto levanta un túnel SSH en `localhost:1080` para tráfico saliente. Sin una configuración explícita, Git ignora el túnel y continúa usando el proxy corporativo.

## Decisión

Agregamos la variable `MCP_GIT_PROXY` a `config/versions.conf` con el valor predeterminado `socks5h://127.0.0.1:1080` y expusimos la función `configure_git_proxy` en `utils/common.sh`. El instalador `scripts/install_mcp.sh` invoca esta función durante la fase de configuración para escribir `http.proxy`, `https.proxy` y las entradas específicas de GitHub en el `~/.gitconfig` del servicio, o para limpiarlas cuando `MCP_GIT_PROXY` se establece vacío.

## Consecuencias

- Git utiliza automáticamente el túnel SOCKS5 del proyecto, evitando los errores `CONNECT tunnel failed` en entornos restringidos.
- Los valores pueden ajustarse en `config/versions.conf` para apuntar a otro proxy o deshabilitarse dejando `MCP_GIT_PROXY` vacío.
- Documentamos el cambio en el README y en la guía del MCP para que operadores y agentes sepan cómo adaptar la configuración cuando el puerto del túnel cambie.
