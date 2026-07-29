#!/bin/bash
# ============================================================
# RUN ALL - Master installer
# Runs each setup script in order with sudo
# Tracks progress — restart picks up where you left off
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROGRESS_FILE="$SCRIPT_DIR/.install-progress"

# --- Ensure running as root ---
if [ "$EUID" -ne 0 ]; then
  echo "Re-running with sudo..."
  exec sudo bash "$0" "$@"
fi

# --- Script list ---
SCRIPTS=(
  "01-system-setup.sh:System Setup (updates, firewall, SSH)"
  "02-docker-install.sh:Docker Install"
  "03-npm-setup.sh:Nginx Proxy Manager"
  "04-cloudflared-setup.sh:Cloudflare Tunnel"
  "05-portainer-setup.sh:Portainer"
  "06-monitoring-setup.sh:Monitoring (Uptime Kuma + Netdata)"
  "07-claude-cli-setup.sh:Claude CLI + MCP"
  "08-extras-setup.sh:Extras (Supabase, n8n, SurrealDB, Homepage, Dozzle)"
  "09-backup-setup.sh:Backup System"
  "10-linux-helper-setup.sh:Linux Helper (menu, aliases, tools)"
  "11-hardware-monitor-setup.sh:Hardware Monitoring"
  "12-security-setup.sh:Security Hardening"
  "13-github-deploy-setup.sh:GitHub Deploy"
  "14-terminal-setup.sh:Terminal Setup (prompt, dashboard, banner)"
  "15-server-console-setup.sh:Server Console + ChatOps (Cockpit, alerts)"
  "16-ai-setup.sh:Local AI (Ollama, Open WebUI, OpenClaw)"
)

