#!/bin/bash
# ============================================================
# 01 - SYSTEM SETUP
# Updates, firewall, timezone, SSH hardening, essentials
# ============================================================

set -e

echo "========================================"
echo "  01 - SYSTEM SETUP"
echo "========================================"

# --- Timezone ---
echo ""
echo "Common timezones:"
echo "  1) America/New_York (Eastern)"
echo "  2) America/Chicago (Central)"
echo "  3) America/Denver (Mountain)"
echo "  4) America/Los_Angeles (Pacific)"
echo "  5) UTC"
echo "  6) Enter custom"
read -p "Pick timezone [1-6]: " tz_choice

case $tz_choice in
  1) TZ="America/New_York" ;;
  2) TZ="America/Chicago" ;;
  3) TZ="America/Denver" ;;
  4) TZ="America/Los_Angeles" ;;
  5) TZ="UTC" ;;
  6) read -p "Enter timezone (e.g. Europe/London): " TZ ;;
  *) TZ="America/New_York" ;;
esac

sudo timedatectl set-timezone "$TZ"
echo "Timezone set to $TZ"

# --- System Update ---
echo ""
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# --- Essential Packages ---
echo ""
echo "Installing essentials..."
sudo apt install -y \
  curl wget git htop net-tools unzip jq \
  ufw fail2ban ncdu tmux tree \
  ca-certificates gnupg lsb-release \
  software-properties-common apt-transport-https

# --- Firewall (UFW) ---
echo ""
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 81/tcp     # NPM Admin
sudo ufw allow 3001/tcp   # Uptime Kuma
sudo ufw allow 9443/tcp   # Portainer
sudo ufw allow 8090/tcp   # Dozzle
sudo ufw allow 8085/tcp   # ntfy
sudo ufw allow 8765/tcp   # hub
sudo ufw allow 3000/tcp   # Homepage / general app port
sudo ufw allow 8000/tcp   # Supabase Studio
sudo ufw allow 5678/tcp   # n8n
sudo ufw allow 8181/tcp   # SurrealDB
sudo ufw allow 19999/tcp  # Netdata
sudo ufw --force enable
echo "Firewall configured and enabled."

# --- SSH Hardening ---
echo ""
echo "Hardening SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable root login, disable password auth (optional - uncomment if using keys)
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
# sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

sudo systemctl restart sshd
echo "SSH hardened (root login disabled)."

# --- Fail2Ban ---
echo ""
echo "Configuring fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "Fail2ban active."

# --- Create project directory ---
echo ""
echo "Creating /srv/docker directory for all projects..."
sudo mkdir -p /srv/docker
sudo chown $USER:$USER /srv/docker

# --- Create backup directory ---
sudo mkdir -p /srv/backups
sudo chown $USER:$USER /srv/backups

echo ""
echo "========================================"
echo "  01 - SYSTEM SETUP COMPLETE"
echo "  Timezone: $TZ"
echo "  Firewall: active"
echo "  SSH: hardened"
echo "  Project dir: /srv/docker"
echo "  Backup dir: /srv/backups"
echo "========================================"
