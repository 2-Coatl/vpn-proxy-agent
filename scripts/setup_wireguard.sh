#!/bin/bash
set -e

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/utils/logging.sh"

log_header "Installing WireGuard"
sudo apt update
sudo apt install -y wireguard wireguard-tools
log_success "WireGuard installed. Configure /etc/wireguard/wg0.conf manually"
