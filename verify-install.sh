#!/usr/bin/env bash
# verify-install.sh — run after server-kit setup to confirm everything is working
# Usage: bash verify-install.sh
# Returns exit 0 if all checks pass, 1 if any fail.

set -euo pipefail
PASS=0; FAIL=0
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; RESET='\033[0m'; BOLD='\033[1m'

ok()   { echo -e "  ✓ $1"; ((PASS++)); }
fail() { echo -e "  ✗ $1"; ((FAIL++)); }
warn() { echo -e "  ~ $1"; }
hdr()  { echo -e "\n$1"; }

echo -e "╔══════════════════════════════════════╗"
echo -e "║   Server-Kit Install Verifier        ║"
echo -e "╚══════════════════════════════════════╝"

# ── SYSTEM ────────────────────────────────────────────────────────────────────
hdr "System"
[ -f /etc/os-release ] && . /etc/os-release && ok "OS: $PRETTY_NAME" || fail "Cannot read OS release"
command -v docker &>/dev/null && ok "Docker installed: $(docker --version | cut -d' ' -f3 | tr -d ,)" || fail "Docker not installed"
docker info &>/dev/null && ok "Docker daemon running" || fail "Docker daemon not running"
command -v git &>/dev/null && ok "Git: $(git --version | cut -d' ' -f3)" || fail "Git not installed"

# ── CLI TOOLS ─────────────────────────────────────────────────────────────────
hdr "CLI Tools"
for tool in health-check server-backup server-update sec ai-models dkps dklogs dkrestart dkstop dkstart server-menu; do
  command -v "$tool" &>/dev/null && ok "$tool" || fail "$tool missing from /usr/local/bin"
done

# ── CONTAINERS RUNNING ────────────────────────────────────────────────────────
hdr "Core Containers"
RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null)
for svc in npm portainer homepage uptime-kuma netdata dozzle ntfy; do
  echo "$RUNNING" | grep -q "^$svc$" && ok "$svc running" || fail "$svc not running"
done

hdr "Tool Containers"
for svc in n8n redis surrealdb adminer mailpit wikijs watchtower; do
  echo "$RUNNING" | grep -q "^$svc$" && ok "$svc running" || warn "$svc not running (optional or extra)"
done

# ── PORTS REACHABLE ───────────────────────────────────────────────────────────
hdr "Port Checks (localhost)"
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

# ── FIREWALL ──────────────────────────────────────────────────────────────────
hdr "Security"
sudo ufw status 2>/dev/null | grep -q 'Status: active' && ok "UFW active" || fail "UFW not active"
systemctl is-active fail2ban &>/dev/null && ok "Fail2Ban active" || warn "Fail2Ban not running"
systemctl is-active unattended-upgrades &>/dev/null && ok "Unattended upgrades active" || warn "Unattended upgrades not active"

# ── HUB SERVICE ───────────────────────────────────────────────────────────────
hdr "Hub"
systemctl --user is-active hub &>/dev/null && ok "hub.service active" || fail "hub.service not running"
curl -s --max-time 3 http://localhost:8765/api/status | python3 -c 'import sys,json; d=json.load(sys.stdin); print()' 2>/dev/null && ok "Hub API responding" || fail "Hub API not responding"

# ── SYSTEMD TIMERS ────────────────────────────────────────────────────────────
hdr "Timers"
systemctl --user is-active hub-maintenance.timer &>/dev/null && ok "Maintenance timer active" || warn "hub-maintenance.timer not set up"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo
echo -e "──────────────────────────────────────────"
echo -e "  Results:  ${PASS} passed  ${FAIL} failed"
echo -e "──────────────────────────────────────────"
[ "$FAIL" -eq 0 ] && echo -e "  All checks passed ✓" || echo -e "  Fix the items marked ✗ above"
exit "$FAIL"
