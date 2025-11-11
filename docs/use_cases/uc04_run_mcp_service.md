# UC04 – Run MCP Service

## Overview
This use case covers launching the MCP server under supervision, ensuring configuration files, permissions, and ports are ready before the binary executes in the foreground.

## Actors
- MCP operator starting the service manually
- Systemd service executing the wrapper
- Logging infrastructure capturing runtime events

## Preconditions
- `install_mcp.sh` has staged the environment file, binary, and log directory
- User has permission to execute the MCP binary or escalate with sudo for chmod adjustments
- The configured MCP port is available or collision warnings are acceptable

## Postconditions
- MCP environment variables loaded into the process context
- Log file initialised with startup entries
- MCP binary executed with provided arguments, inheriting stdout/stderr redirection

## High-Level Flow
1. Source shared utilities and load configuration defaults.
2. Ensure log directory exists and import environment overrides.
3. Validate binary path and execute permission, rectifying if necessary.
4. Optionally warn if the configured port is already in use.
5. Launch the MCP binary, redirecting output to the service log.

## Low-Level Flow
- The wrapper reads `config/versions.conf` to locate `MCP_LOG_DIR`, `MCP_ENV_FILE`, and `MCP_BIN_PATH`.
- If `/etc/mcp/mcp.env` exists, it is sourced to override defaults; missing files generate a warning but do not abort execution.
- When the binary lacks execute permissions, the script attempts to `chmod +x` using sudo, tolerating failures.
- Port availability is checked with `ss -ltn`, logging a warning instead of blocking when the port is busy.
- The `exec` call replaces the wrapper process with the MCP binary, redirecting both stdout and stderr to `mcp-server.log`.

## UML Activity Diagram
```mermaid
flowchart TD
    A[Start run_mcp] --> B[Load env + versions]
    B --> C[Ensure log directory]
    C --> D{Env file present?}
    D -- Yes --> E[Source MCP env file]
    D -- No --> F[Log warning]
    E --> G
    F --> G
    G --> H{Binary executable?}
    H -- No --> I[Attempt chmod +x]
    H -- Yes --> J
    I --> J[Check port availability]
    J --> K[Log startup entry]
    K --> L[Exec MCP binary]
```

## UML Sequence Diagram
```mermaid
sequenceDiagram
    participant Operator
    participant RunWrapper
    participant Filesystem
    participant MCPBinary
    Operator->>RunWrapper: ./scripts/run_mcp.sh
    RunWrapper->>Filesystem: read versions.conf & mcp.env
    Filesystem-->>RunWrapper: config values
    RunWrapper->>Filesystem: ensure log dir & permissions
    RunWrapper->>RunWrapper: ss -ltn port check
    RunWrapper->>MCPBinary: exec MCP_BIN
    MCPBinary-->>Filesystem: append logs
    MCPBinary-->>Operator: service running in foreground
```

## Related Artifacts
- `scripts/run_mcp.sh`
- `config/versions.conf`
- `/etc/mcp/mcp.env`
