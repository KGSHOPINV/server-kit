---
slug: /
sidebar_position: 1
title: Quick Start
---

# Server Kit

Your complete self-hosted server infrastructure — from bare metal to production in one script.

**What this is:** A collection of setup scripts, Docker compose files, CLI tools, and documentation that turns a fresh Ubuntu install into a fully configured server with reverse proxy, monitoring, security, backups, AI, and more.

**What this is NOT:** This doesn't deploy your projects. It builds the infrastructure your projects run on.

---

## 4-Step Install

### 1. Install Ubuntu Server 24.04 LTS

1. Download from [ubuntu.com](https://ubuntu.com/download/server)
2. Flash ISO to USB with [Rufus](https://rufus.ie) (Windows) or [Balena Etcher](https://etcher.balena.io) (any OS)
3. Boot target machine from USB
4. Follow installer — use entire disk, set username/password, enable OpenSSH
5. Reboot, remove USB

### 2. Get Server Kit

**Option A — Clone from GitHub:**
```bash
sudo apt install git -y
git clone https://github.com/KGSHOPINV/server-kit.git ~/server-kit
```

**Option B — Copy from USB:**
```bash
sudo mount /dev/sdb1 /mnt
cp -r /mnt/server-kit ~/server-kit
sudo umount /mnt
```

### 3. Run Setup

```bash
cd ~/server-kit
sudo bash run-all.sh
```

:::tip Important — use `sudo bash`
Don't use `chmod +x` then `./run-all.sh`. Always use **`sudo bash run-all.sh`**. This ensures root permissions for Docker, firewall rules, and system configs. Every script in this kit should be run with `sudo bash`.
:::

Follow the prompts. It will:
1. Update the system and configure firewall
2. Install Docker
3. Deploy core services (NPM, Portainer, monitoring)
4. Ask which extras you want (Supabase, n8n, SurrealDB, etc.)
5. Set up security, backups, terminal tools
6. Optionally install local AI (Ollama + Open WebUI)

**The installer tracks progress.** If it fails or you need to stop, just run `sudo bash run-all.sh` again — it picks up where you left off.

### 4. You're Done

```bash
menu
```

That opens the command center. From there you can check health, scan ports, deploy projects, and manage everything.

---

## What Gets Installed

| Category | Services |
|----------|----------|
| **Infrastructure** | Nginx Proxy Manager, Cloudflare Tunnel, Portainer, Watchtower |
| **Monitoring** | Uptime Kuma, Netdata, Homepage, Dozzle |
| **Databases** | PostgreSQL, Supabase, SurrealDB, Redis, MinIO |
| **Dev Tools** | n8n, Adminer, Mailpit, Wiki.js, LanguageTool, Claude CLI |
| **AI** | Ollama, Open WebUI, OpenClaw |
| **Security** | Fail2Ban, CrowdSec, AIDE, rkhunter, Lynis, Trivy, auditd |
| **Server Tools** | 16+ custom CLI commands, tmux dashboard, cheatsheet |

Everything is optional. The setup asks before installing each piece.
