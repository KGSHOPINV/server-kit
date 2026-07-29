---
sidebar_position: 3
title: Monitoring
---

# Monitoring Services

How you know things are working (or not).

---

## Uptime Kuma

**What:** Service monitoring — checks if your stuff is alive and sends alerts when it's not.

**Port:** `:3001`

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Monitor** | A check — HTTP ping, TCP port, Docker container, or DNS |
| **Heartbeat** | Each check interval (default: every 60 seconds) |
| **Status Page** | Public page showing service status (share with others) |
| **Notification** | Alert channel — email, Discord, Slack, Telegram, webhook |

### What to Monitor

After install, add a monitor for every service you're running:

| Monitor Name | Type | Target |
|-------------|------|--------|
| NPM | HTTP | `http://npm:80` |
| Portainer | HTTP | `https://portainer:9443` |
| Supabase | HTTP | `http://supabase-studio:3000` |
| Your App | HTTP | `http://your-app:3000` |

### Commands

```bash
# Container name: uptime-kuma
docker logs uptime-kuma
docker restart uptime-kuma
```

---

## Netdata

**What:** Real-time system monitoring — CPU, RAM, disk, network, per-container metrics.

**Port:** `:19999`

### What You Can See

- **CPU usage** per core, per container
- **Memory** total and per container
- **Disk I/O** read/write speeds
- **Network** bandwidth in/out
- **Docker** container-level stats
- **Disk space** per mount
- **System load** and process count

### Built-in Alarms

Netdata has automatic warnings for:
- High CPU usage (sustained above 85%)
- Low memory (less than 15% free)
- Disk space running low (less than 10% free)
- High disk I/O
- Network interface errors

### Commands

```bash
# Container name: netdata
docker logs netdata
docker restart netdata
```

### When You Touch It
When something feels slow — open Netdata and see what's eating resources.

---

## Homepage

**What:** Dashboard — shows all your services as clickable tiles on one page.

**Port:** `:3000`

### How It Works

Homepage auto-discovers Docker containers and shows them as tiles. It reads Docker labels to find services.

### Customization

Config lives in the Homepage container. For custom layouts, edit the config files:
```bash
cd /srv/docker/homepage
docker exec homepage ls /app/config/
```

---

## Dozzle

**What:** Live container log viewer — see logs from ALL containers in one browser tab.

**Port:** `:8090`

### Why It's Better Than `docker logs`

- See **all** containers at once
- Filter, search, and highlight in real time
- No SSH needed — works from any browser
- Color-coded output

### Commands

```bash
# Container name: dozzle
docker logs dozzle
docker restart dozzle
```

### When You Touch It
When debugging — way easier than SSH + `docker logs container-name`.
