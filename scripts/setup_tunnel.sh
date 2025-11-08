#!/bin/bash
# SSH Tunnel Setup Script
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/utils/logging.sh"

log_header "SSH SOCKS5 Tunnel Setup"

# Check SSH config
if [ ! -f ~/.ssh/config ]; then
    log_error "SSH config not found. Run setup_ssh.sh first"
    exit 1
fi

# Check if tunnel already running
if netstat -tlnp 2>/dev/null | grep -q ":1080"; then
    log_warn "Tunnel already running on port 1080"
    exit 0
fi

# Start tunnel
log_info "Starting SOCKS5 tunnel on localhost:1080..."
ssh -D 1080 -f -N vpn-server || {
    log_error "Failed to start tunnel"
    exit 1
}

sleep 2

# Verify
if netstat -tlnp 2>/dev/null | grep -q ":1080"; then
    log_success "Tunnel active on localhost:1080"
else
    log_error "Tunnel failed to start"
    exit 1
fi

echo ""
echo "Test tunnel:"
echo "  curl --socks5 localhost:1080 https://api.anthropic.com"
