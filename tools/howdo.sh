#!/bin/bash
# ============================================================
# HOW DO I...
# Quick answers to common Linux/Docker/server questions
# Built-in knowledge base + Claude CLI fallback
# ============================================================

# Built-in answers for the most common questions
declare -A ANSWERS

# --- FILE OPERATIONS ---
ANSWERS["rename a file"]="mv oldname newname"
ANSWERS["copy a file"]="cp source destination
cp -r folder/ destination/    (recursive, for folders)"
ANSWERS["delete a file"]="rm filename
rm -rf foldername    (folder + contents, BE CAREFUL)"
ANSWERS["find a file"]="find / -name 'filename'
find /srv -name '*.yml'    (find all yml files in /srv)"
ANSWERS["edit a file"]="nano filename    (simple editor)
vim filename     (powerful editor)
Ctrl+X to save in nano"
ANSWERS["view a file"]="cat filename           (whole file)
head -20 filename      (first 20 lines)
tail -20 filename      (last 20 lines)
tail -f filename       (follow in real time)"
ANSWERS["create a folder"]="mkdir foldername
mkdir -p path/to/nested/folder"
ANSWERS["move a file"]="mv source destination
mv file.txt /srv/docker/"
ANSWERS["file permissions"]="chmod 755 file      (rwx r-x r-x)
chmod 644 file      (rw- r-- r--)
chmod +x file       (make executable)
chown user:group file   (change owner)"
ANSWERS["file size"]="du -sh filename        (single file/folder)
du -sh /srv/docker/*   (each subfolder)
ncdu /                 (interactive disk usage)"

# --- SYSTEM ---
ANSWERS["restart the server"]="sudo reboot"
ANSWERS["shut down"]="sudo shutdown now"
ANSWERS["check disk space"]="df -h                  (overview)
ncdu /                 (interactive)
du -sh /srv/docker/*   (per project)"
ANSWERS["check memory"]="free -h
htop    (interactive)"
ANSWERS["check cpu"]="htop
top
lscpu    (CPU info)"
ANSWERS["check temperature"]="sensors
s-tui    (interactive + stress test)"
ANSWERS["change hostname"]="sudo hostnamectl set-hostname new-name
sudo nano /etc/hosts    (update 127.0.0.1 line too)
sudo reboot"
ANSWERS["change timezone"]="sudo timedatectl set-timezone America/New_York
timedatectl list-timezones    (see all options)"
ANSWERS["change password"]="passwd                     (your password)
sudo passwd username       (another user's password)"
ANSWERS["add a user"]="sudo adduser newusername
sudo usermod -aG docker newusername    (give docker access)
sudo usermod -aG sudo newusername      (give sudo access)"
ANSWERS["check uptime"]="uptime -p"
ANSWERS["see who is logged in"]="who
w
last -10    (last 10 logins)"
ANSWERS["check os version"]="lsb_release -a
cat /etc/os-release"
ANSWERS["update the system"]="sudo apt update && sudo apt upgrade -y"
ANSWERS["install software"]="sudo apt install packagename
apt search keyword    (find packages)"
ANSWERS["check running processes"]="htop
ps aux
ps aux | grep processname"
ANSWERS["kill a process"]="kill PID
kill -9 PID    (force kill)
pkill processname"
ANSWERS["see system logs"]="journalctl -xe             (recent)
tail -100 /var/log/syslog  (syslog)
dmesg                      (kernel)"

# --- NETWORKING ---
ANSWERS["check my ip"]="hostname -I                (local IP)
curl ifconfig.me           (public IP)"
ANSWERS["check open ports"]="ports                      (server-kit tool)
ss -tlnp                   (raw)
sudo ufw status            (firewall rules)"
ANSWERS["open a port"]="sudo ufw allow PORT/tcp
sudo ufw reload"
ANSWERS["close a port"]="sudo ufw deny PORT/tcp
sudo ufw delete allow PORT/tcp"
ANSWERS["test connectivity"]="ping google.com
ping 192.168.1.1    (your router)"
ANSWERS["check dns"]="nslookup domain.com
dig domain.com"
ANSWERS["download a file"]="wget URL
curl -O URL"
ANSWERS["ssh to another server"]="ssh user@ip-address
ssh -p 2222 user@ip    (different port)"
ANSWERS["copy file to remote"]="scp file.txt user@ip:/path/
scp -r folder/ user@ip:/path/"
ANSWERS["mount a usb drive"]="lsblk                          (find the device)
sudo mount /dev/sdb1 /mnt      (mount it)
ls /mnt                        (see contents)
sudo umount /mnt               (unmount when done)"
ANSWERS["set static ip"]="sudo nano /etc/netplan/00-installer-config.yaml
# Change dhcp4: yes to:
#   dhcp4: no
#   addresses: [192.168.1.100/24]
#   gateway4: 192.168.1.1
#   nameservers:
#     addresses: [1.1.1.1, 8.8.8.8]
sudo netplan apply"

# --- DOCKER ---
ANSWERS["start a container"]="docker compose up -d
docker start containername"
ANSWERS["stop a container"]="docker compose down          (whole stack)
docker stop containername    (single container)"
ANSWERS["restart a container"]="docker compose restart
docker restart containername"
ANSWERS["see container logs"]="docker logs containername
docker logs -f containername    (follow live)
# Or use Dozzle: http://$(hostname -I | awk '{print $1}'):8090"
ANSWERS["shell into container"]="docker exec -it containername bash
docker exec -it containername sh    (if bash not available)"
ANSWERS["list containers"]="dps                            (alias)
docker ps                      (running)
docker ps -a                   (all including stopped)"
ANSWERS["remove a container"]="docker rm containername
docker compose down            (remove whole stack)"
ANSWERS["update a container"]="cd /srv/docker/servicename
docker compose pull
docker compose up -d"
ANSWERS["update all containers"]="Watchtower does this automatically at 4am.
Manual: go to each /srv/docker/X and run docker compose pull && docker compose up -d"
ANSWERS["clean docker"]="docker system prune -a         (remove unused images/containers)
docker volume prune            (remove unused volumes)
docker system df               (see disk usage)"
ANSWERS["check docker disk"]="docker system df"
ANSWERS["see container resources"]="docker stats"

# --- SECURITY ---
ANSWERS["check security"]="sec                            (server-kit tool)
sudo lynis audit system        (full audit)"
ANSWERS["see banned ips"]="sudo fail2ban-client status sshd"
ANSWERS["unban an ip"]="sudo fail2ban-client set sshd unbanip IP_ADDRESS"
ANSWERS["ban an ip"]="sudo fail2ban-client set sshd banip IP_ADDRESS
sudo ufw deny from IP_ADDRESS"
ANSWERS["check for attacks"]="sec
sudo fail2ban-client status
sudo cscli alerts list
grep 'Failed password' /var/log/auth.log | tail -20"
ANSWERS["scan for rootkits"]="sudo rkhunter --check"
ANSWERS["check file integrity"]="sudo aide --check"

# --- SERVER KIT ---
ANSWERS["update server kit"]="kit-update"
ANSWERS["add a project"]="add-project"
ANSWERS["deploy from github"]="deploy"
ANSWERS["backup everything"]="server-backup"
ANSWERS["check all services"]="health"
ANSWERS["see all servers"]="kit-servers"
ANSWERS["open the menu"]="menu"

# ============================================================
# SEARCH FUNCTION
# ============================================================

search() {
  local query=$(echo "$*" | tr '[:upper:]' '[:lower:]')
  local found=0

  echo ""
  echo "  Results for: \"$*\""
  echo "  ─────────────────────────────────────"

  for key in "${!ANSWERS[@]}"; do
    if echo "$key" | grep -qi "$query"; then
      echo ""
      echo "  Q: How do I $key?"
      echo ""
      echo "${ANSWERS[$key]}" | while read -r line; do
        echo "    $line"
      done
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    # Try partial word matching
    for key in "${!ANSWERS[@]}"; do
      for word in $query; do
        if echo "$key" | grep -qi "$word"; then
          echo ""
          echo "  Q: How do I $key?"
          echo ""
          echo "${ANSWERS[$key]}" | while read -r line; do
            echo "    $line"
          done
          found=1
          break
        fi
      done
    done
  fi

  if [ "$found" -eq 0 ]; then
    echo ""
    echo "  No built-in answer found."
    echo ""
    echo "  Options:"
    echo "    - Try different words"
    echo "    - Type 'claude' to ask Claude CLI"
    echo "    - Type 'list' to see all available topics"
  fi
  echo ""
}

list_topics() {
  echo ""
  echo "  AVAILABLE TOPICS"
  echo "  ─────────────────────────────────────"
  echo ""
  echo "  Files:"
  for key in "${!ANSWERS[@]}"; do
    echo "$key"
  done | grep -iE "file|folder|copy|move|delete|rename|edit|view|permission|size" | sort | while read -r topic; do
    echo "    $topic"
  done
  echo ""
  echo "  System:"
  for key in "${!ANSWERS[@]}"; do
    echo "$key"
  done | grep -iE "restart|shut|disk|memory|cpu|temp|hostname|timezone|password|user|uptime|logged|os|update|install|process|kill|log" | sort | while read -r topic; do
    echo "    $topic"
  done
  echo ""
  echo "  Networking:"
  for key in "${!ANSWERS[@]}"; do
    echo "$key"
  done | grep -iE "ip|port|connect|dns|download|ssh|mount|static|remote" | sort | while read -r topic; do
    echo "    $topic"
  done
  echo ""
  echo "  Docker:"
  for key in "${!ANSWERS[@]}"; do
    echo "$key"
  done | grep -iE "container|docker|shell|start|stop|restart|update|clean|resource" | sort | while read -r topic; do
    echo "    $topic"
  done
  echo ""
  echo "  Security:"
  for key in "${!ANSWERS[@]}"; do
    echo "$key"
  done | grep -iE "security|ban|attack|rootkit|integrity" | sort | while read -r topic; do
    echo "    $topic"
  done
  echo ""
  echo "  Server Kit:"
  for key in "${!ANSWERS[@]}"; do
    echo "$key"
  done | grep -iE "server kit|project|deploy|backup|services|servers|menu" | sort | while read -r topic; do
    echo "    $topic"
  done
  echo ""
}

# ============================================================
# MAIN
# ============================================================

if [ -n "$*" ]; then
  # Called with arguments: howdo mount usb
  search "$@"
  exit 0
fi

# Interactive mode
echo ""
echo "=========================================="
echo "  HOW DO I..."
echo "=========================================="
echo ""
echo "  Type a question (or 'list' for topics, 'q' to quit)"
echo ""

while true; do
  read -p "  how do I... " question
  case "$question" in
    q|quit|exit) break ;;
    list) list_topics ;;
    "") echo "  Type something, or 'list' to see topics." ;;
    *) search "$question" ;;
  esac
done
