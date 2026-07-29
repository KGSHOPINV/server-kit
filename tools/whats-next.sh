#!/bin/bash
# ============================================================
# WHAT'S NEXT
# Context-aware guide — checks your server and tells you
# what still needs to be done
# ============================================================

echo ""
echo "=========================================="
echo "  WHAT'S NEXT"
echo "=========================================="

TASKS_TODO=0
TASKS_DONE=0

check() {
  local description="$1"
  local condition="$2"
  local how_to="$3"

  if eval "$condition" 2>/dev/null; then
    printf "  [DONE]  %s\n" "$description"
    ((TASKS_DONE++))
  else
    printf "  [TODO]  %s\n" "$description"
    printf "          → %s\n" "$how_to"
    echo ""
    ((TASKS_TODO++))
  fi
}

# ===========================================
echo ""
echo "  --- SETUP ---"
echo ""

check "Docker installed" \
  "command -v docker &>/dev/null" \
  "Run: sudo bash ~/server-kit/02-docker-install.sh"

check "Nginx Proxy Manager running" \
  "docker ps 2>/dev/null | grep -q npm" \
  "Run: sudo bash ~/server-kit/03-npm-setup.sh"

check "NPM default password changed" \
  "[ -f /srv/docker/npm/.password-changed ]" \
  "Open http://$(hostname -I | awk '{print $1}'):81 — login with admin@example.com / changeme — change it! Then run: touch /srv/docker/npm/.password-changed"

check "Portainer running" \
  "docker ps 2>/dev/null | grep -q portainer" \
  "Run: sudo bash ~/server-kit/05-portainer-setup.sh"

check "Portainer admin created" \
  "[ -f /srv/docker/portainer/.admin-created ]" \
  "Open https://$(hostname -I | awk '{print $1}'):9443 — create admin account. Then run: touch /srv/docker/portainer/.admin-created"

check "Uptime Kuma running" \
  "docker ps 2>/dev/null | grep -q uptime-kuma" \
  "Run: sudo bash ~/server-kit/06-monitoring-setup.sh"

check "Netdata running" \
  "docker ps 2>/dev/null | grep -q netdata" \
  "Run: sudo bash ~/server-kit/06-monitoring-setup.sh"

check "Homepage running" \
  "docker ps 2>/dev/null | grep -q homepage" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh"

check "Dozzle running" \
  "docker ps 2>/dev/null | grep -q dozzle" \
  "Run: cd /srv/docker/dozzle && sudo docker compose up -d"

# ===========================================
echo ""
echo "  --- NETWORKING ---"
echo ""

check "Server has static IP (or DHCP reservation)" \
  "[ -f /srv/docker/.static-ip-confirmed ]" \
  "Set a static IP in your router (DHCP reservation) or on the server. Then run: touch /srv/docker/.static-ip-confirmed"

check "Cloudflare tunnel running" \
  "docker ps 2>/dev/null | grep -q cloudflared" \
  "Get a tunnel token from https://one.dash.cloudflare.com → Tunnels → Create. Then: sudo bash ~/server-kit/04-cloudflared-setup.sh"

check "Domain connected to Cloudflare" \
  "[ -f /srv/docker/.domain-configured ]" \
  "Add your domain to Cloudflare, point nameservers. Then run: touch /srv/docker/.domain-configured"

check "NPM proxy hosts configured" \
  "[ -f /srv/docker/npm/.proxy-configured ]" \
  "Open NPM admin (:81) → Proxy Hosts → add routes for your services. Then run: touch /srv/docker/npm/.proxy-configured"

# ===========================================
echo ""
echo "  --- SECURITY ---"
echo ""

check "Firewall active" \
  "sudo ufw status 2>/dev/null | grep -q 'Status: active'" \
  "Run: sudo ufw enable"

check "Fail2Ban running" \
  "systemctl is-active fail2ban &>/dev/null" \
  "Run: sudo systemctl start fail2ban"

