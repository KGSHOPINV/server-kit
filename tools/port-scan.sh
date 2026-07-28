#!/bin/bash
# ============================================================
# PORT SCANNER
# Shows all open ports, matches to Docker containers
# ============================================================

echo ""
echo "=========================================="
echo "  PORT SCANNER"
echo "=========================================="
echo ""

# Get all listening ports
printf "%-8s %-28s %-22s %-10s\n" "PORT" "SERVICE" "CONTAINER" "STATUS"
echo "──────────────────────────────────────────────────────────────────────"

# Known port mappings
declare -A KNOWN_PORTS=(
  [80]="Nginx Proxy Manager"
  [81]="NPM Admin"
  [443]="NPM SSL"
  [3000]="Homepage"
  [3001]="Uptime Kuma"
  [5432]="PostgreSQL"
  [5678]="n8n"
  [8000]="Supabase Studio"
  [8080]="Dozzle"
  [8100]="Supabase Kong"
  [8181]="SurrealDB"
  [9443]="Portainer"
  [19999]="Netdata"
  [22]="SSH"
)

# Get listening ports
ss -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
  port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)

  # Skip non-numeric
  [[ ! "$port" =~ ^[0-9]+$ ]] && continue

  # Get service name
  service="${KNOWN_PORTS[$port]:-"(unknown)"}"

  # Try to match to a Docker container
  container=$(docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null | grep ":${port}->" | awk '{print $1}' | head -1)
  container=${container:-"—"}

  # Status
  if [[ "$container" != "—" ]]; then
    status="running"
  else
    status="no container"
  fi

  printf "%-8s %-28s %-22s %-10s\n" "$port" "$service" "$container" "$status"
done

echo ""

# Show Docker containers not mapped to any known port
echo "DOCKER CONTAINERS:"
echo "──────────────────────────────────────────────────────────────────────"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker not running."

echo ""
