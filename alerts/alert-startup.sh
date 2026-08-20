#!/bin/bash
# alert-startup.sh — fires when server comes online
# Put in /etc/rc.local or systemd unit After=network-online.target
# Distro-agnostic: uses only curl + hostname

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/notify.sh"

# Detect IP — try multiple commands
get_ip() {
  if command -v ip >/dev/null 2>&1; then
    ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7}' | head -1
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig | awk '/inet / && !/127.0.0/ {print $2}' | head -1
  else
    echo "unknown"
  fi
}

# Detect Tailscale
get_ts() {
  if command -v tailscale >/dev/null 2>&1; then
    tailscale ip 2>/dev/null | head -1 || echo "offline"
  else
    echo "not installed"
  fi
}

HOST=$(hostname -s 2>/dev/null || echo "server")
LAN=$(get_ip)
TS=$(get_ts)
UPTIME=$(uptime -p 2>/dev/null || uptime 2>/dev/null | awk -F'up ' '{print $2}' | cut -d',' -f1)

notify \
  "✅ $HOST is online" \
  "Server started successfully.

LAN:       ${LAN:-none}
Tailscale: $TS
Uptime:    $UPTIME
Hub:       http://${LAN:-?}:${HUB_PORT:-8765}" \
  "default" \
  "white_check_mark,server"
