#!/bin/bash
# Docker Complete Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/validation.sh"
source "${PROJECT_ROOT}/utils/common.sh"

log_header "Docker Installation and Configuration"

# Check if already installed
if command -v docker &>/dev/null; then
    log_info "Docker already installed: $(docker --version)"
    exit 0
fi

# Install Docker
log_step 1 4 "Installing Docker Engine"
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh
rm /tmp/get-docker.sh

# Add user to docker group
log_step 2 4 "Adding user to docker group"
sudo usermod -aG docker "$USER"

# Install Docker Compose
log_step 3 4 "Installing Docker Compose plugin"
sudo apt install -y docker-compose-plugin

# Configure Docker daemon
log_step 4 4 "Configuring Docker daemon"
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'EOFJSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOFJSON

sudo systemctl restart docker
sudo systemctl enable docker

log_success "Docker installed successfully"
echo ""
echo "IMPORTANT: Log out and back in for group changes to take effect"
echo ""
echo "Test: docker ps"
