#!/bin/bash
# storage-setup.sh — detect and optionally mount raw/unmounted drives
# Called by install.sh only when unmounted block devices are found.
# Fully portable — works on any server with any drives.

set -uo pipefail

BLU='\033[0;34m'; GRN='\033[0;32m'; YLW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

# Find all block devices that are:
# - Not a partition (type=disk)
# - Have no filesystem (no FSTYPE in lsblk)
# - Not already mounted
# - Not the boot/OS disk (skip the disk that contains /)

get_raw_disks() {
    # Get the disk containing /
    ROOT_DISK=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /) 2>/dev/null | head -1)
    [ -z "$ROOT_DISK" ] && ROOT_DISK=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' | xargs basename)

    # List disks with no filesystem, not the root disk
    lsblk -dpno NAME,SIZE,FSTYPE,TYPE | awk '$4=="disk" && $3==""' | while read -r name size fstype type; do
        basename_dev=$(basename "$name")
        [ "$basename_dev" = "$ROOT_DISK" ] && continue
        echo "$name $size"
    done
}

RAW_DISKS=$(get_raw_disks)

if [ -z "$RAW_DISKS" ]; then
    echo "No unmounted raw drives found — nothing to do."
    exit 0
fi

echo ""
echo -e "${BOLD}Unmounted drives detected:${NC}"
echo "$RAW_DISKS" | while read -r dev size; do
    echo "  $dev  ($size)"
done
echo ""

# For each raw disk, ask what to do
echo "$RAW_DISKS" | while IFS=' ' read -r DEV SIZE; do
    echo -e "${YLW}Drive: $DEV ($SIZE)${NC}"
    echo ""
    echo "  What do you want to do with this drive?"
    echo "  1) Mount as /data        (general purpose data)"
    echo "  2) Mount as /storage     (large file storage)"
    echo "  3) Mount as /srv/data    (Docker/service data)"
    echo "  4) Mount as /backup      (backup destination)"
    echo "  5) Custom mount point"
    echo "  6) Skip — leave it alone"
    echo ""
    read -rp "  Choice [1-6]: " CHOICE

    case "$CHOICE" in
        1) MOUNT_POINT="/data" ;;
        2) MOUNT_POINT="/storage" ;;
        3) MOUNT_POINT="/srv/data" ;;
        4) MOUNT_POINT="/backup" ;;
        5)
            read -rp "  Enter mount point (e.g. /mnt/drives/media): " MOUNT_POINT
            [ -z "$MOUNT_POINT" ] && echo "  Skipping." && continue
            ;;
        6|*)
            echo "  Skipping $DEV."
            continue
            ;;
    esac

    # Confirm before formatting
    echo ""
    echo -e "${RED}WARNING: This will format $DEV as ext4 and mount at $MOUNT_POINT${NC}"
    echo -e "${RED}ALL DATA ON $DEV WILL BE ERASED.${NC}"
    echo ""
    read -rp "  Type YES to confirm: " CONFIRM
    [ "$CONFIRM" != "YES" ] && echo "  Cancelled." && continue

    echo "  Formatting $DEV as ext4..."
    sudo mkfs.ext4 -L "$(basename $MOUNT_POINT)" "$DEV" 2>&1

    echo "  Creating mount point $MOUNT_POINT..."
    sudo mkdir -p "$MOUNT_POINT"

    # Get UUID for fstab (more reliable than device name)
    UUID=$(sudo blkid -s UUID -o value "$DEV")

    echo "  Adding to /etc/fstab (UUID=$UUID)..."
    echo "UUID=$UUID  $MOUNT_POINT  ext4  defaults,noatime  0  2" | sudo tee -a /etc/fstab

    echo "  Mounting..."
    sudo mount "$MOUNT_POINT"

    # Set permissions so the admin user owns it
    ADMIN="${ADMIN_USER:-$USER}"
    sudo chown "$ADMIN:$ADMIN" "$MOUNT_POINT"
    sudo chmod 755 "$MOUNT_POINT"

    echo -e "${GRN}  ✓ $DEV mounted at $MOUNT_POINT${NC}"
    echo ""
done

echo -e "${GRN}Storage setup complete.${NC}"
df -h | grep -E "^Filesystem|/data|/storage|/srv/data|/backup|/mnt" || true
