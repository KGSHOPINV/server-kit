#!/bin/bash
# ============================================================
# LINUX CHEAT SHEET
# Quick reference for common commands
# ============================================================

show_section() {
  echo ""
  echo "  [$1]"
  echo "  ─────────────────────────────────────────────"
}

show_cheatsheet() {
  clear
  echo ""
  echo "=========================================="
  echo "  LINUX CHEAT SHEET"
  echo "=========================================="

  echo ""
  echo "  CATEGORIES:"
  echo "    1) Files & Navigation"
  echo "    2) System & Process"
  echo "    3) Networking"
  echo "    4) Docker"
  echo "    5) Disk & Storage"
  echo "    6) Users & Permissions"
  echo "    7) Package Management"
  echo "    8) Logs & Troubleshooting"
  echo "    9) Show all"
  echo "    0) Exit"
  echo ""
}

files_nav() {
  show_section "FILES & NAVIGATION"
  echo "  ls -la              List all files with details"
  echo "  cd /path            Change directory"
  echo "  pwd                 Print current directory"
  echo "  mkdir -p dir/sub    Create nested directories"
  echo "  cp -r src dest      Copy recursively"
  echo "  mv old new          Move / rename"
  echo "  rm -rf dir          Delete directory (careful!)"
  echo "  find / -name '*.log'  Find files by name"
  echo "  tree -L 2           Show directory tree"
  echo "  ncdu                Interactive disk usage"
  echo "  tail -f file        Follow file in real time"
  echo "  nano file           Edit file (simple)"
  echo "  vim file            Edit file (powerful)"
}

system_process() {
  show_section "SYSTEM & PROCESS"
  echo "  htop                Interactive process viewer"
  echo "  top                 Process list"
  echo "  ps aux              All running processes"
  echo "  kill PID            Kill a process"
  echo "  kill -9 PID         Force kill"
  echo "  systemctl status X  Check service status"
  echo "  systemctl restart X Restart a service"
  echo "  journalctl -u X     View service logs"
  echo "  uptime              System uptime"
  echo "  reboot              Restart system"
  echo "  shutdown now        Power off"
  echo "  uname -a            System info"
  echo "  lsb_release -a      OS version"
}

networking() {
  show_section "NETWORKING"
  echo "  ip a                Show IP addresses"
  echo "  ss -tlnp            Show listening ports"
  echo "  ping host           Test connectivity"
  echo "  curl url            Fetch a URL"
  echo "  wget url            Download a file"
  echo "  ufw status          Firewall status"
  echo "  ufw allow 8080      Open a port"
  echo "  ufw deny 8080       Block a port"
  echo "  ssh user@host       Connect to remote"
  echo "  scp file user@h:/p  Copy file to remote"
  echo "  nslookup domain     DNS lookup"
  echo "  traceroute host     Trace network path"
}

docker_cmds() {
  show_section "DOCKER"
  echo "  docker ps            Running containers"
  echo "  docker ps -a         All containers"
  echo "  docker images        List images"
  echo "  docker logs -f NAME  Follow container logs"
  echo "  docker exec -it NAME bash  Shell into container"
  echo "  docker compose up -d      Start services"
  echo "  docker compose down       Stop services"
  echo "  docker compose pull       Pull latest images"
  echo "  docker compose restart    Restart services"
  echo "  docker system prune -a    Clean everything unused"
  echo "  docker volume ls          List volumes"
  echo "  docker network ls         List networks"
  echo "  docker stats              Live resource usage"
  echo "  docker inspect NAME       Full container details"
}

disk_storage() {
  show_section "DISK & STORAGE"
  echo "  df -h               Disk space summary"
  echo "  du -sh /path        Folder size"
  echo "  ncdu /              Interactive disk usage"
  echo "  lsblk               List block devices"
  echo "  mount /dev/sdb1 /mnt  Mount a drive"
  echo "  umount /mnt         Unmount"
  echo "  fdisk -l            List partitions"
  echo "  docker system df    Docker disk usage"
}

users_perms() {
  show_section "USERS & PERMISSIONS"
  echo "  whoami              Current user"
  echo "  sudo command        Run as root"
  echo "  adduser name        Create user"
  echo "  usermod -aG grp usr Add user to group"
  echo "  chmod 755 file      Set permissions"
  echo "  chown user:grp file Change ownership"
  echo "  passwd              Change password"
}

packages() {
  show_section "PACKAGE MANAGEMENT"
  echo "  apt update          Refresh package list"
  echo "  apt upgrade         Upgrade all packages"
  echo "  apt install pkg     Install package"
  echo "  apt remove pkg      Remove package"
  echo "  apt search keyword  Search packages"
  echo "  apt autoremove      Clean unused packages"
}

logs_trouble() {
  show_section "LOGS & TROUBLESHOOTING"
  echo "  journalctl -xe      Recent system logs"
  echo "  dmesg               Kernel messages"
  echo "  tail -100 /var/log/syslog  Last 100 syslog lines"
  echo "  docker logs NAME    Container logs"
  echo "  systemctl status X  Service status"
  echo "  free -h             Memory usage"
  echo "  vmstat 1            Virtual memory stats"
  echo "  iostat              Disk I/O stats"
  echo "  netstat -tlnp       Ports (legacy)"
}

while true; do
  show_cheatsheet
  read -p "  Pick a category [0-9]: " choice

  case $choice in
    1) files_nav; echo ""; read -p "  Press Enter..." ;;
    2) system_process; echo ""; read -p "  Press Enter..." ;;
    3) networking; echo ""; read -p "  Press Enter..." ;;
    4) docker_cmds; echo ""; read -p "  Press Enter..." ;;
    5) disk_storage; echo ""; read -p "  Press Enter..." ;;
    6) users_perms; echo ""; read -p "  Press Enter..." ;;
    7) packages; echo ""; read -p "  Press Enter..." ;;
    8) logs_trouble; echo ""; read -p "  Press Enter..." ;;
    9)
      files_nav; system_process; networking; docker_cmds
      disk_storage; users_perms; packages; logs_trouble
      echo ""; read -p "  Press Enter..."
      ;;
    0) break ;;
    *) echo "  Invalid."; sleep 1 ;;
  esac
done
