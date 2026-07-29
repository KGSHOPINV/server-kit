---
sidebar_position: 4
title: Linux Essentials
---

# Linux Essentials

If you're new to Linux, this is your survival guide.

---

## The 8 Golden Rules

1. **If you don't know what it does, don't run it**
2. **`sudo` means you're running as GOD** — be careful with it
3. **`rm -rf` deletes forever** — there is no recycle bin
4. **Tab key is your best friend** — auto-completes everything
5. **Up arrow** shows your last command
6. **Ctrl+C** stops anything
7. **When in doubt:** `health`, `sec`, `ports`
8. **If it's really broken:** `sudo reboot`

---

## Navigation

```bash
ls                    # what's in this folder
ls -la                # everything, including hidden files
cd /path/to/folder    # go somewhere
cd ..                 # go up one level
cd ~                  # go to your home directory
cd -                  # go back to previous directory
pwd                   # print where you are
```

---

## Files

```bash
cat file.txt          # read a file
nano file.txt         # edit a file (Ctrl+O save, Ctrl+X exit)
cp file1 file2        # copy a file
cp -r dir1 dir2       # copy a directory
mv file1 file2        # move or rename
rm file               # delete a file (PERMANENT)
rm -r folder          # delete a folder (PERMANENT)
mkdir new-folder      # create folder
touch newfile.txt     # create empty file
```

---

## Searching

```bash
# Find a file by name
find / -name "docker-compose.yml" 2>/dev/null

# Search inside files
grep "error" /var/log/syslog
grep -r "password" /srv/docker/    # search recursively

# Search command history
history | grep "docker"
Ctrl+R                              # interactive search
```

---

## System Info

```bash
free -h               # memory usage
df -h                 # disk usage
htop                  # interactive process viewer (q to quit)
uptime                # how long the server has been running
whoami                # what user am I
hostname -I           # server's IP address
uname -a              # OS and kernel info
lsb_release -a        # Ubuntu version
```

---

## Package Management (apt)

```bash
sudo apt update                    # refresh package list
sudo apt upgrade -y                # install all updates
sudo apt install PACKAGE           # install something
sudo apt remove PACKAGE            # remove something
sudo apt autoremove                # clean up unused packages
apt list --installed | grep NAME   # check if something is installed
```

---

## Users & Permissions

```bash
sudo command              # run as root
sudo -i                   # become root (exit to leave)
chmod +x script.sh        # make a file executable
chown user:group file     # change ownership
passwd                    # change your password
```

---

## Networking

```bash
ip a                      # show IP addresses
ping google.com           # test internet
curl http://localhost:81   # test a web service
ss -tlnp                  # show listening ports
wget URL                  # download a file
```

---

## Logs

```bash
# System log
sudo tail -50 /var/log/syslog
sudo journalctl -xe                   # recent system events

# Auth log (SSH logins, sudo usage)
sudo tail -50 /var/log/auth.log

# Follow a log in real time
sudo tail -f /var/log/syslog
```

---

## Processes

```bash
ps aux                    # list all processes
ps aux | grep NAME        # find a specific process
kill PID                  # stop a process (graceful)
kill -9 PID               # force kill a process
```

---

## Useful Tricks

```bash
# Run last command with sudo
sudo !!

# Repeat last command
!!

# Clear the screen
clear    # or Ctrl+L

# See how big a folder is
du -sh /srv/docker/

# Pipe output to search
docker ps | grep npm
cat /var/log/auth.log | grep Failed

# Redirect output to a file
command > output.txt        # overwrite
command >> output.txt       # append
command 2>&1 > output.txt   # include errors
```
