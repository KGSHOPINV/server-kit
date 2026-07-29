#!/bin/bash
# ============================================================
# 10 - LINUX HELPER
# Server menu TUI, cheat sheet, aliases, auto-login menu
# ============================================================

set -e

echo "========================================"
echo "  10 - LINUX HELPER SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Install tools ---
echo "Installing server menu and tools..."
sudo cp "$SCRIPT_DIR/tools/server-menu.sh" /usr/local/bin/server-menu
sudo cp "$SCRIPT_DIR/tools/port-scan.sh" /usr/local/bin/port-scan
sudo cp "$SCRIPT_DIR/tools/add-project.sh" /usr/local/bin/add-project
sudo cp "$SCRIPT_DIR/tools/health-check.sh" /usr/local/bin/health-check
sudo cp "$SCRIPT_DIR/tools/linux-cheatsheet.sh" /usr/local/bin/cheatsheet
sudo cp "$SCRIPT_DIR/tools/self-update.sh" /usr/local/bin/kit-update
sudo cp "$SCRIPT_DIR/tools/whats-next.sh" /usr/local/bin/whats-next
sudo cp "$SCRIPT_DIR/tools/howdo.sh" /usr/local/bin/howdo
sudo cp "$SCRIPT_DIR/tools/server-register.sh" /usr/local/bin/server-register
sudo cp "$SCRIPT_DIR/tools/server-list.sh" /usr/local/bin/kit-servers
sudo cp "$SCRIPT_DIR/tools/server-sync.sh" /usr/local/bin/kit-sync

sudo chmod +x /usr/local/bin/server-menu
sudo chmod +x /usr/local/bin/port-scan
sudo chmod +x /usr/local/bin/add-project
sudo chmod +x /usr/local/bin/health-check
sudo chmod +x /usr/local/bin/cheatsheet
sudo chmod +x /usr/local/bin/kit-update
sudo chmod +x /usr/local/bin/whats-next
sudo chmod +x /usr/local/bin/howdo
sudo chmod +x /usr/local/bin/server-register
sudo chmod +x /usr/local/bin/kit-servers
sudo chmod +x /usr/local/bin/kit-sync

# --- Bash aliases ---
echo ""
echo "Adding helpful aliases..."
ALIAS_BLOCK='
# === SERVER KIT ALIASES ===
alias menu="server-menu"
alias ports="port-scan"
alias health="health-check"
alias cheat="cheatsheet"
alias dps="docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\" "
alias dlogs="docker logs -f"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcr="docker compose restart"
alias dcp="docker compose pull && docker compose up -d"
alias update-kit="kit-update"
# === END SERVER KIT ==='

if ! grep -q "SERVER KIT ALIASES" ~/.bashrc 2>/dev/null; then
  echo "$ALIAS_BLOCK" >> ~/.bashrc
  echo "Aliases added to ~/.bashrc"
else
  echo "Aliases already present in ~/.bashrc"
fi

# --- Auto-show menu on login (optional) ---
echo ""
read -p "Show server menu automatically on SSH login? (y/n): " auto_menu
if [[ "$auto_menu" == "y" ]]; then
  if ! grep -q "server-menu" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Auto-launch server menu on login" >> ~/.bashrc
    echo '[[ $- == *i* ]] && server-menu' >> ~/.bashrc
    echo "Menu will show on login."
  fi
fi

echo ""
echo "========================================"
echo "  10 - LINUX HELPER INSTALLED"
echo ""
echo "  Commands available:"
echo "    menu       - Server command center"
echo "    ports      - Scan open ports"
echo "    health     - Check all services"
echo "    cheat      - Linux cheat sheet"
echo "    add-project - Add a new Docker project"
echo ""
echo "  Docker shortcuts:"
echo "    dps        - Docker containers status"
echo "    dlogs      - Follow container logs"
echo "    dcu/dcd    - Compose up/down"
echo "========================================"
