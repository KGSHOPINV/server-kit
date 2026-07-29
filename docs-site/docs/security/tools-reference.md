---
sidebar_position: 2
title: Security Tools
---

# Security Tools Reference

Every security tool on your server — what it does and how to use it.

---

## Fail2Ban — Auto-Ban Attackers

Watches log files. After X failed attempts → bans the IP via firewall.

| Jail | Max Retries | Ban Time | Watches |
|------|-------------|----------|---------|
| sshd | 3 | 24 hours | SSH login failures |
| sshd-ddos | 6 | 48 hours | SSH connection floods |
| recidive | 3 bans | 1 week | Repeat offenders |

```bash
# Status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Unban an IP (if you locked yourself out)
sudo fail2ban-client set sshd unbanip YOUR_IP

# Ban an IP manually
sudo fail2ban-client set sshd banip ATTACKER_IP

# Check log
sudo tail -50 /var/log/fail2ban.log
```

---

## CrowdSec — Community Threat Intelligence

Like Fail2Ban but smarter — blocks known attackers **before** they try you.

```bash
# See current bans
sudo cscli decisions list

# See recent alerts
sudo cscli alerts list

# See metrics
sudo cscli metrics

# Manual ban
sudo cscli decisions add --ip ATTACKER_IP --duration 24h --reason "suspicious"

# Remove a ban
sudo cscli decisions delete --ip ATTACKER_IP

# Update threat data
sudo cscli hub update && sudo cscli hub upgrade
```

---

## UFW Firewall

```bash
# Check status
sudo ufw status verbose

# Add a rule
sudo ufw allow 8888/tcp

# Remove a rule
sudo ufw delete allow 8888/tcp

# Block a specific IP
sudo ufw deny from ATTACKER_IP

# Allow only from your LAN
sudo ufw allow from 192.168.1.0/24 to any port 9443
```

---

## Lynis — System Security Audit

Full scan of your Linux system. Gives a hardening score (0-100) with specific recommendations.

```bash
sudo lynis audit system
```

---

## rkhunter — Rootkit Detection

Scans for known rootkits, backdoors, and suspicious files.

```bash
sudo rkhunter --check
sudo rkhunter --update      # update signatures
```

---

## AIDE — File Integrity Monitoring

Detects unauthorized changes to system files.

```bash
# Check for changes
sudo aide --check

# After legitimate updates, rebuild baseline
sudo aide --update
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

:::info AIDE scan is slow on large disks
First scan builds a baseline of every file. On a 1TB+ system, this takes 10-20 minutes. That's normal.
:::

---

## Trivy — Container Vulnerability Scanner

Scans Docker images for known CVEs.

```bash
# Scan an image
trivy image nginx:latest

# Only high/critical
trivy image --severity HIGH,CRITICAL nginx:latest

# Scan all running containers
docker ps --format '{{.Image}}' | sort -u | while read img; do
  echo "=== $img ==="
  trivy image --severity HIGH,CRITICAL "$img" 2>/dev/null
done
```

---

## Docker Bench — Docker Security Audit

```bash
cd /srv/docker/docker-bench/docker-bench-security
sudo sh docker-bench-security.sh
```

Gives a scorecard with pass/warn/fail for Docker security configuration.

---

## auditd — System Audit Logging

Logs security-relevant events: SSH changes, user mods, sudo usage, Docker socket access.

```bash
# Search audit logs
sudo ausearch -k ssh_config
sudo ausearch -k user_changes
sudo ausearch -k docker_socket

# Recent events
sudo ausearch --start recent

# Summary report
sudo aureport
```

---

## Network Monitoring

```bash
# Live bandwidth per connection
sudo iftop

# Bandwidth per process
sudo nethogs

# Scan yourself
nmap localhost
sudo nmap -sV localhost

# Current connections
ss -tlnp                    # listening ports
ss -tn state established    # active connections

# Count connections per IP
ss -tn state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
```
