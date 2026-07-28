#!/bin/bash
# ============================================================
# 08 - EXTRAS
# Supabase (self-hosted), n8n, SurrealDB, Homepage, Dozzle
# ============================================================

set -e

echo "========================================"
echo "  08 - EXTRAS SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Shared proxy network ---
docker network create proxy 2>/dev/null || true

# --- Homepage (dashboard) ---
echo "Setting up Homepage dashboard..."
HP_DIR="/srv/docker/homepage"
mkdir -p "$HP_DIR"
cp "$SCRIPT_DIR/docker-compose/homepage/docker-compose.yml" "$HP_DIR/"
cd "$HP_DIR"
docker compose up -d

# --- Dozzle (live logs) ---
echo ""
echo "Setting up Dozzle (container logs)..."
DZ_DIR="/srv/docker/dozzle"
mkdir -p "$DZ_DIR"
cp "$SCRIPT_DIR/docker-compose/dozzle/docker-compose.yml" "$DZ_DIR/"
cd "$DZ_DIR"
docker compose up -d

# --- Supabase (self-hosted) ---
echo ""
read -p "Install Supabase self-hosted? (y/n): " install_supa
if [[ "$install_supa" == "y" ]]; then
  echo "Setting up Supabase..."
  SUPA_DIR="/srv/docker/supabase"
  mkdir -p "$SUPA_DIR"
  cp "$SCRIPT_DIR/docker-compose/supabase/docker-compose.yml" "$SUPA_DIR/"
  cp "$SCRIPT_DIR/docker-compose/supabase/.env.example" "$SUPA_DIR/.env"
  echo ""
  echo "IMPORTANT: Edit /srv/docker/supabase/.env before starting!"
  echo "At minimum change:"
  echo "  - POSTGRES_PASSWORD"
  echo "  - JWT_SECRET"
  echo "  - ANON_KEY"
  echo "  - SERVICE_ROLE_KEY"
  echo ""
  read -p "Start Supabase now? (y/n): " start_supa
  if [[ "$start_supa" == "y" ]]; then
    cd "$SUPA_DIR"
    docker compose up -d
  fi
fi

# --- n8n ---
echo ""
read -p "Install n8n (workflow automation)? (y/n): " install_n8n
if [[ "$install_n8n" == "y" ]]; then
  echo "Setting up n8n..."
  N8N_DIR="/srv/docker/n8n"
  mkdir -p "$N8N_DIR"
  cp "$SCRIPT_DIR/docker-compose/n8n/docker-compose.yml" "$N8N_DIR/"
  cd "$N8N_DIR"
  docker compose up -d
fi

# --- SurrealDB ---
echo ""
read -p "Install SurrealDB? (y/n): " install_surreal
if [[ "$install_surreal" == "y" ]]; then
  echo "Setting up SurrealDB..."
  SDB_DIR="/srv/docker/surrealdb"
  mkdir -p "$SDB_DIR"
  cp "$SCRIPT_DIR/docker-compose/surrealdb/docker-compose.yml" "$SDB_DIR/"
  cd "$SDB_DIR"
  docker compose up -d
fi

echo ""
echo "========================================"
echo "  08 - EXTRAS COMPLETE"
echo ""
IP=$(hostname -I | awk '{print $1}')
echo "  Homepage:   http://$IP:3000"
echo "  Dozzle:     http://$IP:8080"
[[ "$install_supa" == "y" ]] && echo "  Supabase:   http://$IP:8000"
[[ "$install_n8n" == "y" ]] && echo "  n8n:        http://$IP:5678"
[[ "$install_surreal" == "y" ]] && echo "  SurrealDB:  http://$IP:8181"
echo "========================================"
