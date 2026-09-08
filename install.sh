#!/usr/bin/env bash
# server-kit install.sh — interactive server setup with bounce-back
# Safe to re-run — completed steps are tracked and skipped automatically.
# https://github.com/KGSHOPINV/server-kit
set -uo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$INSTALL_DIR/.install.log"
PROGRESS="$INSTALL_DIR/.install-progress"
CONFIG="$INSTALL_DIR/.install-config"
: > "$LOG"
touch "$PROGRESS"

BLU='\033[0;34m'; GRN='\033[0;32m'; YLW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'
info()      { echo -e "${BLU}→${NC} $1" | tee -a "$LOG"; }
success()   { echo -e "${GRN}✓${NC} $1" | tee -a "$LOG"; }
warn()      { echo -e "${YLW}⚠${NC}  $1" | tee -a "$LOG"; }
skipped()   { echo -e "${GRN}✓${NC} $1 ${YLW}(already done)${NC}" | tee -a "$LOG"; }
fail()      { echo -e "${RED}✗${NC} $1" | tee -a "$LOG"; exit 1; }

# ── Progress helpers ────────────────────────────────────────────────────────────
step_done()    { grep -q "^$1:done$" "$PROGRESS" 2>/dev/null; }
mark_done()    { echo "$1:done"    >> "$PROGRESS"; }
mark_skipped() { echo "$1:skipped" >> "$PROGRESS"; }

# ── Roadblock detector ──────────────────────────────────────────────────────────
# Looks at error output and returns a human hint + optional auto-fix command.
detect_roadblock() {
  local err="$1"
  HINT=""
  FIX_CMD=""

  if echo "$err" | grep -qE "port is already allocated|address already in use|bind.*failed"; then
    PORT=$(echo "$err" | grep -oP '(?<=:)[0-9]{2,5}' | tail -1)
    HINT="Port conflict${PORT:+ on :$PORT} — something else is using that port."
    FIX_CMD="ss -tlnp${PORT:+ | grep :$PORT} && docker ps --format 'table {{.Names}}\\t{{.Ports}}'"

  elif echo "$err" | grep -q "container name.*already in use"; then
    CNAME=$(echo "$err" | grep -oP 'container name "/?\K[^"]+' | head -1)
    HINT="Container '$CNAME' already exists (leftover from a previous attempt)."
    FIX_CMD="docker rm -f $CNAME"

  elif echo "$err" | grep -qiE "permission denied|cannot open|access denied"; then
    HINT="Permission denied — a file or directory isn't accessible."
    FIX_CMD="sudo chown -R ${ADMIN_USER:-admin1}:${ADMIN_USER:-admin1} /srv/docker && sudo chmod -R 755 /srv/docker"

  elif echo "$err" | grep -q "No space left on device"; then
    HINT="Disk is full."
    FIX_CMD="df -h && docker system prune -f"

  elif echo "$err" | grep -qE "Unable to find image|failed to pull|network.*timeout|dial tcp"; then
    HINT="Docker image pull failed — internet connection or Docker Hub issue."
    FIX_CMD="ping -c 2 registry-1.docker.io && docker info"

  elif echo "$err" | grep -q "command not found"; then
    CMD=$(echo "$err" | grep -oP "[\w-]+: command not found" | head -1)
    HINT="Missing command: $CMD — a prerequisite may not have installed correctly."
    FIX_CMD="which docker && docker --version && which curl"

  elif echo "$err" | grep -qE "dpkg.*lock|apt.*locked|Could not get lock"; then
    HINT="apt/dpkg is locked — another package manager process is running."
    FIX_CMD="sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock && sudo dpkg --configure -a"

  elif echo "$err" | grep -qE "Failed to connect|Connection refused|ssh.*timeout"; then
    HINT="Connection refused — the service may not have started in time."
    FIX_CMD="docker ps && sleep 5 && docker ps"

  elif echo "$err" | grep -q "Conflict. The container name"; then
    CNAME=$(echo "$err" | grep -oP '"/\K[^"]+' | head -1)
    HINT="Container '$CNAME' already exists from a previous install attempt."
    FIX_CMD="docker rm -f $CNAME"
  fi
}

