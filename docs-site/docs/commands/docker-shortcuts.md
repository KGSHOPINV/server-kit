---
sidebar_position: 3
title: Docker Shortcuts
---

# Docker Shortcuts

Everything you need to manage containers, organized by task.

---

## Daily Operations

```bash
# What's running?
dps                          # clean formatted table
docker ps                    # full output
docker ps -a                 # include stopped containers

# Start/Stop/Restart a container
docker start NAME
docker stop NAME
docker restart NAME

# Start/Stop/Restart a project (from its directory)
cd /srv/docker/PROJECT
dcu                          # docker compose up -d
dcd                          # docker compose down
dcr                          # docker compose restart

# Update a project
cd /srv/docker/PROJECT
dcp                          # pull latest + restart
```

---

## Logs

```bash
# View logs
docker logs NAME                    # all logs
docker logs -f NAME                 # follow (live)
docker logs --tail 100 NAME         # last 100 lines
docker logs --since 1h NAME         # last hour only
dlogs NAME                          # alias: docker logs -f

# Or use Dozzle (web UI)
http://YOUR-IP:8090
```

---

## Debugging a Container

```bash
# Shell into a running container
docker exec -it NAME bash
docker exec -it NAME sh       # if bash not available

# Run a one-off command inside a container
docker exec NAME cat /etc/hostname
docker exec NAME ls /app

# Check environment variables
docker exec NAME env

# Check what image a container is using
docker inspect NAME | grep Image

# Check container's IP address
docker inspect NAME | grep IPAddress

# Check container resource usage
docker stats NAME --no-stream
docker stats                   # all containers (live)
```

---

## Managing Images

```bash
# List images
docker images

# Pull latest version
docker pull IMAGE:TAG

# Remove an image
docker rmi IMAGE:TAG

# Remove ALL unused images (frees disk space)
docker image prune -a
```

---

## Docker Compose Reference

Always run these from the project directory (`cd /srv/docker/PROJECT`):

```bash
docker compose up -d           # start in background
docker compose down            # stop and remove containers
docker compose restart         # restart all containers
docker compose pull            # pull latest images
docker compose logs -f         # follow all logs
docker compose ps              # status of this project's containers
docker compose exec NAME bash  # shell into a specific service
```

---

## Cleanup (Free Disk Space)

```bash
# Remove stopped containers, unused networks, dangling images
docker system prune

# Remove EVERYTHING unused (images, containers, volumes)
docker system prune -a

# Remove unused volumes (careful — this deletes data)
docker volume prune

# Check what's using space
docker system df
```

:::danger Be careful with volume prune
`docker volume prune` deletes data from stopped containers. Make sure you have backups before running this.
:::

---

## Networking

```bash
# List networks
docker network ls

# Inspect a network (see who's on it)
docker network inspect proxy

# Create a network
docker network create my-network

# Connect a container to a network
docker network connect proxy CONTAINER_NAME
```

### Key Rule
Containers on the same Docker network can reach each other **by container name**:
```
http://ollama:11434     # from any container on the proxy network
http://redis:6379       # from any container on the proxy network
```
