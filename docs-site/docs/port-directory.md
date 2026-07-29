---
sidebar_position: 20
title: Port Directory
---

# Port Directory

Every port used by Server Kit, what's on it, and its category.

---

## Infrastructure

| Port | Service | Notes |
|------|---------|-------|
| `22` | SSH | System — remote access |
| `80` | NPM (HTTP) | Reverse proxy — incoming HTTP |
| `443` | NPM (HTTPS) | Reverse proxy — incoming HTTPS |
| `81` | NPM Admin | Web UI for managing proxy rules |
| `9443` | Portainer | Docker management web UI (HTTPS) |

## Monitoring

| Port | Service | Notes |
|------|---------|-------|
| `3000` | Homepage | Dashboard with service tiles |
| `3001` | Uptime Kuma | Service monitoring + alerts |
| `3002` | Grafana | Custom dashboards (if installed) |
| `8090` | Dozzle | Live container log viewer |
| `9090` | Cockpit | Web-based server console |
| `19999` | Netdata | Real-time system metrics |

## Databases & Storage

| Port | Service | Notes |
|------|---------|-------|
| `5432` | PostgreSQL | Relational database (with Supabase) |
| `6379` | Redis | In-memory cache/queue |
| `8000` | Supabase Studio | Database admin + API dashboard |
| `8082` | Redis Commander | Redis web UI |
| `8083` | Adminer | Lightweight DB browser |
| `8100` | Supabase Kong | API gateway |
| `8181` | SurrealDB | Multi-model database |
| `9000` | MinIO API | S3-compatible storage API |
| `9001` | MinIO Console | Storage web UI |

## Dev Tools

| Port | Service | Notes |
|------|---------|-------|
| `1025` | Mailpit SMTP | Fake email — SMTP endpoint |
| `3003` | Wiki.js | Knowledge base |
| `5678` | n8n | Workflow automation |
| `8025` | Mailpit Web | Fake email — view caught emails |
| `8084` | LanguageTool | Grammar/spell check API |

## AI

| Port | Service | Notes |
|------|---------|-------|
| `3004` | Open WebUI | ChatGPT-like interface |
| `3005` | OpenClaw | Autonomous AI agent |
| `11434` | Ollama API | AI model runner |

## Notifications

| Port | Service | Notes |
|------|---------|-------|
| `8085` | ntfy | Push notifications (if installed) |
| `8086` | Gotify | Push notifications (if installed) |

---

## Finding Port Conflicts

```bash
# Scan all listening ports with service info
ports

# Check a specific port
ss -tlnp | grep :PORT

# Find which Docker container uses a port
docker ps --filter "publish=PORT"
```
