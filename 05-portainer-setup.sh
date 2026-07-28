#!/bin/bash
# ============================================================
# 05 - PORTAINER
# Web UI for Docker container management
# ============================================================

set -e

echo "========================================"
echo "  05 - PORTAINER"
echo "========================================"

COMPOSE_DIR="/srv/docker/portainer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$COMPOSE_DIR"
cp "$SCRIPT_DIR/docker-compose/portainer/docker-compose.yml" "$COMPOSE_DIR/"

cd "$COMPOSE_DIR"
docker compose up -d

echo ""
echo "========================================"
echo "  05 - PORTAINER RUNNING"
echo ""
echo "  URL: https://$(hostname -I | awk '{print $1}'):9443"
echo "  Create admin account on first visit."
echo "========================================"
