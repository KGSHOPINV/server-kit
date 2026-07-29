---
sidebar_position: 4
title: App Directory
---

# App Directory

Every app on your server — port, first login, what to configure, how to verify it's working.

**Access pattern:** `http://YOUR-SERVER-IP:PORT` (run `hostname -I` to get your IP)

---

## Infrastructure

### Nginx Proxy Manager (NPM)

| | |
|---|---|
| **URL** | `http://IP:81` |
| **Port** | `80` (HTTP), `443` (HTTPS), `81` (admin) |
| **Container** | `npm` |
| **Default login** | `admin@example.com` / `changeme` |
| **Data location** | `/srv/docker/npm/` |

**First visit:**
1. Open `:81` in browser
2. Login with defaults above
3. **Immediately change the email and password** (top-right → Settings)
4. Mark done: `sudo touch /srv/docker/npm/.password-changed`

**What to configure:**
- Proxy Hosts — add one for every service you want on a domain
- SSL Certificates — auto-generated if using Let's Encrypt (skip if Cloudflare handles SSL)

**Verify it works:**
```bash
curl -I http://localhost:80      # should return 200/301
docker logs npm | tail -5        # no errors
```

---

### Portainer

| | |
|---|---|
| **URL** | `https://IP:9443` |
| **Port** | `9443` (HTTPS) |
| **Container** | `portainer` |
| **Default login** | Create on first visit |
| **Data location** | `/srv/docker/portainer/` |

**First visit:**
1. Open `https://IP:9443` (accept the self-signed cert warning)
2. Create admin username + password (you have ~5 minutes before it locks)
3. Select "Local" environment → Connect
4. Mark done: `sudo touch /srv/docker/portainer/.admin-created`

**What to configure:**
- Nothing required — it auto-detects your Docker environment

**Verify it works:**
```bash
docker logs portainer | tail -5
# You should see your containers listed in the web UI
```

:::warning 5-minute timeout
If you don't create the admin account within ~5 minutes of first start, Portainer locks out. Fix: `docker restart portainer`
:::

---

### Cloudflare Tunnel (cloudflared)

| | |
|---|---|
| **URL** | No web UI — background service |
| **Port** | None (outbound only) |
| **Container** | `cloudflared` |
| **Config** | `/srv/docker/cloudflared/docker-compose.yml` |

