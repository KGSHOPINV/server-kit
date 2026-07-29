#!/bin/bash
# ============================================================
# SERVER LIST
# Shows all registered servers and their status
# ============================================================

REGISTRY_DIR="/srv/docker/server-registry"
REGISTRY_FILE="$REGISTRY_DIR/servers.json"

echo ""
echo "=========================================="
echo "  SERVER REGISTRY"
echo "=========================================="

# --- Update self first ---
server-register 2>/dev/null

if [ ! -f "$REGISTRY_FILE" ]; then
  echo ""
  echo "  No servers registered yet."
  echo "  Run: server-register"
  echo ""
  exit 0
fi

# --- Display servers ---
echo ""
printf "  %-16s %-16s %-6s %-10s %-12s %-8s %s\n" "NAME" "IP" "CONT" "MEM" "DISK" "KIT" "LAST SEEN"
echo "  ────────────────────────────────────────────────────────────────────────────────────"

jq -r '.[] | "\(.hostname)|\(.ip)|\(.containers_running)/\(.containers_total)|\(.mem_used_mb)/\(.mem_total_mb)MB|\(.disk_used)/\(.disk_total) (\(.disk_pct)%)|\(.kit_version)|\(.last_seen)"' "$REGISTRY_FILE" 2>/dev/null | while IFS='|' read -r hostname ip containers mem disk kit seen; do
  # Calculate time since last seen
  SEEN_TS=$(date -d "$seen" +%s 2>/dev/null || echo 0)
  NOW_TS=$(date +%s)
  DIFF=$(( (NOW_TS - SEEN_TS) / 60 ))

  if [ "$DIFF" -lt 5 ]; then
    AGO="just now"
  elif [ "$DIFF" -lt 60 ]; then
    AGO="${DIFF}m ago"
  elif [ "$DIFF" -lt 1440 ]; then
    AGO="$(( DIFF / 60 ))h ago"
  else
    AGO="$(( DIFF / 1440 ))d ago"
  fi

  printf "  %-16s %-16s %-6s %-10s %-12s %-8s %s\n" "$hostname" "$ip" "$containers" "$mem" "$disk" "$kit" "$AGO"
done

# --- Show details ---
echo ""
echo "  SERVICES PER SERVER"
echo "  ────────────────────────────────────────────────────────────────────────────────────"

jq -r '.[] | "  \(.hostname): \(.services)"' "$REGISTRY_FILE" 2>/dev/null

echo ""
echo "=========================================="
echo "  Commands:"
echo "    server-register     — update this server's entry"
echo "    kit-servers         — show this list"
echo "    kit-sync            — sync registry across servers"
echo "=========================================="
echo ""
