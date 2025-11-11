#!/bin/bash
# shellcheck shell=bash
# =============================================================================
# MCP Server Installation Script
# =============================================================================
# Description: Provision the MCP service runtime and configuration on the host.
# Usage: ./scripts/install_mcp.sh
# =============================================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${REPO_ROOT}/utils/common.sh"
source "${REPO_ROOT}/config/versions.conf"

log_header "MCP Server Installer"

create_service_principals() {
    log_section "Preparing service account"
    if id "$MCP_USER" >/dev/null 2>&1; then
        log_debug "Service user '$MCP_USER' already exists"
    else
        log_step 1 "Creating system user $MCP_USER"
        sudo useradd --system --home "$MCP_DATA_DIR" --shell /usr/sbin/nologin "$MCP_USER"
        log_success "User $MCP_USER created"
    fi

    if getent group "$MCP_GROUP" >/dev/null 2>&1; then
        log_debug "Group '$MCP_GROUP' already exists"
    else
        log_step 2 "Creating system group $MCP_GROUP"
        sudo groupadd --system "$MCP_GROUP"
        log_success "Group $MCP_GROUP created"
    fi

    sudo usermod -a -G "$MCP_GROUP" "$MCP_USER" || true
}

install_dependencies() {
    log_section "Installing dependencies"
    local packages=("curl" "jq" "netcat" "python3" "ripgrep")
    install_packages "${packages[@]}"
}

configure_language_toolchain() {
    local mise_config="${HOME}/.config/mise/config.toml"
    log_section "Configuring language runtimes"
    LANGUAGE_TOOLCHAIN_SUPPRESS_HEADER=1 configure_language_runtimes "$mise_config"
}

prepare_directories() {
    log_section "Preparing directories"
    create_directory "$MCP_INSTALL_DIR" "755" "$MCP_USER"
    create_directory "$MCP_DATA_DIR" "750" "$MCP_USER"
    create_directory "$MCP_LOG_DIR" "750" "$MCP_USER"
    create_directory "$MCP_CERT_DIR" "700" "$MCP_USER"
    sudo touch "${MCP_LOG_DIR}/mcp-server.log"
    sudo chown "$MCP_USER:$MCP_GROUP" "${MCP_LOG_DIR}/mcp-server.log"
}

install_binary_stub() {
    log_section "Staging MCP binary"
    if [ -x "$MCP_BIN_PATH" ]; then
        log_debug "Binary already present at $MCP_BIN_PATH"
        return 0
    fi

    cat <<'WRAPPER' | sudo tee "$MCP_BIN_PATH" >/dev/null
#!/bin/bash
set -euo pipefail
echo "MCP server stub - replace with real binary" >&2
sleep 2
WRAPPER
    sudo chmod 750 "$MCP_BIN_PATH"
    sudo chown "$MCP_USER:$MCP_GROUP" "$MCP_BIN_PATH"
    log_warn "Installed placeholder MCP binary. Replace with production artifact."
}

configure_environment_file() {
    log_section "Writing environment file"
    sudo mkdir -p "$(dirname "$MCP_ENV_FILE")"
    sudo tee "$MCP_ENV_FILE" >/dev/null <<EOF_ENV
# Managed by install_mcp.sh
MCP_PORT=${MCP_DEFAULT_PORT}
MCP_DATA_DIR=${MCP_DATA_DIR}
MCP_LOG_DIR=${MCP_LOG_DIR}
MCP_CERT_DIR=${MCP_CERT_DIR}
MCP_CONFIG_DIR=${MCP_CONFIG_DIR}
MCP_BIN=${MCP_BIN_PATH}
EOF_ENV
    sudo chmod 640 "$MCP_ENV_FILE"
    sudo chown "$MCP_USER:$MCP_GROUP" "$MCP_ENV_FILE"
}

configure_logrotate() {
    log_section "Configuring log rotation"
    local config_path="${MCP_LOGROTATE_CONFIG:-/etc/logrotate.d/mcp}"
    sudo tee "$config_path" >/dev/null <<EOF_LOGROTATE
${MCP_LOG_DIR}/mcp-server.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${MCP_USER} ${MCP_GROUP}
    sharedscripts
    postrotate
        systemctl reload mcp.service >/dev/null 2>&1 || true
    endscript
}
EOF_LOGROTATE
    sudo chmod 644 "$config_path"
}

deploy_systemd_unit() {
    log_section "Deploying systemd unit"
    local unit_source="${REPO_ROOT}/systemd/mcp.service"
    local unit_target="/etc/systemd/system/mcp.service"

    if [ ! -f "$unit_source" ]; then
        log_error "Missing systemd unit at $unit_source"
        return 1
    fi

    sudo cp "$unit_source" "$unit_target"
    sudo chmod 644 "$unit_target"
    sudo systemctl daemon-reload || true
    sudo systemctl enable --now mcp.service || true
    log_info "Systemd unit staged. Verify status with: sudo systemctl status mcp.service"
}

main() {
    create_service_principals
    install_dependencies
    configure_language_toolchain
    prepare_directories
    install_binary_stub
    configure_environment_file
    configure_logrotate
    deploy_systemd_unit
    log_success "MCP server installation workflow completed"
}

main "$@"
