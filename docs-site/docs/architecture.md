---
sidebar_position: 2
title: Architecture Map
---

# Architecture Map

How Server Hub fits into the full system — two repos, order of operations, access layers, and where this is going.

---

## Two Repos — Source of Everything

```
claude-server              server-kit
─────────────────          ─────────────────────────
hub/server.py              00-bootstrap.sh
hub/app.html               01–16 install scripts
hub/guides/                docker/ (24 compose files)
PORTS.md                   docs-site/ → Netlify
CLAUDE.example.md
```

**server-kit** sets up a blank server (Docker, UFW, Fail2Ban, all services by tier).
**claude-server** is the hub app that runs on a server after server-kit has done its job.

The server pulls from `claude-server` on GitHub on every update. The Netlify docs site builds from `server-kit`.

---

## Order of Operations — Any New Server

| Step | What | How |
|------|------|-----|
| 1 · Provision | Bare Ubuntu 24.04, SSH key access | VPS, homelab, cloud |
| 2 · Bootstrap | Docker, UFW, Fail2Ban, SSH hardening | `00-bootstrap.sh` |
| 3 · Stack | Services by tier (only what you need) | Scripts 01–16 |
| 4 · Hub | Clone claude-server, set `HUB_SSH_HOST`, start systemd | `systemctl --user start hub` |
| 5 · Access | Tailscale enroll, Cloudflare tunnel | :8765 = control room |

`HUB_SSH_HOST` is the only thing that tells the hub which server it's controlling. Default is `localhost`. Set to `user@ip` to control a remote machine.

---

## The Hub at :8765

| View | What it gives you |
|------|-------------------|
| **Server** | Live RAM, CPU, disk, uptime, container count |
| **Services** | All Docker containers — start, stop, restart, logs |
| **Terminal** | SSH shell in the browser, command history |
| **Files** | Browse the server filesystem |
| **Vault** | Encrypted passwords — master key never leaves the browser |
| **Remote** | Local / Tailscale / Cloudflare URLs, tunnel on/off |
| **Infra Map** | Visual map of running services and ports |
| **Docs** | In-app guides |

---

## Access Topology — Three Paths In

```
LAN           192.168.x.x:8765   Same network, just works
Tailscale     100.x.x.x:8765    Your devices, anywhere — intranet extension
Cloudflare    https://hub.domain  Anyone with the URL, Access auth gate optional
```

**The key division:**
- Your devices → Tailscale (you are *on* the intranet from anywhere)
- Public internet / sharing → Cloudflare Tunnel + Access

---

## Port Lanes

All services assigned to category-scoped ranges. Full registry in PORTS.md.

| Lane | Range |
|------|-------|
| Hub | 8765 (reserved) |
| Infrastructure | 3000–3099 |
| Monitoring | 19000–19999 |
| Automation | 5600–5699 |
| Database | 5400–5499, 6300–6399 |
| Storage | 9000–9099 |
| Admin | 9400–9499 |
| AI | 11000–11999 |

---

## Multi-Server Vision

**Pattern A — one hub, SSH into remote**
Hub on Server A, `HUB_SSH_HOST` points at Server B via Tailscale. Terminal and monitoring run against B.

**Pattern B — hub on each server**
Each server runs its own hub at `100.x.x.x:8765`. Switch between them in the browser.

**Pattern C — hub of hubs (planned)**
A server picker UI — one hub registering multiple servers, switching SSH context between them.

---

## What Makes It Portable

- No hardcoded IPs — `HUB_SSH_HOST` / `HUB_SSH_USER` env vars
- `CLAUDE.md` gitignored — real IPs and SSH details stay local only
- Server identity (hostname, OS, IP, cores) read live at runtime
- Drop on any Ubuntu box: clone, set env vars, start systemd — done in ~5 min
