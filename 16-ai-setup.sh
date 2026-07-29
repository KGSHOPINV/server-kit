#!/bin/bash
# ============================================================
# 16 - LOCAL AI STACK
# Ollama (model runner) + Open WebUI (chat) + OpenClaw (agent)
# ============================================================

set -e

echo "========================================"
echo "  16 - LOCAL AI SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Check hardware ---
echo ""
echo "  HARDWARE CHECK"
echo "  ─────────────────────────────────────"
TOTAL_RAM=$(free -g | awk '/Mem:/ {print $2}')
echo "  RAM: ${TOTAL_RAM}GB"

GPU_INFO=$(lspci 2>/dev/null | grep -i 'vga\|3d\|nvidia\|amd' | head -1)
if [ -n "$GPU_INFO" ]; then
  echo "  GPU: $GPU_INFO"
else
  echo "  GPU: None detected (CPU-only mode)"
fi

echo ""
echo "  Recommended models for your RAM:"
if [ "$TOTAL_RAM" -ge 64 ]; then
  echo "    - Gemma 4 31B (best quality)"
  echo "    - Llama 3.1 70B (needs GPU)"
  echo "    - Gemma 4 12B (fast)"
  echo "    - Any smaller model"
elif [ "$TOTAL_RAM" -ge 32 ]; then
  echo "    - Gemma 4 12B (recommended)"
  echo "    - Llama 3.1 8B (fast)"
  echo "    - Mistral 7B (good for code)"
  echo "    - Gemma 4 2B (very fast)"
elif [ "$TOTAL_RAM" -ge 16 ]; then
  echo "    - Gemma 4 12B (might be tight)"
  echo "    - Llama 3.1 8B (recommended)"
  echo "    - Gemma 4 2B (fast)"
  echo "    - Mistral 7B"
elif [ "$TOTAL_RAM" -ge 8 ]; then
  echo "    - Gemma 4 2B (recommended)"
  echo "    - Phi-3 mini"
  echo "    - TinyLlama"
else
  echo "    - Gemma 4 2B (minimum)"
  echo "    - TinyLlama"
  echo "    WARNING: Low RAM — AI will be slow"
fi

# --- NVIDIA GPU check ---
HAS_NVIDIA=false
if echo "$GPU_INFO" | grep -qi nvidia; then
  echo ""
  echo "  NVIDIA GPU detected!"
  read -p "  Install NVIDIA Container Toolkit for GPU acceleration? (y/n): " install_nvidia
  if [[ "$install_nvidia" == "y" ]]; then
    echo "  Installing NVIDIA Container Toolkit..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    HAS_NVIDIA=true
    echo "  NVIDIA toolkit installed. GPU acceleration enabled."
  fi
fi

# --- Install Ollama + Open WebUI ---
echo ""
read -p "Install Ollama + Open WebUI (local AI chat)? (y/n): " install_ai
if [[ "$install_ai" == "y" ]]; then
  echo ""
  echo "  Setting up Ollama + Open WebUI..."
  AI_DIR="/srv/docker/ai"
  mkdir -p "$AI_DIR"

  if [[ "$HAS_NVIDIA" == true ]]; then
    # Use GPU-enabled compose
    cp "$SCRIPT_DIR/docker-compose/openwebui/docker-compose.yml" "$AI_DIR/"
    # Uncomment GPU lines
    sed -i 's/# deploy:/deploy:/' "$AI_DIR/docker-compose.yml"
    sed -i 's/#   resources:/  resources:/' "$AI_DIR/docker-compose.yml"
    sed -i 's/#     reservations:/    reservations:/' "$AI_DIR/docker-compose.yml"
    sed -i 's/#       devices:/      devices:/' "$AI_DIR/docker-compose.yml"
    sed -i 's/#         - driver: nvidia/        - driver: nvidia/' "$AI_DIR/docker-compose.yml"
    sed -i 's/#           count: all/          count: all/' "$AI_DIR/docker-compose.yml"
    sed -i 's/#           capabilities: \[gpu\]/          capabilities: [gpu]/' "$AI_DIR/docker-compose.yml"
    echo "  GPU acceleration enabled in compose file."
  else
    cp "$SCRIPT_DIR/docker-compose/openwebui/docker-compose.yml" "$AI_DIR/"
  fi

  cd "$AI_DIR"
  docker compose up -d

  echo ""
  echo "  Waiting for Ollama to start..."
  sleep 10

  # --- Pull models ---
  echo ""
  echo "  Which models do you want to download?"
  echo ""
  echo "  1) Gemma 4 2B   (~1.5GB, fast, good for basics)"
  echo "  2) Gemma 4 12B  (~7GB, great quality, needs 16GB+ RAM)"
  echo "  3) Llama 3.1 8B (~4.7GB, good all-rounder)"
  echo "  4) Mistral 7B   (~4.1GB, good for code)"
  echo "  5) All of the above"
  echo "  6) Skip (download later)"
  echo ""
  read -p "  Pick [1-6]: " model_choice

  case $model_choice in
    1) docker exec ollama ollama pull gemma4:e2b ;;
    2) docker exec ollama ollama pull gemma4:12b ;;
    3) docker exec ollama ollama pull llama3.1:8b ;;
    4) docker exec ollama ollama pull mistral:7b ;;
    5)
      docker exec ollama ollama pull gemma4:e2b
      docker exec ollama ollama pull gemma4:12b
      docker exec ollama ollama pull llama3.1:8b
      docker exec ollama ollama pull mistral:7b
      ;;
    6) echo "  Skipped. Pull later with: docker exec ollama ollama pull MODEL" ;;
  esac

  echo ""
  echo "  Ollama + Open WebUI deployed!"