check "SSH root login disabled" \
  "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config 2>/dev/null" \
  "Edit /etc/ssh/sshd_config → set PermitRootLogin no → sudo systemctl restart sshd"

check "SSH key auth setup (optional but recommended)" \
  "[ -f ~/.ssh/authorized_keys ] && [ -s ~/.ssh/authorized_keys ]" \
  "On your PC: ssh-keygen → ssh-copy-id user@server-ip. Then disable password auth in sshd_config"

check "Cloudflare Access on admin services" \
  "[ -f /srv/docker/.cf-access-configured ]" \
  "In Cloudflare Zero Trust → Access → add applications for Portainer, NPM, Netdata, etc. Then run: touch /srv/docker/.cf-access-configured"

check "Auto security updates enabled" \
  "dpkg -l 2>/dev/null | grep -q unattended-upgrades" \
  "Run: sudo apt install -y unattended-upgrades"

# ===========================================
echo ""
echo "  --- BACKUPS ---"
echo ""

check "Backup system installed" \
  "command -v server-backup &>/dev/null" \
  "Run: sudo bash ~/server-kit/09-backup-setup.sh"

check "Backup cron job active" \
  "crontab -l 2>/dev/null | grep -q server-backup" \
  "Run: (crontab -l; echo '0 3 * * * /usr/local/bin/server-backup') | crontab -"

check "First backup completed" \
  "[ -d /srv/backups ] && [ \$(ls /srv/backups/ 2>/dev/null | wc -l) -gt 0 ]" \
  "Run: server-backup"

check "Offsite backup configured (optional)" \
  "command -v rclone &>/dev/null && rclone listremotes 2>/dev/null | grep -q ." \
  "Install rclone: curl https://rclone.org/install.sh | sudo bash — then: rclone config"

# ===========================================
echo ""
echo "  --- TOOLS ---"
echo ""

check "Claude CLI installed" \
  "command -v claude &>/dev/null" \
  "Run: sudo bash ~/server-kit/07-claude-cli-setup.sh"

check "GitHub CLI installed" \
  "command -v gh &>/dev/null" \
  "Run: sudo bash ~/server-kit/13-github-deploy-setup.sh"

check "GitHub CLI authenticated" \
  "gh auth status &>/dev/null 2>&1" \
  "Run: gh auth login"

# ===========================================
echo ""
echo "  --- OPTIONAL SERVICES ---"
echo ""

check "Redis" \
  "docker ps 2>/dev/null | grep -q redis" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to Redis)"

check "Supabase" \
  "docker ps 2>/dev/null | grep -q supabase" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to Supabase)"

check "n8n" \
  "docker ps 2>/dev/null | grep -q n8n" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to n8n)"

check "SurrealDB" \
  "docker ps 2>/dev/null | grep -q surrealdb" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to SurrealDB)"

check "MinIO" \
  "docker ps 2>/dev/null | grep -q minio" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to MinIO)"

check "Wiki.js" \
  "docker ps 2>/dev/null | grep -q wikijs" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to Wiki.js)"

check "Grafana" \
  "docker ps 2>/dev/null | grep -q grafana" \
  "Run: sudo bash ~/server-kit/08-extras-setup.sh (say y to Grafana)"

# ===========================================
echo ""
echo "=========================================="
TOTAL=$((TASKS_DONE + TASKS_TODO))
echo "  $TASKS_DONE done / $TASKS_TODO remaining / $TOTAL total"
echo ""

if [ "$TASKS_TODO" -eq 0 ]; then
  echo "  Everything is set up. You're good."
elif [ "$TASKS_TODO" -le 5 ]; then
  echo "  Almost there — just a few things left."
elif [ "$TASKS_TODO" -le 15 ]; then
  echo "  Good progress. Work through the TODOs above."
else
  echo "  Fresh install — start from the top with: bash run-all.sh"
fi
echo "=========================================="
echo ""
