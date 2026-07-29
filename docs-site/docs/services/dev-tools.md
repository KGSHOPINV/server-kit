---
sidebar_position: 5
title: Dev Tools
---

# Developer Tools

Services that help you build, automate, and debug.

---

## n8n — Workflow Automation

**What:** Self-hosted Zapier/Make — connect services together with visual workflows.

**Port:** `:5678`

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Workflow** | A chain of triggers and actions |
| **Trigger** | What starts it — webhook, schedule, event |
| **Node** | A step — HTTP request, database query, send message |
| **Credentials** | Stored API keys for services |

### Example Workflows

- New GitHub issue → Slack message
- Daily 6am → check all services → email report
- Webhook → process data → insert into Supabase
- Form submit → send email → add to spreadsheet

### Commands

```bash
docker logs n8n
docker restart n8n
```

---

## Adminer

**What:** Lightweight database admin web UI — browse, query, edit any database.

**Port:** `:8083`

### Connecting to Databases

| Database | Server | Username | Password |
|----------|--------|----------|----------|
| Supabase Postgres | `supabase-db` | `postgres` | (from .env) |
| SurrealDB | Use Surrealist instead | — | — |

Just open `http://YOUR-IP:8083`, pick PostgreSQL, enter the connection info.

---

## Mailpit

**What:** Fake email server for development — catches all outgoing email so you can inspect it without actually sending anything.

**Ports:** `:8025` (web UI), `:1025` (SMTP)

### How to Use

Point your app's email config at:
```
SMTP_HOST=mailpit
SMTP_PORT=1025
```

Then check `http://YOUR-IP:8025` to see every email your app tried to send.

---

## Wiki.js

**What:** Self-hosted wiki / knowledge base with visual editor and full-text search.

**Port:** `:3003`

### Good For

- Documenting your server setup
- Project notes and runbooks
- Internal team knowledge base
- Anything you'd put in Notion/Confluence

---

## LanguageTool

**What:** Self-hosted grammar and spell checker — API-based.

**Port:** `:8084`

### API Usage

```bash
curl -X POST http://localhost:8084/v2/check \
  -d "text=This is a test sentnce." \
  -d "language=en-US"
```

Returns JSON with spelling/grammar suggestions.

---

## Claude CLI + MCP

**What:** Claude AI assistant running in your terminal with server awareness.

**Port:** None — terminal tool

### How to Use

```bash
claude
```

### MCP (Model Context Protocol)

MCP gives Claude access to tools on your server:

| MCP Server | What It Does |
|-----------|--------------|
| **Filesystem** | Claude can read/edit files in `/srv/docker` and `/home` |
| **Fetch** | Claude can make HTTP requests to check services |

### When to Use

Anytime you need help — debugging, writing scripts, managing configs, understanding errors.

---

## Cockpit

**What:** Web-based server management console — terminal, logs, networking, storage, all in the browser.

**Port:** `:9090`

**Login:** Your Linux username and password

### What You Can Do

- Terminal in the browser
- View system logs
- Manage networking
- Monitor storage/disks
- Manage services (systemd)
- See performance graphs

### When to Use

When you want a web-based alternative to SSH. Especially useful from a phone or tablet.
