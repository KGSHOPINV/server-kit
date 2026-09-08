#!/bin/bash
# static-ip-setup.sh — configure static IP via netplan
# Called by install.sh during setup. Portable — detects the right interface and netplan file.

set -uo pipefail

STATIC_IP="${SERVER_IP:-}"
GATEWAY="${SERVER_GW:-}"
ADMIN_USER="${ADMIN_USER:-$USER}"

[ -z "$STATIC_IP" ] && echo "SERVER_IP not set — skipping static IP" && exit 0
[ -z "$GATEWAY" ] && GATEWAY=$(ip route | awk '/default/ {print $3}' | head -1)

# Detect primary network interface (the one with the default route)
IFACE=$(ip route | awk '/default/ {print $5}' | head -1)
[ -z "$IFACE" ] && echo "Cannot detect network interface — skipping" && exit 0

# Get current IP and prefix length
PREFIX=$(ip addr show "$IFACE" | awk '/inet / {print $2}' | head -1 | cut -d'/' -f2)
[ -z "$PREFIX" ] && PREFIX=24

# Find the netplan config file
NETPLAN_FILE=$(ls /etc/netplan/*.yaml 2>/dev/null | head -1)
[ -z "$NETPLAN_FILE" ] && NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

echo "Setting static IP: $STATIC_IP/$PREFIX on $IFACE via $NETPLAN_FILE"
echo "Gateway: $GATEWAY"

# Backup existing config
sudo cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak" 2>/dev/null || true

# Write new netplan config
sudo tee "$NETPLAN_FILE" > /dev/null << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      addresses:
        - $STATIC_IP/$PREFIX
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      dhcp4: false
EOF

echo "Applying netplan..."
sudo netplan apply 2>&1 || {
  echo "netplan apply failed — reverting"
  sudo cp "${NETPLAN_FILE}.bak" "$NETPLAN_FILE" 2>/dev/null || true
  sudo netplan apply 2>/dev/null || true
  exit 1
}

echo "Static IP set to $STATIC_IP/$PREFIX"
echo "Interface: $IFACE | Gateway: $GATEWAY | DNS: 1.1.1.1, 8.8.8.8"
