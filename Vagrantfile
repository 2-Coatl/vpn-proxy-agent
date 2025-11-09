# -*- mode: ruby -*-
# vi: set ft=ruby :

# =============================================================================
# VPN/Proxy Agent - Vagrantfile
# =============================================================================
# Description: Local development and testing environment
# Usage: vagrant up
# =============================================================================

Vagrant.configure("2") do |config|
  # -----------------------------------------------------------------------------
  # Box Configuration
  # -----------------------------------------------------------------------------
  
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = true
  
  # -----------------------------------------------------------------------------
  # Network Configuration
  # -----------------------------------------------------------------------------
  
  # Private network with static IP (avoids DHCP conflicts)
  config.vm.network "private_network", ip: "192.168.56.10"
  
  # Forwarded ports for services
  config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", auto_correct: true
  config.vm.network "forwarded_port", guest: 1080, host: 1080, id: "socks5"
  config.vm.network "forwarded_port", guest: 51820, host: 51820, protocol: "udp", id: "wireguard"
  config.vm.network "forwarded_port", guest: 5432, host: 5432, id: "postgres"
  config.vm.network "forwarded_port", guest: 6379, host: 6379, id: "redis"
  config.vm.network "forwarded_port", guest: 8000, host: 8000, id: "app"
  config.vm.network "forwarded_port", guest: 19999, host: 19999, id: "netdata"
  
  # -----------------------------------------------------------------------------
  # VM Provider Configuration
  # -----------------------------------------------------------------------------
  
  config.vm.provider "virtualbox" do |vb|
    vb.name = "vpn-proxy-agent-dev"
    vb.memory = "2048"
    vb.cpus = 2
    
    # Enable nested virtualization (for Docker)
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    
    # Enable DNS resolution
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    
    # Increase video memory (optional, for GUI)
    vb.customize ["modifyvm", :id, "--vram", "128"]
  end
  
  # -----------------------------------------------------------------------------
  # Synced Folders
  # -----------------------------------------------------------------------------
  
  # Sync project directory
  config.vm.synced_folder ".", "/vagrant",
    type: "virtualbox",
    owner: "vagrant",
    group: "vagrant",
    mount_options: ["dmode=775", "fmode=664"]
  
  # Create shared directory for artifacts
  config.vm.synced_folder "./artifacts", "/vagrant/artifacts",
    create: true,
    type: "virtualbox",
    owner: "vagrant",
    group: "vagrant"
  
  # -----------------------------------------------------------------------------
  # SSH Configuration
  # -----------------------------------------------------------------------------
  
  config.ssh.forward_agent = true
  config.ssh.insert_key = true
  
  # -----------------------------------------------------------------------------
  # Provisioning
  # -----------------------------------------------------------------------------
  
  # Update system and install basic tools
  config.vm.provision "shell", name: "system-update", inline: <<-SHELL
    echo "[PROVISION] Updating system..."
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq
    apt-get install -y -qq \
      curl \
      wget \
      git \
      vim \
      htop \
      net-tools \
      ca-certificates \
      gnupg \
      lsb-release \
      build-essential \
      python3 \
      python3-pip
    
    echo "[PROVISION] System updated successfully"
  SHELL
  
  # Configure proxy if needed (commented by default)
  # Uncomment and configure if you need proxy in Vagrant VM
  # config.vm.provision "shell", name: "configure-proxy", inline: <<-SHELL
  #   echo "[PROVISION] Configuring proxy..."
  #   
  #   cat > /etc/apt/apt.conf.d/95proxies << 'EOF'
  # Acquire::http::Proxy "socks5h://10.0.2.2:1080";
  # Acquire::https::Proxy "socks5h://10.0.2.2:1080";
  # EOF
  #   
  #   cat >> /etc/environment << 'EOF'
  # http_proxy="socks5h://10.0.2.2:1080"
  # https_proxy="socks5h://10.0.2.2:1080"
  # no_proxy="localhost,127.0.0.1,10.0.2.*"
  # EOF
  #   
  #   echo "[PROVISION] Proxy configured"
  # SHELL
  
  # Setup project environment
  config.vm.provision "shell", name: "setup-project", privileged: false, inline: <<-SHELL
    echo "[PROVISION] Setting up project environment..."
    
    cd /vagrant
    
    # Make scripts executable
    chmod +x bootstrap.sh
    chmod +x utils/*.sh
    chmod +x scripts/*.sh 2>/dev/null || true
    
    # Create log directory
    mkdir -p logs
    
    echo "[PROVISION] Project environment ready"
    echo ""
    echo "================================================"
    echo "  VPN/Proxy Agent Development Environment"
    echo "================================================"
    echo ""
    echo "To install the agent, run:"
    echo "  cd /vagrant"
    echo "  ./bootstrap.sh"
    echo ""
    echo "VM IP: 192.168.56.10"
    echo "SSH: vagrant ssh"
    echo ""
  SHELL
  
  # Automatically run bootstrap in automation mode during provisioning
  config.vm.provision "shell", name: "auto-bootstrap", privileged: false, inline: <<-SHELL
    set -e
    cd /vagrant

    if [ ! -f logs/bootstrap_auto_complete.flag ]; then
      echo "[PROVISION] Running bootstrap in automation mode..."
      BOOTSTRAP_AUTO=1 BOOTSTRAP_INSTALL_TYPE=standard ./bootstrap.sh
      touch logs/bootstrap_auto_complete.flag
      echo "[PROVISION] Bootstrap completed."
    else
      echo "[PROVISION] Bootstrap already completed. Skipping."
    fi
  SHELL
  
  # -----------------------------------------------------------------------------
  # Post-Up Message
  # -----------------------------------------------------------------------------
  
  config.vm.post_up_message = <<-MSG
  ===============================================
  VPN/Proxy Agent VM is ready!
  ===============================================
  
  Access VM:
    vagrant ssh
  
  Project directory:
    /vagrant
  
  Install the agent:
    vagrant ssh
    cd /vagrant
    ./bootstrap.sh
  
  Services available at:
    - SOCKS5 Proxy: localhost:1080
    - PostgreSQL:   localhost:5432
    - Redis:        localhost:6379
    - App:          localhost:8000
    - Netdata:      localhost:19999
  
  VM Management:
    vagrant halt       # Stop VM
    vagrant up         # Start VM
    vagrant reload     # Restart VM
    vagrant destroy    # Delete VM
  
  ===============================================
  MSG
end
