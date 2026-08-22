# Server Kit

USB-ready bootstrap kit for a Linux server running Docker with full service stack.

## What's Included

### Core Infrastructure
- **Nginx Proxy Manager** — reverse proxy with SSL (ports 80/443/81)
- **Cloudflare Tunnel** — expose services without opening ports
- **Portainer** — Docker container management UI (port 9443)

### Monitoring
- **Uptime Kuma** — service uptime monitoring (port 3001)
- **Netdata** — real-time system stats (port 19999)
- **Dozzle** — live container log viewer (port 8080)
- **Homepage** — auto-discovering service dashboard (port 3000)

### Databases & Services
- **Supabase** — self-hosted Postgres + Auth + API (port 8000)
- **SurrealDB** — multi-model database (port 8181)
- **n8n** — workflow automation (port 5678)

### Tools
- **Claude CLI + MCP** — AI assistant with server awareness
- **Port Scanner** — auto-detect what's running where
- **Server Menu** — TUI command center
- **Add Project Wizard** — guided Docker project setup
- **Health Check** — service status overview
- **Backup System** — automated volume + config backups
- **Linux Cheat Sheet** — interactive command reference
- **Watchtower** — auto-update containers

## USB Setup

1. Flash Ubuntu Server 24.04 ISO onto USB (use Rufus or Balena Etcher)
2. Copy the `server-kit/` folder onto a second partition or a second USB
3. Boot target machine, install Ubuntu
4. Mount USB, run setup

```bash
# Mount USB (find it with lsblk)
sudo mount /dev/sdb1 /mnt

# Copy kit to home directory
cp -r /mnt/server-kit ~/server-kit

# Run
cd ~/server-kit
chmod +x run-all.sh
./run-all.sh
```

## Individual Scripts

Run any script on its own:

| Script | Purpose |
|--------|---------|
| `01-system-setup.sh` | Updates, firewall, SSH, timezone |
| `02-docker-install.sh` | Docker + Compose |
| `03-npm-setup.sh` | Nginx Proxy Manager |
| `04-cloudflared-setup.sh` | Cloudflare tunnel |
| `05-portainer-setup.sh` | Portainer |
| `06-monitoring-setup.sh` | Uptime Kuma + Netdata |
| `07-claude-cli-setup.sh` | Claude CLI + MCP |
| `08-extras-setup.sh` | Supabase, n8n, SurrealDB, Homepage, Dozzle |
| `09-backup-setup.sh` | Backup system + cron |
| `10-linux-helper-setup.sh` | Menu, aliases, cheatsheet |

## After Install

Type `menu` to open the server command center.

## Federation

ServerHub (server-kit) participates in a three-system federation with FlareVault and Metaforge.

| System | Role | Repo |
|--------|------|------|
| **Metaforge** | The Ledger — knows what things ARE | [KGSHOPINV/metaforge](https://github.com/KGSHOPINV/metaforge) |
| **FlareVault** | The Vault — controls what things CAN DO | [KGSHOPINV/flarevault](https://github.com/KGSHOPINV/flarevault) |
| **ServerHub** | The Ops Floor — manages what things RUN ON | [KGSHOPINV/server-kit](https://github.com/KGSHOPINV/server-kit) |

Doctrines, bilateral contracts, and the trilateral integration spec live in the shared repo:
**[KGSHOPINV/FV-MF-SH-integrations](https://github.com/KGSHOPINV/FV-MF-SH-integrations)**
