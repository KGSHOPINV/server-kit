#!/bin/bash
# ============================================================
# 15 - SERVER CONSOLE + CHATOPS
# Cockpit (web console), notifications, Discord/Slack alerts
# ============================================================

set -e

echo "========================================"
echo "  15 - SERVER CONSOLE + CHATOPS"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Cockpit (web-based server management) ---
echo ""
echo "  Cockpit gives you a FULL server console in your browser:"
echo "    - Web terminal (no SSH needed)"
echo "    - Storage management (disks, RAID, mounts)"
echo "    - Network configuration"
echo "    - Service management (start/stop/restart)"
echo "    - System logs (searchable)"
echo "    - User management"
echo "    - Performance graphs"
echo "    - Software updates"
echo ""
read -p "Install Cockpit (web server console)? (y/n): " install_cockpit
if [[ "$install_cockpit" == "y" ]]; then
  bash "$SCRIPT_DIR/docker-compose/cockpit/setup.sh"
fi

# --- Notification service ---
echo ""
echo "  Pick a notification service for alerts:"
echo "    1) ntfy — simple push notifications (phone + desktop)"
echo "    2) Gotify — self-hosted notification server"
echo "    3) Skip"
echo ""
read -p "Pick [1-3]: " notif_choice

case $notif_choice in
  1)
    echo "Setting up ntfy..."
    NTFY_DIR="/srv/docker/ntfy"
    mkdir -p "$NTFY_DIR"
    cp "$SCRIPT_DIR/docker-compose/ntfy/docker-compose.yml" "$NTFY_DIR/"
    cd "$NTFY_DIR"
    docker compose up -d
    echo ""
    echo "  ntfy running on port 8085"
    echo "  Subscribe on phone: install ntfy app, add your server"
    echo "  Send test: curl -d 'Hello from server' http://localhost:8085/alerts"
    ;;
  2)
    echo "Setting up Gotify..."
    GOTIFY_DIR="/srv/docker/gotify"
    mkdir -p "$GOTIFY_DIR"
    cp "$SCRIPT_DIR/docker-compose/gotify/docker-compose.yml" "$GOTIFY_DIR/"
    cd "$GOTIFY_DIR"
    docker compose up -d
    echo ""
    echo "  Gotify running on port 8086"
    echo "  Default login: admin / admin"
    ;;
  3)
    echo "Skipping notifications."
    ;;
esac

# --- ChatOps alert script ---
echo ""
echo "  Setting up alert system..."

sudo tee /usr/local/bin/server-alert > /dev/null << 'ALERTEOF'
#!/bin/bash
# ============================================================
# SERVER ALERT
# Send alerts to Discord, Slack, ntfy, or Gotify
# Usage: server-alert "message"
#        server-alert "title" "message"
# ============================================================

CONFIG_FILE="$HOME/.server-alerts.conf"

# Load config
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

TITLE="${1:-Server Alert}"
MESSAGE="${2:-$1}"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

FULL_MESSAGE="[$HOSTNAME] $TIMESTAMP — $MESSAGE"

# --- Discord ---
if [ -n "$DISCORD_WEBHOOK" ]; then
  curl -s -X POST "$DISCORD_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"**$TITLE**\n$FULL_MESSAGE\"}" > /dev/null 2>&1
fi

# --- Slack ---
if [ -n "$SLACK_WEBHOOK" ]; then
  curl -s -X POST "$SLACK_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"*$TITLE*\n$FULL_MESSAGE\"}" > /dev/null 2>&1
fi

# --- ntfy ---
if [ -n "$NTFY_URL" ]; then
  curl -s -d "$FULL_MESSAGE" \
    -H "Title: $TITLE" \
    "${NTFY_URL}/server-alerts" > /dev/null 2>&1
fi

