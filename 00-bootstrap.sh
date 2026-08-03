#!/usr/bin/env bash
# 00-bootstrap.sh — SSH hardening + Tailscale
# Run FIRST on a fresh server. Safe to re-run (idempotent — skips what's done).
# https://github.com/KGSHOPINV/server-kit
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${INSTALL_DIR}/.bootstrap.log"
: > "$LOG"

BLU='\033[0;34m'; GRN='\033[0;32m'; YLW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'
info()    { echo -e "${BLU}→${NC} $1" | tee -a "$LOG"; }
success() { echo -e "${GRN}✓${NC} $1" | tee -a "$LOG"; }
warn()    { echo -e "${YLW}⚠${NC}  $1" | tee -a "$LOG"; }
done_skip(){ echo -e "${GRN}✓${NC} $1 ${YLW}(already done — skipping)${NC}" | tee -a "$LOG"; }
fail()    { echo -e "${RED}✗${NC} $1" | tee -a "$LOG"; exit 1; }

command -v whiptail &>/dev/null || sudo apt-get install -y whiptail &>/dev/null

# ── Who are we? ────────────────────────────────────────────────────────────────
ADMIN_USER="${USER:-admin1}"
HOME_DIR=$(eval echo "~$ADMIN_USER")
SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# ── Screen: welcome ────────────────────────────────────────────────────────────
whiptail --msgbox "BOOTSTRAP — Step 0 of Install

This runs FIRST and locks in two things:

  1. SSH key authentication
     Your machine → this server, passwordless,
     hardened (no more password logins)

  2. Tailscale
     Connects this server to your tailnet so you
     can reach it from anywhere — phone, laptop,
     work PC — no port forwarding needed.

Both are idempotent: safe to re-run." \
  20 60 --title "Bootstrap: SSH + Tailscale" 3>&1 1>&2 2>&3 || exit 0

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 — SSH
# ══════════════════════════════════════════════════════════════════════════════

info "=== SSH SETUP ==="

# 1a. Generate server identity key (ed25519) if not present
if [[ -f "$HOME_DIR/.ssh/id_ed25519" ]]; then
  done_skip "Server SSH identity key exists"
else
  info "Generating server SSH key (ed25519)..."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  ssh-keygen -t ed25519 -f "$HOME_DIR/.ssh/id_ed25519" -N "" -C "$ADMIN_USER@$(hostname)" >> "$LOG" 2>&1
  success "Server key generated: $HOME_DIR/.ssh/id_ed25519.pub"
  SERVER_PUBKEY=$(cat "$HOME_DIR/.ssh/id_ed25519.pub")
  whiptail --msgbox "Server public key created:

$SERVER_PUBKEY

Add this to GitHub → Settings → SSH Keys
if you want the server to pull from private repos." \
    16 72 --title "Server Public Key" 3>&1 1>&2 2>&3 || true
fi

# 1b. Add your client machine's public key
mkdir -p "$SSH_DIR"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

