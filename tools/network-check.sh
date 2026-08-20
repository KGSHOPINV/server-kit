#!/bin/bash
# ============================================================
# NETWORK CHECK — universal
# Auto-detects interface, gateway, LAN IP, hub port
# Works on any server in the kit
# ============================================================

detect() {
  # Primary interface = default route interface (not docker/lo)
  IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | grep -v 'docker\|veth\|br-\|virbr' | head -1)
  [ -z "$IFACE" ] && IFACE=$(ip -br link show | awk '$1 !~ /^(lo|docker|veth|br-|virbr)/ && $2=="UP" {print $1}' | head -1)

  GATEWAY=$(ip route show default 2>/dev/null | awk '/default/ {print $3}' | head -1)

  LAN_IP=$(ip addr show "$IFACE" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -1)

  TS_IP=$(tailscale ip 2>/dev/null | head -1)
  tailscale status >/dev/null 2>&1 && TS_STATUS='online' || TS_STATUS='offline'

  if [ -n "$GATEWAY" ]; then
    INTERNET=$(ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && echo 'YES' || echo 'NO')
    GW_PING=$(ping -c1 -W2 "$GATEWAY" >/dev/null 2>&1 && echo 'YES' || echo 'NO')
  else
    INTERNET='NO'; GW_PING='NO'
  fi

  DNS=$(ping -c1 -W2 google.com >/dev/null 2>&1 && echo 'YES' || echo 'NO')

  # Detect hub port from systemd service file
  HUB_PORT=$(grep -r 'PORT\|8765\|ExecStart' ~/.config/systemd/user/hub.service 2>/dev/null | grep -oP '\d{4,5}' | head -1)
  [ -z "$HUB_PORT" ] && HUB_PORT='8765'
  HUB=$(curl -s --max-time 2 "http://localhost:$HUB_PORT/api/status" >/dev/null 2>&1 && echo 'YES' || echo 'NO')

  UFW=$(sudo ufw status 2>/dev/null | awk 'NR==1 {print $2}')
  [ -z "$UFW" ] && UFW='unknown'

  if grep -rq 'dhcp4: no\|dhcp4: false' /etc/netplan/ 2>/dev/null; then
    IP_MODE='static'
  else
    IP_MODE='dhcp'
  fi
}

show_status() {
  echo ''
  echo '  =================================================='
  echo "    NETWORK STATUS — $(hostname)"
  echo '  =================================================='
  echo ''

  if [ -n "$LAN_IP" ]; then
    LAN_LINE="$LAN_IP  [$IP_MODE]  ✓"
  else
    LAN_LINE='NOT ASSIGNED  ⚠  FIX NEEDED'
  fi

  [ "$INTERNET" = 'YES' ] && INT_LINE='Connected ✓' || INT_LINE='DOWN ⚠'
  [ "$DNS" = 'YES' ] && DNS_LINE='Working ✓' || DNS_LINE='DOWN ⚠'
  [ "$GW_PING" = 'YES' ] && GW_LINE="${GATEWAY}  ✓" || GW_LINE="${GATEWAY:-?}  ⚠"

  if [ -n "$TS_IP" ]; then
    TS_LINE="$TS_IP  [$TS_STATUS]  ✓"
  else
    TS_LINE='offline  ⚠'
  fi

  [ "$HUB" = 'YES' ] && HUB_LINE=":$HUB_PORT  ✓" || HUB_LINE=":$HUB_PORT  DOWN ⚠"

  printf '  %-15s %s\n' 'Interface:' "${IFACE:-unknown}"
  printf '  %-15s %s\n' 'LAN IP:' "$LAN_LINE"
  printf '  %-15s %s\n' 'Gateway:' "$GW_LINE"
  printf '  %-15s %s\n' 'Internet:' "$INT_LINE"
  printf '  %-15s %s\n' 'DNS:' "$DNS_LINE"
  echo ''
  printf '  %-15s %s\n' 'Tailscale:' "$TS_LINE"
  printf '  %-15s %s\n' 'Hub:' "$HUB_LINE"
  printf '  %-15s %s\n' 'Firewall:' "$UFW"
  echo ''
  echo '  =================================================='
  echo ''
}

do_renew_dhcp() {
  echo ''
  echo "  Renewing DHCP on $IFACE..."
  sudo dhcpcd "$IFACE" 2>&1 | tail -5
  echo ''
  read -p '  Done. Enter to continue...'
}

