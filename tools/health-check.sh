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

check_service() {
  local name="$1"
  local port="$2"

  if ss -tlnp | grep -q ":${port} " 2>/dev/null; then
    container=$(docker ps --format '{{.Names}}' --filter "publish=${port}" 2>/dev/null | head -1)
    container=${container:-"(system)"}
    printf "  %-24s %-8s %-22s %s\n" "$name" ":$port" "$container" "[OK]"
    ((PASS++))
  else
    printf "  %-24s %-8s %-22s %s\n" "$name" ":$port" "—" "[DOWN]"
    ((FAIL++))
  fi
}

printf "  %-24s %-8s %-22s %s\n" "SERVICE" "PORT" "CONTAINER" "STATUS"
echo "  ──────────────────────────────────────────────────────────────"

echo ""
echo "  --- SYSTEM ---"
check_service "SSH" 22

echo ""
echo "  --- INFRASTRUCTURE ---"
check_service "HTTP (NPM)" 80
check_service "HTTPS (NPM)" 443
check_service "NPM Admin" 81
check_service "Portainer" 9443

echo ""
echo "  --- MONITORING ---"
check_service "Homepage" 3000
check_service "Uptime Kuma" 3001
check_service "Grafana" 3002
check_service "Netdata" 19999
check_service "Dozzle" 8090

echo ""
echo "  --- DATABASES & STORAGE ---"
check_service "PostgreSQL" 5432
check_service "Supabase Studio" 8000
check_service "SurrealDB" 8181
check_service "Redis" 6379
check_service "Redis Commander" 8082
check_service "MinIO API" 9000
check_service "MinIO Console" 9001
check_service "Adminer" 8083

echo ""
echo "  --- AI ---"
check_service "Ollama API" 11434
check_service "Open WebUI" 3004
check_service "OpenClaw" 3005

echo ""
echo "  --- DEV TOOLS ---"
check_service "n8n" 5678
check_service "Mailpit Web" 8025
check_service "Mailpit SMTP" 1025
check_service "Wiki.js" 3003
check_service "LanguageTool" 8084

echo ""
echo "  ──────────────────────────────────────────────────────────────"
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