# ── Per-step runner with bounce-back ────────────────────────────────────────────
# run_step "step-id" "Human Label" "script-filename.sh"
run_step() {
  local id="$1" label="$2" script="$3"
  local script_path="$INSTALL_DIR/$script"

  # Already done from a prior run?
  if step_done "$id"; then
    skipped "$label"
    return 0
  fi

  if [[ ! -f "$script_path" ]]; then
    warn "$label: script '$script' not found — skipping"
    mark_skipped "$id"
    return 0
  fi

  local attempt=0
  while true; do
    attempt=$((attempt + 1))
    info "[$label] attempt $attempt..."
    local tmp=$(mktemp)

    if bash "$script_path" >> "$tmp"; then
      cat "$tmp" >> "$LOG"
      rm -f "$tmp"
      success "$label"
      mark_done "$id"
      return 0
    fi

    # Failed — capture output and detect what went wrong
    local err_tail
    err_tail=$(tail -30 "$tmp")
    cat "$tmp" >> "$LOG"
    rm -f "$tmp"

    detect_roadblock "$err_tail"

    # Build the menu prompt
    local prompt="Step failed: $label"
    if [[ -n "$HINT" ]]; then
      prompt="$prompt\n\nDiagnosis: $HINT"
    fi
    if [[ -n "$FIX_CMD" ]]; then
      prompt="$prompt\n\nSuggested fix:\n  $FIX_CMD"
    fi

    CHOICE=$(whiptail --menu "$prompt" 22 72 5 \
      "show"    "Show error output" \
      "autofix" "Run suggested fix, then retry" \
      "shell"   "Open a shell to fix manually, then retry" \
      "retry"   "Retry without changes" \
      "skip"    "Skip this step and continue" \
      "abort"   "Stop installation" \
      --title "Step Failed: $label" \
      3>&1 1>&2 2>&3) || CHOICE="abort"

    case "$CHOICE" in
      show)
        whiptail --scrolltext --msgbox "$err_tail" 24 78 \
          --title "$label — Last 30 lines of output" 3>&1 1>&2 2>&3 || true
        # Loop back to the menu (don't retry automatically after show)
        attempt=$((attempt - 1))
        ;;
      autofix)
        if [[ -n "$FIX_CMD" ]]; then
          clear
          echo -e "${YLW}Running fix:${NC} $FIX_CMD"
          eval "$FIX_CMD" 2>&1 | tee -a "$LOG" || true
          echo ""
          read -rp "  Fix applied. Press Enter to retry..." _
        else
          warn "No auto-fix available for this error"
          read -rp "  Press Enter to retry anyway..." _
        fi
        ;;
      shell)
        clear
        echo -e "${YLW}  Opening shell — fix the issue then type 'exit' to retry${NC}"
        [[ -n "$HINT" ]] && echo -e "  Hint: $HINT"
        [[ -n "$FIX_CMD" ]] && echo -e "  Try:  $FIX_CMD"
        echo ""
        bash --norc || true
        ;;
      retry)
        ;;  # just loop
      skip)
        warn "$label skipped by user"
        mark_skipped "$id"
        return 0
        ;;
      abort|*)
        echo "" | tee -a "$LOG"
        echo -e "${RED}Installation aborted at: $label${NC}" | tee -a "$LOG"
        show_summary
        exit 1
        ;;
    esac
  done
}

# ── Summary printer ─────────────────────────────────────────────────────────────
show_summary() {
  local done_count skipped_count
  done_count=$(grep -c ':done$' "$PROGRESS" 2>/dev/null || echo 0)
  skipped_count=$(grep -c ':skipped$' "$PROGRESS" 2>/dev/null || echo 0)
  echo ""
  echo -e "${BOLD}Progress saved to $PROGRESS${NC}"
  echo "  Completed: $done_count steps"
  echo "  Skipped:   $skipped_count steps"
  echo "  Re-run install.sh to continue from where you left off."
}

# ── Pre-flight ──────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && fail "Run as your admin user, not root."
command -v whiptail &>/dev/null || { sudo apt-get install -y whiptail &>/dev/null; }

