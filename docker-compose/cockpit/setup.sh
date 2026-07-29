#!/bin/bash
# ============================================================
# COCKPIT — Web-based server management console
# NOT a Docker container — installs directly on the OS
# ============================================================

echo "Installing Cockpit..."
sudo apt install -y cockpit cockpit-storaged cockpit-networkmanager cockpit-packagekit

# Enable and start
sudo systemctl enable --now cockpit.socket

# Open firewall
sudo ufw allow 9090/tcp

echo ""
echo "Cockpit installed!"
echo "  URL: https://$(hostname -I | awk '{print $1}'):9090"
echo "  Login with your server username and password"
echo ""
echo "  What you get:"
echo "    - Full web terminal (no SSH needed)"
echo "    - Storage management"
echo "    - Network configuration"
echo "    - Service management"
echo "    - System logs"
echo "    - User management"
echo "    - Performance monitoring"
echo "    - Software updates"
