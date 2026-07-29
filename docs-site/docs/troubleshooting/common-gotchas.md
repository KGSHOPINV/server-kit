---
sidebar_position: 4
title: Common Gotchas
---

# Common Gotchas

Things that trip people up. Learn from past mistakes.

---

## "Permission denied" when running scripts

**Wrong:**
```bash
./run-all.sh
chmod +x run-all.sh && ./run-all.sh
```

**Right:**
```bash
sudo bash run-all.sh
```

Always use `sudo bash`. Every script in this kit needs root.

---

## "docker: permission denied"

You need to be in the docker group, or use sudo:

```bash
# Option A: Add yourself to docker group (needs re-login)
sudo usermod -aG docker $USER
# Log out and back in

# Option B: Just use sudo
sudo docker ps
```

---

## "Port already in use"

Something else is already listening on that port.

```bash
# Find what's using it
ss -tlnp | grep :PORT

# If it's a Docker container, stop it or change the port
# If it's a system service, either stop it or use a different port for your container
```

**Example fix:** Dozzle defaulted to 8080 but something else was there. Changed to 8090:
```yaml
ports:
  - "8090:8080"    # was "8080:8080"
```

---

## "Network 'proxy' not found"

The shared Docker network needs to exist before containers can join it:

```bash
docker network create proxy
```

---

## Cloudflare tunnel token contains special characters

If pasting the token fails, try wrapping it in quotes in the compose file:

```yaml
command: tunnel run --token "your-token-here"
```

---

## AIDE scan takes forever

Normal. On a 1TB+ system, AIDE scans every file to build a baseline. Takes 10-20 minutes. Just wait.

---

## Services disappear after reboot

Check that the containers have `restart: always` in their compose files:

```yaml
services:
  myapp:
    restart: always    # ← this is crucial
```

And make sure Docker starts on boot:
```bash
sudo systemctl enable docker
```

---

## Can't reach services from another computer on the LAN

Check the firewall:
```bash
sudo ufw status
# If the port isn't listed:
sudo ufw allow PORT/tcp
```

---

## NPM shows "502 Bad Gateway"

The container NPM is trying to reach is down or on a different network.

```bash
# Is the target container running?
docker ps | grep CONTAINER_NAME

# Is it on the proxy network?
docker network inspect proxy | grep CONTAINER_NAME

# Check NPM logs
docker logs npm
```

---

## "localhost" doesn't work inside containers

Inside a container, `localhost` means **that container**, not your server.

Use **container names** instead:
```
http://redis:6379          ← RIGHT
http://localhost:6379      ← WRONG (from inside another container)
```

---

## Watchtower updated something and broke it

Roll back to the previous image:

```bash
# See what images are available locally
docker images | grep SERVICE_NAME

# Pin to a specific version in compose
image: nginx:1.25    # instead of nginx:latest

# Exclude from Watchtower
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```
