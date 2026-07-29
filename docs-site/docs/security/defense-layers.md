---
sidebar_position: 1
title: Defense Layers
---

# Security Defense Layers

Your server has 6 layers of protection. An attacker has to get through ALL of them.

---

```
INTERNET
  │
  ▼
┌─────────────────────────────────────┐
│ Cloudflare                          │  DDoS protection, WAF, bot blocking
│ + Access (authentication wall)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Tunnel (cloudflared)                │  Encrypted, no open ports to internet
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ UFW Firewall                        │  Blocks unexpected traffic
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Fail2Ban + CrowdSec                 │  Bans attackers automatically
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Docker Network Isolation            │  Containers can't reach what they shouldn't
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ App-level Auth                      │  Each service has its own login
└─────────────────────────────────────┘
```

---

## What Each Layer Stops

| Attack Type | What Stops It |
|-------------|---------------|
| DDoS (traffic flood) | Cloudflare absorbs it |
| Port scanning | Tunnel — no ports to scan |
| SSH brute force | Fail2Ban bans after 3 failures |
| Known attacker IPs | CrowdSec (community intelligence) |
| Web exploits (SQLi, XSS) | Cloudflare WAF |
| Unauthorized access | Cloudflare Access login wall |
| Container escape | Docker isolation, no root containers |
| Credential stuffing | Rate limiting + Access policies |
| Rootkits | rkhunter detection |
| File tampering | AIDE integrity monitoring |
| Privilege escalation | auditd logging, auto-updates |