fi

# --- Install OpenClaw ---
echo ""
read -p "Install OpenClaw (autonomous AI agent)? (y/n): " install_claw
if [[ "$install_claw" == "y" ]]; then
  echo ""
  echo "  Setting up OpenClaw..."
  CLAW_DIR="/srv/docker/openclaw"
  mkdir -p "$CLAW_DIR"
  cp "$SCRIPT_DIR/docker-compose/openclaw/docker-compose.yml" "$CLAW_DIR/"
  cd "$CLAW_DIR"
  docker compose up -d
  echo "  OpenClaw deployed!"
fi

# --- Model management script ---
sudo tee /usr/local/bin/ai-models > /dev/null << 'MODELSEOF'
#!/bin/bash
# Manage Ollama AI models

echo ""
echo "  AI MODEL MANAGER"
echo "  ─────────────────────────────────────"
echo ""
echo "  1) List installed models"
echo "  2) Pull a new model"
echo "  3) Remove a model"
echo "  4) Run a model (chat in terminal)"
echo "  5) Check Ollama status"
echo ""
read -p "  Pick [1-5]: " choice

case $choice in
  1)
    echo ""
    docker exec ollama ollama list 2>/dev/null || echo "  Ollama not running."
    ;;
  2)
    echo ""
    echo "  Popular models:"
    echo "    gemma4:e2b     — Google, small, fast"
    echo "    gemma4:12b    — Google, great quality"
    echo "    gemma4:31b    — Google, best quality (needs lots of RAM)"
    echo "    llama3.1:8b   — Meta, good all-rounder"
    echo "    llama3.1:70b  — Meta, very large (needs GPU)"
    echo "    mistral:7b    — Mistral, good for code"
    echo "    codellama:7b  — Meta, coding specific"
    echo "    phi3:mini     — Microsoft, very small"
    echo ""
    read -p "  Model name to pull: " model
    docker exec ollama ollama pull "$model"
    ;;
  3)
    echo ""
    docker exec ollama ollama list 2>/dev/null
    echo ""
    read -p "  Model name to remove: " model
    docker exec ollama ollama rm "$model"
    ;;
  4)
    echo ""
    docker exec ollama ollama list 2>/dev/null
    echo ""
    read -p "  Model to chat with: " model
    docker exec -it ollama ollama run "$model"
    ;;
  5)
    echo ""
    if docker ps 2>/dev/null | grep -q ollama; then
      echo "  Ollama: running"
      echo "  Models:"
      docker exec ollama ollama list 2>/dev/null
      echo ""
      echo "  RAM used by Ollama:"
      docker stats ollama --no-stream --format "  {{.MemUsage}}" 2>/dev/null
    else
      echo "  Ollama: not running"
      echo "  Start with: cd /srv/docker/ai && docker compose up -d"
    fi
    ;;
esac
echo ""
MODELSEOF

sudo chmod +x /usr/local/bin/ai-models

echo ""
echo "========================================"
echo "  16 - LOCAL AI COMPLETE"
echo ""
IP=$(hostname -I | awk '{print $1}')
[[ "$install_ai" == "y" ]] && echo "  Open WebUI:  http://$IP:3004  (ChatGPT-like interface)"
[[ "$install_ai" == "y" ]] && echo "  Ollama API:  http://$IP:11434"
[[ "$install_claw" == "y" ]] && echo "  OpenClaw:    http://$IP:3005"
echo ""
echo "  Commands:"
echo "    ai-models      — manage AI models"
echo "    docker exec -it ollama ollama run gemma4:12b"
echo "                   — chat with AI in terminal"
echo ""
echo "  All AI runs LOCAL — no API keys, no subscriptions,"
echo "  no data leaves your server."
echo "========================================"
