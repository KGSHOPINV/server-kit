#!/bin/bash
# ============================================================
# 14 - TERMINAL SETUP
# Nice prompt, tmux dashboard, motd, essentials
# ============================================================

set -e

echo "========================================"
echo "  14 - TERMINAL SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

# --- Install terminal tools ---
echo ""
echo "Installing terminal tools..."
sudo apt install -y tmux neofetch figlet

# --- Custom bash prompt ---
echo ""
echo "Setting up custom prompt..."

PROMPT_BLOCK='
# === SERVER KIT PROMPT ===
parse_git_branch() {
  git branch 2>/dev/null | grep "^*" | sed "s/* / /"
}

CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)

# Colors
C_GREEN="\[\033[0;32m\]"
C_BLUE="\[\033[0;34m\]"
C_CYAN="\[\033[0;36m\]"
C_YELLOW="\[\033[0;33m\]"
C_RED="\[\033[0;31m\]"
C_PURPLE="\[\033[0;35m\]"
C_RESET="\[\033[0m\]"

PS1="${C_GREEN}\u${C_RESET}@${C_CYAN}\h${C_RESET}:${C_BLUE}\w${C_YELLOW}\$(parse_git_branch)${C_RESET}\n${C_PURPLE}[kit]${C_RESET} \$ "
# === END SERVER KIT PROMPT ==='

if ! grep -q "SERVER KIT PROMPT" "$REAL_HOME/.bashrc" 2>/dev/null; then
  echo "$PROMPT_BLOCK" >> "$REAL_HOME/.bashrc"
  echo "Custom prompt added."
else
  echo "Custom prompt already set."
fi

# --- MOTD (Message of the Day) ---
echo ""
echo "Setting up login banner..."

sudo tee /etc/update-motd.d/99-server-kit > /dev/null << 'MOTDEOF'
#!/bin/bash
# Server Kit MOTD

IP=$(hostname -I | awk '{print $1}')
CONTAINERS=$(docker ps -q 2>/dev/null | wc -l || echo 0)
MEM=$(free -h | awk '/Mem:/ {printf "%s / %s", $3, $2}')
DISK=$(df -h / | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')
UP=$(uptime -p)

echo ""
echo "  =================================================="
echo "    $(hostname) — Server Kit"
echo "  =================================================="
echo ""
echo "    IP:          $IP"
echo "    Uptime:      $UP"
echo "    Memory:      $MEM"
echo "    Disk:        $DISK"
echo "    Containers:  $CONTAINERS running"
echo ""
echo "    Commands:  menu | health | sec | hw | ports"
echo "               howdo | cheat | whats-next"
echo ""
echo "  =================================================="
echo ""
MOTDEOF

sudo chmod +x /etc/update-motd.d/99-server-kit

# Disable default Ubuntu motd noise
sudo chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/88-esm-announce 2>/dev/null || true

# --- Tmux dashboard config ---
echo ""
echo "Setting up tmux dashboard..."

cat > "$REAL_HOME/.tmux.conf" << 'TMUXEOF'
# === SERVER KIT TMUX CONFIG ===

# Better prefix key
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Mouse support
set -g mouse on

# Start window numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Status bar
set -g status-style 'bg=#1a1a2e fg=#e0e0e0'
set -g status-left '#[bg=#0f3460 fg=#e0e0e0] #H '
set -g status-right '#[bg=#0f3460 fg=#e0e0e0] %H:%M | #(docker ps -q 2>/dev/null | wc -l) containers | #(free -h | awk "/Mem:/ {print \\$3}") RAM '
set -g status-right-length 60
set -g status-left-length 20

# Pane borders
set -g pane-border-style 'fg=#333333'
set -g pane-active-border-style 'fg=#0f3460'

# Easy pane splitting
bind | split-window -h
bind - split-window -v

# Easy pane switching
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded"

# History
set -g history-limit 10000

# === END SERVER KIT TMUX ===
TMUXEOF

chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.tmux.conf"

# --- Tmux dashboard launcher ---
sudo tee /usr/local/bin/dashboard > /dev/null << 'DASHEOF'
#!/bin/bash
# Server Kit Dashboard — tmux layout

SESSION="dashboard"

# Kill existing session
tmux kill-session -t $SESSION 2>/dev/null

# Create session with main pane
tmux new-session -d -s $SESSION -n "main"

# Top left: docker stats
tmux send-keys "watch -n5 'docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\"'" C-m

# Split right: system monitor
tmux split-window -h
tmux send-keys "htop" C-m

# Split bottom right: logs
tmux split-window -v
tmux send-keys "echo 'Container logs — pick one:'; echo ''; docker ps --format '{{.Names}}'; echo ''; echo 'Run: docker logs -f CONTAINERNAME'" C-m

# Split bottom left: general terminal
tmux select-pane -t 0
tmux split-window -v
tmux send-keys "echo ''; echo '  Server Kit — type menu for command center'; echo ''" C-m

# Select the terminal pane
tmux select-pane -t 2

# Attach
tmux attach-session -t $SESSION
DASHEOF

sudo chmod +x /usr/local/bin/dashboard

# --- Add alias ---
if ! grep -q "alias dash=" "$REAL_HOME/.bashrc" 2>/dev/null; then
  echo 'alias dash="dashboard"' >> "$REAL_HOME/.bashrc"
fi

echo ""
echo "========================================"
echo "  14 - TERMINAL SETUP COMPLETE"
echo ""
echo "  What changed:"
echo "    - Custom colored prompt"
echo "    - Login banner shows server status"
echo "    - tmux dashboard: type 'dash'"
echo "    - Ctrl+A is tmux prefix (not Ctrl+B)"
echo ""
echo "  Tmux basics:"
echo "    dash              — launch dashboard"
echo "    Ctrl+A |          — split vertical"
echo "    Ctrl+A -          — split horizontal"
echo "    Ctrl+A arrow      — switch panes"
echo "    Ctrl+A d          — detach (keeps running)"
echo "    tmux attach       — reattach"
echo "========================================"
