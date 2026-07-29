---
sidebar_position: 2
title: Docker Networking
---

# Docker Networking

How containers talk to each other and to the outside world.

---

## The `proxy` Network

All public-facing containers join the `proxy` network. This is created during setup.

```bash
# See all containers on the proxy network
docker network inspect proxy
```

### The Key Rule

Containers on the same network reach each other **by container name**:

```
http://ollama:11434        ← from Open WebUI
http://redis:6379          ← from your app
http://supabase-db:5432    ← from your app
http://npm:80              ← from cloudflared
```

**NOT** `localhost` — that means "myself" inside a container.

### Common Mistake

```yaml
# WRONG — localhost means the container itself
OLLAMA_URL=http://localhost:11434

# RIGHT — use the container name
OLLAMA_URL=http://ollama:11434
```

## Port Mapping

```yaml
ports:
  - "3100:3000"
#    ▲       ▲
#    │       └── container's internal port
#    └────────── port exposed on the host
```

- `http://SERVER-IP:3100` → reaches the container
- Other containers use `http://containername:3000` (internal port)

## Creating Isolated Networks

If two projects shouldn't talk to each other:

```yaml
# Project A
networks:
  project-a:
    driver: bridge

# Project B
networks:
  project-b:
    driver: bridge
```

Containers on `project-a` can't reach containers on `project-b`.

## Reaching the Host from a Container

```
http://host.docker.internal
```

This resolves to the host machine's IP from inside a container.
