#!/usr/bin/env bash
# verify-install.sh — run after server-kit setup to confirm everything works
# Usage: bash verify-install.sh

export PATH="$HOME/bin:/usr/local/bin:$PATH"
PASS=0; FAIL=0; WARN=0
GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"; RESET="\033[0m"; BOLD="\033[1m"

ok()   { echo -e "  ${GREEN}✓${RESET} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗${RESET} $1"; FAIL=$((FAIL+1)); }
warn() { echo -e "  ${YELLOW}~${RESET} $1"; WARN=$((WARN+1)); }
hdr()  { echo -e "\n${BOLD}$1${RESET}"; }

echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Server-Kit Install Verifier        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"

hdr "System"
if [ -f /etc/os-release ]; then
  . /etc/os-release; ok "OS: $PRETTY_NAME"
else
  fail "Cannot read OS release"
fi
command -v docker &>/dev/null && ok "Docker: $(docker --version | cut -d" " -f3 | tr -d ,)" || fail "Docker not installed"
docker info &>/dev/null && ok "Docker daemon running" || fail "Docker daemon not running"
command -v git &>/dev/null && ok "Git: $(git --version | cut -d" " -f3)" || warn "Git not installed"

hdr "CLI Tools"
for tool in health-check server-backup server-update sec dkps dklogs dkrestart dkstop dkstart server-menu; do
  command -v "$tool" &>/dev/null && ok "$tool" || fail "$tool missing"
done

hdr "Core Containers"
RUNNING=$(docker ps --format "{{.Names}}" 2>/dev/null || echo "")
for svc in npm portainer homepage uptime-kuma netdata dozzle ntfy; do
  echo "$RUNNING" | grep -q "^${svc}$" && ok "$svc running" || fail "$svc NOT running"
done

hdr "Extra Containers (optional)"
for svc in n8n redis surrealdb adminer mailpit wikijs watchtower; do
  echo "$RUNNING" | grep -q "^${svc}$" && ok "$svc running" || warn "$svc not running"
done

hdr "Port Checks"
check_port() {
  local port=$1 name=$2
  timeout 2 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null && ok "$name (:$port)" || fail "$name (:$port) not listening"
}
check_port 81    "NPM admin"
check_port 3000  "Homepage"
check_port 3001  "Uptime Kuma"
check_port 8090  "Dozzle"
check_port 19999 "Netdata"
check_port 5678  "n8n"
check_port 8082  "Adminer"
check_port 8025  "Mailpit"
check_port 3002  "Wiki.js"
check_port 6379  "Redis"
check_port 8001  "SurrealDB"
check_port 8765  "Hub API"

hdr "Security"
sudo -n ufw status 2>/dev/null | grep -q "Status: active" && ok "UFW active" || warn "UFW status unknown (needs sudo)"
systemctl is-active fail2ban &>/dev/null && ok "Fail2Ban active" || warn "Fail2Ban not running"

hdr "Hub"
systemctl --user is-active hub &>/dev/null && ok "hub.service running" || fail "hub.service not running"
if curl -s --max-time 3 http://localhost:8765/api/status | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  ok "Hub API responding"
else
  fail "Hub API not responding"
fi
[ -f "$HOME/db/server.db" ] && ok "Hub DB at ~/db/server.db" || fail "~/db/server.db missing"

hdr "Timers"
systemctl --user is-active hub-maintenance.timer &>/dev/null && ok "Maintenance timer active" || warn "hub-maintenance.timer not set up"

echo
echo -e "${BOLD}──────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}Passed: $PASS${RESET}  ${RED}Failed: $FAIL${RESET}  ${YELLOW}Warnings: $WARN${RESET}"
echo -e "${BOLD}──────────────────────────────────────────${RESET}"
[ "$FAIL" -eq 0 ] && echo -e "  ${GREEN}All critical checks passed ✓${RESET}" || echo -e "  ${RED}$FAIL critical issue(s) — see ✗ above${RESET}"
exit "$FAIL"
