#!/bin/bash
set -e
echo "Installing WireGuard..."
sudo apt update
sudo apt install -y wireguard wireguard-tools
echo "WireGuard installed. Configure /etc/wireguard/wg0.conf manually"
