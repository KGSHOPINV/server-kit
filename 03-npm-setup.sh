#!/bin/bash
# ============================================================
# 03 - NGINX PROXY MANAGER
# Reverse proxy with web UI
# ============================================================

set -e

echo "========================================"
echo "  03 - NGINX PROXY MANAGER"
echo "========================================"

COMPOSE_DIR="/srv/docker/npm"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$COMPOSE_DIR"
cp "$SCRIPT_DIR/docker-compose/npm/docker-compose.yml" "$COMPOSE_DIR/"

cd "$COMPOSE_DIR"
docker compose up -d

echo ""
echo "========================================"
echo "  03 - NPM RUNNING"
echo ""
echo "  Admin:  http://$(hostname -I | awk '{print $1}'):81"
echo "  Login:  admin@example.com / changeme"
echo "  CHANGE THE PASSWORD ON FIRST LOGIN!"
echo "========================================"
