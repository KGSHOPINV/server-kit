#!/bin/bash
# ============================================================
# 06 - MONITORING
# Uptime Kuma (service monitoring) + Netdata (system stats)
# ============================================================

set -e

echo "========================================"
echo "  06 - MONITORING SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Uptime Kuma ---
echo "Setting up Uptime Kuma..."
KUMA_DIR="/srv/docker/uptime-kuma"
mkdir -p "$KUMA_DIR"
cp "$SCRIPT_DIR/docker-compose/monitoring/docker-compose.yml" "$KUMA_DIR/"
cd "$KUMA_DIR"
docker compose up -d

# --- Netdata ---
echo ""
echo "Setting up Netdata (system monitoring)..."
NETDATA_DIR="/srv/docker/netdata"
mkdir -p "$NETDATA_DIR"
cp "$SCRIPT_DIR/docker-compose/netdata/docker-compose.yml" "$NETDATA_DIR/"
cd "$NETDATA_DIR"
docker compose up -d

echo ""
echo "========================================"
echo "  06 - MONITORING RUNNING"
echo ""
echo "  Uptime Kuma: http://$(hostname -I | awk '{print $1}'):3001"
echo "  Netdata:     http://$(hostname -I | awk '{print $1}'):19999"
echo "========================================"
