#!/bin/bash
# ============================================================
# 11 - HARDWARE MONITORING
# CPU temps, disk health, fan speeds, power, sensors
# ============================================================

set -e

echo "========================================"
echo "  11 - HARDWARE MONITORING SETUP"
echo "========================================"

# --- Install lm-sensors (CPU temp, fan speed, voltage) ---
echo ""
echo "Installing lm-sensors..."
sudo apt install -y lm-sensors
echo ""
echo "Detecting sensors..."
sudo sensors-detect --auto
echo ""
echo "Current sensor readings:"
sensors

# --- Install smartmontools (disk health / SMART data) ---
echo ""
echo "Installing smartmontools (disk health)..."
sudo apt install -y smartmontools

echo ""
echo "Disk health overview:"
for disk in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
  echo ""
  echo "  --- /dev/$disk ---"
  sudo smartctl -H /dev/$disk 2>/dev/null | grep -E "result|Status" || echo "  SMART not supported"
done

# --- Install powertop (power usage analysis) ---
echo ""
echo "Installing powertop (power analysis)..."
sudo apt install -y powertop

# --- Install s-tui (terminal-based CPU stress test + monitor) ---
echo ""
echo "Installing s-tui (CPU stress test + temp monitor)..."
sudo apt install -y s-tui stress

# --- Setup SMART disk monitoring cron ---
echo ""
read -p "Setup weekly disk health check with email alerts? (y/n): " setup_smart_cron
if [[ "$setup_smart_cron" == "y" ]]; then
  sudo systemctl enable smartd
  sudo systemctl start smartd
  echo "SMART daemon enabled — will monitor disk health continuously."
fi

# --- Install hardware tools script ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo cp "$SCRIPT_DIR/tools/hardware-monitor.sh" /usr/local/bin/hw-monitor
sudo chmod +x /usr/local/bin/hw-monitor

# --- Add alias ---
if ! grep -q "alias hw=" ~/.bashrc 2>/dev/null; then
  echo 'alias hw="hw-monitor"' >> ~/.bashrc
fi

echo ""
echo "========================================"
echo "  11 - HARDWARE MONITORING READY"
echo ""
echo "  Commands:"
echo "    hw           - Full hardware status"
echo "    sensors      - CPU temp, fan, voltage"
echo "    s-tui        - Interactive CPU temp + stress test"
echo "    sudo smartctl -a /dev/sda  - Full disk health"
echo "    sudo powertop - Power usage analysis"
echo "========================================"