# --- Check for previous progress ---
START_AT=0
if [ -f "$PROGRESS_FILE" ]; then
  LAST_DONE=$(cat "$PROGRESS_FILE")
  echo ""
  echo "========================================================"
  echo "  SERVER KIT - RESUMING INSTALL"
  echo "========================================================"
  echo ""
  echo "  Last completed: $LAST_DONE"
  echo ""

  # Find where to resume
  for i in "${!SCRIPTS[@]}"; do
    SCRIPT_NAME="${SCRIPTS[$i]%%:*}"
    if [ "$SCRIPT_NAME" == "$LAST_DONE" ]; then
      START_AT=$((i + 1))
      break
    fi
  done

  echo "  Remaining steps:"
  for i in $(seq $START_AT $((${#SCRIPTS[@]} - 1))); do
    LABEL="${SCRIPTS[$i]#*:}"
    echo "    $((i + 1)). $LABEL"
  done
  echo ""
  read -p "  Continue from where you left off? (y/n/restart): " resume
  if [[ "$resume" == "restart" ]]; then
    START_AT=0
    rm -f "$PROGRESS_FILE"
  elif [[ "$resume" != "y" ]]; then
    echo ""
    echo "  Pick a step to start from (1-${#SCRIPTS[@]}):"
    for i in "${!SCRIPTS[@]}"; do
      LABEL="${SCRIPTS[$i]#*:}"
      echo "    $((i + 1)). $LABEL"
    done
    echo ""
    read -p "  Start at step: " step_num
    START_AT=$((step_num - 1))
  fi
else
  echo ""
  echo "========================================================"
  echo "  SERVER KIT - FULL INSTALL"
  echo "========================================================"
  echo ""
  echo "  Steps:"
  for i in "${!SCRIPTS[@]}"; do
    LABEL="${SCRIPTS[$i]#*:}"
    echo "    $((i + 1)). $LABEL"
  done
  echo ""
  read -p "  Run full install? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo ""
echo "Starting install..."
echo ""

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null
chmod +x "$SCRIPT_DIR"/tools/*.sh 2>/dev/null

# --- Run scripts ---
TOTAL=${#SCRIPTS[@]}

for i in $(seq $START_AT $((TOTAL - 1))); do
  SCRIPT_NAME="${SCRIPTS[$i]%%:*}"
  LABEL="${SCRIPTS[$i]#*:}"
  STEP=$((i + 1))

  echo ""
  echo "========================================================"
  echo "  [$STEP/$TOTAL] $LABEL"
  echo "========================================================"
  echo ""

  bash "$SCRIPT_DIR/$SCRIPT_NAME"
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "========================================================"
    echo "  SCRIPT FAILED: $SCRIPT_NAME (exit code $EXIT_CODE)"
    echo "========================================================"
    echo ""
    echo "  Options:"
    echo "    1) Retry this step"
    echo "    2) Skip and continue"
    echo "    3) Stop here (resume later with: sudo bash run-all.sh)"
    echo ""
    read -p "  Pick [1-3]: " fail_choice

    case $fail_choice in
      1)
        bash "$SCRIPT_DIR/$SCRIPT_NAME"
        if [ $? -ne 0 ]; then
          echo "  Failed again. Skipping."
        fi
        ;;
      2)
        echo "  Skipping $SCRIPT_NAME..."
        ;;
      3)
        echo "$SCRIPT_NAME" > "$PROGRESS_FILE"
        echo ""
        echo "  Progress saved. Run 'sudo bash run-all.sh' to resume."
        exit 1
        ;;
    esac
  fi

  # Save progress
  echo "$SCRIPT_NAME" > "$PROGRESS_FILE"

  # Pause after Docker install for group permissions
  if [ "$SCRIPT_NAME" == "02-docker-install.sh" ]; then
    echo ""
    echo "  Docker installed. Adding current user to docker group..."
    REAL_USER=${SUDO_USER:-$USER}
    usermod -aG docker "$REAL_USER" 2>/dev/null
    echo ""
    echo "  NOTE: If docker commands fail in later steps, they'll"
    echo "  run with sudo automatically. No need to log out."
    echo ""
  fi
done

# --- Done ---
rm -f "$PROGRESS_FILE"

echo ""
echo "========================================================"
echo "  SERVER KIT - INSTALL COMPLETE"
echo "========================================================"
echo ""
IP=$(hostname -I | awk '{print $1}')
echo "  Your server IP: $IP"
echo ""
echo "  SERVICES:"
echo "  ─────────────────────────────────────────"
echo "  NPM Admin:       http://$IP:81"
echo "  Portainer:       https://$IP:9443"
echo "  Homepage:        http://$IP:3000"
echo "  Uptime Kuma:     http://$IP:3001"
echo "  Grafana:         http://$IP:3002  (if installed)"
echo "  Wiki.js:         http://$IP:3003  (if installed)"
echo "  Supabase:        http://$IP:8000  (if installed)"
echo "  n8n:             http://$IP:5678  (if installed)"
echo "  Dozzle:          http://$IP:8090"
echo "  Redis Commander: http://$IP:8082  (if installed)"
echo "  Adminer:         http://$IP:8083  (if installed)"
echo "  LanguageTool:    http://$IP:8084  (if installed)"
echo "  SurrealDB:       http://$IP:8181  (if installed)"
echo "  MinIO:           http://$IP:9001  (if installed)"
echo "  Netdata:         http://$IP:19999"
echo "  Open WebUI:      http://$IP:3004  (if installed)"
echo "  OpenClaw:        http://$IP:3005  (if installed)"
echo "  Ollama API:      http://$IP:11434 (if installed)"
echo ""
echo "  COMMANDS:"
echo "  ─────────────────────────────────────────"
echo "  menu          Server command center"
echo "  health        Check all services"
echo "  sec           Security status"
echo "  hw            Hardware status"
echo "  ports         Scan open ports"
echo "  cheat         Linux cheat sheet"
echo "  deploy        Deploy from GitHub"
echo "  ai-models     Manage AI models"
echo "  update-kit    Update server-kit"
echo "  kit-servers   Multi-server registry"
echo ""
echo "  Type 'menu' to get started."
echo "========================================================"
