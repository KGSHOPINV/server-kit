---
sidebar_position: 3
title: First Login Checklist
---

# First Login Checklist

You ran the installer. Everything is up. Now what?

This is your post-install walkthrough — the things you should do the first time you log in.

---

## 1. Check Everything Is Running

```bash
health
```

This scans every service and shows OK / DOWN. If anything is down, it tells you the port and container name.

## 2. Change Default Passwords

These services ship with default credentials. **Change them immediately.**

| Service | URL | Default Login | Change Where |
|---------|-----|---------------|-------------|
| NPM Admin | `http://YOUR-IP:81` | `admin@example.com` / `changeme` | Settings in web UI |
| Portainer | `https://YOUR-IP:9443` | Create on first visit | First-time setup screen |
| Grafana | `http://YOUR-IP:3002` | `admin` / `admin` | Settings in web UI |
| SurrealDB | `http://YOUR-IP:8181` | `root` / `root` | Environment variable |
| MinIO | `http://YOUR-IP:9001` | `minioadmin` / `minioadmin` | Environment variable |

:::tip Tracking password changes
After changing a password, mark it done so `whats-next` knows:
```bash
sudo touch /srv/docker/npm/.password-changed
sudo touch /srv/docker/portainer/.admin-created
```
:::

## 3. Set a Static IP

Your router probably gave your server an IP via DHCP. That can change after a reboot.

**Option A — DHCP Reservation (easier):**
Log into your router, find the server's MAC address, and assign it a permanent IP.

**Option B — Static IP on the server:**
```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Once done:
```bash
sudo touch /srv/docker/.static-ip-confirmed
```

## 4. Set Up Cloudflare Tunnel (if you skipped it)

If you want your services accessible from the internet:

1. Create a free [Cloudflare account](https://cloudflare.com)
2. Add your domain, point nameservers to Cloudflare
3. Go to Zero Trust → Tunnels → Create a tunnel
4. Copy the token
5. Run:
```bash
sudo bash ~/server-kit/04-cloudflared-setup.sh
```

See the [Cloudflare Guide](/networking/cloudflare) for full details.

## 5. Add Uptime Monitors

Open Uptime Kuma at `http://YOUR-IP:3001` and add a monitor for each running service. This way you get alerted if anything goes down.

## 6. Run Your First Backup

```bash
server-backup
```

This backs up all Docker configs and volumes to `/srv/backups/`. The daily cron runs at 3am automatically if you enabled it.

## 7. Check Security

```bash
sec
```

This shows firewall status, fail2ban bans, SSH config, active connections, and Docker security. Make sure everything looks right.

## 8. Explore Your Tools

```bash
menu           # command center — start here
whats-next     # what still needs doing
howdo          # search for how to do anything
essentials     # the only commands you need to know
cheat          # full linux cheat sheet
```

## 9. Learn the Server Kit Commands

See the [Quick Reference](/commands/quick-reference) for every command and alias installed by the kit.

---

## The "Oh Shit" Commands

Things you'll need at some point:

| Situation | Command |
|-----------|---------|
| Something is down | `health` |
| What's on what port | `ports` |
| Am I being attacked | `sec` |
| Container is broken | `docker logs CONTAINER_NAME` |
| Restart a container | `docker restart CONTAINER_NAME` |
| Full restart of a project | `cd /srv/docker/NAME && docker compose down && docker compose up -d` |
| Out of disk space | `docker system prune -a` |
| Out of memory | `docker stats` (find the hog) |
| Locked out of SSH | Physical access → `sudo fail2ban-client set sshd unbanip YOUR_IP` |
| Everything is broken | `sudo reboot` |
