#!/bin/bash
# ============================================================
# DEPLOY PROJECT
# Clone or update a GitHub repo and deploy with Docker
# ============================================================

echo ""
echo "=========================================="
echo "  DEPLOY PROJECT FROM GITHUB"
echo "=========================================="
echo ""

echo "  1) Deploy NEW project from GitHub"
echo "  2) Update EXISTING project"
echo "  3) List deployed projects"
echo ""
read -p "  Pick [1-3]: " action

case $action in
  1)
    echo ""
    read -p "  GitHub repo (e.g. KGSHOPINV/taskmaster): " REPO
    read -p "  Project name (e.g. taskmaster): " PROJECT_NAME
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    DEPLOY_DIR="/srv/docker/$PROJECT_NAME"

    if [ -d "$DEPLOY_DIR" ]; then
      echo "  $DEPLOY_DIR already exists!"
      read -p "  Overwrite? (y/n): " overwrite
      if [[ "$overwrite" != "y" ]]; then
        echo "  Cancelled."
        exit 0
      fi
      rm -rf "$DEPLOY_DIR"
    fi

    echo ""
    echo "  Cloning $REPO..."
    git clone "https://github.com/$REPO.git" "$DEPLOY_DIR"

    cd "$DEPLOY_DIR"

    # Check for docker-compose file
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ]; then
      echo ""
      read -p "  Found compose file. Start the project? (y/n): " start_now
      if [[ "$start_now" == "y" ]]; then
        docker compose pull 2>/dev/null
        docker compose up -d
        echo ""
        echo "  Project deployed!"
        echo ""
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -i "$PROJECT_NAME"
      fi
    elif [ -f "Dockerfile" ]; then
      echo ""
      echo "  Found Dockerfile but no compose file."
      read -p "  Build and run? (y/n): " build_now
      if [[ "$build_now" == "y" ]]; then
        read -p "  Host port to expose: " HOST_PORT
        read -p "  Container port: " CONT_PORT
        docker build -t "$PROJECT_NAME" .
        docker run -d --name "$PROJECT_NAME" --restart always -p "$HOST_PORT:$CONT_PORT" --network proxy "$PROJECT_NAME"
        echo "  Running on port $HOST_PORT"
      fi
    else
      echo ""
      echo "  No Dockerfile or compose file found."
      echo "  You'll need to add one manually."
    fi

    echo ""
    echo "  Project cloned to: $DEPLOY_DIR"
    echo ""
    echo "  NEXT STEPS:"
    echo "  1. Add proxy host in NPM for the domain"
    echo "  2. Add public hostname in Cloudflare tunnel"
    echo "  3. Add monitor in Uptime Kuma"
    echo "  4. (Optional) Add GitHub webhook for auto-deploy"
    ;;

  2)
    echo ""
    echo "  Deployed projects:"
    ls -d /srv/docker/*/ 2>/dev/null | while read -r dir; do
      name=$(basename "$dir")
      if [ -d "$dir/.git" ]; then
        branch=$(cd "$dir" && git branch --show-current 2>/dev/null)
        echo "    $name (git: $branch)"
      else
        echo "    $name"
      fi
    done

    echo ""
    read -p "  Project name to update: " PROJECT_NAME
    DEPLOY_DIR="/srv/docker/$PROJECT_NAME"

    if [ ! -d "$DEPLOY_DIR" ]; then
      echo "  $DEPLOY_DIR not found."
      exit 1
    fi

    cd "$DEPLOY_DIR"

    if [ -d ".git" ]; then
      echo "  Pulling latest..."
      git pull
    fi

    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ]; then
      docker compose pull 2>/dev/null
      docker compose up -d
      echo "  Updated and restarted."
    else
      docker build -t "$PROJECT_NAME" .
      docker restart "$PROJECT_NAME"
      echo "  Rebuilt and restarted."
    fi
    ;;

  3)
    echo ""
    echo "  DEPLOYED PROJECTS"
    echo "  ─────────────────────────────────────"
    ls -d /srv/docker/*/ 2>/dev/null | while read -r dir; do
      name=$(basename "$dir")
      has_git=""
      has_compose=""
      running=""

      [ -d "$dir/.git" ] && has_git="git"
      [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/docker-compose.yaml" ] || [ -f "$dir/compose.yml" ] && has_compose="compose"

      container_status=$(docker ps --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -i "^${name}" | head -1 | awk '{$1=""; print $0}' | xargs)
      [ -n "$container_status" ] && running="$container_status" || running="stopped"

      printf "  %-20s  %-6s  %-8s  %s\n" "$name" "$has_git" "$has_compose" "$running"
    done
    echo ""
    ;;

  *)
    echo "  Invalid option."
    ;;
esac
