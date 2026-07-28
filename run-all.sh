#!/bin/bash
# ============================================================
# RUN ALL - Master installer
# Runs each setup script in order
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "========================================================"
echo "  SERVER KIT - FULL INSTALL"
echo "========================================================"
echo ""
echo "This will run all setup scripts in order:"
echo "  01 - System Setup (updates, firewall, SSH)"
echo "  02 - Docker Install"
echo "  03 - Nginx Proxy Manager"
echo "  04 - Cloudflare Tunnel"
echo "  05 - Portainer"
echo "  06 - Monitoring (Uptime Kuma + Netdata)"
echo "  07 - Claude CLI + MCP"
echo "  08 - Extras (Supabase, n8n, SurrealDB, Homepage, Dozzle)"
echo "  09 - Backup System"
echo "  10 - Linux Helper (menu, aliases, tools)"
echo "  11 - Hardware Monitoring (temps, disk health, sensors)"
echo "  12 - Security Hardening (fail2ban, CrowdSec, scanning, audit)"
echo ""
read -p "Run full install? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo "Starting full install..."
echo ""

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh
chmod +x "$SCRIPT_DIR"/tools/*.sh

# Run in order
bash "$SCRIPT_DIR/01-system-setup.sh"
echo ""
echo "--- Pausing. Log out and back in if docker group was just added. ---"
echo ""

bash "$SCRIPT_DIR/02-docker-install.sh"

echo ""
read -p "Docker installed. Continue with services? (y/n): " cont
if [[ "$cont" != "y" ]]; then
  echo "Stopped. Run individual scripts to continue later."
  exit 0
fi

bash "$SCRIPT_DIR/03-npm-setup.sh"
bash "$SCRIPT_DIR/04-cloudflared-setup.sh"
bash "$SCRIPT_DIR/05-portainer-setup.sh"
bash "$SCRIPT_DIR/06-monitoring-setup.sh"
bash "$SCRIPT_DIR/07-claude-cli-setup.sh"
bash "$SCRIPT_DIR/08-extras-setup.sh"
bash "$SCRIPT_DIR/09-backup-setup.sh"
bash "$SCRIPT_DIR/10-linux-helper-setup.sh"
bash "$SCRIPT_DIR/11-hardware-monitor-setup.sh"
bash "$SCRIPT_DIR/12-security-setup.sh"

echo ""
echo "========================================================"
echo "  SERVER KIT - INSTALL COMPLETE"
echo "========================================================"
echo ""
IP=$(hostname -I | awk '{print $1}')
echo "  Your services:"
echo ""
echo "  NPM Admin:    http://$IP:81"
echo "  Portainer:    https://$IP:9443"
echo "  Uptime Kuma:  http://$IP:3001"
echo "  Netdata:      http://$IP:19999"
echo "  Homepage:     http://$IP:3000"
echo "  Dozzle:       http://$IP:8080"
echo "  Supabase:     http://$IP:8000  (if installed)"
echo "  n8n:          http://$IP:5678  (if installed)"
echo "  SurrealDB:    http://$IP:8181  (if installed)"
echo ""
echo "  Commands: menu | ports | health | sec | hw | cheat | add-project"
echo ""
echo "  Run 'menu' to access the server command center."
echo "========================================================"
