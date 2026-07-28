#!/bin/bash
# ============================================================
# HARDWARE MONITOR
# Full hardware status — temps, disk health, power, resources
# ============================================================

echo ""
echo "=========================================="
echo "  HARDWARE STATUS"
echo "=========================================="

# --- System Info ---
echo ""
echo "  SYSTEM"
echo "  ─────────────────────────────────────"
echo "  Hostname:  $(hostname)"
echo "  OS:        $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY | cut -d= -f2 | tr -d '"')"
echo "  Kernel:    $(uname -r)"
echo "  Uptime:    $(uptime -p)"
echo "  Boot:      $(who -b | awk '{print $3, $4}')"

# --- CPU ---
echo ""
echo "  CPU"
echo "  ─────────────────────────────────────"
echo "  Model:     $(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')"
echo "  Cores:     $(nproc) ($(lscpu | grep 'Socket' | awk '{print $2}') socket)"
echo "  Usage:     $(top -bn1 | grep 'Cpu(s)' | awk '{printf "%.1f%%", $2+$4}')"
echo "  Load Avg:  $(cat /proc/loadavg | awk '{print $1, $2, $3}')"

# --- CPU Temperature ---
echo ""
echo "  TEMPERATURES"
echo "  ─────────────────────────────────────"
if command -v sensors &> /dev/null; then
  sensors 2>/dev/null | grep -E '(Core|temp|Tctl|Tdie|Package)' | while read -r line; do
    echo "  $line"
  done
  if [ $? -ne 0 ] || [ -z "$(sensors 2>/dev/null | grep -E '(Core|temp|Tctl)')" ]; then
    echo "  No temperature sensors detected."
    echo "  Run: sudo sensors-detect"
  fi
else
  echo "  lm-sensors not installed. Run: sudo apt install lm-sensors"
fi

# --- Fan Speeds ---
echo ""
echo "  FANS"
echo "  ─────────────────────────────────────"
if command -v sensors &> /dev/null; then
  FAN_DATA=$(sensors 2>/dev/null | grep -i 'fan' || true)
  if [ -n "$FAN_DATA" ]; then
    echo "$FAN_DATA" | while read -r line; do
      echo "  $line"
    done
  else
    echo "  No fan sensors detected (normal for fanless / mini PCs)."
  fi
fi

# --- Memory ---
echo ""
echo "  MEMORY"
echo "  ─────────────────────────────────────"
free -h | awk '
  /Mem:/ {printf "  RAM:       %s used / %s total (%s free)\n", $3, $2, $4}
  /Swap:/ {printf "  Swap:      %s used / %s total\n", $3, $2}
'

# --- Disk Health ---
echo ""
echo "  DISK HEALTH"
echo "  ─────────────────────────────────────"
for disk in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
  SIZE=$(lsblk -d -n -o SIZE /dev/$disk)
  MODEL=$(lsblk -d -n -o MODEL /dev/$disk | sed 's/[[:space:]]*$//')

  HEALTH="unknown"
  if command -v smartctl &> /dev/null; then
    SMART=$(sudo smartctl -H /dev/$disk 2>/dev/null)
    if echo "$SMART" | grep -q "PASSED"; then
      HEALTH="PASSED"
    elif echo "$SMART" | grep -q "FAILED"; then
      HEALTH="!! FAILED !!"
    fi
  fi

  printf "  /dev/%-6s  %-20s  %6s  Health: %s\n" "$disk" "$MODEL" "$SIZE" "$HEALTH"
done

# --- Disk Usage ---
echo ""
echo "  DISK USAGE"
echo "  ─────────────────────────────────────"
df -h | grep -E '^/dev/' | awk '{printf "  %-20s %6s / %6s  (%s used)\n", $1, $3, $2, $5}'

# --- Docker Disk ---
echo ""
echo "  DOCKER DISK USAGE"
echo "  ─────────────────────────────────────"
if command -v docker &> /dev/null; then
  docker system df 2>/dev/null | while read -r line; do
    echo "  $line"
  done
else
  echo "  Docker not installed."
fi

# --- Network Interfaces ---
echo ""
echo "  NETWORK"
echo "  ─────────────────────────────────────"
ip -br addr | while read -r line; do
  echo "  $line"
done

# --- Power (if available) ---
echo ""
echo "  POWER"
echo "  ─────────────────────────────────────"
if command -v sensors &> /dev/null; then
  POWER_DATA=$(sensors 2>/dev/null | grep -iE '(power|watt|volt|in[0-9])' || true)
  if [ -n "$POWER_DATA" ]; then
    echo "$POWER_DATA" | while read -r line; do
      echo "  $line"
    done
  else
    echo "  No power sensors detected."
  fi
fi

# --- Warnings ---
echo ""
echo "  WARNINGS"
echo "  ─────────────────────────────────────"
WARNINGS=0

# High CPU temp
if command -v sensors &> /dev/null; then
  HIGH_TEMP=$(sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -n | tail -1)
  if [ -n "$HIGH_TEMP" ] && [ "$HIGH_TEMP" -gt 80 ]; then
    echo "  !! CPU temperature is ${HIGH_TEMP}C — check cooling"
    ((WARNINGS++))
  fi
fi

# High disk usage
DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_PCT" -gt 90 ]; then
  echo "  !! Root disk at ${DISK_PCT}% — clean up needed"
  ((WARNINGS++))
elif [ "$DISK_PCT" -gt 80 ]; then
  echo "  Disk at ${DISK_PCT}% — getting full"
  ((WARNINGS++))
fi

# High memory usage
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
if [ "$MEM_PCT" -gt 90 ]; then
  echo "  !! Memory at ${MEM_PCT}% — consider stopping services"
  ((WARNINGS++))
fi

# Failed disks
if command -v smartctl &> /dev/null; then
  for disk in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
    if sudo smartctl -H /dev/$disk 2>/dev/null | grep -q "FAILED"; then
      echo "  !! /dev/$disk SMART health FAILED — replace this drive!"
      ((WARNINGS++))
    fi
  done
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "  None — all good."
fi

echo ""
echo "=========================================="
echo "  Quick commands:"
echo "    sensors        — live temp/fan readings"
echo "    s-tui          — interactive CPU monitor + stress test"
echo "    sudo powertop  — power usage breakdown"
echo "    sudo smartctl -a /dev/sda  — full disk report"
echo "=========================================="
echo ""
