---
sidebar_position: 9
title: Storage, RAID & Backup Strategy
---

# Storage, RAID & Backup Strategy

How Linux sees your disks, how RAID works, and where backups should actually go.

---

## How Linux Sees Storage

```
Physical Disks         /dev/sda, /dev/sdb, /dev/sdc
       │
       ▼
RAID (optional)        Combines disks → /dev/md0 (one virtual disk)
       │
       ▼
Partitions             /dev/md0p1 (slices of the disk)
       │
       ▼
Filesystem             ext4, xfs, btrfs (how files are organized)
       │
       ▼
Mount Point            /, /srv, /mnt/storage (where it appears in folders)
```

Docker doesn't know or care about RAID — it just sees folders. If your RAID is mounted at `/mnt/storage`, anything you put there is on the RAID.

## Check What You Have

```bash
# See all disks and partitions
lsblk

# See filesystems and mount points
lsblk -f

# See disk usage
df -h

# Check RAID status
cat /proc/mdstat

# Detailed RAID info
sudo mdadm --detail /dev/md0
```

### Reading `lsblk` Output

```
NAME    SIZE  MOUNTPOINT
sda     1TB
├─sda1  512M  /boot
└─sda2  999G  /
sdb     4TB
sdc     4TB
md0     4TB                ← RAID array from sdb + sdc
└─md0p1 4TB   /mnt/storage ← mounted here
```

### Reading RAID Status

```bash
cat /proc/mdstat
# md0 : active raid1 sdb[0] sdc[1]
#       3906886656 blocks [2/2] [UU]
#                                ^^
#                          [UU] = both disks healthy
#                          [U_] = one disk FAILED
```

---

## RAID Levels

| Level | How It Works | Disks | Capacity Lost | If a Disk Dies |
|-------|-------------|-------|---------------|----------------|
| **RAID 0** | Splits data across disks (fast, no safety) | 2+ | None | **Everything gone** |
| **RAID 1** | Mirror — exact copy on each disk | 2 | 50% | Fine, swap the disk |
| **RAID 5** | Striped + 1 parity disk | 3+ | 1 disk worth | Survives 1 failure |
| **RAID 6** | Striped + 2 parity disks | 4+ | 2 disks worth | Survives 2 failures |
| **RAID 10** | Mirrors + stripes combined | 4+ | 50% | Survives 1 per pair |

**For a Docker server:** RAID 1 (2 disks, simple mirror) or RAID 5 (3+ disks) are the smart picks. Never use RAID 0 for a server.

:::danger RAID is NOT a backup
RAID protects against a disk dying. It does NOT protect against accidental deletion, ransomware, bad updates, fire, or theft. You still need backups.
:::

---

## Typical Server Layout: 1TB OS + 4TB RAID

### The Wrong Way

```
OS Disk (1TB)
├── /                        System
├── /var/lib/docker/          Docker images + layers
├── /srv/docker/              Compose configs
├── /srv/backups/             Backups ← SAME DISK AS EVERYTHING ELSE
└── (Ollama models, DB data)  All on the OS disk too
```

Problems:
- OS disk dies → configs AND backups both gone
- 1TB fills up fast (Docker images + AI models + backups + OS)
- RAID sitting there unused for the important stuff

### The Right Way

```
OS Disk (1TB)                    RAID (4TB)
─────────────                    ──────────
/              System            /mnt/storage/
/var/lib/docker  Images/layers   ├── backups/       Backup archives
/srv/docker/     Compose configs ├── docker-data/    Large volumes
                                 │   ├── ollama/     AI models (2-20GB each)
                                 │   ├── minio/      File uploads
                                 │   ├── postgres/   Database data
                                 │   └── supabase/   Supabase volumes
                                 └── media/          Anything big
```

### Setting This Up

**Move backups to RAID:**
```bash
# Create backup dir on RAID
sudo mkdir -p /mnt/storage/backups

# Replace the old backup dir with a symlink
sudo rm -rf /srv/backups
sudo ln -s /mnt/storage/backups /srv/backups

# Now server-backup writes to the RAID automatically
```

