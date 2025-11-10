#!/bin/bash
# shellcheck shell=bash
# =============================================================================
# MCP Server Watchdog
# =============================================================================
# Description: Perform lightweight health checks against the MCP server.
# Usage: ./scripts/watchdog_mcp.sh
# =============================================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${REPO_ROOT}/utils/common.sh"
source "${REPO_ROOT}/config/versions.conf"

log_header "MCP Server Watchdog"
log_section "MCP Watchdog"

HOST="127.0.0.1"
PORT="${MCP_DEFAULT_PORT}"

log_step 1 "Checking TCP connectivity on ${HOST}:${PORT}"
if command -v nc >/dev/null 2>&1; then
    if nc -z "$HOST" "$PORT"; then
        log_success "MCP port ${PORT} is reachable"
    else
        log_error "Unable to connect to MCP port ${PORT}"
        exit 1
    fi
else
    log_warn "nc command not available. Skipping TCP connectivity check."
fi

log_step 2 "Verifying process state"
if command -v pgrep >/dev/null 2>&1; then
    if pgrep -f "$MCP_SERVICE_NAME" >/dev/null 2>&1; then
        log_success "MCP process detected"
    else
        log_error "MCP process not found"
        exit 1
    fi
else
    log_warn "pgrep not available. Skipping process validation."
fi

log_step 3 "Probing health endpoint"
if command -v curl >/dev/null 2>&1; then
    if curl --fail --silent --max-time 5 "$MCP_HEALTHCHECK_URL" >/dev/null; then
        log_success "Health endpoint ${MCP_HEALTHCHECK_URL} responded successfully"
    else
        log_error "Health endpoint ${MCP_HEALTHCHECK_URL} is not responding"
        exit 1
    fi
else
    log_warn "curl not installed. Skipping health endpoint probe."
fi

log_success "MCP watchdog checks completed"
