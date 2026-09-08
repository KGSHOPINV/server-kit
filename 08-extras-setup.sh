#!/bin/bash
# ============================================================
# 08 - EXTRAS
# Supabase, n8n, SurrealDB, Redis, MinIO, Adminer, Grafana,
# Mailpit, Wiki.js, LanguageTool, Homepage, Dozzle
# ============================================================

set -e

echo "========================================"
echo "  08 - EXTRAS SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Shared proxy network ---
docker network create proxy 2>/dev/null || true

# Helper function
deploy_service() {
  local name="$1"
  local src="$2"
  local dir="/srv/docker/$name"
  mkdir -p "$dir"
  cp "$SCRIPT_DIR/docker-compose/$src/docker-compose.yml" "$dir/"
  cd "$dir"
  docker compose up -d
  echo "  $name deployed."
}

# === ALWAYS INSTALL (core visibility) ===

echo ""
echo "--- Core Services (auto-install) ---"
deploy_service "homepage" "homepage"
deploy_service "dozzle" "dozzle"

# === ASK FOR EACH ===

echo ""
echo "--- Optional Services ---"
echo ""

# --- Redis ---
read -p "Install Redis (cache + queue + Redis Commander UI)? (y/n): " install_redis
if [[ "$install_redis" == "y" ]]; then
  deploy_service "redis" "redis"
fi

# --- MinIO ---
echo ""
read -p "Install MinIO (S3-compatible file storage)? (y/n): " install_minio
if [[ "$install_minio" == "y" ]]; then
  deploy_service "minio" "minio"
fi

