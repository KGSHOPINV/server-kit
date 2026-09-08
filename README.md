# server-kit

Bootstrap installer for a Linux server running ServerHub + Docker services.

One command on a fresh Ubuntu 24.04 server:

```bash
git clone https://github.com/KGSHOPINV/server-kit
cd server-kit
bash install.sh
```

After install: open `http://YOUR_SERVER_IP:8765` -- ServerHub is live.

---

## What install.sh does

Asks which optional services you want, then in order:

1. System setup (UFW, Fail2Ban, SSH hardening, packages)
2. Docker install
3. ServerHub (cloned from KGSHOPINV/claude-server, runs native on port 8765)
   → **Open your browser here -- watch the rest of the install happen live**
4. Nginx Proxy Manager (creates the `proxy` Docker network)
5. Portainer
6. Monitoring stack (Homepage, Uptime Kuma, Netdata, Dozzle)
7. Claude CLI
8. Optional services (whatever you selected)
9. Backup setup
10. Linux helper tools
11. Hardware monitor
12. Security hardening
13. GitHub deploy setup
14. Terminal setup (tmux, MOTD, aliases)
15. Server console (Cockpit, ntfy)

---

## Optional Services

All optional. ServerHub works without any of them -- it monitors whatever is installed.

**Infrastructure**
| Service | Port | What it does |
|---------|------|-------------|
| Nginx Proxy Manager | 80/81/443 | Routes domains to containers, SSL termination |
| Portainer | 9443 | Visual Docker container manager |
| Watchtower | -- | Auto-updates containers |
| Cloudflare Tunnel | -- | Expose services without opening firewall ports |

**Monitoring**
| Service | Port | What it does |
|---------|------|-------------|
| Homepage | 3000 | Auto-discovering service dashboard |
| Uptime Kuma | 3001 | Uptime monitoring + alerts |
| Netdata | 19999 | Real-time CPU/RAM/disk/network graphs |
| Dozzle | 8090 | Live container log viewer |
| Cockpit | 9090 | Linux admin panel in browser |
| ntfy | 8085 | Self-hosted push notifications (phone alerts) |

**Databases**
| Service | Port | What it does |
|---------|------|-------------|
| Supabase | 8000 | Postgres + auth + realtime + API |
| PostgreSQL | 5432 | SQL database (standalone) |
| Redis | 6379 | Cache / fast key-value store |
| SurrealDB | 8001 | Multi-model database |
| Adminer | 8082 | Database browser UI |

**Dev Tools**
| Service | Port | What it does |
|---------|------|-------------|
| n8n | 5678 | Workflow automation |
| MinIO | 9000/9001 | Object storage (S3-compatible) |
| Mailpit | 8025 | Dev email catcher |
| Wiki.js | 3002 | Knowledge base |
| LanguageTool | 8081 | Grammar checker API |
| Webhook | 9000 | Inbound webhook receiver |

**AI (keep OFF -- CPU-only, no GPU)**
| Service | Port | What it does |
|---------|------|-------------|
| Ollama | 11434 | AI model engine |
| Open WebUI | 3004 | Chat interface for Ollama |
| OpenClaw | 3005 | AI playground |

---

## Access Flavors

How you reach the server from outside your LAN depends on your setup. See:
- [docs/access-flavors.md](docs/access-flavors.md) -- full guide, 7 flavors
- [docs/access-quick-ref.md](docs/access-quick-ref.md) -- one-page cheat sheet

**Quick pick:**
- Home only → LAN (no setup)
- Remote access → add Tailscale
- Phone alerts without VPN → add Cloudflare Tunnel
- Both → Flavor 4 (recommended)

---

## Multi-Server Setup

One server is HQ. Others are nodes. HQ generates a pairing token; nodes use it during install to register themselves. HQ aggregates status from all nodes. See [docs/access-flavors.md](docs/access-flavors.md) for the mesh setup.

```bash
# Install a node and pair it to HQ:
PAIR_TOKEN=xxx PAIR_HOST=hub.yourdomain.com bash install.sh
```

---

## Docker Services

All services live under `/srv/docker/SERVICE_NAME/`.
Container name always matches folder name -- no generated names.
Each `docker-compose.yml` is self-contained with ports, volumes, and restart policy.

To manage any service:
```bash
cd /srv/docker/SERVICE_NAME
docker compose up -d       # start
docker compose down        # stop
docker compose logs -f     # watch logs
docker compose pull        # update image
```

---

## Tools installed to /usr/local/bin/

| Command | What it does |
|---------|-------------|
| `server-menu` | Interactive TUI menu for everything |
| `health-check` | Full service + port status report |
| `server-backup` | Run backup now |
| `server-update` | Update all containers + system packages |
| `sec` / `security-check` | Security audit |
| `port-scan` | Show all bound ports and what owns them |
| `add-project` | Guided wizard to add a new Docker project |
| `deploy-project` | Deploy a project from GitHub |
| `howdo` | Ask Claude a question from the terminal |
| `dkps` | Docker ps -- running containers |
| `dklogs [name]` | Docker logs for a container |
| `dkrestart [name]` | Restart a container |
| `dkstop [name]` | Stop a container |
| `dkstart [name]` | Start a container |
| `server-list` | List all servers (HQ + nodes) |
| `server-register` | Register this server with HQ |
| `server-sync` | Sync config from HQ |
| `self-update` | Update server-kit from GitHub |
| `network-check` | Check network connectivity and DNS |
| `whats-next` | Show suggested next steps |

---

## Two repos

| Repo | What | Server path |
|------|------|-------------|
| KGSHOPINV/claude-server | ServerHub app -- all hub code, UI, API | `~/hub` |
| KGSHOPINV/server-kit | This repo -- bootstrap + Docker stack | `~/server-kit` |

Hub app code goes in `claude-server`. Docker compose files and install scripts go in `server-kit`. Never cross them.

Update hub independently at any time -- no reinstall needed:
```bash
cd ~/hub && git pull && systemctl --user restart hub
```

---

## Federation

ServerHub participates in a three-system federation with FlareVault and Metaforge.

| System | Role | Repo |
|--------|------|------|
| **ServerHub** | The Ops Floor -- manages what things RUN ON | [KGSHOPINV/server-kit](https://github.com/KGSHOPINV/server-kit) |
| **FlareVault** | The Vault -- controls what things CAN DO | [KGSHOPINV/flarevault](https://github.com/KGSHOPINV/flarevault) |
| **Metaforge** | The Ledger -- knows what things ARE | [KGSHOPINV/metaforge](https://github.com/KGSHOPINV/metaforge) |

Doctrines, bilateral contracts, and the trilateral integration spec live in the shared private repo:
**[KGSHOPINV/FV-MF-SH-integrations](https://github.com/KGSHOPINV/FV-MF-SH-integrations)**
