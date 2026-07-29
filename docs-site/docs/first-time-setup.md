---
sidebar_position: 2
title: First Time Setup
---

# First Time Setup

What to expect and know before running the installer.

---

## Before You Start

You need:
- A machine to install Linux on (mini PC, old laptop, desktop, dedicated server)
- A USB drive (8GB+) for the Ubuntu installer
- Network access (ethernet recommended) or a second USB to transfer the kit files
- **Optional:** A domain name and free Cloudflare account for public access

## The Golden Rule: `sudo bash`

Every script in this kit runs with:

```bash
sudo bash script-name.sh
```

**Not** `./script-name.sh`. **Not** `bash script-name.sh` without sudo.

Why? These scripts install system packages, configure firewall rules, write to `/srv/docker/`, create system services, and modify system configs. All of that needs root.

:::danger Don't use chmod +x
If you see "permission denied" when trying `./run-all.sh`, don't reach for `chmod`. Just use `sudo bash run-all.sh`. It works every time, no extra steps.
:::

## What the Installer Does (Step by Step)

| Step | Script | What It Does | Interactive? |
|------|--------|-------------|-------------|
| 1 | `01-system-setup.sh` | Updates OS, configures UFW firewall, hardens SSH, installs fail2ban | No |
| 2 | `02-docker-install.sh` | Installs Docker Engine + Compose, adds your user to docker group | No |
| 3 | `03-npm-setup.sh` | Deploys Nginx Proxy Manager (reverse proxy) | No |
| 4 | `04-cloudflared-setup.sh` | Sets up Cloudflare tunnel (asks for token, can skip) | Yes |
| 5 | `05-portainer-setup.sh` | Deploys Portainer (Docker web UI) | No |
| 6 | `06-monitoring-setup.sh` | Deploys Uptime Kuma + Netdata | No |
| 7 | `07-claude-cli-setup.sh` | Installs Node.js 22, Claude Code CLI, MCP config | No |
| 8 | `08-extras-setup.sh` | Asks about each optional service (Supabase, n8n, Redis, etc.) | Yes |
| 9 | `09-backup-setup.sh` | Installs backup script + daily cron, optional rclone for offsite | Yes |
| 10 | `10-linux-helper-setup.sh` | Installs all CLI tools, bash aliases, optional auto-menu | Yes |
| 11 | `11-hardware-monitor-setup.sh` | Installs lm-sensors, smartmontools, powertop, s-tui | No |
| 12 | `12-security-setup.sh` | Full security stack (CrowdSec, AIDE, Lynis, Trivy, auditd, etc.) | No |
| 13 | `13-github-deploy-setup.sh` | GitHub CLI, GHCR login, webhook receiver, deploy templates | Yes |
| 14 | `14-terminal-setup.sh` | Custom prompt, tmux config, login banner, dashboard | No |
| 15 | `15-server-console-setup.sh` | Cockpit web console, notification services (Discord/Slack/ntfy) | Yes |
| 16 | `16-ai-setup.sh` | Ollama + Open WebUI + OpenClaw, GPU detection, model picker | Yes |

## Resuming After Failure

The installer saves progress to `.install-progress`. If anything fails:

1. **Retry** — runs the failed script again
2. **Skip** — moves to the next script
3. **Stop** — saves progress, exit. Run `sudo bash run-all.sh` later to resume

You can also jump to any step when resuming.

## Running Individual Scripts

Don't need the full install? Run scripts individually:

```bash
cd ~/server-kit
sudo bash 08-extras-setup.sh    # just install extras
sudo bash 16-ai-setup.sh        # just install AI stack
```

## Folder Structure on Your Server

After install, your server looks like:

```
/srv/docker/               ← all Docker projects live here
├── npm/                   ← Nginx Proxy Manager
├── portainer/             ← Portainer
├── monitoring/            ← Uptime Kuma
├── netdata/               ← Netdata
├── homepage/              ← Homepage dashboard
├── dozzle/                ← Log viewer
├── cloudflared/           ← Cloudflare tunnel
├── supabase/              ← Supabase (if installed)
├── n8n/                   ← n8n (if installed)
├── ai/                    ← Ollama + Open WebUI (if installed)
├── openclaw/              ← OpenClaw (if installed)
└── your-projects/         ← your apps go here

/srv/backups/              ← automated backups land here
~/server-kit/              ← the kit itself (scripts, templates, docs)
```