# ── Step 0: Bootstrap (SSH + Tailscale) ────────────────────────────────────────
if [[ -f "$INSTALL_DIR/00-bootstrap.sh" ]] && ! step_done "bootstrap"; then
  whiptail --yesno "Run bootstrap first?\n\nBootstrap sets up SSH key auth and Tailscale\nbefore anything else — locking in remote access\nso you can always get back in.\n\nSafe to skip if already done." \
    14 60 --title "Step 0: Bootstrap" --yes-button "Run Bootstrap" --no-button "Skip" \
    3>&1 1>&2 2>&3 && { bash "$INSTALL_DIR/00-bootstrap.sh" && mark_done "bootstrap"; } || true
elif step_done "bootstrap"; then
  skipped "Bootstrap (SSH + Tailscale)"
fi

# Load saved config (pre-fills fields on re-run)
[[ -f "$CONFIG" ]] && source "$CONFIG" 2>/dev/null || true

# ── Step 1: Configuration ───────────────────────────────────────────────────────
DEFAULT_IP="${SERVER_IP:-$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)}"
SERVER_IP=$(whiptail --inputbox "Server local IP address:" 8 50 "$DEFAULT_IP" \
  --title "Server Kit Setup (1/3)" 3>&1 1>&2 2>&3) || exit 0

DEFAULT_USER="${ADMIN_USER:-${USER:-admin1}}"
ADMIN_USER=$(whiptail --inputbox "Admin username (your current user):" 8 50 "$DEFAULT_USER" \
  --title "Server Kit Setup (1/3)" 3>&1 1>&2 2>&3) || exit 0

DEFAULT_TZ="${TZ_NAME:-America/Los_Angeles}"
TZ_NAME=$(whiptail --inputbox "Timezone (e.g. America/New_York):" 8 55 "$DEFAULT_TZ" \
  --title "Server Kit Setup (1/3)" 3>&1 1>&2 2>&3) || exit 0

HUB_PASS=$(whiptail --passwordbox "Hub admin password:" 8 50 \
  --title "Server Kit Setup (1/3)" 3>&1 1>&2 2>&3) || exit 0

export SERVER_IP ADMIN_USER TZ_NAME INSTALL_DIR

# Save config for re-runs
cat > "$CONFIG" <<CFGEOF
SERVER_IP=$SERVER_IP
ADMIN_USER=$ADMIN_USER
TZ_NAME=$TZ_NAME
INSTALL_DIR=$INSTALL_DIR
CFGEOF

