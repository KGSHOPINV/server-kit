---
sidebar_position: 1
title: Deploy a Project
---

# How Do I Deploy a Project?

Three ways, from simplest to fully automated.

---

## Option 1: Use the Wizard

```bash
add-project
```

It asks for name, ports, database needs, and generates everything.

## Option 2: Manual Deploy

```bash
# Create project directory
sudo mkdir -p /srv/docker/myproject
cd /srv/docker/myproject

# Create docker-compose.yml (or copy yours in)
sudo nano docker-compose.yml

# Start it
docker compose up -d

# Check it's running
docker ps | grep myproject
```

### Example docker-compose.yml

```yaml
services:
  myapp:
    image: node:20
    container_name: myapp
    restart: always
    ports:
      - "3100:3000"
    volumes:
      - ./app:/app
    working_dir: /app
    command: npm start
    networks:
      - proxy

networks:
  proxy:
    external: true
```

## Option 3: Deploy from GitHub

```bash
deploy
```

Pick "Deploy NEW" → enter the GitHub repo URL → it clones, sets up compose, and starts.

## After Deploying

1. **Check it's running:** `docker ps | grep myproject`
2. **Add to NPM** (if public): `http://YOUR-IP:81` → Proxy Hosts → add route
3. **Add to Cloudflare** (if internet-facing): Tunnel → Public Hostnames
4. **Add monitoring:** Uptime Kuma → add a monitor for the service
