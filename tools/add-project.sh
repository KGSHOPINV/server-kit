#!/bin/bash
# ============================================================
# ADD PROJECT WIZARD
# Guided setup for adding a new Docker project
# ============================================================

echo ""
echo "=========================================="
echo "  ADD NEW PROJECT"
echo "=========================================="
echo ""

# --- Project name ---
read -p "Project name (lowercase, no spaces): " PROJECT_NAME
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

if [[ -z "$PROJECT_NAME" ]]; then
  echo "No name given. Cancelled."
  exit 1
fi

PROJECT_DIR="/srv/docker/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
  echo "Directory $PROJECT_DIR already exists!"
  exit 1
fi

# --- Port ---
read -p "Container internal port (e.g. 3000): " INTERNAL_PORT
read -p "Host port to expose on (e.g. 3100): " HOST_PORT

# --- Database ---
echo ""
echo "Does this project need a database?"
echo "  1) None"
echo "  2) PostgreSQL"
echo "  3) SurrealDB (use existing)"
echo "  4) Supabase (use existing)"
read -p "Pick [1-4]: " db_choice

# --- Docker image or build ---
echo ""
echo "How will this project run?"
echo "  1) Docker image (e.g. myapp:latest)"
echo "  2) Build from source (Dockerfile)"
read -p "Pick [1-2]: " run_choice

if [[ "$run_choice" == "1" ]]; then
  read -p "Docker image name: " DOCKER_IMAGE
else
  DOCKER_IMAGE=""
fi

# --- Subdomain ---
echo ""
read -p "Subdomain for Cloudflare (e.g. myapp): " SUBDOMAIN
echo "Will route: $SUBDOMAIN.yourdomain.com -> localhost:$HOST_PORT"

# --- Generate compose file ---
mkdir -p "$PROJECT_DIR"

if [[ "$run_choice" == "1" ]]; then
  # Image-based
  cat > "$PROJECT_DIR/docker-compose.yml" << EOF
services:
  $PROJECT_NAME:
    image: $DOCKER_IMAGE
    container_name: $PROJECT_NAME
    restart: always
    ports:
      - "$HOST_PORT:$INTERNAL_PORT"
    volumes:
      - ${PROJECT_NAME}-data:/data
    networks:
      - proxy

EOF
else
  # Build-based
  cat > "$PROJECT_DIR/docker-compose.yml" << EOF
services:
  $PROJECT_NAME:
    build: .
    container_name: $PROJECT_NAME
    restart: always
    ports:
      - "$HOST_PORT:$INTERNAL_PORT"
    volumes:
      - ${PROJECT_NAME}-data:/data
    networks:
      - proxy

EOF
fi

# Add database if needed
if [[ "$db_choice" == "2" ]]; then
  cat >> "$PROJECT_DIR/docker-compose.yml" << EOF
  ${PROJECT_NAME}-db:
    image: postgres:16
    container_name: ${PROJECT_NAME}-db
    restart: always
    environment:
      POSTGRES_DB: $PROJECT_NAME
      POSTGRES_USER: $PROJECT_NAME
      POSTGRES_PASSWORD: changeme
    volumes:
      - ${PROJECT_NAME}-pgdata:/var/lib/postgresql/data
    networks:
      - proxy

EOF
fi

# Add volumes and networks
cat >> "$PROJECT_DIR/docker-compose.yml" << EOF
volumes:
  ${PROJECT_NAME}-data:
EOF

if [[ "$db_choice" == "2" ]]; then
  echo "  ${PROJECT_NAME}-pgdata:" >> "$PROJECT_DIR/docker-compose.yml"
fi

cat >> "$PROJECT_DIR/docker-compose.yml" << EOF

networks:
  proxy:
    external: true
EOF

echo ""
echo "=========================================="
echo "  PROJECT CREATED: $PROJECT_NAME"
echo "=========================================="
echo ""
echo "  Directory:  $PROJECT_DIR"
echo "  Compose:    $PROJECT_DIR/docker-compose.yml"
echo "  Port:       $HOST_PORT -> $INTERNAL_PORT"
echo "  Subdomain:  $SUBDOMAIN.yourdomain.com"
echo ""

# --- Start? ---
read -p "Start the project now? (y/n): " start_now
if [[ "$start_now" == "y" ]]; then
  cd "$PROJECT_DIR"
  docker compose up -d
  echo ""
  echo "  $PROJECT_NAME is running!"
  echo ""
  echo "  NEXT STEPS:"
  echo "  1. Add proxy host in NPM:  http://$(hostname -I | awk '{print $1}'):81"
  echo "     Forward: $SUBDOMAIN.yourdomain.com -> $PROJECT_NAME:$INTERNAL_PORT"
  echo "  2. Add tunnel route in Cloudflare dashboard"
  echo "  3. Add monitor in Uptime Kuma"
fi

echo ""