# ── Step 2: Component checklist ─────────────────────────────────────────────────
CHOICES=$(whiptail --separate-output --checklist \
"FUNDAMENTALS (always installed)
  System setup, Docker, UFW, Fail2Ban
  Nginx Proxy Manager
  Server Hub (:8765)

SELECT OPTIONAL COMPONENTS:" \
  26 72 12 \
  "monitoring"  "Monitoring (Homepage, Uptime Kuma, Netdata, Dozzle)"  ON \
  "portainer"   "Portainer — Docker GUI (:9443)"                       ON \
  "cloudflare"  "Cloudflare Tunnel (expose services, no port fwd)"     OFF \
  "n8n"         "n8n — Workflow automation (:5678)"                    ON \
  "redis"       "Redis — Cache / key-value store (:6379)"              ON \
  "surrealdb"   "SurrealDB — Multi-model database (:8001)"             ON \
  "minio"       "MinIO — Object storage / S3 compatible (:9000)"       OFF \
  "adminer"     "Adminer — Database browser (:8082)"                   OFF \
  "mailpit"     "Mailpit — Dev email catcher (:8025)"                  OFF \
  "wikijs"      "Wiki.js — Knowledge base (:3002)"                     OFF \
  "claude"      "Claude CLI — AI assistant with server context"        ON \
  "ai"          "AI Stack — Ollama + Open WebUI  [CPU-only = SLOW]"    OFF \
  3>&1 1>&2 2>&3) || exit 0

# ── Step 3: Confirm ─────────────────────────────────────────────────────────────
SUMMARY="Server: $SERVER_IP  |  User: $ADMIN_USER  |  TZ: $TZ_NAME

Always: system, docker, NPM, security, backup, hub"
[[ "$CHOICES" =~ monitoring ]] && SUMMARY+="\n + Monitoring"
[[ "$CHOICES" =~ portainer  ]] && SUMMARY+="\n + Portainer"
[[ "$CHOICES" =~ cloudflare ]] && SUMMARY+="\n + Cloudflare Tunnel"
[[ "$CHOICES" =~ n8n        ]] && SUMMARY+="\n + n8n"
[[ "$CHOICES" =~ redis      ]] && SUMMARY+="\n + Redis"
[[ "$CHOICES" =~ surrealdb  ]] && SUMMARY+="\n + SurrealDB"
[[ "$CHOICES" =~ minio      ]] && SUMMARY+="\n + MinIO"
[[ "$CHOICES" =~ adminer    ]] && SUMMARY+="\n + Adminer"
[[ "$CHOICES" =~ mailpit    ]] && SUMMARY+="\n + Mailpit"
[[ "$CHOICES" =~ wikijs     ]] && SUMMARY+="\n + Wiki.js"
[[ "$CHOICES" =~ claude     ]] && SUMMARY+="\n + Claude CLI"
[[ "$CHOICES" =~ ai         ]] && SUMMARY+="\n + AI Stack"

# Show what's already done
DONE_COUNT=$(grep -c ':done$' "$PROGRESS" 2>/dev/null || echo 0)
[[ "$DONE_COUNT" -gt 0 ]] && SUMMARY+="\n\n(Re-run: $DONE_COUNT steps already done and will be skipped)"

whiptail --yesno "$SUMMARY

Proceed?" \
  26 62 --title "Confirm (2/3)" --yes-button "Install" --no-button "Back" \
  3>&1 1>&2 2>&3 || exit 0

# ── Step 4: Install ─────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${BLU}  Server Kit — Installing...${NC}"
echo "  Log:      $LOG"
echo "  Progress: $PROGRESS"
echo "  Re-run install.sh anytime to resume from where you left off."
echo ""

# Fundamentals — always
run_step "system"    "System Setup"           "01-system-setup.sh"
run_step "docker"    "Docker Install"         "02-docker-install.sh"
# Give current session docker access without needing logout/login
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# ── Server Hub comes up FIRST — visible in browser before anything else installs
# ── Step 5: Server Hub ──────────────────────────────────────────────────────────
if step_done "hub"; then
  skipped "Server Hub"
else
  info "=== Server Hub ==="
  HUB_DIR="/home/$ADMIN_USER/hub"

  if [[ -d "$HUB_DIR" && -f "$HUB_DIR/server.py" ]]; then
    info "Hub already present — updating..."
    [[ -f "$HUB_DIR/update.sh" ]] && bash "$HUB_DIR/update.sh" >> "$LOG" 2>&1 || true
  else
    info "Cloning Server Hub from GitHub..."
    git clone https://github.com/KGSHOPINV/claude-server /tmp/_sk_hub >> "$LOG" 2>&1
    mkdir -p "$HUB_DIR"
    cp -r /tmp/_sk_hub/hub/. "$HUB_DIR/"
    mkdir -p "$(dirname "$HUB_DIR")/guides"
    cp -r /tmp/_sk_hub/guides/. "$(dirname "$HUB_DIR")/guides/" 2>/dev/null || true
    rm -rf /tmp/_sk_hub
    success "Hub installed at $HUB_DIR"
  fi

  mkdir -p "$HUB_DIR/../db"

  sudo tee /etc/systemd/system/hub.service > /dev/null <<ENDSVC
[Unit]
Description=Server Hub
After=network.target

[Service]
User=$ADMIN_USER
WorkingDirectory=$HUB_DIR
ExecStart=/usr/bin/python3 $HUB_DIR/server.py
EnvironmentFile=-/etc/default/hub
Environment=HUB_LOCAL=1
Environment=HUB_PORT=8765
Environment=HUB_SERVER_IP=$SERVER_IP
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
ENDSVC

  # Write hub admin password to environment file
  echo "HUB_ADMIN_PASS=$HUB_PASS" | sudo tee /etc/default/hub > /dev/null 2>/dev/null || true

  sudo systemctl daemon-reload
  sudo systemctl enable hub
  sudo systemctl restart hub
  sleep 2
  if systemctl is-active --quiet hub; then
    success "Hub running at http://$SERVER_IP:8765 — open it now to watch the rest of the install"
    mark_done "hub"
  else
    warn "Hub service failed — check: sudo journalctl -u hub -n 30"
  fi
fi

# Claude context — fill in real server values
if [[ -d "$INSTALL_DIR/claude" ]]; then
  mkdir -p "$HOME/.claude"
  CLAUDE_DEST="$HOME/.claude/CLAUDE.md"
  cp "$INSTALL_DIR/claude/CLAUDE.md" "$CLAUDE_DEST" 2>/dev/null || true
  # Replace placeholders with real values from this install
  sed -i "s/YOUR_HOSTNAME/$(hostname -s)/g" "$CLAUDE_DEST"
  sed -i "s/YOUR_LOCAL_IP/$SERVER_IP/g" "$CLAUDE_DEST"
  sed -i "s/YOUR_ADMIN_USER/$ADMIN_USER/g" "$CLAUDE_DEST"
  TS_IP_CL=$(tailscale ip -4 2>/dev/null || echo "not-connected")
  sed -i "s/YOUR_TAILSCALE_IP/$TS_IP_CL/g" "$CLAUDE_DEST"
  success "Claude context installed with real server values"
  cp "$INSTALL_DIR/claude/mcp-servers.json" "$HOME/.claude/mcp_servers.json" 2>/dev/null || true
fi

# Rest of fundamentals — hub is already up, these install while you can watch
run_step "npm"       "Nginx Proxy Manager"    "03-npm-setup.sh"
run_step "backup"    "Backup System"          "09-backup-setup.sh"
run_step "helpers"   "Linux Helper Tools"     "10-linux-helper-setup.sh"
run_step "hardware-monitor" "Hardware Monitor"       "11-hardware-monitor-setup.sh"
run_step "security"  "Security Setup"         "12-security-setup.sh"
run_step "terminal"  "Terminal Setup"         "14-terminal-setup.sh"
run_step "console"   "Server Console"         "15-server-console-setup.sh"

# Optional services
[[ "$CHOICES" =~ portainer  ]] && run_step "portainer"  "Portainer"          "05-portainer-setup.sh"
[[ "$CHOICES" =~ cloudflare ]] && run_step "cloudflare" "Cloudflare Tunnel"  "04-cloudflared-setup.sh"
[[ "$CHOICES" =~ monitoring ]] && run_step "monitoring" "Monitoring Stack"   "06-monitoring-setup.sh"
[[ "$CHOICES" =~ claude     ]] && run_step "claude"     "Claude CLI"         "07-claude-cli-setup.sh"
[[ "$CHOICES" =~ n8n|redis|surrealdb|minio|adminer|mailpit|wikijs ]] && \
  run_step "extras" "Extras (n8n/Redis/etc)" "08-extras-setup.sh"
[[ "$CHOICES" =~ ai         ]] && run_step "ai"         "AI Stack"           "16-ai-setup.sh"

# ── Done ────────────────────────────────────────────────────────────────────────
show_summary

TS_IP=$(tailscale ip -4 2>/dev/null || echo "not connected")

whiptail --msgbox "Installation complete!

Server Hub:  http://$SERVER_IP:8765
             http://$TS_IP:8765  (Tailscale)
Portainer:   https://$SERVER_IP:9443
Homepage:    http://$SERVER_IP:3000

Hub login:   admin / (your password)

AI entry points:
  Hub API:  http://$SERVER_IP:8765/api
  n8n:      http://$SERVER_IP:5678
  Redis:    $SERVER_IP:6379

To update hub:  cd ~/hub && bash update.sh
To update kit:  cd ~/server-kit && git pull && bash install.sh

Re-running install.sh is always safe — completed
steps are skipped automatically." \
  28 64 --title "Done! (3/3)" 3>&1 1>&2 2>&3 || true

echo ""
echo -e "${GRN}${BOLD}Done!${NC} Hub: http://$SERVER_IP:8765"
