# Server Security — Full Guide

Everything about protecting your server from attacks, monitoring threats, and responding to incidents.

---

## Table of Contents

1. [Your Defense Layers](#your-defense-layers)
2. [What Attacks Look Like](#what-attacks-look-like)
3. [Fail2Ban — Auto-Banning Attackers](#fail2ban)
4. [CrowdSec — Community Threat Intelligence](#crowdsec)
5. [Firewall (UFW)](#firewall-ufw)
6. [SSH Security](#ssh-security)
7. [Docker Security](#docker-security)
8. [Vulnerability Scanning](#vulnerability-scanning)
9. [File Integrity Monitoring](#file-integrity-monitoring)
10. [Network Monitoring](#network-monitoring)
11. [Audit Logging](#audit-logging)
12. [Automatic Updates](#automatic-updates)
13. [Cloudflare Security](#cloudflare-security)
14. [Incident Response](#incident-response)
15. [Security Checklist](#security-checklist)
16. [Common Attack Types & Defenses](#common-attack-types--defenses)

---

## Your Defense Layers

```
INTERNET
  |
  v
[Cloudflare] ── DDoS protection, WAF, bot blocking, Access login
  |
  v
[Tunnel] ── encrypted, no open ports to the internet
  |
  v
[UFW Firewall] ── blocks unexpected traffic
  |
  v
[Fail2Ban + CrowdSec] ── bans attackers automatically
  |
  v
[Docker Network Isolation] ── containers can't reach what they shouldn't
  |
  v
[App-level Auth] ── each service has its own login
```

An attacker has to get through ALL of these layers. Each one stops different types of attacks.

---

## What Attacks Look Like

### Brute Force (most common)
Someone tries thousands of passwords on your SSH or web login.
```
# What it looks like in /var/log/auth.log:
Failed password for root from 185.234.xxx.xxx port 45672 ssh2
Failed password for root from 185.234.xxx.xxx port 45673 ssh2
Failed password for admin from 185.234.xxx.xxx port 45674 ssh2
# ... hundreds of these per minute
```
**Defense:** Fail2Ban bans them after 3 attempts. CrowdSec knows their IP from community data.

### Port Scanning
Someone scans your server to find what's running.
```
# What it looks like:
Rapid connection attempts on ports 21, 22, 23, 80, 443, 3306, 5432...
```
**Defense:** Cloudflare tunnel means there are no open ports to scan. UFW blocks everything not explicitly allowed.

### DDoS (Distributed Denial of Service)
Flood your server with traffic to take it offline.
**Defense:** Cloudflare absorbs the traffic before it reaches your server. Your server IP is hidden.

### Vulnerability Exploitation
Attacker finds a known bug in software you're running and exploits it.
**Defense:** Automatic security updates. Trivy scans containers for known vulnerabilities. Keep everything updated.

### Container Escape
Attacker breaks out of a Docker container to access the host.
**Defense:** Don't run containers as root. Don't mount Docker socket unless necessary. Use read-only mounts where possible.

---

## Fail2Ban

Auto-bans IPs that fail authentication too many times.

### How It Works
1. Watches log files for failed login attempts
2. After X failures in Y time → bans the IP via UFW
3. Ban lasts for configured duration
4. Repeat offenders get longer bans

### Current Configuration (set in 12-security-setup.sh)
| Jail | Max Retries | Ban Time | What It Watches |
|------|-------------|----------|-----------------|
| sshd | 3 | 24 hours | SSH login failures |
| sshd-ddos | 6 | 48 hours | SSH connection floods |
| recidive | 3 bans | 1 week | IPs that keep getting banned |

### Commands
```bash
# See all jails and their status
sudo fail2ban-client status

# See banned IPs for SSH
sudo fail2ban-client status sshd

# Unban an IP (if you locked yourself out)
sudo fail2ban-client set sshd unbanip 192.168.1.100

# Ban an IP manually
sudo fail2ban-client set sshd banip 185.234.xxx.xxx

# Check fail2ban log
sudo tail -50 /var/log/fail2ban.log
```

### Adding Jails for Other Services
If you expose other services, add jails for them. Example for NPM:
```ini
# /etc/fail2ban/jail.local
[npm-auth]
enabled  = true
logpath  = /srv/docker/npm/data/logs/fallback_access.log
maxretry = 5
bantime  = 1h
```

---

## CrowdSec

Modern intrusion detection powered by community threat data.

### How It Works
1. Analyzes your server logs for attack patterns
2. Compares against a community database of known attacker IPs
3. Proactively blocks IPs that have attacked OTHER servers
4. Shares your attack data back to help the community

### Why It's Better Than Fail2Ban Alone
- Fail2Ban: reactive — waits for attacks on YOUR server
- CrowdSec: proactive — blocks known attackers BEFORE they try you

### Commands
```bash
# See current decisions (bans)
sudo cscli decisions list

# See recent alerts
sudo cscli alerts list

# See metrics
sudo cscli metrics

# Add a manual ban
sudo cscli decisions add --ip 185.234.xxx.xxx --duration 24h --reason "suspicious"

# Remove a ban
sudo cscli decisions delete --ip 185.234.xxx.xxx

# Update threat intelligence
sudo cscli hub update
sudo cscli hub upgrade
```

### CrowdSec Console (optional)
1. Go to https://app.crowdsec.net
2. Create account
3. Enroll your server: `sudo cscli console enroll YOUR_KEY`
4. See all your servers' security status in one dashboard

---

## Firewall (UFW)

### Current Rules
The setup script opens only the ports your services need. Everything else is blocked.

### Commands
```bash
# Check status
sudo ufw status verbose

# See numbered rules (for deletion)
sudo ufw status numbered

# Add a rule
sudo ufw allow 8888/tcp

# Remove a rule
sudo ufw delete allow 8888/tcp

# Block a specific IP
sudo ufw deny from 185.234.xxx.xxx

# Allow only from your network
sudo ufw allow from 192.168.1.0/24 to any port 9443

# Reset everything (careful!)
sudo ufw reset
```

### Best Practices
- Only open ports for services you're actually running
- For admin services, consider allowing only your local network
- With Cloudflare tunnel, you technically only need port 22 (SSH) open for direct access
- Everything else goes through the tunnel

---

## SSH Security

### Current Hardening
- Root login: disabled
- Fail2Ban: 3 failures = 24hr ban
- Optional: password auth disabled (key-only)

### Switch to Key-Only Auth (recommended)
```bash
# On your LOCAL machine, generate a key
ssh-keygen -t ed25519

# Copy it to the server
ssh-copy-id user@server-ip

# Test that key login works
ssh user@server-ip

# Then disable password auth on the server
sudo nano /etc/ssh/sshd_config
# Change: PasswordAuthentication no
sudo systemctl restart sshd
```

Now ONLY your key can log in. No password = nothing to brute force.

### Change SSH Port (optional extra layer)
```bash
sudo nano /etc/ssh/sshd_config
# Change: Port 2222

sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
sudo systemctl restart sshd

# Connect with: ssh -p 2222 user@server-ip
```

---

## Docker Security

### Container Isolation
Each container is isolated — it can only access what you explicitly give it.

### Risk: Docker Socket
Containers with `/var/run/docker.sock` mounted can control ALL other containers. Only give this to trusted management tools:
- Portainer (needs it to manage containers)
- Dozzle (needs it to read logs)
- Watchtower (needs it to update containers)
- Netdata (needs it for container metrics)

**Never give docker socket access to application containers.**

### Scan Images for Vulnerabilities
```bash
# Scan a specific image
trivy image nginx:latest

# Scan all running containers
docker ps --format '{{.Image}}' | sort -u | while read img; do
  echo "=== $img ==="
  trivy image --severity HIGH,CRITICAL "$img" 2>/dev/null
done

# Scan before deploying
trivy image myapp:latest
```

### Docker Bench Security Audit
```bash
cd /srv/docker/docker-bench/docker-bench-security
sudo sh docker-bench-security.sh
```
Gives you a scorecard of your Docker security configuration with specific recommendations.

### Best Practices
- Use specific image tags (nginx:1.25) not :latest
- Don't run containers as root when possible
- Use read-only mounts where possible (`:ro`)
- Don't expose ports you don't need
- Keep images updated (Watchtower helps)
- Use Docker networks to isolate groups of containers

---

## Vulnerability Scanning

### System Level — Lynis
Full security audit of your Linux system.
```bash
sudo lynis audit system

# Generates a report with:
# - Hardening score (0-100)
# - Specific warnings
# - Suggestions for improvement
# - Compliance checks

# View the report
sudo cat /var/log/lynis-report.dat
```

### Rootkit Detection — rkhunter
Scans for known rootkits, backdoors, and suspicious files.
```bash
sudo rkhunter --check

# Update signatures
sudo rkhunter --update

# Results in /var/log/rkhunter.log
```

### Container Level — Trivy
Scans Docker images for known CVEs (vulnerabilities).
```bash
# Quick scan
trivy image nginx:latest

# Only show high/critical
trivy image --severity HIGH,CRITICAL nginx:latest

# Scan filesystem
trivy fs /srv/docker/

# Output as JSON
trivy image -f json -o results.json nginx:latest
```

---

## File Integrity Monitoring

### AIDE (Advanced Intrusion Detection Environment)
Watches for unauthorized changes to system files.

```bash
# Check for changes
sudo aide --check

# If it reports changes, review them
# Legitimate changes (after updates): update the database
sudo aide --update
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Set up daily check
# Add to crontab:
0 5 * * * /usr/bin/aide --check | mail -s "AIDE Report" you@email.com
```

### What It Detects
- Modified system binaries (someone replaced /usr/bin/ssh)
- Changed config files (someone edited /etc/passwd)
- New files in system directories
- Permission changes on sensitive files

---

## Network Monitoring

### iftop — Live Network Traffic
```bash
sudo iftop
# Shows real-time bandwidth usage per connection
# See who's talking to your server and how much data
```

### nethogs — Per-Process Bandwidth
```bash
sudo nethogs
# Shows bandwidth usage PER PROCESS
# Find out which container is eating your bandwidth
```

### nmap — Port Scan Yourself
```bash
# Scan your own server from the server
nmap localhost

# Full scan with service detection
sudo nmap -sV localhost

# Scan from another machine to see what's exposed
nmap your-server-ip
```

### ss — Current Connections
```bash
# All listening ports
ss -tlnp

# All established connections
ss -tn state established

# Count connections per remote IP
ss -tn state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
```

---

## Audit Logging

The auditd system logs security-relevant events.

### What's Being Logged
- SSH config changes
- User/password/group modifications
- Sudo usage
- Docker socket access
- Crontab changes
- Firewall changes

### Commands
```bash
# Search audit logs
sudo ausearch -k ssh_config          # SSH config changes
sudo ausearch -k user_changes        # User modifications
sudo ausearch -k docker_socket       # Docker socket access
sudo ausearch -k password_changes    # Password changes

# Recent events
sudo ausearch --start recent

# Generate audit report
sudo aureport

# Failed login report
sudo aureport --auth --failed
```

---

## Automatic Updates

### What's Configured
- Security updates install automatically (daily check)
- Package lists refresh daily
- Old packages cleaned weekly

### Check Status
```bash
# See if auto-updates are enabled
cat /etc/apt/apt.conf.d/20auto-upgrades

# See update log
cat /var/log/unattended-upgrades/unattended-upgrades.log

# See what would be upgraded
apt list --upgradable

# Manual update
sudo apt update && sudo apt upgrade -y
```

---

## Cloudflare Security

See CLOUDFLARE-FULL-GUIDE.md for complete details. Key security features:

### Already Active (with tunnel)
- Server IP hidden
- No open ports needed
- DDoS protection
- SSL/TLS encryption

### Enable These
- **WAF:** Security → WAF → Enable managed rules
- **Bot Fight Mode:** Security → Bots → ON
- **Browser Integrity Check:** Security → Settings → ON
- **Cloudflare Access:** Login wall for admin services

### WAF Custom Rules (recommended)
```
Block wp-admin, .env, phpinfo paths
Rate limit /login and /auth endpoints
Block countries you don't expect traffic from
```

---

## Incident Response

### "I Think I've Been Compromised"

#### Step 1 — Isolate
```bash
# Kill the tunnel (takes server offline immediately)
cd /srv/docker/cloudflared && docker compose down

# Or disable networking entirely
sudo ufw default deny incoming
sudo ufw default deny outgoing
```

#### Step 2 — Investigate
```bash
# Check who's logged in
who
w
last -20

# Check for suspicious processes
ps aux | grep -v "^\[" | sort -k3 -rn | head -20

# Check for recently modified files
find / -mmin -60 -type f 2>/dev/null | grep -v proc | grep -v sys

# Check auth log
sudo tail -200 /var/log/auth.log

# Check audit log
sudo ausearch --start recent

# Check for rootkits
sudo rkhunter --check

# Check file integrity
sudo aide --check

# Check for unauthorized containers
docker ps -a
```

#### Step 3 — Contain
```bash
# Change all passwords
passwd
sudo passwd root

# Rotate SSH keys
rm ~/.ssh/authorized_keys
# Add your new key

# Rotate Cloudflare tunnel token
# Create new tunnel in Cloudflare, delete old one

# Rotate all service passwords (Portainer, NPM, databases)
```

#### Step 4 — Clean
```bash
# If you have backups — restore from last known good backup
# If not — rebuild (fresh install + server-kit)
```

#### Step 5 — Harden
- Figure out HOW they got in
- Fix that specific vulnerability
- Run `sudo lynis audit system` for more recommendations

### "Someone Is Attacking Right Now"

```bash
# See who's connecting
ss -tn state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head

# Ban an IP immediately
sudo ufw deny from ATTACKER_IP

# Or with fail2ban
sudo fail2ban-client set sshd banip ATTACKER_IP

# Or with CrowdSec
sudo cscli decisions add --ip ATTACKER_IP --duration 720h --reason "active attack"

# Nuclear option — take everything offline
cd /srv/docker/cloudflared && docker compose down
```

---

## Security Checklist

### Initial Setup (do once)
- [ ] Run 12-security-setup.sh
- [ ] SSH root login disabled
- [ ] Fail2Ban active
- [ ] CrowdSec installed and enrolled
- [ ] Automatic security updates enabled
- [ ] Firewall configured (UFW)
- [ ] Cloudflare tunnel (no open ports)
- [ ] Cloudflare Access on all admin services
- [ ] Strong passwords on all services
- [ ] SSH key auth (disable password auth)

### Weekly
- [ ] Run `sec` (security check)
- [ ] Run `health` (service check)
- [ ] Check fail2ban bans: `sudo fail2ban-client status sshd`
- [ ] Check pending updates: `apt list --upgradable`
- [ ] Glance at Cloudflare analytics for unusual traffic

### Monthly
- [ ] Run `sudo lynis audit system`
- [ ] Run `sudo rkhunter --check`
- [ ] Run `sudo aide --check`
- [ ] Scan Docker images with Trivy
- [ ] Review audit logs: `sudo aureport`
- [ ] Test backups (can you actually restore?)
- [ ] Update all Docker images: `docker compose pull` in each project
- [ ] Review Cloudflare Access policies (remove old users)

### After Any Incident
- [ ] Change all passwords
- [ ] Rotate SSH keys
- [ ] Rotate Cloudflare tunnel token
- [ ] Run full security scan (lynis + rkhunter + aide)
- [ ] Review how the breach happened
- [ ] Document and fix the vulnerability

---

## Common Attack Types & Defenses

| Attack | What It Is | Your Defense |
|--------|-----------|-------------|
| SSH Brute Force | Guessing passwords | Fail2Ban + key-only auth |
| DDoS | Flood with traffic | Cloudflare absorbs it |
| Port Scan | Finding open services | Tunnel = no ports to scan |
| SQL Injection | Malicious database queries | WAF + parameterized queries in apps |
| XSS | Injecting scripts into pages | WAF + CSP headers |
| Container Escape | Breaking out of Docker | No root containers, limited socket access |
| Supply Chain | Compromised Docker image | Trivy scanning, pinned versions |
| Credential Stuffing | Using leaked passwords | Cloudflare Access + rate limiting |
| Man in the Middle | Intercepting traffic | SSL/TLS everywhere |
| Rootkit | Hidden malware on system | rkhunter + AIDE |
| Privilege Escalation | Normal user → root | Keep system updated, audit logging |
| Zero Day | Unknown vulnerability | Defense in depth (all layers help) |
