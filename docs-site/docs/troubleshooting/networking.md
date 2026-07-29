---
sidebar_position: 2
title: Networking Issues
---

# Troubleshooting — Networking

---

## Can't Reach a Service from Browser

**Check in order:**

1. **Is the container running?**
```bash
docker ps | grep CONTAINER_NAME
```

2. **Is the port mapped?**
```bash
docker port CONTAINER_NAME
```

3. **Is the port listening on the host?**
```bash
ss -tlnp | grep :PORT
```

4. **Is the firewall allowing it?**
```bash
sudo ufw status | grep PORT
# If not listed, add it:
sudo ufw allow PORT/tcp
```

5. **Can you reach it locally?**
```bash
curl http://localhost:PORT
```

6. **Is NPM configured? (for domain access)**
Check proxy hosts at `http://YOUR-IP:81`

---

## Cloudflare Tunnel Not Working

```bash
# Is cloudflared running?
docker ps | grep cloudflared

# Check logs
docker logs cloudflared

# Is the token correct?
cat /srv/docker/cloudflared/docker-compose.yml | grep token

# Restart
docker restart cloudflared
```

**Common issues:**
- Token is wrong or expired → get a new one from Cloudflare dashboard
- Public hostname not configured → add it in Cloudflare → Tunnels → Public Hostnames
- Service points to wrong target → should be `http://npm:80` for most things

---

## Containers Can't Talk to Each Other

```bash
# Are they on the same network?
docker network inspect proxy | grep -A2 CONTAINER_A
docker network inspect proxy | grep -A2 CONTAINER_B

# Connect a container to the proxy network
docker network connect proxy CONTAINER_NAME
```

**Remember:** Use **container names**, not `localhost`:
```yaml
# WRONG
DATABASE_URL=http://localhost:5432

# RIGHT
DATABASE_URL=http://supabase-db:5432
```

---

## Port Conflict

```bash
# Find what's using a port
ss -tlnp | grep :PORT
# or
ports    # the server-kit tool shows everything

# Change the port in the compose file
cd /srv/docker/PROJECT
nano docker-compose.yml
# Change "8080:8080" to "8090:8080"
docker compose down && docker compose up -d
```

---

## DNS Not Resolving

```bash
# Test DNS
nslookup yourdomain.com
dig yourdomain.com

# Check if Cloudflare nameservers are set
# Go to your domain registrar and verify
```
