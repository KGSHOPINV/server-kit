---
sidebar_position: 21
title: Setup Scripts
---

# Setup Scripts Reference

What each script does, so you can run them individually.

---

## Running Individual Scripts

```bash
cd ~/server-kit
sudo bash SCRIPT_NAME.sh
```

---

## Script Breakdown

| Script | What It Does |
|--------|-------------|
| `01-system-setup.sh` | OS updates, UFW firewall (opens ports 22/80/443/81 + service ports), SSH hardening (disable root login), fail2ban install, timezone to UTC, creates `/srv/docker` and `/srv/backups` |
| `02-docker-install.sh` | Installs Docker Engine + Docker Compose plugin, adds your user to docker group, enables Docker on boot |
| `03-npm-setup.sh` | Deploys Nginx Proxy Manager — creates the `proxy` Docker network, starts NPM on ports 80/443/81 |
| `04-cloudflared-setup.sh` | Asks for Cloudflare tunnel token (can skip), deploys cloudflared container |
| `05-portainer-setup.sh` | Deploys Portainer CE on port 9443 |
| `06-monitoring-setup.sh` | Deploys Uptime Kuma (3001) + Netdata (19999) |
| `07-claude-cli-setup.sh` | Installs Node.js 22 via NodeSource, installs Claude Code CLI globally, writes MCP config for filesystem + fetch access |
| `08-extras-setup.sh` | Interactive — asks about each: Redis, Redis Commander, MinIO, Supabase, n8n, SurrealDB, Adminer, Grafana, Mailpit, Wiki.js, LanguageTool, Watchtower, Homepage, Dozzle |
| `09-backup-setup.sh` | Installs backup script to `/usr/local/bin/server-backup`, sets up daily cron at 3am, optionally installs rclone for offsite backups |
| `10-linux-helper-setup.sh` | Installs all CLI tools from `tools/` to `/usr/local/bin`, adds bash aliases (`dps`, `dlogs`, `dcu`, `dcd`, `dcr`, `dcp`, `menu`, `health`, etc.), optionally adds auto-menu on SSH login |
| `11-hardware-monitor-setup.sh` | Installs lm-sensors (CPU temps), smartmontools (disk health), powertop (power), s-tui (stress test/monitoring) |
| `12-security-setup.sh` | Fail2Ban custom config (SSH jails), CrowdSec install, rkhunter, Lynis, AIDE (file integrity baseline), Docker Bench Security, Trivy (container scanning), auditd (system audit logging), unattended-upgrades, iftop, nethogs, nmap |
| `13-github-deploy-setup.sh` | GitHub CLI install + auth, GHCR Docker login, webhook receiver container, deploy templates (Dockerfile, compose, GitHub Actions workflow) |
| `14-terminal-setup.sh` | Custom bash prompt (shows user@host, git branch, path), tmux config + dashboard layout, MOTD login banner, `essentials` one-screen reference |
| `15-server-console-setup.sh` | Cockpit web console (9090), ntfy/Gotify notification services, Discord/Slack webhook alerts, auto-alert cron (every 15 min checks services) |
| `16-ai-setup.sh` | Hardware detection (RAM, GPU), NVIDIA Container Toolkit (if GPU), Ollama + Open WebUI (3004), OpenClaw (3005), model picker, `ai-models` CLI tool |

---

## `run-all.sh` — Master Installer

Runs all scripts in order with:
- Auto-sudo (re-runs itself with `sudo` if needed)
- Progress tracking (`.install-progress` file)
- Resume from failure
- Retry / Skip / Stop on errors
- Step picker (jump to any step)

```bash
sudo bash run-all.sh
```
