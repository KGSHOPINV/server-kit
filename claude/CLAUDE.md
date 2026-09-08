# Server Context — Claude CLI

This file is copied to ~/.claude/CLAUDE.md during install.
It gives any Claude session full context about this server.
Edit it after install to fill in your actual server details.

---

## Server Identity

| Key | Value |
|-----|-------|
| Hostname | YOUR_HOSTNAME |
| OS | Ubuntu 24.04 LTS |
| Local IP | YOUR_LOCAL_IP |
| Tailscale IP | YOUR_TAILSCALE_IP |
| SSH user | YOUR_ADMIN_USER |
| Docker root | /srv/docker/ |
| Backup root | /srv/backups/ |

> After install, update the values above with your real server details.
> Keep this file local -- never commit it to GitHub.

---

## What's Running

### Hub (native -- not Docker)
- **Server Hub** at ~/hub/ -- Python HTTP server on port 8765
- systemd: hub.service, auto-restarts, HUB_LOCAL=1
- Source: https://github.com/KGSHOPINV/claude-server
- Update: cd ~/hub && git pull && sudo systemctl restart hub

### Docker Services (depends what you selected during install)

| Service | Port |
|---------|------|
| NPM (Nginx Proxy Manager) | 81 |
| Portainer | 9443 |
| Homepage | 3000 |
| Uptime Kuma | 3001 |
| Netdata | 19999 |
| Dozzle | 8090 |
| n8n | 5678 |
| Redis | 6379 |
| SurrealDB | 8001 |
| ntfy | 8085 |
| Ollama | 11434 (keep OFF without GPU) |
| Open WebUI | 3004 (keep OFF without GPU) |

---

## How to Run Commands

Claude running ON this server -- no SSH prefix needed.
- Run bash commands directly
- Docker commands work directly: docker ps, docker compose, etc.
- For sudo: configure NOPASSWD in sudoers or use sudo interactively

---

## CLI Tools (at /usr/local/bin/)

| Command | What it does |
|---------|-------------|
| server-menu | Interactive menu for everything |
| health-check | Full service + port status |
| server-backup | Run backup now |
| server-update | Update all containers + apt |
| dkps | Docker ps (running containers) |
| dklogs [name] | Docker logs for a container |
| dkrestart [name] | Restart a container |
| dkstop [name] | Stop a container |
| dkstart [name] | Start a container |

---

## Docker Compose Locations

All services under /srv/docker/SERVICE_NAME/

  cd /srv/docker/SERVICE && docker compose up -d    # start
  cd /srv/docker/SERVICE && docker compose down      # stop
  cd /srv/docker/SERVICE && docker compose logs -f   # logs

---

## Hub API (localhost:8765)

- GET /api/status -- RAM, disk, uptime, load, containers
- GET /api/storage -- all mounts, disk tree, docker df
- GET /api/containers -- all Docker containers with state
- GET /api/ports -- all bound ports with federation fields
- GET /api/activity -- event log
- GET /api/receipt -- full server snapshot
- POST /api/run -- TOTP-gated command execution

---

## Session Rules

- AI stack (Ollama/OpenWebUI) stays OFF unless you have a GPU
- Never commit passwords or secrets to GitHub
- notes/secrets.env and db/server.db are gitignored in claude-server
- CLAUDE.md itself is gitignored -- keep it local

---

## Repos

- Hub: https://github.com/KGSHOPINV/claude-server
- Server kit: https://github.com/KGSHOPINV/server-kit