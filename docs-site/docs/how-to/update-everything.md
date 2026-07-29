---
sidebar_position: 5
title: Update Everything
---

# How Do I Update Everything?

---

## Update the OS

```bash
sudo apt update && sudo apt upgrade -y
```

Security patches install automatically via unattended-upgrades. This command gets you everything else.

## Update Docker Containers

**Automatic:** Watchtower runs at 4am daily and updates all containers with `:latest` tags.

**Manual (one project):**
```bash
cd /srv/docker/PROJECT
docker compose pull
docker compose up -d
```

**Manual (all projects):**
```bash
for dir in /srv/docker/*/; do
  if [ -f "$dir/docker-compose.yml" ]; then
    echo "Updating $(basename $dir)..."
    cd "$dir"
    docker compose pull 2>/dev/null
    docker compose up -d 2>/dev/null
  fi
done
```

## Update Server Kit

```bash
kit-update
```

Pulls latest from GitHub, re-installs all CLI tools.

## Update AI Models

```bash
ai-models
# Pick option 2 → enter model name
# Or:
docker exec ollama ollama pull gemma4:12b
```
