#!/bin/bash
# ============================================================
# 13 - GITHUB DEPLOY
# GitHub Container Registry, webhook auto-deploy, Actions templates
# ============================================================

set -e

echo "========================================"
echo "  13 - GITHUB DEPLOY SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- GitHub CLI ---
echo ""
echo "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
fi
echo "GitHub CLI installed: $(gh --version | head -1)"

# --- Authenticate ---
echo ""
echo "Authenticate with GitHub:"
echo "  This lets the server pull private repos and images."
echo ""
read -p "Login to GitHub now? (y/n): " do_login
if [[ "$do_login" == "y" ]]; then
  gh auth login
fi

# --- GitHub Container Registry (GHCR) login ---
echo ""
echo "Setting up GitHub Container Registry..."
read -p "Login Docker to GHCR? (y/n): " do_ghcr
if [[ "$do_ghcr" == "y" ]]; then
  echo ""
  echo "You need a GitHub Personal Access Token (PAT) with packages:read scope."
  echo "Create one at: https://github.com/settings/tokens"
  echo ""
  read -p "GitHub username: " GH_USER
  read -sp "GitHub PAT: " GH_TOKEN
  echo ""
  echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
  echo "Docker logged into GHCR."
fi

# --- Webhook receiver ---
echo ""
read -p "Install webhook receiver (auto-deploy on GitHub push)? (y/n): " install_webhook
if [[ "$install_webhook" == "y" ]]; then
  WEBHOOK_DIR="/srv/docker/webhook"
  mkdir -p "$WEBHOOK_DIR/scripts"
  cp "$SCRIPT_DIR/docker-compose/webhook/docker-compose.yml" "$WEBHOOK_DIR/"
  cp "$SCRIPT_DIR/docker-compose/webhook/hooks.json" "$WEBHOOK_DIR/"
  cp "$SCRIPT_DIR/docker-compose/webhook/scripts/deploy.sh" "$WEBHOOK_DIR/scripts/"
  chmod +x "$WEBHOOK_DIR/scripts/deploy.sh"

  cd "$WEBHOOK_DIR"
  docker compose up -d

  echo ""
  echo "  Webhook receiver running on port 9000."
  echo ""
  echo "  To connect GitHub:"
  echo "  1. Go to your repo → Settings → Webhooks → Add"
  echo "  2. Payload URL: https://deploy.yourdomain.com/hooks/deploy"
  echo "  3. Content type: application/json"
  echo "  4. Events: Just the push event"
  echo ""
  echo "  Route through Cloudflare tunnel + NPM:"
  echo "  deploy.yourdomain.com → webhook:9000"
  echo "  Put Cloudflare Access in front of it!"
fi

# --- Deploy templates ---
echo ""
echo "Installing deploy templates..."
TEMPLATE_DIR="/srv/docker/_deploy-templates"
mkdir -p "$TEMPLATE_DIR"

# GitHub Actions workflow template
mkdir -p "$TEMPLATE_DIR/.github/workflows"
cp "$SCRIPT_DIR/deploy-templates/docker-build-push.yml" "$TEMPLATE_DIR/.github/workflows/"
cp "$SCRIPT_DIR/deploy-templates/Dockerfile.template" "$TEMPLATE_DIR/"
cp "$SCRIPT_DIR/deploy-templates/docker-compose.production.yml" "$TEMPLATE_DIR/"

echo "  Templates saved to $TEMPLATE_DIR"
echo "  Copy these into your project repos."

# --- Install deploy tool ---
sudo cp "$SCRIPT_DIR/tools/deploy-project.sh" /usr/local/bin/deploy-project
sudo chmod +x /usr/local/bin/deploy-project

if ! grep -q "alias deploy=" ~/.bashrc 2>/dev/null; then
  echo 'alias deploy="deploy-project"' >> ~/.bashrc
fi

echo ""
echo "========================================"
echo "  13 - GITHUB DEPLOY READY"
echo ""
echo "  Commands:"
echo "    deploy           - Deploy/update a project from GitHub"
echo "    gh repo list     - List your GitHub repos"
echo "    gh auth status   - Check GitHub login"
echo ""
echo "  Workflow:"
echo "    Push to GitHub → Actions build image → GHCR"
echo "    → Webhook triggers → Server pulls and restarts"
echo ""
echo "  Or manual: deploy-project"
echo "========================================"
