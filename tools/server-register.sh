#!/bin/bash
# ============================================================
# SERVER REGISTER
# Registers this server to the shared registry
# Sends heartbeat with status info
# ============================================================

REGISTRY_DIR="/srv/docker/server-registry"
REGISTRY_FILE="$REGISTRY_DIR/servers.json"
LOCAL_ID_FILE="$HOME/.server-kit-id"

# --- Get or create server ID ---
if [ -f "$LOCAL_ID_FILE" ]; then
  SERVER_ID=$(cat "$LOCAL_ID_FILE")
else
  SERVER_ID=$(hostname)-$(date +%s | sha256sum | head -c 8)
  echo "$SERVER_ID" > "$LOCAL_ID_FILE"
fi

# --- Gather info ---
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
UPTIME=$(uptime -p 2>/dev/null || echo "unknown")
CONTAINERS=$(docker ps -q 2>/dev/null | wc -l || echo 0)
TOTAL_CONTAINERS=$(docker ps -aq 2>/dev/null | wc -l || echo 0)
MEM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo 0)
MEM_USED=$(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo 0)
DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "?")
DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "?")
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo 0)
OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY | cut -d= -f2 | tr -d '"' || echo "unknown")
DOCKER_VER=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "none")
KIT_VER=$(cd "$HOME/server-kit" 2>/dev/null && git log --oneline -1 2>/dev/null | awk '{print $1}' || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Get running service names ---
SERVICES=$(docker ps --format '{{.Names}}' 2>/dev/null | sort | tr '\n' ',' | sed 's/,$//')

# --- Build JSON entry ---
SERVER_JSON=$(cat << EOF
{
  "id": "$SERVER_ID",
  "hostname": "$HOSTNAME",
  "ip": "$IP_LOCAL",
  "os": "$OS",
  "docker": "$DOCKER_VER",
  "kit_version": "$KIT_VER",
  "uptime": "$UPTIME",
  "containers_running": $CONTAINERS,
  "containers_total": $TOTAL_CONTAINERS,
  "services": "$SERVICES",
  "mem_used_mb": $MEM_USED,
  "mem_total_mb": $MEM_TOTAL,
  "disk_used": "$DISK_USED",
  "disk_total": "$DISK_TOTAL",
  "disk_pct": $DISK_PCT,
  "last_seen": "$TIMESTAMP"
}
EOF
)

# --- Save locally ---
mkdir -p "$REGISTRY_DIR"
echo "$SERVER_JSON" > "$REGISTRY_DIR/self.json"

# --- If registry file exists, update our entry ---
if [ -f "$REGISTRY_FILE" ]; then
  # Remove old entry for this server, add new one
  TMP=$(mktemp)
  jq --arg id "$SERVER_ID" 'map(select(.id != $id))' "$REGISTRY_FILE" > "$TMP" 2>/dev/null || echo "[]" > "$TMP"
  jq --argjson entry "$SERVER_JSON" '. + [$entry]' "$TMP" > "$REGISTRY_FILE" 2>/dev/null
  rm "$TMP"
else
  echo "[$SERVER_JSON]" | jq '.' > "$REGISTRY_FILE"
fi

echo "Server registered: $SERVER_ID ($HOSTNAME)"
