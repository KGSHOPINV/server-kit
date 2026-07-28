#!/bin/bash
# ============================================================
# 12 - SECURITY HARDENING
# Intrusion detection, vulnerability scanning, audit logging,
# rootkit detection, network monitoring, auto-banning
# ============================================================

set -e

echo "========================================"
echo "  12 - SECURITY HARDENING"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Fail2Ban (already installed in 01, configure here) ---
echo ""
echo "Configuring Fail2Ban (auto-ban attackers)..."

sudo tee /etc/fail2ban/jail.local > /dev/null << 'JAILEOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
banaction = ufw

# Ban repeat offenders longer
[recidive]
enabled  = true
logpath  = /var/log/fail2ban.log
bantime  = 1w
findtime = 1d
maxretry = 3

[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h

[sshd-ddos]
enabled = true
port    = ssh
logpath = /var/log/auth.log
maxretry = 6
bantime = 48h
JAILEOF

sudo systemctl restart fail2ban
echo "Fail2Ban configured — 3 SSH failures = 24hr ban, repeat offenders = 1 week."

# --- CrowdSec (modern intrusion detection) ---
echo ""
read -p "Install CrowdSec (community-driven intrusion detection)? (y/n): " install_crowdsec
if [[ "$install_crowdsec" == "y" ]]; then
  echo "Installing CrowdSec..."
  curl -s https://install.crowdsec.net | sudo sh
  sudo apt install -y crowdsec crowdsec-firewall-bouncer-iptables

  # Enroll in community blocklists
  echo ""
  echo "CrowdSec installed."
  echo "  - Detects attacks using log analysis"
  echo "  - Shares threat data with community"
  echo "  - Auto-bans known attacker IPs"
  echo ""
  echo "  To enroll in console: sudo cscli console enroll YOUR_KEY"
  echo "  Get key at: https://app.crowdsec.net"
fi

# --- rkhunter (rootkit detection) ---
echo ""
echo "Installing rkhunter (rootkit scanner)..."
sudo apt install -y rkhunter
sudo rkhunter --update 2>/dev/null || true
sudo rkhunter --propupd
echo "rkhunter installed. Run: sudo rkhunter --check"

# --- Lynis (security auditor) ---
echo ""
echo "Installing Lynis (security audit tool)..."
sudo apt install -y lynis
echo "Lynis installed. Run: sudo lynis audit system"

# --- aide (file integrity monitoring) ---
echo ""
read -p "Install AIDE (file integrity monitor — detects unauthorized changes)? (y/n): " install_aide
if [[ "$install_aide" == "y" ]]; then
  sudo apt install -y aide
  echo "Initializing AIDE database (this takes a few minutes)..."
  sudo aideinit
  sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
  echo "AIDE installed. Run: sudo aide --check"
  echo "It will tell you if ANY system file has been modified."
fi

# --- Docker Bench Security ---
echo ""
echo "Installing Docker Bench Security (Docker security audit)..."
BENCH_DIR="/srv/docker/docker-bench"
mkdir -p "$BENCH_DIR"
cd "$BENCH_DIR"
if [ ! -d "docker-bench-security" ]; then
  git clone https://github.com/docker/docker-bench-security.git
fi
echo "Docker Bench installed. Run: cd $BENCH_DIR/docker-bench-security && sudo sh docker-bench-security.sh"

# --- Trivy (container vulnerability scanner) ---
echo ""
read -p "Install Trivy (scan Docker images for vulnerabilities)? (y/n): " install_trivy
if [[ "$install_trivy" == "y" ]]; then
  sudo apt install -y wget apt-transport-https gnupg lsb-release
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
  sudo apt update
  sudo apt install -y trivy
  echo "Trivy installed. Scan an image: trivy image nginx:latest"
fi

# --- Unattended upgrades (auto security patches) ---
echo ""
echo "Configuring automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

# Enable automatic security updates
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << 'UPGRADEEOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
UPGRADEEOF

echo "Automatic security updates enabled."

# --- Network monitoring with iftop/nethogs ---
echo ""
echo "Installing network monitoring tools..."
sudo apt install -y iftop nethogs nmap

# --- Audit logging ---
echo ""
echo "Installing auditd (system audit logging)..."
sudo apt install -y auditd

# Watch for suspicious activity
sudo tee /etc/audit/rules.d/server-kit.rules > /dev/null << 'AUDITEOF'
# Monitor SSH config changes
-w /etc/ssh/sshd_config -p wa -k ssh_config

# Monitor user/group changes
-w /etc/passwd -p wa -k user_changes
-w /etc/shadow -p wa -k password_changes
-w /etc/group -p wa -k group_changes

# Monitor sudo usage
-w /var/log/auth.log -p wa -k auth_log

# Monitor Docker socket
-w /var/run/docker.sock -p wa -k docker_socket

# Monitor crontab changes
-w /etc/crontab -p wa -k crontab
-w /var/spool/cron/ -p wa -k user_crontabs

# Monitor firewall changes
-w /etc/ufw/ -p wa -k firewall
AUDITEOF

sudo systemctl restart auditd
echo "Audit logging configured."

# --- Install security tools script ---
sudo cp "$SCRIPT_DIR/tools/security-check.sh" /usr/local/bin/security-check
sudo chmod +x /usr/local/bin/security-check

# Add alias
if ! grep -q "alias sec=" ~/.bashrc 2>/dev/null; then
  echo 'alias sec="security-check"' >> ~/.bashrc
fi

echo ""
echo "========================================"
echo "  12 - SECURITY HARDENING COMPLETE"
echo ""
echo "  Tools installed:"
echo "    sec              - Security status overview"
echo "    sudo lynis audit system    - Full security audit"
echo "    sudo rkhunter --check      - Rootkit scan"
echo "    sudo aide --check          - File integrity check"
echo "    trivy image NAME           - Scan container for vulns"
echo "    sudo fail2ban-client status - Banned IPs"
echo "    sudo cscli metrics          - CrowdSec stats"
echo "    iftop                       - Live network traffic"
echo "    nethogs                     - Per-process bandwidth"
echo "    nmap localhost              - Port scan yourself"
echo ""
echo "  Active protections:"
echo "    - Fail2Ban (SSH brute force banning)"
echo "    - CrowdSec (community threat intelligence)"
echo "    - Unattended security updates"
echo "    - Audit logging (file/user/config changes)"
echo "    - UFW firewall"
echo "========================================"
