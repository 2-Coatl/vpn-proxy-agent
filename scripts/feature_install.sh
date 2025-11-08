#!/bin/bash
# Feature Installation Script
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/utils/logging.sh"
source "${REPO_ROOT}/utils/common.sh"

log_header "Installing VPN/Proxy Agent Features"

# Read options from devcontainer feature
INSTALL_DOCKER="${installDocker:-true}"
INSTALL_WIREGUARD="${installWireguard:-false}"
SETUP_SSH="${setupSSH:-true}"
ENABLE_MONITORING="${enableMonitoring:-true}"

# Install Docker
if [ "$INSTALL_DOCKER" = "true" ]; then
    log_info "Installing Docker..."
    "${SCRIPT_DIR}/setup_docker.sh"
fi

# Install WireGuard
if [ "$INSTALL_WIREGUARD" = "true" ]; then
    log_info "Installing WireGuard..."
    "${SCRIPT_DIR}/setup_wireguard.sh"
fi

# Setup SSH
if [ "$SETUP_SSH" = "true" ]; then
    log_info "Setting up SSH..."
    "${SCRIPT_DIR}/setup_ssh.sh"
fi

# Enable monitoring
if [ "$ENABLE_MONITORING" = "true" ]; then
    log_info "Installing monitoring tools..."
    install_packages htop iotop nethogs ncdu
fi

log_success "Feature installation complete"
