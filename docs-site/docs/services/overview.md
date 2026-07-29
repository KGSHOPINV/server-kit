---
sidebar_position: 1
title: Service Overview
---

# Service Overview

Everything running on your server at a glance.

---

## Quick Glance Card

> **Bookmark this page.** When you forget what's what, come back here.

| Service | Port | What It Is (1 sentence) | Default Login |
|---------|------|------------------------|---------------|
| **NPM** | `:81` | Routes traffic to the right container by domain name | `admin@example.com` / `changeme` |
| **Portainer** | `:9443` | Web UI to manage Docker containers | Create on first visit |
| **Uptime Kuma** | `:3001` | Monitors if your stuff is alive, sends alerts | Create on first visit |
| **Netdata** | `:19999` | Real-time CPU/RAM/disk/network graphs | None |
| **Homepage** | `:3000` | Dashboard with clickable tiles for all services | None |
| **Dozzle** | `:8090` | Live container log viewer in the browser | None |
| **Supabase** | `:8000` | Database + auth + API in a box | Set in `.env` |
| **SurrealDB** | `:8181` | Flexible multi-model database | `root` / `root` |
| **Redis** | `:6379` | Ultra-fast cache and message queue | None |
| **MinIO** | `:9001` | Self-hosted file storage (S3-compatible) | `minioadmin` / `minioadmin` |
| **n8n** | `:5678` | Workflow automation (self-hosted Zapier) | Create on first visit |
| **Adminer** | `:8083` | Lightweight database browser | Uses DB credentials |
| **Grafana** | `:3002` | Custom dashboards and graphs | `admin` / `admin` |
| **Wiki.js** | `:3003` | Self-hosted wiki / knowledge base | Create on first visit |
| **Mailpit** | `:8025` | Fake email server for testing | None |
| **LanguageTool** | `:8084` | Grammar/spell check API | None |
| **Cockpit** | `:9090` | Web-based server management console | Your Linux login |
| **Open WebUI** | `:3004` | ChatGPT-like interface for local AI models | Create on first visit |
| **Ollama** | `:11434` | Runs AI models locally (API) | None |
| **OpenClaw** | `:3005` | Autonomous AI agent | Create on first visit |

:::tip Remember
All URLs are `http://YOUR-SERVER-IP:PORT` — replace with your actual server IP. Run `hostname -I` to find it.
:::

---

## How They Connect

```
INTERNET
   │
   │  (Cloudflare Tunnel — encrypted, no open ports)
   ▼
┌──────────────┐
│  cloudflared  │
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│  NPM (Nginx Proxy Mgr)   │  ← Routes by domain name
│  :80 / :443 / :81         │
└──────┬───────────────────┘
       │
       ├──→ your-app.com       → App Container
       ├──→ api.your-site.com  → Supabase
       ├──→ admin.your-site.com→ Portainer
       └──→ anything.your.com  → Any Container
```

Every request from the internet: **User → Cloudflare → cloudflared → NPM → your service**

All containers share the `proxy` Docker network, so they can reach each other by container name.
