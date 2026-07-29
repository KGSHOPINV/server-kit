---
sidebar_position: 2
title: Server Tools (Deep Dive)
---

# Server Tools — Deep Dive

Every custom tool explained in detail — what it does, when to use it, what you'll see.

---

## `menu` — Command Center

Interactive TUI with 18 options. Shows system stats at the top (hostname, IP, uptime, memory, disk, container count).

**When to use:** When you don't remember the command for something. It's the front door.

**Options:**
1. What's next?
2. View running services
3. Scan ports
4. Health check
5. Security check
6. Hardware monitor
7. Add new project
8. Deploy from GitHub
9. View logs (Dozzle)
10. Container management (Portainer)
11. System stats (Netdata)
12. Backup now
13. Linux cheat sheet
14. Docker shortcuts
15. Open Claude CLI
16. Update server-kit
17. Server registry
18. AI models

---

## `health` — Health Check

Checks every expected service and reports OK or DOWN.

**What it checks:**
- SSH (22)
- NPM (80, 443, 81)
- Portainer (9443)
- Monitoring (3000, 3001, 3002, 19999, 8090)
- Databases (5432, 8000, 8181, 6379, 8082, 9000, 9001, 8083)
- Dev tools (5678, 8025, 1025, 3003, 8084)
- AI (11434, 3004, 3005)

Also reports: Docker engine status, container counts, disk usage, memory usage.

**When to use:** First thing to run when something feels wrong.

---

## `ports` — Port Scan

Scans all listening ports, matches each to a Docker container, and shows the service name.

**When to use:** When you need to know what's on what port, or something has a port conflict.

---

## `sec` — Security Check

Shows:
- Firewall (UFW) status and rules
- Fail2Ban — active jails, banned IPs, recent bans
- SSH config — root login, password auth, key auth
- Active connections — who's connected right now
- Docker security — socket access, privileged containers

**When to use:** Periodically (weekly), or when you suspect something is wrong.

---

## `hw` — Hardware Monitor

Shows:
- CPU temperatures (per core, per sensor)
- Disk SMART status (health, temperature, hours, errors)
- Memory usage (total, used, available, swap)
- Power stats (if available)
- Warnings if anything is out of range

**When to use:** When the server feels hot, slow, or you hear disk noises.

---

## `whats-next` — Guided Checklist

Scans your actual server state and tells you what still needs doing. Checks:

- **Setup:** Docker, NPM, Portainer, Uptime Kuma, Netdata, Homepage, Dozzle
- **Networking:** Static IP, Cloudflare tunnel, domain, proxy hosts
- **Security:** Firewall, Fail2Ban, SSH hardening, Cloudflare Access, auto updates
- **Backups:** System installed, cron active, first backup done, offsite configured
- **Tools:** Claude CLI, GitHub CLI, GitHub auth
- **Optional:** Redis, Supabase, n8n, SurrealDB, MinIO, Wiki.js, Grafana

Each TODO includes the exact command to fix it.

**When to use:** After install, or whenever you want to know what you should be doing.

---

## `howdo` — Search Engine

Built-in search with 60+ Linux/Docker/server answers. Type a keyword and get instant help.

**Example searches:**
- `howdo restart` — how to restart containers, services, the server
- `howdo backup` — how backups work
- `howdo port` — port management, conflicts, scanning
- `howdo firewall` — UFW commands
- `howdo ssl` — SSL/TLS setup with NPM + Cloudflare

**When to use:** Instead of googling basic server questions.

---

## `essentials` — One-Screen Cheat Sheet

The only commands you actually need to know — daily life, Docker, troubleshooting, security, and the golden rules.

**When to use:** When you're blanking on a command.

---

## `cheat` — Full Cheat Sheet

Interactive categorized reference:
- Files & directories
- System info
- Networking
- Docker
- Disk & storage
- Users & permissions
- Packages
- Logs

---

## `add-project` — New Project Wizard

Guided wizard that asks:
1. Project name
2. Ports needed
3. Database requirements
4. Subdomain

Then generates a `docker-compose.yml` and optionally starts it.

---

## `deploy` — GitHub Deploy

- **Deploy NEW** — clone from GitHub, set up compose, start
- **Update EXISTING** — git pull, rebuild, restart
- **List deployed** — show all projects with status

---

## `server-backup` — Backup

Backs up all Docker configs and volumes from `/srv/docker/` to `/srv/backups/`.
- Date-stamped archives
- 7-day retention (auto-deletes older)
- Runs at 3am daily via cron (if enabled)

---

## `kit-update` — Self Update

Pulls the latest server-kit from GitHub and re-installs all tools. Keeps your server's kit current.

```bash
kit-update
```

---

## `kit-servers` / `server-register` / `kit-sync` — Multi-Server

If you have multiple servers running server-kit:

- `server-register` — register this server to the shared registry (name, IP, role)
- `kit-servers` — list all registered servers with status
- `kit-sync` — sync registry between servers via git/SSH/file