do_static_ip() {
  echo ''
  echo "  Current LAN IP : ${LAN_IP:-none}"
  echo "  Interface      : $IFACE"
  echo "  Gateway        : ${GATEWAY:-unknown}"
  echo ''
  read -p "  IP to set (e.g. ${LAN_IP:-192.168.1.100}): " STATIC_IP
  [ -z "$STATIC_IP" ] && { echo '  Cancelled.'; sleep 1; return; }
  read -p "  Gateway [${GATEWAY}]: " GW_INPUT
  [ -z "$GW_INPUT" ] && GW_INPUT="$GATEWAY"
  read -p '  Prefix length [24]: ' PREFIX
  [ -z "$PREFIX" ] && PREFIX=24

  echo ''
  echo "  Applying: $IFACE → ${STATIC_IP}/${PREFIX} via ${GW_INPUT}"
  echo ''

  # Write netplan config via a temp file to avoid heredoc nesting
  TMPF=$(mktemp)
  cat > "$TMPF" << EOF
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: no
      addresses:
        - ${STATIC_IP}/${PREFIX}
      routes:
        - to: default
          via: $GW_INPUT
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
EOF

  sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak 2>/dev/null || true
  sudo cp "$TMPF" /etc/netplan/00-installer-config.yaml
  sudo chmod 600 /etc/netplan/00-installer-config.yaml
  rm -f "$TMPF"
  sudo netplan apply
  echo ''
  echo '  Static IP applied. SSH may drop briefly — reconnect if needed.'
  echo ''
  read -p '  Enter to continue...'
}

basic_menu() {
  while true; do
    clear
    detect
    show_status
    echo '  BASIC — quick fixes'
    echo ''
    echo '    1)  Renew DHCP'
    echo '    2)  Set static IP (permanent)'
    echo '    3)  Restart Tailscale'
    echo '    4)  Restart Hub'
    echo '    5)  Advanced mode →'
    echo '    0)  Back'
    echo ''
    read -p '  Pick: ' c
    case $c in
      1) do_renew_dhcp ;;
      2) do_static_ip ;;
      3)
        echo ''
        sudo systemctl restart tailscaled
        sleep 2
        tailscale status | head -6
        echo ''
        read -p '  Enter...'
        ;;
      4)
        echo ''
        systemctl --user restart hub 2>/dev/null || sudo systemctl restart hub 2>/dev/null
        sleep 1
        systemctl --user status hub --no-pager 2>/dev/null | tail -4 || sudo systemctl status hub --no-pager 2>/dev/null | tail -4
        echo ''
        read -p '  Enter...'
        ;;
      5) advanced_menu ;;
      0) break ;;
      *) echo '  Invalid.'; sleep 1 ;;
    esac
  done
}

advanced_menu() {
  while true; do
    clear
    detect
    show_status
    echo '  ADVANCED — full toolkit'
    echo ''
    echo '    1)  All interfaces (no docker noise)'
    echo '    2)  Routing table'
    echo '    3)  Firewall rules (UFW)'
    echo '    4)  Scan LAN devices'
    echo '    5)  DNS test'
    echo '    6)  Ping gateway'
    echo '    7)  Ping internet (8.8.8.8)'
    echo '    8)  Active TCP connections'
    echo '    9)  Tailscale full status'
    echo '   10)  Netdata URL (realtime stats)'
    echo '    0)  Back'
    echo ''
    read -p '  Pick: ' c
    case $c in
      1)
        echo ''
        ip -br addr show | grep -Ev 'veth|br-|docker|^lo'
        echo ''
        read -p '  Enter...'
        ;;
      2)
        echo ''
        ip route show | grep -Ev 'veth|br-|docker'
        echo ''
        read -p '  Enter...'
        ;;
      3)
        echo ''
        sudo ufw status verbose
        echo ''
        read -p '  Enter...'
        ;;
      4)
        echo ''
        # Derive subnet from gateway (works universally)
        BASE="${GATEWAY%.*}"
        echo "  Scanning ${BASE}.1-254 ... (15-20s)"
        echo ''
        for i in $(seq 1 254); do
          TARGET="${BASE}.${i}"
          ping -c1 -W1 "$TARGET" >/dev/null 2>&1 && \
            printf '  %-18s %s\n' "$TARGET" "$(arp -n "$TARGET" 2>/dev/null | awk 'NR==2{print $3}')" &
        done
        wait
        echo ''
        read -p '  Enter...'
        ;;
      5)
        echo ''
        nslookup google.com
        echo '---'
        nslookup github.com
        echo ''
        read -p '  Enter...'
        ;;
      6)
        echo ''
        ping -c4 "$GATEWAY"
        echo ''
        read -p '  Enter...'
        ;;
      7)
        echo ''
        ping -c4 8.8.8.8
        echo ''
        read -p '  Enter...'
        ;;
      8)
        echo ''
        ss -tnp | grep -Ev 'docker|127.0.0\.' | head -30
        echo ''
        read -p '  Enter...'
        ;;
      9)
        echo ''
        tailscale status
        echo ''
        read -p '  Enter...'
        ;;
     10)
        echo ''
        echo "  Netdata: http://${LAN_IP:-localhost}:19999"
        echo "  Open that address in your browser."
        echo ''
        read -p '  Enter...'
        ;;
      0) break ;;
      *) echo '  Invalid.'; sleep 1 ;;
    esac
  done
}

basic_menu
