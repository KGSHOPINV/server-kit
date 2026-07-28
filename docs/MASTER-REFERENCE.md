# Server Kit — Master Reference

Everything on this server, what it does, why it's here, and how to use it.

---

## Table of Contents

1. [Service Map](#service-map)
2. [Core Infrastructure](#core-infrastructure)
3. [Monitoring & Visibility](#monitoring--visibility)
4. [Databases & Storage](#databases--storage)
5. [Developer Tools](#developer-tools)
6. [Server Tools (Linux)](#server-tools-linux)
7. [Networking Concepts](#networking-concepts)
8. [Port Directory](#port-directory)
9. [Common Workflows](#common-workflows)
10. [Troubleshooting](#troubleshooting)

---

## Service Map

```
INTERNET
   |
   | (Cloudflare Tunnel — encrypted, no open ports needed)
   |
   v
[cloudflared] ──> [NPM (Nginx Proxy Manager)]
                        |
         ┌──────────────┼──────────────────────┐
         |              |                      |
    your-app.com   api.your.com    admin.your.com
         |              |                      |
   [App Container] [Supabase API]    [Portainer]
```

Every request from the internet flows:
**User → Cloudflare → cloudflared container → NPM → your service**

---

## Core Infrastructure

### Nginx Proxy Manager (NPM)
- **What:** Reverse proxy — routes incoming traffic to the right container
- **Port:** 80 (HTTP), 443 (HTTPS), 81 (admin panel)
- **Why:** Without this, you'd have to remember which port each service is on. NPM lets you use domain names instead (taskmaster.yourdomain.com → container on port 3000)
- **Key concepts:**
  - **Proxy Host** = a routing rule (domain → container:port)
  - **SSL Certificate** = HTTPS encryption (NPM gets these automatically from Let's Encrypt)
  - **Access List** = restrict who can access a service (IP whitelist, password)
- **Default login:** admin@example.com / changeme (CHANGE THIS)
- **When to touch it:** Every time you add a new project that needs a public URL

### Cloudflare Tunnel (cloudflared)
- **What:** Encrypted tunnel from your server to Cloudflare's network
- **Port:** None exposed — it connects outbound
- **Why:** Your server doesn't need a public IP or open ports. The tunnel punches out to Cloudflare, and Cloudflare routes traffic back through it
- **Key concepts:**
  - **Tunnel** = the connection between your server and Cloudflare
  - **Token** = authentication for the tunnel (from Cloudflare dashboard)
  - **Public Hostname** = a domain/subdomain you route through the tunnel
  - **Service** = what the hostname points to (http://npm:80 usually)
- **When to touch it:** When you need a new subdomain accessible from the internet

### Portainer
- **What:** Web UI for managing Docker containers
- **Port:** 9443 (HTTPS)
- **Why:** Visual way to see all containers, start/stop them, view logs, manage volumes
- **Key concepts:**
  - **Stack** = a group of containers (same as docker-compose)
  - **Volume** = persistent data storage for a container
  - **Network** = how containers talk to each other
- **When to touch it:** When you want to manage containers without command line

### Watchtower
- **What:** Auto-updates Docker containers
- **Port:** None — runs in background
- **Why:** Pulls latest images and recreates containers automatically
- **Schedule:** Runs at 4am daily
- **When to touch it:** If you DON'T want a container auto-updated, add label: `com.centurylinklabs.watchtower.enable=false`

---

## Monitoring & Visibility

### Uptime Kuma
- **What:** Service monitoring — checks if your stuff is alive
- **Port:** 3001
- **Why:** Alerts you (email, Discord, Slack, etc.) when something goes down
- **Key concepts:**
  - **Monitor** = a check (HTTP ping, TCP port, Docker container)
  - **Heartbeat** = each check interval
  - **Status Page** = public page showing service status
- **When to touch it:** Add a monitor for every new service you deploy

### Netdata
- **What:** Real-time system monitoring (CPU, RAM, disk, network, per-container)
- **Port:** 19999
- **Why:** See exactly what's eating resources, spot problems before they crash things
- **Key concepts:**
  - **Charts** = live-updating graphs of every metric
  - **Alarms** = automatic warnings when things are out of range
  - **Container metrics** = per-container CPU/RAM/network usage
- **When to touch it:** When something feels slow, or just to check on the server

### Grafana
- **What:** Dashboard builder — makes pretty graphs from any data source
- **Port:** 3002
- **Why:** Long-term trends, custom dashboards, alerting
- **Default login:** admin / admin
- **Key concepts:**
  - **Dashboard** = a page of graphs/panels
  - **Data Source** = where the data comes from (Postgres, Prometheus, etc.)
  - **Panel** = a single graph/chart/table
- **When to touch it:** When you want custom dashboards or long-term metric history

### Homepage
- **What:** Dashboard — shows all your services as clickable tiles
- **Port:** 3000
- **Why:** One page to see everything running and jump to any service
- **Key concepts:**
  - **Auto-discovery** = reads Docker labels to find services
  - **Widgets** = shows live stats from services (container count, CPU, etc.)
- **When to touch it:** Mostly automatic — configure via its config files for custom layout

### Dozzle
- **What:** Live container log viewer
- **Port:** 8080
- **Why:** See logs from ALL containers in one browser tab, real-time
- **When to touch it:** When debugging — way easier than SSH + docker logs

---

## Databases & Storage

### Supabase (Self-Hosted)
- **What:** Backend-in-a-box — Postgres database + auth + auto-generated API + admin dashboard
- **Ports:** 8000 (Studio), 5432 (Postgres), 8100 (API gateway)
- **Containers:** 5 (db, auth, rest, studio, kong)
- **Why:** Full backend without writing backend code. Create tables in Studio, get an API automatically
- **Key concepts:**
  - **Studio** = web dashboard to manage tables, auth, storage
  - **PostgREST** = auto-generates a REST API from your database tables
  - **GoTrue** = handles user auth (signup, login, JWT tokens)
  - **Kong** = API gateway that ties the pieces together
  - **Row Level Security (RLS)** = database rules that control who can see/edit what
  - **Anon Key** = public API key (safe to expose, limited by RLS)
  - **Service Role Key** = admin API key (NEVER expose this)
- **Can run multiple instances:** Yes — one per project, different ports, separate data
- **When to touch it:** When a project needs a database + API + auth

### PostgreSQL
- **What:** Relational database (comes with Supabase, or standalone)
- **Port:** 5432
- **Why:** The most reliable, feature-rich open source database
- **Key concepts:**
  - **Database** = a collection of tables
  - **Schema** = namespace within a database (public, auth, storage, etc.)
  - **Table** = rows and columns of data
  - **Migration** = a versioned SQL change to the schema
- **When to touch it:** Through Supabase Studio or Adminer, rarely direct

### SurrealDB
- **What:** Multi-model database (relational + document + graph in one)
- **Port:** 8181
- **Default creds:** root / root (CHANGE THIS)
- **Why:** Flexible — can store structured data, documents, and graph relationships
- **Key concepts:**
  - **Namespace** = top-level container
  - **Database** = within a namespace
  - **Table** = within a database (schemaless by default)
  - **SurrealQL** = its query language (SQL-like but more flexible)
  - **Record links** = built-in graph relationships between records
- **When to touch it:** When you want a more flexible DB than pure Postgres

### Redis
- **What:** In-memory data store — ultra-fast cache and message queue
- **Port:** 6379 (Redis), 8082 (Redis Commander web UI)
- **Why:** Caching (speed up repeated queries), sessions (user login state), queues (background jobs)
- **Key concepts:**
  - **Key-Value** = store data as key:value pairs
  - **TTL** = time-to-live, data auto-expires
  - **Pub/Sub** = real-time messaging between services
  - **Maxmemory policy** = what happens when memory fills up (evicts least-recently-used by default)
- **When to touch it:** When an app needs caching, sessions, or a job queue

### MinIO
- **What:** S3-compatible object/file storage
- **Port:** 9000 (API), 9001 (console)
- **Default creds:** minioadmin / minioadmin (CHANGE THIS)
- **Why:** Self-hosted file uploads — images, documents, backups, any binary data
- **Key concepts:**
  - **Bucket** = a container for files (like a folder)
  - **Object** = a file stored in a bucket
  - **S3 API** = industry standard — any app that works with AWS S3 works with MinIO
  - **Presigned URL** = temporary link to download/upload a file
- **When to touch it:** When a project needs file upload/storage

---

## Developer Tools

### Adminer
- **What:** Lightweight database admin web UI
- **Port:** 8083
- **Why:** Quick way to browse, query, and edit any database (Postgres, MySQL, SQLite)
- **When to touch it:** When you need to look at or edit database tables directly

### n8n
- **What:** Workflow automation (self-hosted Zapier/Make)
- **Port:** 5678
- **Why:** Connect services together — when X happens, do Y
- **Key concepts:**
  - **Workflow** = a chain of triggers and actions
  - **Trigger** = what starts the workflow (webhook, schedule, event)
  - **Node** = a step in the workflow (HTTP request, database query, send email)
  - **Credentials** = stored API keys/passwords for services
- **Examples:** New GitHub issue → Slack message. Daily → backup check → email report
- **When to touch it:** When you want to automate repetitive tasks between services

### Mailpit
- **What:** Fake email server for development/testing
- **Port:** 8025 (web UI), 1025 (SMTP)
- **Why:** Point your app's email at localhost:1025 — Mailpit catches all outgoing emails so you can see them without actually sending anything
- **When to touch it:** When testing email functionality in any project

### LanguageTool
- **What:** Self-hosted grammar and spell checker
- **Port:** 8084
- **Why:** API for grammar checking — can integrate with apps, editors, or use standalone
- **Key concepts:**
  - **API endpoint** = POST to http://localhost:8084/v2/check with text
  - **Languages** = supports 30+ languages
- **When to touch it:** When you need grammar/spell checking in a project or for writing

### Wiki.js
- **What:** Self-hosted wiki / knowledge base
- **Port:** 3003
- **Why:** Document everything — server setup, project notes, runbooks, processes. Searchable, markdown support, visual editor
- **Key concepts:**
  - **Page** = a wiki article
  - **Navigation** = auto-generated sidebar from page structure
  - **Search** = full-text search across all pages
  - **Storage** = using SQLite (lightweight, no extra DB needed)
- **When to touch it:** To build your personal knowledge base about your server and projects

### Claude CLI + MCP
- **What:** Claude AI assistant running in your terminal with server awareness
- **Port:** None — terminal tool
- **Why:** Ask Claude to help debug, write scripts, manage files, all with direct access to your server
- **Key concepts:**
  - **MCP** = Model Context Protocol — lets Claude access tools (filesystem, docker, fetch)
  - **Filesystem MCP** = Claude can read/edit files in /srv/docker and /home
  - **Fetch MCP** = Claude can make HTTP requests to check services
- **When to touch it:** Anytime you need help — just type `claude`

---

## Server Tools (Linux)

These run directly on the OS, not in Docker.

### server-menu (command: `menu`)
- Interactive TUI command center
- Shows system stats (IP, uptime, memory, disk, container count)
- Quick access to all other tools and service URLs

### port-scan (command: `ports`)
- Scans all open ports on the server
- Matches each port to its Docker container
- Shows known service names
- Flags unknown/unassigned ports

### health-check (command: `health`)
- Checks every expected service is running
- Reports OK / DOWN for each
- Shows Docker engine status, container counts
- Warns on high disk/memory usage

### add-project (command: `add-project`)
- Guided wizard to deploy a new Docker project
- Asks for name, ports, database needs, subdomain
- Generates docker-compose.yml automatically
- Optionally starts the project and tells you next steps

### backup (command: `server-backup`)
- Backs up all Docker configs and volumes
- Stores in /srv/backups/ with date stamps
- Keeps 7 days, auto-deletes older
- Can run manually or via daily cron (3am)

### cheatsheet (command: `cheat`)
- Interactive Linux command reference
- Categories: files, system, networking, docker, disk, users, packages, logs
- Quick lookup when you forget a command

### Bash Aliases
| Alias | Command |
|-------|---------|
| `menu` | server-menu |
| `ports` | port-scan |
| `health` | health-check |
| `cheat` | cheatsheet |
| `dps` | docker ps (formatted table) |
| `dlogs NAME` | docker logs -f NAME |
| `dcu` | docker compose up -d |
| `dcd` | docker compose down |
| `dcr` | docker compose restart |
| `dcp` | docker compose pull + up |

---

## Networking Concepts

### How Traffic Flows
```
Internet User
    ↓
Cloudflare (DNS + CDN + DDoS protection)
    ↓
cloudflared tunnel (encrypted connection to your server)
    ↓
Nginx Proxy Manager (routes by domain name)
    ↓
Docker container (your app on its internal port)
```

### Docker Networking
- **proxy** network = shared network all public-facing containers join
- Containers on the same network can talk to each other BY NAME (e.g. `http://redis:6379`)
- Containers on different networks are isolated from each other
- Port mapping (`3000:3000`) exposes a container port to the host

### Key Networking Rules
1. Containers talk to each other using container names, not localhost
2. `localhost` inside a container means THAT container, not the host
3. To reach the host from a container, use `host.docker.internal`
4. If two containers need to talk, put them on the same Docker network

### DNS / Domain Setup
1. Buy a domain (Cloudflare, Namecheap, etc.)
2. Point nameservers to Cloudflare
3. In Cloudflare dashboard: create tunnel, add public hostnames
4. Each hostname points to `http://npm:80` (NPM handles the rest)
5. In NPM: create proxy host mapping that hostname to the right container

---

## Port Directory

| Port | Service | Type |
|------|---------|------|
| 22 | SSH | System |
| 80 | NPM (HTTP) | Infrastructure |
| 81 | NPM Admin | Infrastructure |
| 443 | NPM (HTTPS) | Infrastructure |
| 1025 | Mailpit SMTP | Dev Tool |
| 3000 | Homepage | Dashboard |
| 3001 | Uptime Kuma | Monitoring |
| 3002 | Grafana | Monitoring |
| 3003 | Wiki.js | Knowledge Base |
| 5432 | PostgreSQL | Database |
| 5678 | n8n | Automation |
| 6379 | Redis | Database |
| 8000 | Supabase Studio | Database |
| 8025 | Mailpit Web UI | Dev Tool |
| 8080 | Dozzle | Monitoring |
| 8082 | Redis Commander | Database |
| 8083 | Adminer | Database |
| 8084 | LanguageTool | Dev Tool |
| 8100 | Supabase Kong | Database |
| 8181 | SurrealDB | Database |
| 9000 | MinIO API | Storage |
| 9001 | MinIO Console | Storage |
| 9443 | Portainer | Infrastructure |
| 19999 | Netdata | Monitoring |

---

## Common Workflows

### "I want to deploy a new project"
1. Run `add-project` (or do it manually with a compose file)
2. Put compose file in `/srv/docker/projectname/`
3. `cd /srv/docker/projectname && docker compose up -d`
4. Add proxy host in NPM (port 81) → domain → container:port
5. Add public hostname in Cloudflare tunnel → http://npm:80
6. Add monitor in Uptime Kuma (port 3001)

### "Something is broken"
1. Run `health` — see what's down
2. Run `ports` — see what's listening
3. Check Dozzle (port 8080) for container logs
4. Check Netdata (port 19999) for resource problems
5. SSH in and run `docker logs containername` for details

### "I need to update everything"
1. System: `sudo apt update && sudo apt upgrade -y`
2. Containers: Watchtower does this automatically at 4am
3. Manual container update: `cd /srv/docker/service && docker compose pull && docker compose up -d`

### "I need to backup"
1. Manual: run `server-backup`
2. Automatic: already runs at 3am daily (if you set up cron)
3. Offsite: configure rclone to sync /srv/backups to cloud storage

### "I need a database for my project"
- **Option A:** Use existing shared Supabase (port 8000) — just create a new database
- **Option B:** Spin up a dedicated Supabase instance (copy compose, change ports)
- **Option C:** Use standalone Postgres (add to your project's compose file)
- **Option D:** Use SurrealDB (port 8181) if you want document/graph flexibility
- Browse any DB with Adminer (port 8083)

### "I want to automate something"
1. Open n8n (port 5678)
2. Create a workflow
3. Add trigger (schedule, webhook, event)
4. Add action nodes (HTTP, database, email, etc.)

---

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs containername

# Check if port is already in use
ss -tlnp | grep :PORT

# Check if image pulled correctly
docker images | grep imagename

# Remove and recreate
docker compose down && docker compose up -d
```

### Can't reach a service from browser
1. Is the container running? `docker ps | grep name`
2. Is the port mapped? `docker port containername`
3. Is the firewall allowing it? `sudo ufw status`
4. Is NPM configured? Check proxy hosts in NPM admin

### Out of disk space
```bash
# Check what's using space
ncdu /

# Clean Docker
docker system prune -a    # removes unused images/containers
docker volume prune        # removes unused volumes

# Check backup size
du -sh /srv/backups/*
```

### Out of memory
```bash
# Check what's using RAM
free -h
docker stats              # per-container RAM usage

# Stop non-essential containers
cd /srv/docker/servicename && docker compose down
```

### Cloudflare tunnel not working
1. Is cloudflared running? `docker ps | grep cloudflared`
2. Check logs: `docker logs cloudflared`
3. Is the token correct? Check /srv/docker/cloudflared/docker-compose.yml
4. Is the public hostname configured in Cloudflare dashboard?
5. Is it pointing to `http://npm:80`?

### SSH locked out
- Fail2ban might have blocked your IP
- From physical console: `sudo fail2ban-client set sshd unbanip YOUR_IP`
- Or: `sudo systemctl stop fail2ban` temporarily
