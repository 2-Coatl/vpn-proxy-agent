#!/bin/bash
# shellcheck shell=bash
# =============================================================================
# MCP Server Runtime Wrapper
# =============================================================================
# Description: Load configuration, emit structured logs and execute the MCP
#              server binary in the foreground.
# Usage: ./scripts/run_mcp.sh [args]
# =============================================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${REPO_ROOT}/utils/common.sh"
source "${REPO_ROOT}/config/versions.conf"

LOG_FILE_NAME="mcp-server.log"
MCP_LOG_FILE="${MCP_LOG_DIR}/${LOG_FILE_NAME}"
MCP_ENV_FILE="${MCP_ENV_FILE:-/etc/mcp/mcp.env}"
MCP_BIN="${MCP_BIN_PATH}"

log_header "Starting MCP Server"
log_section "Preparing runtime"

mkdir -p "$(dirname "$MCP_LOG_FILE")"

if [ -f "$MCP_ENV_FILE" ]; then
    log_step 1 "Loading environment file $MCP_ENV_FILE"
    # shellcheck disable=SC1090
    source "$MCP_ENV_FILE"
else
    log_warn "Environment file $MCP_ENV_FILE not found. Using defaults."
fi

if [ -z "${MCP_BIN:-}" ]; then
    log_error "MCP_BIN is not defined. Update $MCP_ENV_FILE or versions.conf"
    exit 1
fi

if [ ! -x "$MCP_BIN" ]; then
    log_warn "MCP binary $MCP_BIN is not executable. Attempting to set permissions."
    sudo chmod +x "$MCP_BIN" || true
fi

log_step 2 "Validating MCP port availability"
if command -v ss >/dev/null 2>&1; then
    if ss -ltn | grep -q ":${MCP_PORT:-$MCP_DEFAULT_PORT}\s"; then
        log_warn "Port ${MCP_PORT:-$MCP_DEFAULT_PORT} already in use"
    fi
else
    log_debug "ss command not available; skipping port collision check"
fi

log_step 3 "Launching MCP binary"
log_file "$MCP_LOG_FILE" "Starting MCP server with binary $MCP_BIN"
exec "$MCP_BIN" "$@" 2>>"$MCP_LOG_FILE" >>"$MCP_LOG_FILE"
