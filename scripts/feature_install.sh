#!/bin/bash
# Feature Installation Script
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/utils/logging.sh"

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
