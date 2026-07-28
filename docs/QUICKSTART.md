# Quickstart

## Before You Start

You need:
- A machine to install Linux on (mini PC, old laptop, desktop)
- A USB drive (8GB+) for Ubuntu installer
- A second USB or network access to get the server-kit files onto the machine
- (Optional) A domain name and Cloudflare account for public access

## Step 1 — Install Ubuntu

1. Download Ubuntu Server 24.04 LTS from ubuntu.com
2. Flash ISO to USB using Rufus (Windows) or Balena Etcher (any OS)
3. Boot the target machine from USB
4. Follow the installer:
   - Language, keyboard, network (use DHCP)
   - Use entire disk
   - Set your username and password
   - Enable OpenSSH server
   - Skip featured snaps
5. Reboot, remove USB

## Step 2 — Get Server Kit Onto the Machine

Option A — Clone from GitHub:
```bash
sudo apt install git -y
git clone https://github.com/KGSHOPINV/server-kit.git ~/server-kit
```

Option B — Copy from USB:
```bash
sudo mount /dev/sdb1 /mnt
cp -r /mnt/server-kit ~/server-kit
sudo umount /mnt
```

## Step 3 — Run Setup

```bash
cd ~/server-kit
chmod +x run-all.sh
./run-all.sh
```

Follow the prompts. It will:
1. Update the system and configure firewall
2. Install Docker
3. Deploy core services (NPM, monitoring, etc.)
4. Ask which extras you want (Supabase, n8n, SurrealDB, etc.)
5. Set up backup system
6. Install server menu and tools

## Step 4 — You're Done

Type `menu` to open the command center.

See MASTER-REFERENCE.md for details on every service.