# --- Supabase ---
echo ""
read -p "Install Supabase self-hosted (Postgres + Auth + API + Studio)? (y/n): " install_supa
if [[ "$install_supa" == "y" ]]; then
  SUPA_DIR="/srv/docker/supabase"
  mkdir -p "$SUPA_DIR"
  cp "$SCRIPT_DIR/docker-compose/supabase/docker-compose.yml" "$SUPA_DIR/"
  cp "$SCRIPT_DIR/docker-compose/supabase/kong.yml" "$SUPA_DIR/"

  # Generate Supabase secrets if .env doesn't exist
  if [ ! -f "$SUPA_DIR/.env" ]; then
    JWT_SECRET=$(openssl rand -base64 32)
    ANON_KEY=$(python3 -c "
import base64, json, hmac, hashlib, time
secret = b'$JWT_SECRET'
header = base64.urlsafe_b64encode(json.dumps({'alg':'HS256','typ':'JWT'}).encode()).rstrip(b'=').decode()
payload = base64.urlsafe_b64encode(json.dumps({'role':'anon','iss':'supabase','iat':int(time.time()),'exp':int(time.time())+315360000}).encode()).rstrip(b'=').decode()
sig = base64.urlsafe_b64encode(hmac.new(secret, f'{header}.{payload}'.encode(), hashlib.sha256).digest()).rstrip(b'=').decode()
print(f'{header}.{payload}.{sig}')
" 2>/dev/null || openssl rand -base64 48 | tr -d '=+/' | head -c 64)
    SERVICE_KEY=$(python3 -c "
import base64, json, hmac, hashlib, time
secret = b'$JWT_SECRET'
header = base64.urlsafe_b64encode(json.dumps({'alg':'HS256','typ':'JWT'}).encode()).rstrip(b'=').decode()
payload = base64.urlsafe_b64encode(json.dumps({'role':'service_role','iss':'supabase','iat':int(time.time()),'exp':int(time.time())+315360000}).encode()).rstrip(b'=').decode()
sig = base64.urlsafe_b64encode(hmac.new(secret, f'{header}.{payload}'.encode(), hashlib.sha256).digest()).rstrip(b'=').decode()
print(f'{header}.{payload}.{sig}')
" 2>/dev/null || openssl rand -base64 48 | tr -d '=+/' | head -c 64)
    POSTGRES_PASS=$(openssl rand -base64 24 | tr -d '=+/')

    cat > "$SUPA_DIR/.env" << EOF
POSTGRES_PASSWORD=$POSTGRES_PASS
JWT_SECRET=$JWT_SECRET
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_KEY
API_EXTERNAL_URL=http://localhost:8000
SITE_URL=http://localhost:3000
EOF
    echo "  ✓ Generated Supabase secrets → $SUPA_DIR/.env"
    echo "  ! Save these — they cannot be regenerated without resetting the database"
  fi

  echo ""
  read -p "  Start Supabase now? (y/n): " start_supa
  if [[ "$start_supa" == "y" ]]; then
    cd "$SUPA_DIR"
    docker compose up -d
  fi
fi

# --- n8n ---
echo ""
read -p "Install n8n (workflow automation)? (y/n): " install_n8n
if [[ "$install_n8n" == "y" ]]; then
  deploy_service "n8n" "n8n"
fi

# --- SurrealDB ---
echo ""
read -p "Install SurrealDB (multi-model database)? (y/n): " install_surreal
if [[ "$install_surreal" == "y" ]]; then
  deploy_service "surrealdb" "surrealdb"
fi

# --- Adminer ---
echo ""
read -p "Install Adminer (database admin UI)? (y/n): " install_adminer
if [[ "$install_adminer" == "y" ]]; then
  deploy_service "adminer" "adminer"
fi

# --- Grafana ---
echo ""
read -p "Install Grafana (dashboards & alerting)? (y/n): " install_grafana
if [[ "$install_grafana" == "y" ]]; then
  deploy_service "grafana" "grafana"
fi

# --- Mailpit ---
echo ""
read -p "Install Mailpit (dev email catcher)? (y/n): " install_mailpit
if [[ "$install_mailpit" == "y" ]]; then
  deploy_service "mailpit" "mailpit"
fi

# --- Wiki.js ---
echo ""
read -p "Install Wiki.js (knowledge base / wiki)? (y/n): " install_wiki
if [[ "$install_wiki" == "y" ]]; then
  deploy_service "wiki" "wiki"
fi

# --- LanguageTool ---
echo ""
read -p "Install LanguageTool (grammar & spell checker API)? (y/n): " install_lang
if [[ "$install_lang" == "y" ]]; then
  deploy_service "languagetool" "languagetool"
fi

# --- Watchtower (auto-update) ---
echo ""
read -p "Install Watchtower (auto-update containers daily)? (y/n): " install_watchtower
if [[ "$install_watchtower" == "y" ]]; then
  deploy_service "watchtower" "watchtower"
fi

# === SUMMARY ===

echo ""
echo "========================================"
echo "  08 - EXTRAS COMPLETE"
echo ""
IP=$(hostname -I | awk '{print $1}')
echo "  Homepage:         http://$IP:3000"
echo "  Dozzle:           http://$IP:8090"
[[ "$install_redis" == "y" ]]      && echo "  Redis Commander:  http://$IP:8082"
[[ "$install_minio" == "y" ]]      && echo "  MinIO Console:    http://$IP:9001"
[[ "$install_supa" == "y" ]]       && echo "  Supabase Studio:  http://$IP:8000"
[[ "$install_n8n" == "y" ]]        && echo "  n8n:              http://$IP:5678"
[[ "$install_surreal" == "y" ]]    && echo "  SurrealDB:        http://$IP:8181"
[[ "$install_adminer" == "y" ]]    && echo "  Adminer:          http://$IP:8083"
[[ "$install_grafana" == "y" ]]    && echo "  Grafana:          http://$IP:3002"
[[ "$install_mailpit" == "y" ]]    && echo "  Mailpit:          http://$IP:8025"
[[ "$install_wiki" == "y" ]]       && echo "  Wiki.js:          http://$IP:3003"
[[ "$install_lang" == "y" ]]       && echo "  LanguageTool:     http://$IP:8084"
echo "========================================"
