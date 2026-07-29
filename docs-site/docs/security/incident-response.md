---
sidebar_position: 3
title: Incident Response
---

# Incident Response

What to do when something bad happens.

---

## "I Think I've Been Compromised"

### Step 1 — Isolate

```bash
# Take server offline immediately (kill the tunnel)
cd /srv/docker/cloudflared && docker compose down

# Or block all network traffic
sudo ufw default deny incoming
sudo ufw default deny outgoing
```

### Step 2 — Investigate

```bash
# Who's logged in?
who
w
last -20

# Suspicious processes?
ps aux | sort -k3 -rn | head -20

# Recently modified files?
find / -mmin -60 -type f 2>/dev/null | grep -v proc | grep -v sys

# Auth log
sudo tail -200 /var/log/auth.log

# Audit log
sudo ausearch --start recent

# Rootkit scan
sudo rkhunter --check

# File integrity
sudo aide --check

# Unknown containers?
docker ps -a
```

### Step 3 — Contain

```bash
# Change ALL passwords
passwd
sudo passwd root

# Rotate SSH keys
rm ~/.ssh/authorized_keys
# Add your new key

# Create new Cloudflare tunnel token (delete old one)
# Change all service passwords (Portainer, NPM, databases)
```

### Step 4 — Clean

If you have backups → restore from last known good backup.
If not → rebuild (fresh install + server-kit).

### Step 5 — Harden

- Figure out HOW they got in
- Fix that vulnerability
- Run `sudo lynis audit system` for more recommendations

---

## "Someone Is Attacking Right Now"

```bash
# See who's connecting
ss -tn state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head

# Ban them
sudo ufw deny from ATTACKER_IP
sudo fail2ban-client set sshd banip ATTACKER_IP
sudo cscli decisions add --ip ATTACKER_IP --duration 720h --reason "active attack"

# Nuclear option — take everything offline
cd /srv/docker/cloudflared && docker compose down
```

---

## "I Locked Myself Out of SSH"

Fail2Ban probably banned your IP.

**If you have physical access:**
```bash
sudo fail2ban-client set sshd unbanip YOUR_IP
```

**If you have Cockpit access (`:9090`):**
Use the web terminal to unban yourself.

**If you have no access:**
You need physical access to the machine (keyboard + monitor).
