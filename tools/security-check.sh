#!/bin/bash
# ============================================================
# SECURITY CHECK
# Overview of server security status
# ============================================================

echo ""
echo "=========================================="
echo "  SECURITY STATUS"
echo "=========================================="

# --- Firewall ---
echo ""
echo "  FIREWALL (UFW)"
echo "  ─────────────────────────────────────"
UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1)
echo "  Status: $UFW_STATUS"
OPEN_PORTS=$(sudo ufw status 2>/dev/null | grep "ALLOW" | wc -l)
echo "  Open ports: $OPEN_PORTS rules"

# --- Fail2Ban ---
echo ""
echo "  FAIL2BAN (Brute Force Protection)"
echo "  ─────────────────────────────────────"
if systemctl is-active fail2ban &>/dev/null; then
  echo "  Status: active"
  JAILS=$(sudo fail2ban-client status 2>/dev/null | grep "Jail list" | sed 's/.*://;s/,/ /g')
  for jail in $JAILS; do
    BANNED=$(sudo fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    TOTAL=$(sudo fail2ban-client status "$jail" 2>/dev/null | grep "Total banned" | awk '{print $NF}')
    printf "  %-15s Currently banned: %-4s  Total banned: %s\n" "$jail" "$BANNED" "$TOTAL"
  done
else
  echo "  Status: NOT RUNNING"
fi

# --- CrowdSec ---
echo ""
echo "  CROWDSEC (Intrusion Detection)"
echo "  ─────────────────────────────────────"
if command -v cscli &>/dev/null; then
  if systemctl is-active crowdsec &>/dev/null; then
    echo "  Status: active"
    DECISIONS=$(sudo cscli decisions list -o raw 2>/dev/null | tail -n +2 | wc -l)
    echo "  Active bans: $DECISIONS"
    ALERTS=$(sudo cscli alerts list -o raw 2>/dev/null | tail -n +2 | wc -l)
    echo "  Recent alerts: $ALERTS"
  else
    echo "  Status: installed but NOT RUNNING"
  fi
else
  echo "  Status: not installed"
fi

# --- SSH ---
echo ""
echo "  SSH SECURITY"
echo "  ─────────────────────────────────────"
ROOT_LOGIN=$(grep -E "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
echo "  Root login: ${ROOT_LOGIN:-"not set (defaults to yes — FIX THIS)"}"

PASS_AUTH=$(grep -E "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
echo "  Password auth: ${PASS_AUTH:-"not set (defaults to yes)"}"

FAILED_SSH=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
echo "  Failed login attempts (today's log): $FAILED_SSH"

LAST_LOGINS=$(last -5 2>/dev/null | head -5)
echo ""
echo "  Last 5 logins:"
echo "$LAST_LOGINS" | while read -r line; do
  [ -n "$line" ] && echo "    $line"
done

# --- Listening Ports ---
echo ""
echo "  OPEN PORTS (what's listening)"
echo "  ─────────────────────────────────────"
ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | rev | cut -d: -f1 | rev | sort -un | while read -r port; do
  PROC=$(ss -tlnp 2>/dev/null | grep ":${port} " | head -1 | grep -oP 'users:\(\("\K[^"]+' || echo "unknown")
  printf "  %-8s %s\n" ":$port" "$PROC"
done

# --- Active Connections ---
echo ""
echo "  ACTIVE CONNECTIONS (established)"
echo "  ─────────────────────────────────────"
CONN_COUNT=$(ss -tn state established 2>/dev/null | tail -n +2 | wc -l)
echo "  Total: $CONN_COUNT"

# Show unique remote IPs
ss -tn state established 2>/dev/null | tail -n +2 | awk '{print $5}' | rev | cut -d: -f2- | rev | sort | uniq -c | sort -rn | head -10 | while read -r count ip; do
  printf "    %4s connections from %s\n" "$count" "$ip"
done

# --- Automatic Updates ---
echo ""
echo "  AUTO UPDATES"
echo "  ─────────────────────────────────────"
if dpkg -l | grep -q unattended-upgrades 2>/dev/null; then
  echo "  Unattended upgrades: installed"
  LAST_UPDATE=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null)
  if [ -n "$LAST_UPDATE" ]; then
    LAST_DATE=$(date -d @"$LAST_UPDATE" "+%Y-%m-%d %H:%M")
    echo "  Last update check: $LAST_DATE"
  fi
else
  echo "  Unattended upgrades: NOT INSTALLED"
fi

PENDING=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
echo "  Pending updates: $PENDING packages"

SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
if [ "$SECURITY_UPDATES" -gt 0 ]; then
  echo "  !! SECURITY UPDATES AVAILABLE: $SECURITY_UPDATES"
fi

# --- Docker Security ---
echo ""
echo "  DOCKER SECURITY"
echo "  ─────────────────────────────────────"
# Containers running as root
ROOT_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | while read -r name; do
  USER=$(docker inspect --format '{{.Config.User}}' "$name" 2>/dev/null)
  if [ -z "$USER" ] || [ "$USER" = "root" ] || [ "$USER" = "0" ]; then
    echo "$name"
  fi
done)
ROOT_COUNT=$(echo "$ROOT_CONTAINERS" | grep -c . 2>/dev/null || echo 0)
echo "  Containers as root: $ROOT_COUNT"

# Containers with docker socket mounted
SOCKET_CONTAINERS=$(docker ps --format '{{.Names}} {{.Mounts}}' 2>/dev/null | grep "docker.sock" | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')
if [ -n "$SOCKET_CONTAINERS" ]; then
  echo "  Docker socket access: $SOCKET_CONTAINERS"
else
  echo "  Docker socket access: none"
fi

# --- Warnings ---
echo ""
echo "  WARNINGS"
echo "  ─────────────────────────────────────"
WARNINGS=0

if [ "$ROOT_LOGIN" != "no" ]; then
  echo "  !! SSH root login is enabled — disable it"
  ((WARNINGS++))
fi

if [ "$FAILED_SSH" -gt 100 ]; then
  echo "  !! $FAILED_SSH failed SSH attempts — check fail2ban"
  ((WARNINGS++))
fi

if [ "$SECURITY_UPDATES" -gt 0 ]; then
  echo "  !! $SECURITY_UPDATES security updates pending — run: sudo apt upgrade"
  ((WARNINGS++))
fi

if [ "$PENDING" -gt 20 ]; then
  echo "  !! $PENDING packages pending update"
  ((WARNINGS++))
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "  None — looking good."
fi

echo ""
echo "=========================================="
echo "  Quick commands:"
echo "    sudo lynis audit system    — full security audit"
echo "    sudo rkhunter --check      — rootkit scan"
echo "    sudo aide --check          — file integrity check"
echo "    trivy image IMAGE          — scan container for vulns"
echo "    sudo fail2ban-client status — ban status"
echo "    sudo cscli alerts list     — CrowdSec alerts"
echo "    iftop                      — live network traffic"
echo "    nethogs                    — per-process bandwidth"
echo "=========================================="
echo ""
