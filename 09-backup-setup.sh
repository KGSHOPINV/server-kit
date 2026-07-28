#!/bin/bash
# ============================================================
# 09 - BACKUP SYSTEM
# Automated Docker volume + config backup with rotation
# ============================================================

set -e

echo "========================================"
echo "  09 - BACKUP SYSTEM SETUP"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Install backup script ---
echo "Installing backup script..."
sudo cp "$SCRIPT_DIR/tools/backup.sh" /usr/local/bin/server-backup
sudo chmod +x /usr/local/bin/server-backup

# --- Setup cron for daily backups ---
echo ""
read -p "Setup daily automatic backups at 3am? (y/n): " setup_cron
if [[ "$setup_cron" == "y" ]]; then
  (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/server-backup >> /var/log/server-backup.log 2>&1") | crontab -
  echo "Daily backup cron job added (3:00 AM)."
fi

# --- Setup backup compose (optional offsite with rclone) ---
echo ""
echo "Installing rclone for offsite backups (Google Drive, S3, etc.)..."
read -p "Install rclone? (y/n): " install_rclone
if [[ "$install_rclone" == "y" ]]; then
  curl https://rclone.org/install.sh | sudo bash
  echo ""
  echo "rclone installed. Configure with: rclone config"
  echo "Then add to backup script for offsite sync."
fi

echo ""
echo "========================================"
echo "  09 - BACKUP SYSTEM READY"
echo ""
echo "  Manual backup: server-backup"
echo "  Backup dir:    /srv/backups/"
echo "  Retention:     7 daily backups"
echo "========================================"
