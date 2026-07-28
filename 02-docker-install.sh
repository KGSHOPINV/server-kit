#!/bin/bash
# ============================================================
# 02 - DOCKER INSTALL
# Docker Engine + Docker Compose
# ============================================================

set -e

echo "========================================"
echo "  02 - DOCKER INSTALL"
echo "========================================"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
  echo "Docker is already installed: $(docker --version)"
  read -p "Reinstall? (y/n): " reinstall
  if [[ "$reinstall" != "y" ]]; then
    echo "Skipping Docker install."
    exit 0
  fi
fi

# --- Install Docker ---
echo ""
echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

# --- Add current user to docker group ---
echo ""
echo "Adding $USER to docker group..."
sudo usermod -aG docker $USER

# --- Enable Docker on boot ---
sudo systemctl enable docker
sudo systemctl start docker

# --- Verify ---
echo ""
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker compose version

echo ""
echo "========================================"
echo "  02 - DOCKER INSTALL COMPLETE"
echo ""
echo "  NOTE: Log out and back in for docker"
echo "  group permissions to take effect."
echo "  Or run: newgrp docker"
echo "========================================"
