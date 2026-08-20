#!/bin/bash
# alert-disk.sh — disk usage alert
# Runs via cron. Alerts at WARN threshold, urgent at CRIT.
# Distro-agnostic: df is POSIX standard

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/notify.sh"

DISK_WARN="${DISK_WARN:-85}"
DISK_CRIT="${DISK_CRIT:-92}"
[ -f "$HOME/.server-alerts.conf" ] && source "$HOME/.server-alerts.conf"

HOST=$(hostname -s 2>/dev/null || echo "server")

# Check all real mounts (skip docker overlay, tmpfs, devtmpfs)
ALERTED=0

while IFS= read -r line; do
  PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
  MOUNT=$(echo "$line" | awk '{print $6}')
  USED=$(echo "$line" | awk '{print $3}')
  AVAIL=$(echo "$line" | awk '{print $4}')
  SIZE=$(echo "$line" | awk '{print $2}')

  [ -z "$PCT" ] || [ "$PCT" = "Use%" ] && continue

  if [ "$PCT" -ge "$DISK_CRIT" ] 2>/dev/null; then
    notify \
      "🔴 Disk CRITICAL on $HOST" \
      "Mount: $MOUNT
Usage: ${PCT}% used (${USED} / ${SIZE})
Free:  $AVAIL

Action needed — clean up or expand storage." \
      "urgent" \
      "rotating_light,disk"
    ALERTED=1

  elif [ "$PCT" -ge "$DISK_WARN" ] 2>/dev/null; then
    notify \
      "🟡 Disk warning on $HOST" \
      "Mount: $MOUNT
Usage: ${PCT}% used (${USED} / ${SIZE})
Free:  $AVAIL

Getting full — worth a look." \
      "high" \
      "warning,disk"
    ALERTED=1
  fi

done < <(df -h 2>/dev/null | grep -Ev '^(Filesystem|tmpfs|devtmpfs|overlay|udev|shm|/dev/loop)' | grep -v '/docker/')

exit 0
