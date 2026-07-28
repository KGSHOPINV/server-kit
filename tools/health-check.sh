#!/bin/bash
# ============================================================
# HEALTH CHECK
# Checks all services are running
# ============================================================

echo ""
echo "=========================================="
echo "  HEALTH CHECK"
echo "=========================================="
echo ""

IP=$(hostname -I | awk '{print $1}')
PASS=0
FAIL=0
SKIP=0

check_service() {
  local name="$1"
  local port="$2"
  local protocol="${3:-http}"

  if ss -tlnp | grep -q ":${port} " 2>/dev/null; then
    container=$(docker ps --format '{{.Names}}' --filter "publish=${port}" 2>/dev/null | head -1)
    container=${container:-"(non-docker)"}
    printf "  %-22s %-8s %-20s %s\n" "$name" ":$port" "$container" "[OK]"
    ((PASS++))
  else
    printf "  %-22s %-8s %-20s %s\n" "$name" ":$port" "—" "[DOWN]"
    ((FAIL++))
  fi
}

printf "  %-22s %-8s %-20s %s\n" "SERVICE" "PORT" "CONTAINER" "STATUS"
echo "  ────────────────────────────────────────────────────────────"

check_service "SSH" 22
check_service "HTTP (NPM)" 80
check_service "HTTPS (NPM)" 443
check_service "NPM Admin" 81
check_service "Homepage" 3000
check_service "Uptime Kuma" 3001
check_service "Supabase Studio" 8000
check_service "n8n" 5678
check_service "Dozzle" 8080
check_service "SurrealDB" 8181
check_service "Portainer" 9443
check_service "Netdata" 19999

echo ""
echo "  ────────────────────────────────────────────────────────────"
echo "  Results: $PASS OK  |  $FAIL DOWN"
echo ""

# Docker status
echo "  Docker Engine: $(systemctl is-active docker 2>/dev/null || echo 'unknown')"
echo "  Containers:    $(docker ps -q 2>/dev/null | wc -l) running / $(docker ps -aq 2>/dev/null | wc -l) total"
echo ""

# Disk space warning
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
if [[ "$DISK_PCT" -gt 90 ]]; then
  echo "  WARNING: Disk usage at ${DISK_PCT}%!"
elif [[ "$DISK_PCT" -gt 75 ]]; then
  echo "  NOTICE: Disk usage at ${DISK_PCT}%"
else
  echo "  Disk: ${DISK_PCT}% used"
fi

# Memory
echo "  Memory: $(free -h | awk '/Mem:/ {printf "%s / %s", $3, $2}')"
echo ""
