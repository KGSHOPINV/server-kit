#!/bin/bash
# ============================================================
# SERVER SYNC
# Syncs the server registry between multiple servers
# Uses a shared git repo or SSH to exchange registry data
# ============================================================

echo ""
echo "=========================================="
echo "  SERVER REGISTRY SYNC"
echo "=========================================="

REGISTRY_DIR="/srv/docker/server-registry"
REGISTRY_FILE="$REGISTRY_DIR/servers.json"

# Update self first
server-register 2>/dev/null

echo ""
echo "  How do you want to sync?"
echo ""
echo "  1) Git repo (push/pull registry to shared repo)"
echo "  2) SSH (pull from another server)"
echo "  3) Import file (paste or load a servers.json)"
echo ""
read -p "  Pick [1-3]: " method

case $method in
  1)
    # --- Git sync ---
    cd "$REGISTRY_DIR"

    if [ ! -d ".git" ]; then
      echo ""
      echo "  Setting up git sync for registry..."
      read -p "  GitHub repo for registry (e.g. KGSHOPINV/server-registry): " REPO
      git init
      git remote add origin "https://github.com/$REPO.git"
      git add -A
      git commit -m "Initial registry from $(hostname)"
      git branch -M main
      git push -u origin main
      echo "  Registry pushed to GitHub."
    else
      echo ""
      echo "  Pulling latest registry..."
      git pull origin main 2>/dev/null

      # Deduplicate after git pull (git has already merged remote changes into the file)
      if [ -f "$REGISTRY_FILE" ]; then
        TMP=$(mktemp)
        jq -s '.[0] | group_by(.id) | map(max_by(.last_seen))' \
          "$REGISTRY_FILE" > "$TMP" 2>/dev/null && mv "$TMP" "$REGISTRY_FILE"
      fi

      # Update self and push
      server-register 2>/dev/null
      git add -A
      git commit -m "Registry update from $(hostname) - $(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null
      git push origin main 2>/dev/null
      echo "  Registry synced."
    fi
    ;;

  2)
    # --- SSH sync ---
    echo ""
    read -p "  SSH target (user@host): " SSH_TARGET
    echo "  Pulling registry from $SSH_TARGET..."

    REMOTE_JSON=$(ssh "$SSH_TARGET" "cat /srv/docker/server-registry/servers.json" 2>/dev/null)

    if [ -z "$REMOTE_JSON" ]; then
      echo "  Failed to fetch registry from remote."
      exit 1
    fi

    # Merge remote into local
    mkdir -p "$REGISTRY_DIR"
    if [ -f "$REGISTRY_FILE" ]; then
      TMP=$(mktemp)
      echo "$REMOTE_JSON" > "$TMP.remote"
      jq -s '.[0] + .[1] | group_by(.id) | map(max_by(.last_seen))' \
        "$REGISTRY_FILE" "$TMP.remote" > "$TMP" 2>/dev/null && mv "$TMP" "$REGISTRY_FILE"
      rm -f "$TMP.remote"
    else
      echo "$REMOTE_JSON" > "$REGISTRY_FILE"
    fi

    server-register 2>/dev/null
    echo "  Registry merged."
    ;;

  3)
    # --- File import ---
    echo ""
    read -p "  Path to servers.json: " IMPORT_FILE
    if [ ! -f "$IMPORT_FILE" ]; then
      echo "  File not found."
      exit 1
    fi

    mkdir -p "$REGISTRY_DIR"
    if [ -f "$REGISTRY_FILE" ]; then
      TMP=$(mktemp)
      jq -s '.[0] + .[1] | group_by(.id) | map(max_by(.last_seen))' \
        "$REGISTRY_FILE" "$IMPORT_FILE" > "$TMP" 2>/dev/null && mv "$TMP" "$REGISTRY_FILE"
    else
      cp "$IMPORT_FILE" "$REGISTRY_FILE"
    fi

    server-register 2>/dev/null
    echo "  Registry imported."
    ;;

  *)
    echo "  Invalid option."
    exit 1
    ;;
esac

echo ""
echo "  Current registry:"
server-list 2>/dev/null || kit-servers 2>/dev/null
