# Access Flavor Quick Reference

All 7 access combinations at a glance. See `access-flavors.md` for full setup instructions.

## Flavor Comparison Table

| # | Name | Hub access | ntfy (phone alerts) | SSH | Setup complexity |
|---|------|-----------|---------------------|-----|-----------------|
| 1 | LAN Only | `http://SERVER_IP:8765` | `http://SERVER_IP:8085` — WiFi only | `ssh USER@SERVER_IP` | 1 — nothing extra |
| 2 | Tailscale Only | `http://TAILSCALE_IP:8765` | `http://TAILSCALE_IP:8085` — Tailscale app on phone | `ssh USER@TAILSCALE_IP` | 2 — install Tailscale on all devices |
| 3 | Cloudflare Tunnel | `https://hub.yourdomain.com` (Access login) | `https://ntfy.yourdomain.com` — no VPN needed | `ssh -o ProxyCommand='cloudflared access ssh...'` | 4 — domain + cloudflared + Access policy |
| 4 | Tailscale + Cloudflare | Both `https://hub.yourdomain.com` AND `http://TAILSCALE_IP:8765` | `https://ntfy.yourdomain.com` — no VPN on phone | `ssh USER@TAILSCALE_IP` (private) | 4 — Tailscale + cloudflared both |
| 5 | Two Tailscale Accounts | Node sharing: `http://SHARED_IP:8765` — OR — Cloudflare: `https://hub.yourdomain.com` | Via Cloudflare or Tailscale depending on path | `ssh USER@SHARED_IP` or Cloudflare SSH proxy | 3 — node share approval, or use Cloudflare path |
| 6 | Multi-Server Mesh | HQ: `https://hub.yourdomain.com` — Nodes: shown in HQ dashboard | `https://ntfy.yourdomain.com` — HQ aggregates all node alerts | HQ: `ssh USER@HQ_TAILSCALE_IP` — Nodes: `ssh -J USER@HQ USER@NODE` | 5 — HQ full setup + node installs |
| 7 | Cloudflare SSH Proxy | `https://hub.yourdomain.com` (Access login) | `https://ntfy.yourdomain.com` | `ssh ssh.yourdomain.com` (ProxyCommand via cloudflared) — zero open ports | 4 — same as Flavor 3 + close port 22 |

---

## Setup Complexity Scale

| Level | Meaning |
|-------|---------|
| 1 | Built in — no extra steps after install |
| 2 | Install one app on all devices |
| 3 | One account + configuration file |
| 4 | One or two external accounts + DNS records + config files |
| 5 | Multiple servers each configured + inter-server routing |

---

## Key Constraints at a Glance

| Flavor | Phone needs Tailscale app? | Domain required? | Open port 22? | Client software needed? |
|--------|---------------------------|-----------------|--------------|------------------------|
| 1 | No — but WiFi only | No | Yes | None |
| 2 | Yes — Tailscale app | No | No | Tailscale on each device |
| 3 | No | Yes | Optional (can use Cloudflare SSH) | cloudflared on client for SSH |
| 4 | No | Yes | No | Tailscale on admin devices |
| 5 | No (Cloudflare path) | Yes (Cloudflare path) | No | Tailscale or cloudflared |
| 6 | No | Yes (HQ only) | No (Tailscale) | Tailscale on admin devices |
| 7 | No | Yes | No — port 22 closed | cloudflared on every client |

---

## Quick Pick

```
Home only, never remote          →  Flavor 1
Remote access, own all devices   →  Flavor 2
ntfy on phone, no VPN            →  Flavor 3 or 4
Have a domain on Cloudflare      →  Flavor 3 or 4
Best of both worlds              →  Flavor 4
Work + personal Tailscale split  →  Flavor 5 (or just use Cloudflare path)
Multiple servers                 →  Flavor 6
Zero open ports / corporate net  →  Flavor 7
```

---

## Default Ports

| Service | Port |
|---------|------|
| Hub | 8765 |
| ntfy | 8085 |
| SSH | 22 |
| Portainer | 9443 |
| NPM | 81 |
| Cockpit | 9090 |

Full guide: [access-flavors.md](./access-flavors.md)