# --- Gotify ---
if [ -n "$GOTIFY_URL" ] && [ -n "$GOTIFY_TOKEN" ]; then
  curl -s -X POST "${GOTIFY_URL}/message" \
    -H "Content-Type: application/json" \
    -H "X-Gotify-Key: ${GOTIFY_TOKEN}" \
    -d "{\"title\": \"$TITLE\", \"message\": \"$FULL_MESSAGE\", \"priority\": 5}" > /dev/null 2>&1
fi

echo "Alert sent: $TITLE — $MESSAGE"
ALERTEOF

sudo chmod +x /usr/local/bin/server-alert

# --- Alert config ---
echo ""
echo "  Configure alert destinations:"
echo ""

ALERT_CONFIG=""

read -p "  Discord webhook URL (or skip): " discord_url
if [[ "$discord_url" != "skip" && -n "$discord_url" ]]; then
  ALERT_CONFIG+="DISCORD_WEBHOOK=\"$discord_url\"\n"
fi

read -p "  Slack webhook URL (or skip): " slack_url
if [[ "$slack_url" != "skip" && -n "$slack_url" ]]; then
  ALERT_CONFIG+="SLACK_WEBHOOK=\"$slack_url\"\n"
fi

# Auto-detect ntfy
if docker ps 2>/dev/null | grep -q ntfy; then
  ALERT_CONFIG+="NTFY_URL=\"http://localhost:8085\"\n"
  echo "  ntfy auto-detected."
fi

# Auto-detect gotify
if docker ps 2>/dev/null | grep -q gotify; then
  read -p "  Gotify app token (from Gotify admin): " gotify_token
  if [ -n "$gotify_token" ]; then
    ALERT_CONFIG+="GOTIFY_URL=\"http://localhost:8086\"\n"
    ALERT_CONFIG+="GOTIFY_TOKEN=\"$gotify_token\"\n"
  fi
fi

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

if [ -n "$ALERT_CONFIG" ]; then
  echo -e "$ALERT_CONFIG" > "$REAL_HOME/.server-alerts.conf"
  chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.server-alerts.conf"
  chmod 600 "$REAL_HOME/.server-alerts.conf"
  echo "  Alert config saved."
fi

# --- Automated alert cron ---
echo ""
read -p "  Setup automated health check alerts (every 15 min)? (y/n): " setup_alerts
if [[ "$setup_alerts" == "y" ]]; then
  sudo tee /usr/local/bin/auto-alert > /dev/null << 'AUTOEOF'
#!/bin/bash
# Auto health check — sends alert if something is down

DOWN_SERVICES=""

# Check key containers
for container in npm portainer uptime-kuma cloudflared; do
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
    continue
  else
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
      DOWN_SERVICES+="$container "
    fi
  fi
done

# Check disk
DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_PCT" -gt 90 ]; then
  DOWN_SERVICES+="DISK:${DISK_PCT}% "
fi

# Check memory
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
if [ "$MEM_PCT" -gt 95 ]; then
  DOWN_SERVICES+="MEM:${MEM_PCT}% "
fi

if [ -n "$DOWN_SERVICES" ]; then
  server-alert "WARNING" "Issues detected: $DOWN_SERVICES"
fi
AUTOEOF

  sudo chmod +x /usr/local/bin/auto-alert
  (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/auto-alert") | crontab -
  echo "  Auto-alerts configured (every 15 minutes)."
fi

echo ""
echo "========================================"
echo "  15 - SERVER CONSOLE + CHATOPS COMPLETE"
echo ""
IP=$(hostname -I | awk '{print $1}')
[[ "$install_cockpit" == "y" ]] && echo "  Cockpit:     https://$IP:9090"
[[ "$notif_choice" == "1" ]] && echo "  ntfy:        http://$IP:8085"
[[ "$notif_choice" == "2" ]] && echo "  Gotify:      http://$IP:8086"
echo ""
echo "  Commands:"
echo "    server-alert 'something happened'  — send alert"
echo "    server-alert 'Title' 'Details'     — with title"
echo ""
echo "  Auto-alerts check every 15 min for:"
echo "    - Containers down"
echo "    - Disk > 90%"
echo "    - Memory > 95%"
echo "========================================"
