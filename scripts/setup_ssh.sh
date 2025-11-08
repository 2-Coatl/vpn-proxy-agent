#!/bin/bash
# SSH Setup Script
set -e

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/utils/logging.sh"
source "${REPO_ROOT}/utils/validation.sh"
source "${REPO_ROOT}/utils/common.sh"

log_header "SSH Configuration Setup"

# Generate SSH keys if not exist
if [ ! -f ~/.ssh/id_ed25519 ]; then
    log_step 1 5 "Generating SSH keys"
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$USER@$(hostname)"
    log_success "SSH keys generated"
else
    log_info "SSH keys already exist"
fi

# Configure SSH config
log_step 2 5 "Creating SSH config"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat > ~/.ssh/config << 'EOFSSH'
Host vpn-server
    HostName CHANGE_ME
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
EOFSSH

chmod 600 ~/.ssh/config
log_success "SSH config created"

# Install OpenSSH server
log_step 3 5 "Installing OpenSSH server"
if ! is_package_installed openssh-server; then
    install_packages openssh-server
fi

# Configure SSH server
log_step 4 5 "Configuring SSH server"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

sudo tee /etc/ssh/sshd_config.d/99-custom.conf > /dev/null << 'EOFSSHD'
Port 22
Port 53
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
AllowTcpForwarding yes
GatewayPorts no
ClientAliveInterval 60
ClientAliveCountMax 3
MaxAuthTries 3
EOFSSHD

# Restart SSH
log_step 5 5 "Restarting SSH service"
sudo systemctl restart sshd

log_success "SSH setup completed"
echo ""
echo "NEXT STEPS:"
echo "1. Edit ~/.ssh/config and set HostName to your server IP"
echo "2. Copy public key to server: cat ~/.ssh/id_ed25519.pub"
echo "3. Test connection: ssh vpn-server"
