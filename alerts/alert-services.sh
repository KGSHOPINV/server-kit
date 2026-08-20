#!/bin/bash
# alert-services.sh — Docker container health alert
# Detects containers that stopped unexpectedly
# Falls back gracefully if Docker not installed

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/notify.sh"

HOST=$(hostname -s 2>/dev/null || echo "server")

# If Docker not available, exit silently
command -v docker >/dev/null 2>&1 || exit 0

# Get containers that are NOT running (exited, dead, restarting-loop)
UNHEALTHY=$(docker ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null | \
  grep -v 'Up ' | grep -v '^$' | \
  grep -Ev 'Exited \(0\)' )  # Ignore clean exits

[ -z "$UNHEALTHY" ] && exit 0

# State file — only alert on new failures
STATE_FILE="/tmp/.services-alert-state"
PREV=$(cat "$STATE_FILE" 2>/dev/null || echo "")
CURR=$(echo "$UNHEALTHY" | md5sum | awk '{print $1}')

[ "$CURR" = "$PREV" ] && exit 0
echo "$CURR" > "$STATE_FILE"

COUNT=$(echo "$UNHEALTHY" | wc -l)
NAMES=$(echo "$UNHEALTHY" | awk '{print "  • " $1 " — " $2}' | head -10)

notify \
  "🔴 $COUNT service(s) down on $HOST" \
  "Containers not running:

$NAMES

Check: docker ps -a
Fix:   docker start <name>  or  docker compose up -d" \
  "high" \
  "rotating_light,whale"
