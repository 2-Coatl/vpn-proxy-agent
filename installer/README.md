# VPN/Proxy Agent - Installer

Standalone installer for VPN/Proxy Agent system.

## Quick Install

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/your-org/vpn-proxy-agent/main/installer/install.sh | bash
```

### Manual Install

```bash
# Download installer
wget https://raw.githubusercontent.com/your-org/vpn-proxy-agent/main/installer/install.sh

# Make executable
chmod +x install.sh

# Run installer
./install.sh
```

## Dev Container Feature

This project can be used as a VS Code Dev Container Feature.

### Usage in devcontainer.json

```json
{
  "features": {
    "ghcr.io/your-org/vpn-proxy-agent:1.0.0": {
      "version": "latest",
      "installDocker": true,
      "installWireguard": false,
      "setupSSH": true,
      "enableMonitoring": true
    }
  }
}
```

### Feature Options

- `version` - Version to install (default: "latest")
- `installDocker` - Install Docker (default: true)
- `installWireguard` - Install WireGuard VPN (default: false)
- `setupSSH` - Configure SSH (default: true)
- `enableMonitoring` - Install monitoring tools (default: true)

## What Gets Installed

The installer will:

1. Check system requirements
2. Download the project
3. Make scripts executable
4. Set up directory structure
5. Configure basic settings

## Post-Installation

After installation, run:

```bash
cd ~/vpn-proxy-agent
./bootstrap.sh
```

Choose installation type:
- **Quick** (45 min) - SSH Tunnel only
- **Standard** (4 hours) - SSH + Docker + Security
- **Complete** (9 hours) - Everything + WireGuard

## Requirements

- Ubuntu 20.04, 22.04, or 24.04
- 1GB free disk space
- Sudo privileges
- Internet connection

## Troubleshooting

### Permission Denied

Make sure you're not running as root:
```bash
whoami  # Should NOT be 'root'
```

### Insufficient Disk Space

Check available space:
```bash
df -h ~
```

Need at least 1GB free.

### Network Issues

If download fails, try manual download:
```bash
git clone https://github.com/your-org/vpn-proxy-agent.git
cd vpn-proxy-agent
./bootstrap.sh
```

## Support

- GitHub Issues: https://github.com/your-org/vpn-proxy-agent/issues
- Documentation: See main README.md
