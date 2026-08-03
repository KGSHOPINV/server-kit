# Server Context — Claude CLI on fks-services

This file gives Claude full context about this server so any Claude session
can immediately understand the environment without asking.

---

## Server Identity

| Key | Value |
|-----|-------|
| Hostname | fks-services |
| OS | Ubuntu 24.04 LTS |
| Local IP | 192.168.1.229 |
| Tailscale IP | 100.75.1.105 |
| Tailscale name | fks-services |
| RAM | 216 GB |
| GPU | None (CPU only) |
| SSH user | admin1 |
| Docker root | /srv/docker/ |
| Backup root | /srv/backups/ |

---

## What's Running

### Hub (native — not Docker)
- **Server Hub** at `~/hub/` — Python HTTP server on port 8765
- systemd: `hub.service`, runs with `HUB_LOCAL=1` (no SSH needed, commands run directly)
- Source: https://github.com/KGSHOPINV/claude-server
- Update: `cd ~/hub && git pull && sudo systemctl restart hub`

### Docker Services

| Service | Port | Status |
|---------|------|--------|
| NPM (Nginx Proxy Manager) | 81 | always on |
| Portainer | 9443 | always on |
| Cockpit | 9090 | always on |
| Homepage | 3000 | always on |
| Uptime Kuma | 3001 | always on |
| Netdata | 19999 | always on |
| Dozzle | 8090 | always on |
| n8n | 5678 | on |
| Redis | 6379 | on |
| SurrealDB | 8001 | on |
| ntfy | 8085 | on |
| Ollama | 11434 | OFF (no GPU) |
| Open WebUI | 3004 | OFF (no GPU) |

---

## How to Run Commands

Claude is running directly ON this server.
- **No SSH needed** — run bash commands directly
- **Docker**: `docker ps`, `docker compose`, etc. all work
- **Sudo password**: Use `echo '1234qwerR' | sudo -S <command>` when needed

---

## CLI Tools (at /usr/local/bin/)

| Command | What it does |
|---------|-------------|
| `server-menu` | Interactive menu |
| `health-check` | Full service + port status |
| `server-backup` | Run backup now |
| `server-update` | Update all containers + apt |
| `sec` | Security check |
| `dkps` | Docker ps (running containers) |
| `dklogs [name]` | Docker logs for a container |
| `dkrestart [name]` | Restart a container |

---

## Docker Compose Locations

```
/srv/docker/
  npm/          portainer/     watchtower/
  homepage/     uptime-kuma/   netdata/
  dozzle/       n8n/           redis/
  surrealdb/    ntfy/          ai/
```

Manage any service:
```bash
cd /srv/docker/SERVICE && docker compose up -d    # start
cd /srv/docker/SERVICE && docker compose down      # stop
cd /srv/docker/SERVICE && docker compose logs -f   # logs
```

---

## Hub API (always available at localhost:8765)

- GET `/api/status` — RAM, disk, uptime, load, container count
- GET `/api/containers` — all Docker containers with state
- GET `/api/services` — all known services with running status
- GET `/api/integrations` — Redis/SurrealDB/n8n health checks
- GET `/api/manifest?download=1` — full system snapshot JSON
- POST `/api/run` `{"command": "..."}` — run a shell command via hub

---

## Security

- UFW firewall: active, ports 22/80/443/8765 + service ports open
- Fail2Ban: active, SSH ban threshold 5 attempts
- Unban work PC: `sudo fail2ban-client set sshd unbanip 192.168.1.192`

---

## Repos

- Hub: https://github.com/KGSHOPINV/claude-server
- Server kit (this): https://github.com/KGSHOPINV/server-kit
- Docs site: https://server-kit-docs.netlify.app

---

## Session Rules

- AI stack (Ollama/OpenWebUI) stays OFF — CPU only, no GPU
- Never commit secrets or passwords
- `notes/secrets.env` and `db/server.db` are gitignored in claude-server