CLIENT_KEY=$(whiptail --inputbox \
"Paste YOUR machine's public key to add to authorized_keys.
(Leave blank to skip — you'll keep using password login)

Get it from your machine with:
  cat ~/.ssh/id_ed25519.pub
  cat ~/.ssh/id_rsa.pub
  cat ~/.ssh/id_ed25519_server.pub" \
  16 72 "" --title "Add Client SSH Key (1/2)" 3>&1 1>&2 2>&3) || CLIENT_KEY=""

if [[ -n "$CLIENT_KEY" ]]; then
  # Check if already in authorized_keys
  if grep -qF "$CLIENT_KEY" "$AUTH_KEYS" 2>/dev/null; then
    done_skip "Client key already in authorized_keys"
  else
    echo "$CLIENT_KEY" >> "$AUTH_KEYS"
    success "Client key added to authorized_keys"
  fi
else
  warn "No client key added — keeping password auth for now"
fi

# 1c. Harden SSH config (only if client key was added)
SSH_CONFIG="/etc/ssh/sshd_config"
HARDENED_MARKER="# server-kit hardened"

if grep -q "$HARDENED_MARKER" "$SSH_CONFIG" 2>/dev/null; then
  done_skip "SSH config already hardened"
elif [[ -n "$CLIENT_KEY" ]]; then
  whiptail --yesno "SSH hardening:
  - Disable password authentication (key-only)
  - Keep root login disabled
  - Keep port 22

Only do this AFTER confirming your key works in a separate terminal.
Locking yourself out means console access only." \
    14 60 --title "SSH Hardening (2/2)" --yes-button "Harden" --no-button "Skip" \
    3>&1 1>&2 2>&3 && DO_HARDEN=yes || DO_HARDEN=no

  if [[ "$DO_HARDEN" == "yes" ]]; then
    info "Hardening SSH config..."
    sudo cp "$SSH_CONFIG" "${SSH_CONFIG}.bak.$(date +%Y%m%d)"
    sudo tee -a "$SSH_CONFIG" > /dev/null <<SSHCFG

$HARDENED_MARKER
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
AuthorizedKeysFile .ssh/authorized_keys
SSHCFG
    sudo systemctl reload ssh >> "$LOG" 2>&1
    success "SSH hardened — password auth disabled, key-only from now on"
  else
    warn "SSH hardening skipped"
  fi
else
  warn "SSH hardening skipped (no client key added)"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 — Tailscale
# ══════════════════════════════════════════════════════════════════════════════

info "=== TAILSCALE SETUP ==="

# Check if already installed and connected
if command -v tailscale &>/dev/null; then
  TS_STATUS=$(tailscale status 2>/dev/null | head -1 || echo "")
  if [[ "$TS_STATUS" =~ "fks-services" ]] || tailscale status &>/dev/null; then
    TS_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    done_skip "Tailscale already connected — IP: $TS_IP"
    TAILSCALE_DONE=yes
  else
    info "Tailscale installed but not connected"
    TAILSCALE_DONE=no
  fi
else
  TAILSCALE_DONE=no
fi

if [[ "$TAILSCALE_DONE" != "yes" ]]; then
  whiptail --yesno "Install and connect Tailscale?

Tailscale creates an encrypted mesh network between
all your devices. Once connected, you can reach this
server at its Tailscale IP from your phone, laptop,
or work PC — no port forwarding, no VPN config.

The installer will open a link — you paste it in
your browser to approve this machine in your tailnet." \
    18 62 --title "Tailscale" --yes-button "Install" --no-button "Skip" \
    3>&1 1>&2 2>&3 && DO_TS=yes || DO_TS=no

  if [[ "$DO_TS" == "yes" ]]; then
    # Check for optional auth key
    TS_AUTH_KEY=$(whiptail --inputbox \
"Optional: Tailscale auth key for automated connect.
Get one from: tailscale.com/admin/settings/keys

Leave blank to authenticate interactively (a link
will appear in the terminal for you to open)." \
      12 62 "" --title "Tailscale Auth Key (optional)" 3>&1 1>&2 2>&3) || TS_AUTH_KEY=""

    # Install
    if ! command -v tailscale &>/dev/null; then
      info "Installing Tailscale..."
      curl -fsSL https://tailscale.com/install.sh | sh >> "$LOG" 2>&1
      success "Tailscale installed"
    fi

    # Connect
    info "Starting Tailscale..."
    if [[ -n "$TS_AUTH_KEY" ]]; then
      sudo tailscale up --authkey="$TS_AUTH_KEY" --accept-routes >> "$LOG" 2>&1
      success "Tailscale connected via auth key"
    else
      clear
      echo ""
      echo -e "${BOLD}${BLU}  Tailscale — open this link in your browser:${NC}"
      echo ""
      sudo tailscale up --accept-routes 2>&1 | tee -a "$LOG" &
      TS_PID=$!
      sleep 8  # give it time to print the auth URL
      wait $TS_PID 2>/dev/null || true
    fi

    sleep 3
    TS_IP=$(tailscale ip -4 2>/dev/null || echo "not connected yet")
    if [[ "$TS_IP" != "not connected yet" ]]; then
      success "Tailscale connected — IP: $TS_IP"
      echo "TAILSCALE_IP=$TS_IP" >> "$INSTALL_DIR/.install-config" 2>/dev/null || true
    else
      warn "Tailscale may still be authenticating — run 'tailscale status' to check"
    fi
  else
    warn "Tailscale skipped"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo "?")
TS_IP=$(tailscale ip -4 2>/dev/null || echo "not connected")
KEY_COUNT=$(wc -l < "$AUTH_KEYS" 2>/dev/null || echo 0)

whiptail --msgbox "Bootstrap complete!

SSH
  Authorized keys: $KEY_COUNT
  Config: $( grep -q 'server-kit hardened' "$SSH_CONFIG" 2>/dev/null && echo 'hardened (key-only)' || echo 'standard (password still allowed)')
  Server key: $HOME_DIR/.ssh/id_ed25519.pub

Network
  Local IP:     $LOCAL_IP
  Tailscale IP: $TS_IP

AI Entry Points (after full install)
  Hub API:  http://$LOCAL_IP:8765/api
  Hub API:  http://$TS_IP:8765/api   (remote)
  n8n:      http://$LOCAL_IP:5678
  Redis:    $LOCAL_IP:6379

Next: run bash install.sh to set up the full stack" \
  26 62 --title "Bootstrap Done" 3>&1 1>&2 2>&3 || true

echo ""
echo -e "${GRN}${BOLD}Bootstrap done.${NC}"
echo "  Local:     $LOCAL_IP"
echo "  Tailscale: $TS_IP"
echo ""
echo "  Run: bash install.sh   (full stack + hub)"
