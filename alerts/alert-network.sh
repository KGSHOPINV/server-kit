#!/bin/bash
# alert-network.sh — network health alert
# Detects: no LAN IP, no internet, Tailscale down
# Distro-agnostic: tries ip, then ifconfig, then hostname -I

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/notify.sh"

HOST=$(hostname -s 2>/dev/null || echo "server")

# Detect LAN IP — command-agnostic
get_lan_ip() {
  if command -v ip >/dev/null 2>&1; then
    ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7}' | head -1
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig 2>/dev/null | awk '/inet / && !/127\.0\.0/ {print $2}' | grep -v '^172\.' | head -1
  else
    hostname -I 2>/dev/null | awk '{print $1}'
  fi
}

LAN=$(get_lan_ip)

# Internet check
INTERNET="no"
for target in 8.8.8.8 1.1.1.1 9.9.9.9; do
  ping -c1 -W3 "$target" >/dev/null 2>&1 && INTERNET="yes" && break
done

# Tailscale check
TS_UP="no"
TS_IP=""
if command -v tailscale >/dev/null 2>&1; then
  TS_IP=$(tailscale ip 2>/dev/null | head -1)
  [ -n "$TS_IP" ] && TS_UP="yes"
fi

# State file to avoid repeat alerts (only alert on change)
STATE_FILE="/tmp/.network-alert-state"
PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "unknown")

build_state() {
  echo "lan=${LAN:-none}|internet=$INTERNET|ts=$TS_UP"
}

CURR_STATE=$(build_state)

# Only alert if state changed OR first run
if [ "$CURR_STATE" = "$PREV_STATE" ]; then
  exit 0
fi

echo "$CURR_STATE" > "$STATE_FILE"

# What changed?
PROBLEMS=()
NOTES=()

[ -z "$LAN" ] && PROBLEMS+=("No LAN IP assigned") && NOTES+=("Server may have lost DHCP lease")
[ "$INTERNET" = "no" ] && PROBLEMS+=("No internet connectivity")
[ "$TS_UP" = "no" ] && PROBLEMS+=("Tailscale offline")

[ ${#PROBLEMS[@]} -eq 0 ] && {
  # Recovery — all good now
  if echo "$PREV_STATE" | grep -q "internet=no\|ts=no\|lan=none"; then
    notify \
      "✅ Network restored on $HOST" \
      "All connectivity back.

LAN:       ${LAN:-none}
Internet:  $INTERNET
Tailscale: ${TS_IP:-offline}" \
      "default" \
      "white_check_mark,signal_strength"
  fi
  exit 0
}

BODY="$(printf '%s\n' "${PROBLEMS[@]}")

LAN IP:    ${LAN:-NONE}
Internet:  $INTERNET
Tailscale: ${TS_IP:-offline}

$(printf '%s\n' "${NOTES[@]}")"

notify \
  "⚠️ Network issue on $HOST" \
  "$BODY" \
  "high" \
  "warning,signal_strength"
