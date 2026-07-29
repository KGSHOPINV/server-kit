#!/bin/bash
# ============================================================
# SELF UPDATE
# Updates the server-kit itself from GitHub
# Re-installs tools, docs, and compose templates
# ============================================================

echo ""
echo "=========================================="
echo "  SERVER KIT — SELF UPDATE"
echo "=========================================="

# Find where server-kit is installed
KIT_DIR=""
if [ -d "$HOME/server-kit/.git" ]; then
  KIT_DIR="$HOME/server-kit"
elif [ -d "/opt/server-kit/.git" ]; then
  KIT_DIR="/opt/server-kit"
else
  echo ""
  echo "  Can't find server-kit installation."
  echo "  Expected at ~/server-kit or /opt/server-kit"
  read -p "  Enter path to server-kit: " KIT_DIR
  if [ ! -d "$KIT_DIR/.git" ]; then
    echo "  Not a valid git repo. Cancelled."
    exit 1
  fi
fi

echo ""
echo "  Kit location: $KIT_DIR"
echo ""

# --- Pull latest ---
echo "  Pulling latest from GitHub..."
cd "$KIT_DIR"

# Show what's changing
BEFORE=$(git rev-parse HEAD)
git pull origin master
AFTER=$(git rev-parse HEAD)

if [ "$BEFORE" == "$AFTER" ]; then
  echo ""
  echo "  Already up to date."
  echo ""
  exit 0
fi

echo ""
echo "  Updated! Changes:"
git log --oneline "$BEFORE..$AFTER"

# --- Re-install tools ---
echo ""
echo "  Updating installed tools..."

TOOLS=(
  "server-menu.sh:server-menu"
  "port-scan.sh:port-scan"
  "add-project.sh:add-project"
  "health-check.sh:health-check"
  "backup.sh:server-backup"
  "linux-cheatsheet.sh:cheatsheet"
  "hardware-monitor.sh:hw-monitor"
  "security-check.sh:security-check"
  "deploy-project.sh:deploy-project"
  "self-update.sh:kit-update"
  "whats-next.sh:whats-next"
  "howdo.sh:howdo"
  "server-register.sh:server-register"
  "server-list.sh:kit-servers"
  "server-sync.sh:kit-sync"
)

for tool in "${TOOLS[@]}"; do
  FILE="${tool%%:*}"
  CMD="${tool##*:}"
  if [ -f "$KIT_DIR/tools/$FILE" ]; then
    sudo cp "$KIT_DIR/tools/$FILE" "/usr/local/bin/$CMD"
    sudo chmod +x "/usr/local/bin/$CMD"
    echo "    Updated: $CMD"
  fi
done

# --- Update compose templates ---
echo ""
echo "  Updating deploy templates..."
TEMPLATE_DIR="/srv/docker/_deploy-templates"
if [ -d "$TEMPLATE_DIR" ]; then
  cp -r "$KIT_DIR/deploy-templates/"* "$TEMPLATE_DIR/" 2>/dev/null
  echo "    Templates updated."
fi

# --- Update docs ---
echo ""
echo "  Docs updated in: $KIT_DIR/docs/"

echo ""
echo "=========================================="
echo "  UPDATE COMPLETE"
echo ""
echo "  New tools and docs are live."
echo "  Compose files for existing services are NOT changed"
echo "  (your running services are untouched)."
echo ""
echo "  To update a service's compose file manually:"
echo "    cp $KIT_DIR/docker-compose/SERVICE/docker-compose.yml /srv/docker/SERVICE/"
echo "    cd /srv/docker/SERVICE && docker compose up -d"
echo "=========================================="
echo ""
