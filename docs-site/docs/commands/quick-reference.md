---
sidebar_position: 1
title: Quick Reference
---

# Quick Reference

Every command and shortcut installed by Server Kit — on one page.

---

## Server Kit Commands

These are custom tools installed to `/usr/local/bin/`. Run them from anywhere.

| Command | What It Does |
|---------|-------------|
| `menu` | Open the command center (18-option interactive menu) |
| `health` | Check all services — shows OK / DOWN for each |
| `ports` | Scan all open ports, match to Docker containers |
| `sec` | Security status — firewall, bans, SSH, connections |
| `hw` | Hardware monitor — CPU temps, disk SMART, memory, power |
| `whats-next` | Context-aware checklist — scans your server and tells you what to do |
| `howdo` | Built-in search engine — 60+ answers for Linux/Docker/server questions |
| `essentials` | One-screen summary of the only commands you need to know |
| `cheat` | Interactive Linux cheat sheet by category |
| `add-project` | Guided wizard to create a new Docker project |
| `deploy` | Deploy or update a project from GitHub |
| `server-backup` | Run a backup now (all Docker configs + volumes) |
| `ai-models` | Manage AI models (list, pull, remove, chat) |
| `kit-update` | Update server-kit from GitHub |
| `kit-servers` | Show all registered servers (multi-server management) |
| `server-register` | Register this server to the shared registry |
| `kit-sync` | Sync server registry via git/SSH |
| `dash` | Open tmux dashboard layout |

---

## Docker Aliases

Shorthand for common Docker commands. Type these anywhere.

| Alias | Expands To | What It Does |
|-------|-----------|-------------|
| `dps` | `docker ps --format ...` | Container status table (clean format) |
| `dlogs NAME` | `docker logs -f NAME` | Follow a container's logs |
| `dcu` | `docker compose up -d` | Start containers in current directory |
| `dcd` | `docker compose down` | Stop containers in current directory |
| `dcr` | `docker compose restart` | Restart containers |
| `dcp` | `docker compose pull && up -d` | Pull latest images + restart |

---

## Essential Linux Commands

The stuff you actually use daily.

### Moving Around

| Command | What It Does |
|---------|-------------|
| `ls` | What's in this folder |
| `ls -la` | Everything including hidden files, with details |
| `cd /path` | Go to a folder |
| `cd ..` | Go up one level |
| `cd ~` | Go home |
| `pwd` | Where am I? |

### Files

| Command | What It Does |
|---------|-------------|
| `cat file` | Print a file |
| `nano file` | Edit a file (Ctrl+O save, Ctrl+X exit) |
| `cp file1 file2` | Copy |
| `mv file1 file2` | Move or rename |
| `rm file` | Delete a file (**no recycle bin**) |
| `mkdir folder` | Create a folder |

### System

| Command | What It Does |
|---------|-------------|
| `free -h` | Memory usage |
| `df -h` | Disk usage |
| `htop` | Interactive process viewer |
| `sudo reboot` | Restart the server |
| `sudo shutdown now` | Power off |

### Keyboard Shortcuts

| Key | What It Does |
|-----|-------------|
| `Tab` | Auto-complete — **use this constantly** |
| `Up Arrow` | Previous command |
| `Ctrl+C` | Stop whatever is running |
| `Ctrl+R` | Search command history |
| `Ctrl+L` | Clear screen |

---

## Docker Commands You Need

```bash
# See what's running
docker ps

# See ALL containers (including stopped)
docker ps -a

# View logs
docker logs CONTAINER_NAME
docker logs -f CONTAINER_NAME     # follow (live)
docker logs --tail 50 CONTAINER_NAME  # last 50 lines

# Start / Stop / Restart
docker start CONTAINER_NAME
docker stop CONTAINER_NAME
docker restart CONTAINER_NAME

# Shell into a running container
docker exec -it CONTAINER_NAME bash
docker exec -it CONTAINER_NAME sh    # if bash isn't available

# Using docker compose (run from the project directory)
docker compose up -d          # start
docker compose down           # stop
docker compose restart        # restart
docker compose pull           # pull latest images
docker compose logs -f        # follow logs

# Cleanup
docker system prune -a        # remove unused images/containers
docker volume prune           # remove unused volumes

# Stats
docker stats                  # live resource usage per container
docker system df              # disk usage by Docker
```
