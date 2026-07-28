#!/bin/bash
# ============================================================
# 04 - CLOUDFLARE TUNNEL
# Exposes services to the internet without opening ports
# ============================================================

set -e

echo "========================================"
echo "  04 - CLOUDFLARE TUNNEL SETUP"
echo "========================================"

echo ""
echo "You need a Cloudflare Tunnel token."
echo "To get one:"
echo "  1. Go to https://one.dash.cloudflare.com"
echo "  2. Zero Trust > Networks > Tunnels"
echo "  3. Create a tunnel"
echo "  4. Copy the token"
echo ""
read -p "Paste your tunnel token (or 'skip' to set up later): " CF_TOKEN

if [[ "$CF_TOKEN" == "skip" ]]; then
  echo "Skipping Cloudflare setup. Run this script again when ready."
  exit 0
fi

COMPOSE_DIR="/srv/docker/cloudflared"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$COMPOSE_DIR"

# Write the compose file with the token injected
cat > "$COMPOSE_DIR/docker-compose.yml" << EOF
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: always
    command: tunnel --no-autoupdate run --token ${CF_TOKEN}
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF

# Create the proxy network if it doesn't exist
docker network create proxy 2>/dev/null || true

cd "$COMPOSE_DIR"
docker compose up -d

echo ""
echo "========================================"
echo "  04 - CLOUDFLARE TUNNEL RUNNING"
echo ""
echo "  Configure routes in Cloudflare dashboard:"
echo "  Zero Trust > Networks > Tunnels > Configure"
echo "========================================"
