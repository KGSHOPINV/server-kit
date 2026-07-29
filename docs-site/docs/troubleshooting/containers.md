---
sidebar_position: 1
title: Container Issues
---

# Troubleshooting — Containers

---

## Container Won't Start

```bash
# Check the logs — this tells you WHY
docker logs CONTAINER_NAME

# Check if the port is already in use
ss -tlnp | grep :PORT

# Check if the image pulled correctly
docker images | grep IMAGE_NAME

# Nuclear fix — remove and recreate
cd /srv/docker/PROJECT
docker compose down
docker compose pull
docker compose up -d
```

### Common Causes

| Error | Fix |
|-------|-----|
| "port already in use" | Another container or process is on that port. Change the port in compose or stop the conflicting service. |
| "image not found" | Check the image name in compose. Run `docker compose pull`. |
| "permission denied" | Use `sudo` or add yourself to docker group: `sudo usermod -aG docker $USER` |
| "network not found" | Create the proxy network: `docker network create proxy` |
| Exits immediately | Check logs: `docker logs CONTAINER_NAME`. Usually a config issue. |

---

## Container is Running But Not Responding

```bash
# Is it actually healthy?
docker ps | grep CONTAINER_NAME

# Can you reach it from the host?
curl http://localhost:PORT

# Is it on the right network?
docker network inspect proxy | grep CONTAINER_NAME

# Restart it
docker restart CONTAINER_NAME
```

---

## Container Using Too Much RAM

```bash
# Check per-container usage
docker stats

# Find the hog
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -h

# Stop non-essential containers
cd /srv/docker/SERVICE && docker compose down
```

---

## Container Keeps Restarting

```bash
# Check the restart count
docker inspect CONTAINER_NAME | grep RestartCount

# Check logs for the crash reason
docker logs --tail 50 CONTAINER_NAME

# Temporarily stop restarts to investigate
docker update --restart=no CONTAINER_NAME
docker stop CONTAINER_NAME
# Fix the issue, then:
docker update --restart=always CONTAINER_NAME
docker start CONTAINER_NAME
```
