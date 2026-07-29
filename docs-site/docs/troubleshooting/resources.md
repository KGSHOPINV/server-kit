---
sidebar_position: 3
title: Resource Issues
---

# Troubleshooting — Disk, Memory, CPU

---

## Out of Disk Space

```bash
# Check disk usage
df -h

# Find what's using space
sudo du -sh /srv/docker/*/
sudo du -sh /var/log/
sudo du -sh /srv/backups/

# Clean Docker (biggest space saver)
docker system prune -a         # remove unused images/containers
docker volume prune            # remove unused volumes (careful!)

# Check backup size
du -sh /srv/backups/*

# Check Docker disk usage breakdown
docker system df
```

---

## Out of Memory

```bash
# Check memory
free -h

# Per-container memory usage
docker stats --no-stream

# Find the biggest consumers
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -h -r

# Stop non-essential containers to free RAM
cd /srv/docker/SERVICE && docker compose down

# If AI models are eating RAM — they unload after 5 min idle
# Or manually: switch to a smaller model
```

---

## High CPU Usage

```bash
# See what's using CPU
htop                           # interactive (q to quit)
docker stats                   # per-container

# Find the process
ps aux --sort=-%cpu | head -10
```

---

## Server Feels Slow

Run these in order:

```bash
# 1. Check resources
free -h                        # memory
df -h                          # disk
docker stats --no-stream       # per-container

# 2. Check if swap is being used heavily
free -h | grep Swap
# If swap is high → you need to stop some containers or add RAM

# 3. Check disk I/O
iostat -x 1 5                  # if available
# High %util → disk is the bottleneck

# 4. Check network
sudo iftop                     # bandwidth usage
```