**Move large Docker volumes to RAID:**

Edit the compose file to mount from the RAID:

```yaml
# Before (on OS disk):
volumes:
  - ollama-data:/root/.ollama

# After (on RAID):
volumes:
  - /mnt/storage/docker-data/ollama:/root/.ollama
```

Do this for any service with big data: Ollama, MinIO, PostgreSQL, Supabase.

**Create the directories:**
```bash
sudo mkdir -p /mnt/storage/docker-data/{ollama,minio,postgres,supabase}
```

---

## Backup Strategy

### Three Layers of Protection

| Layer | What It Does | Protects Against |
|-------|-------------|-----------------|
| **RAID** | Mirrors your storage disk | Single disk failure |
| **Local backup** (on RAID) | Daily archive of configs + volumes | Accidental deletion, bad updates, container corruption |
| **Offsite backup** (cloud) | Copy of backups to cloud storage | Fire, theft, ransomware, total hardware failure |

### How Big Are Backups?

| What | Typical Size |
|------|-------------|
| All compose files + configs | 10–50 MB |
| Supabase database | 100 MB – 5 GB |
| Redis data | 10–100 MB |
| Ollama models | 2–20 GB per model |
| MinIO files | Depends on uploads |
| Full `/srv/docker/` archive | 500 MB – 10 GB (without models/media) |

With 7-day retention: **3–70 GB** of backup space. Trivial on a 4TB RAID.

### Backup Flow

```
Daily 3am:
  server-backup
    → archives /srv/docker/ configs + volumes
    → writes to /srv/backups/ (symlinked to RAID)
    → deletes archives older than 7 days

Weekly (optional):
  rclone sync /srv/backups/ remote:server-backups/
    → copies to Google Drive / Backblaze B2 / S3
```

### Setting Up Offsite Backup

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure a remote (interactive wizard)
rclone config
# Pick your provider: Google Drive, Backblaze B2, S3, etc.

# Test it
rclone ls remote:

# Sync backups
rclone sync /srv/backups/ remote:server-backups/

# Automate weekly
(crontab -l; echo '0 4 * * 0 rclone sync /srv/backups/ remote:server-backups/') | crontab -
```

### What to Exclude from Backups

Large, re-downloadable data doesn't need backing up:

```bash
# Docker images — can be re-pulled
# Ollama models — can be re-downloaded
# Log files — not critical

# Only backup:
# - Compose files (your configuration)
# - Database volumes (your data)
# - .env files (your secrets)
# - Config files (your settings)
```

---

## Monitoring Disk Health

```bash
# Quick check (server-kit tool)
hw

# SMART status for a specific disk
sudo smartctl -a /dev/sda
sudo smartctl -a /dev/sdb

# Key things to look for:
# - Reallocated_Sector_Ct > 0    → disk is degrading
# - Current_Pending_Sector > 0   → bad sectors forming
# - Temperature > 50°C           → too hot
# - Power_On_Hours > 40000       → getting old (5+ years)

# RAID health
cat /proc/mdstat
# [UU] = healthy
# [U_] = one disk failed — replace ASAP
```

---

## If a RAID Disk Fails

```bash
# 1. Check which disk failed
cat /proc/mdstat
sudo mdadm --detail /dev/md0

# 2. Remove the failed disk
sudo mdadm --remove /dev/md0 /dev/sdc

# 3. Physically replace the disk

# 4. Add the new disk
sudo mdadm --add /dev/md0 /dev/sde

# 5. Watch the rebuild (can take hours on large arrays)
watch cat /proc/mdstat
```

:::warning Don't wait
If a RAID 1 disk fails, you're running on ONE disk with NO redundancy. Replace immediately. If the second disk fails before rebuild, everything is gone.
:::

---

## Quick Reference

```bash
lsblk                         # see all disks
df -h                          # disk usage
cat /proc/mdstat               # RAID status
sudo smartctl -a /dev/sda      # disk health
sudo mdadm --detail /dev/md0   # RAID details
hw                             # server-kit hardware check
```
