#!/bin/bash
# ============================================================
# WEBHOOK DEPLOY SCRIPT
# Called by webhook container when GitHub sends a push event
# ============================================================

REPO_NAME="$1"
REF="$2"
DEPLOY_DIR="/srv/docker/$REPO_NAME"
LOG="/var/log/deploy.log"

echo "$(date) — Deploy triggered for $REPO_NAME ($REF)" >> "$LOG"

if [ ! -d "$DEPLOY_DIR" ]; then
  echo "$(date) — ERROR: $DEPLOY_DIR does not exist" >> "$LOG"
  exit 1
fi

cd "$DEPLOY_DIR"

# Pull latest code
if [ -d ".git" ]; then
  git pull origin main >> "$LOG" 2>&1
fi

# Pull latest images and restart
docker compose pull >> "$LOG" 2>&1
docker compose up -d >> "$LOG" 2>&1

echo "$(date) — Deploy complete for $REPO_NAME" >> "$LOG"