**First visit:**
1. Get a tunnel token from [Cloudflare Zero Trust](https://one.dash.cloudflare.com) → Networks → Tunnels
2. Run `sudo bash ~/server-kit/04-cloudflared-setup.sh`
3. Paste the token

**What to configure:**
- Public Hostnames in Cloudflare dashboard (point each subdomain to `http://npm:80`)

**Verify it works:**
```bash
docker ps | grep cloudflared     # should be "Up"
docker logs cloudflared          # look for "Connection registered"
```

---

### Watchtower

| | |
|---|---|
| **URL** | No web UI — background service |
| **Port** | None |
| **Container** | `watchtower` |
| **Schedule** | 4am daily |

**What to configure:**
- Nothing — runs automatically
- To exclude a container from auto-updates, add label: `com.centurylinklabs.watchtower.enable=false`

**Verify it works:**
```bash
docker logs watchtower | tail -10
```

---

## Monitoring

### Homepage

| | |
|---|---|
| **URL** | `http://IP:3000` |
| **Port** | `3000` |
| **Container** | `homepage` |
| **Default login** | None |
| **Data location** | `/srv/docker/homepage/` |

**First visit:**
1. Open `:3000` — should show auto-discovered Docker services as tiles
2. Click any tile to jump to that service

**What to configure:**
- Mostly automatic via Docker labels
- Custom layout: edit config files inside the container

**Verify it works:**
```bash
curl -s http://localhost:3000 | head -5    # should return HTML
```

---

### Uptime Kuma

| | |
|---|---|
| **URL** | `http://IP:3001` |
| **Port** | `3001` |
| **Container** | `uptime-kuma` |
| **Default login** | Create on first visit |
| **Data location** | `/srv/docker/monitoring/` |

**First visit:**
1. Open `:3001`
2. Create admin account
3. Add monitors for every running service

**What to configure:**
- **Monitors** — add one per service (HTTP check against the container URL)
- **Notifications** — set up Discord, Slack, email, or ntfy alerts
- **Status Page** — optionally create a public status page

**Recommended monitors to add:**

| Name | Type | URL/Target |
|------|------|-----------|
| NPM | HTTP | `http://npm:80` |
| Portainer | HTTP | `https://portainer:9443` (skip cert verify) |
| Ollama | HTTP | `http://ollama:11434` |
| Open WebUI | HTTP | `http://open-webui:8080` |
| Each of your apps | HTTP | `http://container:port` |

**Verify it works:**
```bash
docker logs uptime-kuma | tail -5
# Web UI should show green/red status for each monitor
```

---

### Netdata

| | |
|---|---|
| **URL** | `http://IP:19999` |
| **Port** | `19999` |
| **Container** | `netdata` |
| **Default login** | None (open access) |

**First visit:**
1. Open `:19999`
2. Browse dashboards — CPU, memory, disk, network, Docker containers

**What to configure:**
- Nothing required — works out of the box
- **Recommended:** Put behind Cloudflare Access if exposed publicly (shows system internals)

**Verify it works:**
```bash
curl -s http://localhost:19999/api/v1/info | head -3
```

---

### Grafana

| | |
|---|---|
| **URL** | `http://IP:3002` |
| **Port** | `3002` |
| **Container** | `grafana` |
| **Default login** | `admin` / `admin` |
| **Data location** | `/srv/docker/grafana/` |

**First visit:**
1. Open `:3002`
2. Login with `admin` / `admin`
3. **Change password immediately** when prompted

**What to configure:**
- Data Sources → add Prometheus, PostgreSQL, or other sources
- Dashboards → create or import community dashboards

**Verify it works:**
```bash
curl -s http://localhost:3002/api/health
```

---

### Dozzle

| | |
|---|---|
| **URL** | `http://IP:8090` |
| **Port** | `8090` |
| **Container** | `dozzle` |
| **Default login** | None |

**First visit:**
1. Open `:8090`
2. See all container logs in real time
3. Click any container to view its logs

**What to configure:**
- Nothing — reads Docker socket automatically

**Verify it works:**
```bash
curl -s http://localhost:8090 | head -3
```

---

### Cockpit

| | |
|---|---|
| **URL** | `https://IP:9090` |
| **Port** | `9090` |
| **Container** | Not Docker — runs on the OS |
| **Default login** | Your Linux username + password |

**First visit:**
1. Open `https://IP:9090` (accept cert warning)
2. Login with your server username/password
3. Browse: terminal, logs, networking, storage, services

**What to configure:**
- Nothing — uses your OS authentication

**Verify it works:**
```bash
sudo systemctl status cockpit
```

---

## Databases & Storage

### Supabase

| | |
|---|---|
| **URL** | `http://IP:8000` (Studio) |
| **Ports** | `8000` (Studio), `5432` (Postgres), `8100` (API) |
| **Containers** | `supabase-db`, `supabase-auth`, `supabase-rest`, `supabase-studio`, `supabase-kong` |
| **Default login** | Set in `.env` file |
| **Data location** | `/srv/docker/supabase/` |

**First visit:**
1. Open `:8000`
2. Login with credentials from `.env`
3. Create your first table in the Table Editor

**What to configure:**
- `.env` — change `ANON_KEY`, `SERVICE_ROLE_KEY`, `JWT_SECRET`, `POSTGRES_PASSWORD`
- **Never expose the Service Role Key** — it bypasses all security

**Verify it works:**
```bash
docker ps | grep supabase       # should see 5 containers
curl -s http://localhost:8000    # should return Studio HTML
```

:::danger Change the default keys
The `.env.example` ships with placeholder keys. Generate real ones before going to production. The JWT secret especially — if someone knows it, they can forge admin tokens.
:::

---

### SurrealDB

| | |
|---|---|
| **URL** | Use [Surrealist](https://surrealist.app) web client |
| **Port** | `8181` |
| **Container** | `surrealdb` |
| **Default login** | `root` / `root` |
| **Data location** | `/srv/docker/surrealdb/` |

**First visit:**
1. Open [surrealist.app](https://surrealist.app)
2. Connect to `http://YOUR-IP:8181`
3. Login: `root` / `root`
4. **Change the root password** in the compose file environment variables

**What to configure:**
- Change default password in `docker-compose.yml`:
```yaml
command: start --user root --pass YOUR-NEW-PASSWORD file:/data/db
```

**Verify it works:**
```bash
curl -s http://localhost:8181/health    # should return "OK"
```

---

### Redis

| | |
|---|---|
| **URL** | `http://IP:8082` (Commander web UI) |
| **Ports** | `6379` (Redis), `8082` (Commander) |
| **Containers** | `redis`, `redis-commander` |
| **Default login** | None (no auth by default) |
| **Data location** | `/srv/docker/redis/` |

**First visit:**
1. Open `:8082` for the web UI
2. Browse keys, run commands visually

**What to configure:**
- For production: add a password in compose:
```yaml
command: redis-server --requirepass YOUR-PASSWORD
```

**Verify it works:**
```bash
docker exec redis redis-cli ping    # should return "PONG"
```

---

### MinIO

| | |
|---|---|
| **URL** | `http://IP:9001` (Console) |
| **Ports** | `9000` (API), `9001` (Console) |
| **Container** | `minio` |
| **Default login** | `minioadmin` / `minioadmin` |
| **Data location** | `/srv/docker/minio/` |

**First visit:**
1. Open `:9001`
2. Login with `minioadmin` / `minioadmin`
3. **Change credentials immediately** → Identity → Users
4. Create your first bucket (Object Browser → Create Bucket)

**What to configure:**
- Change default credentials in compose `.env`
- Create buckets for each project that needs file storage

**Verify it works:**
```bash
curl -s http://localhost:9000/minio/health/live    # should return 200
```

---

### Adminer

| | |
|---|---|
| **URL** | `http://IP:8083` |
| **Port** | `8083` |
| **Container** | `adminer` |
| **Default login** | Uses your database credentials |

**First visit:**
1. Open `:8083`
2. Select system (PostgreSQL, MySQL, etc.)
3. Enter connection: server = `supabase-db`, user = `postgres`, password = (from `.env`)

**What to configure:**
- Nothing — it's a client that connects to your databases

---

## Dev Tools

### n8n

| | |
|---|---|
| **URL** | `http://IP:5678` |
| **Port** | `5678` |
| **Container** | `n8n` |
| **Default login** | Create on first visit |
| **Data location** | `/srv/docker/n8n/` |

**First visit:**
1. Open `:5678`
2. Create owner account
3. Build your first workflow

**What to configure:**
- Credentials — store API keys for services you want to connect
- Webhook URL — set your public URL if using webhook triggers

**Verify it works:**
```bash
curl -s http://localhost:5678/healthz    # should return "OK"
```

---

### Mailpit

| | |
|---|---|
| **URL** | `http://IP:8025` (inbox) |
| **Ports** | `8025` (web UI), `1025` (SMTP) |
| **Container** | `mailpit` |
| **Default login** | None |

**First visit:**
1. Open `:8025` — shows empty inbox
2. Point any app's email config to `mailpit:1025`
3. Send a test email — it appears in the inbox

**What to configure:**
- In your apps: `SMTP_HOST=mailpit`, `SMTP_PORT=1025`

---

### Wiki.js

| | |
|---|---|
| **URL** | `http://IP:3003` |
| **Port** | `3003` |
| **Container** | `wikijs` |
| **Default login** | Create on first visit |
| **Data location** | `/srv/docker/wiki/` |

**First visit:**
1. Open `:3003`
2. Follow setup wizard — create admin, pick storage (SQLite works fine)
3. Create your first page

---

### LanguageTool

| | |
|---|---|
| **URL** | `http://IP:8084` |
| **Port** | `8084` |
| **Container** | `languagetool` |
| **Default login** | None (API only) |

**First visit:**
No web UI — it's an API. Test it:
```bash
curl -X POST http://localhost:8084/v2/check \
  -d "text=This is a test sentnce." \
  -d "language=en-US"
```

---

## AI Stack

### Ollama

| | |
|---|---|
| **URL** | `http://IP:11434` (API only) |
| **Port** | `11434` |
| **Container** | `ollama` |
| **Default login** | None |
| **Data location** | Volume: `ollama-data` |

**First visit:**
1. No web UI — use Open WebUI or terminal
2. Pull your first model:
```bash
docker exec ollama ollama pull gemma4:12b
```
3. Test it:
```bash
docker exec -it ollama ollama run gemma4:12b
# Type a message, /bye to exit
```

**What to configure:**
- Which models to download (based on your RAM)
- GPU passthrough if you have NVIDIA

**Verify it works:**
```bash
curl -s http://localhost:11434/api/tags    # lists installed models
```

---

### Open WebUI

| | |
|---|---|
| **URL** | `http://IP:3004` |
| **Port** | `3004` |
| **Container** | `open-webui` |
| **Default login** | Create on first visit |
| **Data location** | Volume: `openwebui-data` |

**First visit:**
1. Open `:3004`
2. Create an account (local only, no external auth)
3. Select a model from the dropdown (must have pulled one in Ollama first)
4. Start chatting

**What to configure:**
- System prompts per chat
- Model defaults
- File upload settings

**Verify it works:**
```bash
curl -s http://localhost:3004     # should return HTML
```

---

### OpenClaw

| | |
|---|---|
| **URL** | `http://IP:3005` |
| **Port** | `3005` |
| **Container** | `openclaw` |
| **Default login** | Create on first visit |
| **Data location** | Volume: `openclaw-data` |

**First visit:**
1. Open `:3005`
2. Create account
3. Configure Ollama connection (should auto-detect via `http://ollama:11434`)

**Verify it works:**
```bash
curl -s http://localhost:3005     # should return HTML
```

---

## Notifications (optional)

### ntfy

| | |
|---|---|
| **URL** | `http://IP:8085` |
| **Port** | `8085` |
| **Container** | `ntfy` |
| **Default login** | None |

**First visit:**
1. Open `:8085`
2. Subscribe to a topic (e.g., `server-alerts`)
3. Test: `curl -d "Hello from server" http://localhost:8085/server-alerts`

---

### Gotify

| | |
|---|---|
| **URL** | `http://IP:8086` |
| **Port** | `8086` |
| **Container** | `gotify` |
| **Default login** | `admin` / `admin` |

**First visit:**
1. Open `:8086`
2. Login with `admin` / `admin`
3. **Change password**
4. Create an Application → get the token for sending alerts

---

## Verification Checklist

Run after first install to make sure everything is healthy:

```bash
# Quick check everything
health

# Or manually check each:
curl -s http://localhost:80    > /dev/null && echo "NPM: OK"        || echo "NPM: DOWN"
curl -s http://localhost:81    > /dev/null && echo "NPM Admin: OK"  || echo "NPM Admin: DOWN"
curl -sk https://localhost:9443 > /dev/null && echo "Portainer: OK" || echo "Portainer: DOWN"
curl -s http://localhost:3000  > /dev/null && echo "Homepage: OK"   || echo "Homepage: DOWN"
curl -s http://localhost:3001  > /dev/null && echo "Kuma: OK"       || echo "Kuma: DOWN"
curl -s http://localhost:8090  > /dev/null && echo "Dozzle: OK"     || echo "Dozzle: DOWN"
curl -s http://localhost:19999 > /dev/null && echo "Netdata: OK"    || echo "Netdata: DOWN"
curl -s http://localhost:11434 > /dev/null && echo "Ollama: OK"     || echo "Ollama: DOWN"
curl -s http://localhost:3004  > /dev/null && echo "WebUI: OK"      || echo "WebUI: DOWN"
curl -s http://localhost:3005  > /dev/null && echo "OpenClaw: OK"   || echo "OpenClaw: DOWN"
```
