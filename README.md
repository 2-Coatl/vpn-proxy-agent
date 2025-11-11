# VPN/Proxy Agent

**Version:** 1.0.0  
**Description:** Complete automation system for VPN/Proxy setup with VS Code Remote SSH and Docker integration

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [MCP Server Deployment](#mcp-server-deployment)
- [Scripts Reference](#scripts-reference)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This project automates the setup and management of:
- **SSH Tunnel (SOCKS5 Proxy)** for bypassing network restrictions
- **WireGuard VPN** for secure full-tunnel encryption
- **VS Code Remote SSH** for remote development
- **Docker containers** (PostgreSQL, Redis, MariaDB, applications)
- **Security hardening** (UFW, Fail2Ban, SSH hardening)
- **Monitoring and maintenance** (Netdata, automated backups)

**Designed for:**
- Developers needing access to blocked APIs (Claude, OpenAI, GitHub Copilot)
- Teams requiring secure remote development environments
- System administrators managing VPN infrastructure
- Students learning VPN/networking concepts

---

## Features

### Core Functionality
- [x] SSH SOCKS5 tunnel setup (45 minutes)
- [x] WireGuard VPN installation and configuration (2 hours)
- [x] VS Code Remote SSH integration (1 hour)
- [x] Docker + Docker Compose setup (1.5 hours)
- [x] Multi-service docker-compose templates

### Security
- [x] UFW firewall configuration
- [x] Fail2Ban intrusion prevention
- [x] SSH hardening (key-only auth, alternate ports)
- [x] Automatic security updates

### Automation
- [x] Centralized configuration management
- [x] Reusable utility libraries (logging, validation, common functions)
- [x] Automated backup scripts
- [x] Health check and monitoring scripts
- [x] Systemd service integration

### Development
- [x] Vagrant support for local testing
- [x] Python build system for CPython compilation
- [x] Dev Container feature support
- [x] Comprehensive test suite

---

## Project Structure

```
vpn-proxy-agent/
├── artifacts/              # Build artifacts and outputs
│   └── ARTIFACTS.md       # Documentation of generated artifacts
├── config/                 # Configuration files
│   ├── .gitkeep
│   └── versions.conf      # Central configuration (versions, ports, paths)
├── installer/              # Installation scripts
│   ├── devcontainer_feature.json
│   ├── install.sh
│   └── README.md
├── logs/                   # Log files directory
│   └── .gitkeep
├── scripts/                # Core automation scripts
│   ├── install_mcp.sh      # Provision MCP server runtime
│   ├── run_mcp.sh          # Wrapper to start the MCP binary
│   ├── watchdog_mcp.sh     # Health checks for MCP service
│   ├── run_tests.sh        # Local regression runner with coverage
│   ├── build_cpython.sh
│   ├── build_wrapper.sh
│   ├── feature_install.sh
│   ├── validate_build.sh
│   └── validate_wrapper.sh
├── tests/                  # Test suite
│   ├── test_cpython_build_system.py
│   └── test_cpython_feature.py
├── utils/                  # Reusable utility libraries
│   ├── common.sh          # Common helper functions
│   ├── logging.sh         # Logging utilities
│   └── validation.sh      # Validation functions
├── bootstrap.sh            # Main bootstrapper script
├── README.md              # This file
└── Vagrantfile            # Vagrant configuration for local testing
```

---

## Quick Start

### Prerequisites

- **OS:** Ubuntu 22.04 LTS (or 20.04, 24.04)
- **RAM:** 2GB minimum (4GB recommended)
- **Disk:** 10GB free space
- **Network:** Internet connection
- **Privileges:** sudo access

### 3-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/vpn-proxy-agent.git
cd vpn-proxy-agent

# 2. Run bootstrap
chmod +x bootstrap.sh
./bootstrap.sh

# 3. Follow prompts
# Choose your installation type:
#   - Quick (SSH Tunnel only - 45 min)
#   - Standard (SSH + Docker + Security - 4 hours)
#   - Complete (Everything including WireGuard - 9 hours)

# Provisioning with Vagrant runs `bootstrap.sh` automatically in automation mode
# (see docs/index.md#quick-start for additional context).
```

> **Tip:** When provisioning with Vagrant, the bootstrap script now runs automatically during `vagrant up`. You can still SSH
> into the VM and rerun `BOOTSTRAP_AUTO=1 ./bootstrap.sh` if you need to reset the environment.

### What happens after provisioning?

Once the VM finishes bootstrapping you can connect with `vagrant ssh` and review the generated log in
`~/logs/bootstrap_latest.log` to confirm all steps completed successfully. From there you can:

- Run the smoke-test suite with `bash tests/test_bootstrap.sh` to validate the environment.
- Adjust configuration files under `config/` and rerun `BOOTSTRAP_AUTO=1 ./bootstrap.sh` to apply the changes.
- Follow the service-specific guides in `docs/` (for example, WireGuard or SOCKS5) to start using the stack.

---

## Installation

### Option 1: Automated Bootstrap

The `bootstrap.sh` script provides an interactive installation:

```bash
./bootstrap.sh
```

**What it does:**
1. Detects OS and validates system requirements
2. Installs dependencies
3. Configures SSH keys
4. Sets up tunnel/VPN
5. Installs Docker (if selected)
6. Configures VS Code Remote (if selected)
7. Sets up monitoring and backups

### Option 2: Manual Installation

#### Step 1: Configure versions.conf

```bash
# Edit config/versions.conf
nano config/versions.conf

# Set your preferences:
DEFAULT_PYTHON_VERSION="3.12.6"
ENABLE_WIREGUARD="true"
ENABLE_DOCKER="true"
```

#### Step 2: Run individual scripts

```bash
# SSH Setup
./scripts/setup_ssh.sh

# Docker Installation
./scripts/setup_docker.sh

# WireGuard VPN (optional)
./scripts/setup_wireguard.sh
```

### Option 3: Vagrant (Local Testing)

```bash
# Start Vagrant VM
vagrant up

# SSH into VM
vagrant ssh

# Wait for provisioning to finish (bootstrap runs automatically)
# Logs are written to /vagrant/logs/bootstrap_*.log

# (Optional) SSH into VM for inspection or manual reruns
vagrant ssh
cd /vagrant
# Re-run bootstrap in automation mode if you need to reset
BOOTSTRAP_AUTO=1 ./bootstrap.sh
```

> 📘 **Need more detail?** See [Automated Vagrant provisioning](docs/index.md#quick-start) for a walkthrough of the automated flow
> and manual rerun options.

---

## Configuration

### Central Configuration File

All settings are in `config/versions.conf`:

```bash
# Python
DEFAULT_PYTHON_VERSION="3.12.6"
PYTHON_INSTALL_PREFIX="/opt/python"

# Network
VPN_DEFAULT_PORT="51820"
SSH_DEFAULT_PORT="22"
SOCKS5_DEFAULT_PORT="1080"

# Docker
POSTGRES_DEFAULT_PORT="5432"
REDIS_DEFAULT_PORT="6379"

# Paths
PROJECT_ROOT="/home/ubuntu/projects"
LOGS_DIR="/home/ubuntu/logs"
BACKUPS_DIR="/home/ubuntu/backups"

# Feature Flags
ENABLE_WIREGUARD="false"
ENABLE_DOCKER="true"
ENABLE_MONITORING="true"
```

### Environment Variables

Create `.env` file for sensitive data:

```bash
# API Keys
ANTHROPIC_API_KEY="your-key-here"
OPENAI_API_KEY="your-key-here"

# Database
POSTGRES_PASSWORD="secure-password"
REDIS_PASSWORD="secure-password"

# VPN
WIREGUARD_PRIVATE_KEY="your-private-key"
```

#### Bootstrap automation flags

These environment variables control non-interactive provisioning:

| Variable | Description |
| --- | --- |
| `BOOTSTRAP_AUTO` | Enables automation mode so `bootstrap.sh` skips interactive prompts. |
| `BOOTSTRAP_INSTALL_TYPE` | Forces the installation tier (`quick`, `standard`, or `complete`) when automation is enabled. |
| `BOOTSTRAP_ASSUME_YES` | Auto-confirms prompts that are still shown when automation is disabled. |
| `BOOTSTRAP_DRY_RUN` | Executes the full bootstrap flow without applying system changes—ideal for CI validation and regression tests. |

---

## Usage

### Starting Services

```bash
# SSH Tunnel
./scripts/start_tunnel.sh

# WireGuard VPN
sudo wg-quick up wg0

# Docker Services
cd ~/projects/your-project
docker compose up -d
```

### Monitoring

```bash
# System dashboard
./scripts/dashboard.sh

# Health check
./scripts/health_check.sh

# View logs
tail -f logs/monitor.log
```

### Maintenance

```bash
# System updates
./scripts/safe_update.sh

# Backups
./scripts/backup_full.sh

# Cleanup
./scripts/cleanup.sh
```

---

## MCP Server Deployment

The repository ahora incluye un flujo completo para instalar y operar un servidor MCP sin depender de contenedores.

### 1. Definir parámetros
- Ajusta los valores bajo `config/versions.conf` en la sección **MCP Service Configuration**.
- Declara las versiones de lenguajes en `MCP_RUNTIME_TOOLCHAIN` para alinear `mise` con el entorno esperado.
- Verifica puertos y rutas con `utils/validation.sh` si personalizas el despliegue.

### 2. Instalación standalone

```bash
# Ejecutar el instalador directamente
./scripts/install_mcp.sh

# Revisar los logs del servicio
tail -f /var/log/mcp/mcp-server.log
```

### 3. Bootstrap dedicado

```bash
# Orquestar únicamente el servidor MCP
./bootstrap.sh --mcp
```

La ruta `--mcp` ejecuta `install_mcp.sh`, valida el servicio con `watchdog_mcp.sh` y deja listo el unit file `systemd/mcp.service`.

### 4. Operación diaria
- Inicia el proceso con `/usr/local/bin/run_mcp.sh` (empaquetado por el instalador).
- Supervisa la disponibilidad con `./scripts/watchdog_mcp.sh` o `sudo systemctl status mcp.service`.
- Personaliza variables sensibles en `/etc/mcp/mcp.env`.

#### Ejemplo de inventario Ansible

```ini
[mcp_servers]
mcp-prod ansible_host=10.0.0.5 ansible_user=ubuntu mcp_port=2288

[mcp_servers:vars]
mcp_bin=/usr/local/bin/mcp-server
mcp_env=/etc/mcp/mcp.env
```

---

## Scripts Reference

### MCP Service Scripts

#### scripts/install_mcp.sh
Idempotent installer that crea el usuario del servicio, directorios `/var/lib/mcp` y `/var/log/mcp`, despliega un binario placeholder, registra la unidad `systemd/mcp.service` y genera `~/.config/mise/config.toml` con el toolchain MCP.

#### scripts/run_mcp.sh
Wrapper que carga `/etc/mcp/mcp.env`, redirige logs a `logs/mcp-server.log` y ejecuta el binario configurado con validaciones previas.

#### scripts/watchdog_mcp.sh
Watchdog que valida conectividad TCP (`nc`), proceso (`pgrep`) y endpoint HTTP (`curl`) para detectar incidentes.

#### scripts/run_tests.sh
Ejecutor combinado que corre `pytest` con `coverage` (fail-under 80%) y la suite bash `tests/test_utilities.sh`, dejando reportes XML/HTML en `artifacts/coverage/`.

### Utility Libraries

#### utils/logging.sh
Centralized logging functions:
- `log_info()` - Informational messages
- `log_success()` - Success messages
- `log_warn()` - Warning messages
- `log_error()` - Error messages
- `log_step()` - Numbered steps
- `log_header()` - Section headers
- `start_timer()` / `end_timer()` - Execution timing

#### utils/validation.sh
Validation functions:
- `validate_command_exists()` - Check if command available
- `validate_python_version()` - Validate Python version format
- `validate_file_exists()` - Check file existence
- `validate_checksum()` - Verify SHA256 checksums
- `validate_port()` - Validate port numbers
- `validate_ip()` - Validate IP addresses
- `validate_ubuntu_version()` - Check OS version

#### utils/common.sh
Common helper functions:
- `detect_os_version()` - Detect OS and set variables
- `install_packages()` - Install system packages
- `download_file()` - Download files with fallback
- `extract_tarball()` - Extract compressed archives
- `create_temp_dir()` - Create temporary directories
- `cleanup_temp_dir()` - Cleanup temporary files
- `enable_service()` - Enable systemd services

### Core Scripts

#### bootstrap.sh
Main installation orchestrator

**Usage:**
```bash
./bootstrap.sh [--quick|--standard|--complete]
```

#### scripts/build_cpython.sh
Build CPython from source

**Usage:**
```bash
./scripts/build_cpython.sh [version]
```

#### scripts/setup_ssh.sh
Configure SSH keys and tunnel

**Usage:**
```bash
./scripts/setup_ssh.sh
```

#### scripts/setup_docker.sh
Install and configure Docker

**Usage:**
```bash
./scripts/setup_docker.sh
```

---

## Testing

### Unified regression runner

```bash
# Ejecuta pytest con cobertura (80%) y la suite bash
./scripts/run_tests.sh
```

### Unit Tests

```bash
# Install pytest
pip install pytest

# Run all tests
pytest tests/

# Run specific test
pytest tests/test_cpython_build_system.py

# With coverage
pytest --cov=scripts tests/
```

### Integration Tests

```bash
# Test in Vagrant VM
vagrant up
vagrant ssh

# Bootstrap runs automatically; rerun in automation mode if needed
cd /vagrant
BOOTSTRAP_AUTO=1 ./bootstrap.sh --quick

# Validate installation
./scripts/validate_build.sh
```

### Manual Testing

```bash
# Test SSH tunnel
ssh -D 1080 -f -N vpn-server
netstat -an | grep 1080

# Test API access
curl --socks5 localhost:1080 https://api.anthropic.com

# Test Docker
docker ps
docker compose ps
```

---

## Troubleshooting

### Common Issues

#### SSH Connection Fails
```bash
# Check SSH service
sudo systemctl status sshd

# View logs
sudo tail -50 /var/log/auth.log

# Test connection with verbose output
ssh -vvv user@server
```

#### Tunnel Not Working
```bash
# Check if tunnel is active
netstat -an | grep 1080

# Restart tunnel
pkill -f "ssh.*-D.*1080"
ssh -D 1080 -f -N vpn-server

# Test connectivity
curl --socks5 localhost:1080 https://ipinfo.io/json
```

#### Docker Containers Won't Start
```bash
# View logs
docker compose logs

# Restart services
docker compose down
docker compose up -d

# Check resources
docker stats
df -h
```

### Diagnostic Scripts

```bash
# Full system diagnostic
./scripts/diagnose_all.sh

# Health check
./scripts/health_check.sh

# View recent logs
./scripts/view_logs.sh
```

### Getting Help

1. Check the logs in `logs/` directory
2. Run diagnostic scripts
3. Review error messages carefully
4. Check GitHub Issues
5. Consult documentation in `docs/`

---

## Contributing

Contributions are welcome! Please follow these guidelines:

### Code Style

- Use **shellcheck** for bash scripts
- Follow **Google Shell Style Guide**
- No emojis in scripts (use text markers instead)
- Add comments for complex logic
- Use utility functions (logging, validation, common)

### Adding New Features

1. Create feature branch
2. Add to appropriate directory (scripts/, utils/, tests/)
3. Update `config/versions.conf` if needed
4. Add tests
5. Update documentation
6. Submit pull request

### Testing Requirements

- All new scripts must have corresponding tests
- Test coverage should be >80%
- Test in Vagrant VM before submitting
- Include edge cases and error handling

---

## License

MIT License

Copyright (c) 2025 VPN/Proxy Agent Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Acknowledgments

- Ubuntu Community for excellent documentation
- WireGuard team for the VPN technology
- Docker team for containerization platform
- VS Code team for Remote SSH extension
- All contributors and testers

---

## Contact

- **GitHub Issues:** https://github.com/your-org/vpn-proxy-agent/issues
- **Documentation:** https://github.com/your-org/vpn-proxy-agent/wiki
- **Email:** support@your-org.com

---

**Last Updated:** November 2025  
**Version:** 1.0.0
