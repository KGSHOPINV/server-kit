---
sidebar_position: 2
title: Infrastructure
---

# Infrastructure Services

The backbone — these make everything else work.

---

## Nginx Proxy Manager (NPM)

**What:** Reverse proxy — routes incoming traffic to the right container based on domain name.

**Ports:** `:80` (HTTP), `:443` (HTTPS), `:81` (admin panel)

**Why you need it:** Without NPM, you'd access every service by IP:port (`192.168.1.50:3001`, `192.168.1.50:5678`). With NPM, you use domain names instead (`kuma.yourdomain.com`, `n8n.yourdomain.com`).

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Proxy Host** | A routing rule — domain → container:port |
| **SSL Certificate** | HTTPS encryption (NPM gets these from Let's Encrypt automatically) |
| **Access List** | Restrict who can access a service (IP whitelist, password) |

### Common Tasks

```bash
# Access NPM admin
http://YOUR-IP:81

# Container name: npm
docker logs npm           # check logs
docker restart npm        # restart it
```

### When You Touch It
Every time you add a new project that needs a public URL. Create a Proxy Host pointing the domain to the container.

---

## Cloudflare Tunnel (cloudflared)

**What:** Encrypted tunnel from your server to Cloudflare's network.

**Ports:** None exposed — it connects outbound only.

**Why you need it:** Your server doesn't need a public IP or open ports. The tunnel punches out to Cloudflare, and Cloudflare routes traffic back through it. Your real IP stays hidden.

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Tunnel** | The encrypted connection between your server and Cloudflare |
| **Token** | Authentication credential (from Cloudflare dashboard) |
| **Public Hostname** | A domain/subdomain routed through the tunnel |
| **Service** | What the hostname points to (usually `http://npm:80`) |

### Common Tasks

```bash
# Check if tunnel is running
docker ps | grep cloudflared

# Check tunnel logs
docker logs cloudflared

# Restart tunnel
docker restart cloudflared
```

### When You Touch It
When you need a new subdomain accessible from the internet. Add it in Cloudflare dashboard → Tunnels → Public Hostnames.

---

## Portainer

**What:** Web UI for managing Docker containers — visual alternative to the command line.

**Port:** `:9443` (HTTPS)

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Stack** | A group of containers (same as docker-compose) |
| **Volume** | Persistent data storage for a container |
| **Network** | How containers talk to each other |

### Common Tasks

```bash
# Access Portainer
https://YOUR-IP:9443

# Container name: portainer
docker logs portainer
docker restart portainer
```

### When You Touch It
When you want to manage containers without the command line — start/stop, view logs, manage volumes.

---

## Watchtower

**What:** Auto-updates Docker containers by pulling latest images and recreating them.

**Port:** None — runs in background.

**Schedule:** Runs at 4am daily.

### Excluding a Container

If you **don't** want a container auto-updated, add this label to its compose file:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

### Commands

```bash
# Check what Watchtower has updated
docker logs watchtower

# Force an update check now
docker exec watchtower /watchtower --run-once
```
