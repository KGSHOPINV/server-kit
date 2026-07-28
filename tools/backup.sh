#!/bin/bash
# ============================================================
# BACKUP SCRIPT
# Backs up all Docker volumes and compose configs
# Keeps 7 days of backups
# ============================================================

BACKUP_DIR="/srv/backups"
DOCKER_DIR="/srv/docker"
DATE=$(date +%Y-%m-%d_%H%M)
BACKUP_PATH="$BACKUP_DIR/$DATE"
RETENTION_DAYS=7

echo ""
echo "=========================================="
echo "  BACKUP - $DATE"
echo "=========================================="

mkdir -p "$BACKUP_PATH"

# --- Backup all compose directories (configs) ---
echo ""
echo "Backing up Docker configs..."
for dir in "$DOCKER_DIR"/*/; do
  project=$(basename "$dir")
  tar -czf "$BACKUP_PATH/${project}-config.tar.gz" -C "$DOCKER_DIR" "$project" 2>/dev/null
  echo "  Config: $project"
done

# --- Backup Docker volumes ---
echo ""
echo "Backing up Docker volumes..."
for volume in $(docker volume ls -q 2>/dev/null); do
  echo "  Volume: $volume"
  docker run --rm \
    -v "$volume":/source:ro \
    -v "$BACKUP_PATH":/backup \
    alpine tar -czf "/backup/vol-${volume}.tar.gz" -C /source . 2>/dev/null
done

# --- Cleanup old backups ---
echo ""
echo "Cleaning backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
REMOVED=$?

# --- Summary ---
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" 2>/dev/null | awk '{print $1}')
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')

echo ""
echo "=========================================="
echo "  BACKUP COMPLETE"
echo ""
echo "  Location: $BACKUP_PATH"
echo "  Size:     $BACKUP_SIZE"
echo "  Total:    $TOTAL_SIZE (all backups)"
echo "  Retention: $RETENTION_DAYS days"
echo "=========================================="
