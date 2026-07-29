---
sidebar_position: 4
title: Backup & Restore
---

# How Do I Backup and Restore?

---

## Backup

### Manual Backup (right now)
```bash
server-backup
```

This creates a dated archive of everything in `/srv/docker/` and stores it in `/srv/backups/`.

### Automatic Backup
Already configured — runs daily at 3am via cron. Check:
```bash
crontab -l | grep backup
```

### What Gets Backed Up
- All Docker compose files
- All Docker volumes (your data)
- All config files in `/srv/docker/`

### Where Backups Go
```
/srv/backups/
├── backup-2026-07-29.tar.gz
├── backup-2026-07-28.tar.gz
└── ... (7-day retention, older auto-deleted)
```

### Offsite Backup (recommended)
Use rclone to sync backups to cloud storage:
```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure a remote (Google Drive, S3, Backblaze, etc.)
rclone config

# Sync backups
rclone sync /srv/backups/ remote:server-backups/
```

---

## Restore

### Restore Everything
```bash
cd /
sudo tar xzf /srv/backups/backup-2026-07-29.tar.gz
cd /srv/docker
# Restart all services
for dir in */; do
  cd "/srv/docker/$dir"
  docker compose up -d 2>/dev/null
  cd ..
done
```

### Restore a Single Project
```bash
# Extract just the project's files
sudo tar xzf /srv/backups/backup-2026-07-29.tar.gz srv/docker/myproject/

# Restart it
cd /srv/docker/myproject
docker compose up -d
```
