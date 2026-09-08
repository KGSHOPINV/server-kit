#!/usr/bin/env bash
# kit-status -- compare desired state (server.manifest.yml) against live docker ps
# Usage: kit-status [--no-color]

set -euo pipefail

MANIFEST="${MANIFEST:-$(dirname "$(realpath "$0")")/../server.manifest.yml}"
# If called from /usr/local/bin, look for the server-kit clone
if [[ ! -f "$MANIFEST" ]]; then
  for candidate in \
    ~/server-kit/server.manifest.yml \
    /srv/server-kit/server.manifest.yml \
    /opt/server-kit/server.manifest.yml; do
    candidate="${candidate/#\~/$HOME}"
    if [[ -f "$candidate" ]]; then
      MANIFEST="$candidate"
      break
    fi
  done
fi

# -- Color helpers ------------------------------------------------------------
if [[ "${1:-}" == "--no-color" ]]; then
  GRN=""; RED=""; YLW=""; GRY=""; BOLD=""; NC=""
else
  GRN='\033[0;32m'; RED='\033[0;31m'; YLW='\033[0;33m'
  GRY='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'
fi

# -- Verify manifest exists --------------------------------------------------
if [[ ! -f "$MANIFEST" ]]; then
  echo -e "${RED}x${NC} Cannot find server.manifest.yml"
  echo "  Set MANIFEST=/path/to/server.manifest.yml or place it at ~/server-kit/server.manifest.yml"
  exit 1
fi

# -- Parse manifest: emit  name|type|port  lines -----------------------------
# Uses python3 when available, falls back to awk
parse_manifest() {
  if command -v python3 >/dev/null 2>&1; then
    python3 /usr/local/lib/kit-status-parse.py "$MANIFEST"
  else
    awk '
      /^  - name:/ { if (name) print name"|"typ"|"port; name=$NF; typ="docker"; port="" }
      /^    type:/  { typ=$NF }
      /^    port:/  { port=$NF }
      END           { if (name) print name"|"typ"|"port }
    ' "$MANIFEST"
  fi
}

# -- Snapshot of running containers ------------------------------------------
DOCKER_RUNNING=""
if command -v docker >/dev/null 2>&1; then
  DOCKER_RUNNING=$(docker ps --format '{{.Names}}|{{.Status}}|{{.Ports}}' 2>/dev/null || true)
fi

container_running() {
  echo "$DOCKER_RUNNING" | grep -q "^${1}|" && return 0 || return 1
}

container_ports() {
  echo "$DOCKER_RUNNING" | awk -F'|' -v n="$1" '$1==n{print $3}' | \
    grep -oP '\d+(?=->)' | sort -u | paste -sd ',' - 2>/dev/null || true
}

# -- Hub via systemd --user ---------------------------------------------------
hub_active() {
  systemctl --user is-active hub 2>/dev/null | grep -q '^active$'
}

# -- Header ------------------------------------------------------------------
echo ""
echo -e "${BOLD}  Service Status -- $(hostname)${NC}"
echo -e "  ${GRY}Manifest: $MANIFEST${NC}"
echo "  --------------------------------------------------------------------"
printf "  ${BOLD}%-22s %-10s %-10s %-8s %s${NC}\n" "NAME" "DESIRED" "ACTUAL" "PORT" "STATUS"
echo "  --------------------------------------------------------------------"

# -- Check each service ------------------------------------------------------
total=0; running=0; skipped=0

while IFS='|' read -r name stype port; do
  [[ -z "$name" ]] && continue
  total=$((total + 1))
  live_ports="$port"

  case "$stype" in
    docker)
      if container_running "$name"; then
        live_ports=$(container_ports "$name")
        status_icon="${GRN}OK${NC}"
        actual="running"
        running=$((running + 1))
      else
        status_icon="${RED}DOWN${NC}"
        actual="stopped"
      fi
      ;;
    systemd)
      if [[ "$name" == "hub" ]]; then
        if hub_active; then
          status_icon="${GRN}OK${NC}"
          actual="active"
          running=$((running + 1))
        else
          status_icon="${RED}DOWN${NC}"
          actual="inactive"
        fi
      else
        status_icon="${YLW}?${NC}"
        actual="unknown"
        skipped=$((skipped + 1))
      fi
      ;;
    snap)
      status_icon="${YLW}SNAP${NC}"
      actual="snap"
      skipped=$((skipped + 1))
      ;;
    *)
      status_icon="${YLW}?${NC}"
      actual="unknown"
      skipped=$((skipped + 1))
      ;;
  esac

  printf "  %-22s %-10s %-10s %-8s " "$name" "running" "$actual" "${live_ports:---}"
  echo -e "$status_icon"

done < <(parse_manifest)

# -- Summary -----------------------------------------------------------------
echo "  --------------------------------------------------------------------"
checked=$((total - skipped))
if [[ $running -eq $checked ]]; then
  echo -e "  ${GRN}${BOLD}$running/$checked services running${NC}  ${GRY}($skipped skipped -- snap/unknown)${NC}"
else
  stopped=$((checked - running))
  echo -e "  ${YLW}${BOLD}$running/$checked services running${NC}  ${GRY}($skipped skipped)${NC}  ${RED}$stopped stopped${NC}"
fi
echo ""
