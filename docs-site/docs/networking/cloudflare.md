---
sidebar_position: 3
title: Cloudflare Guide
---

# Cloudflare Setup Guide

From zero to public access with SSL, DDoS protection, and authentication walls.

---

## Step 1 — Add Domain

1. Buy a domain (Cloudflare, Namecheap, wherever)
2. Log into [dash.cloudflare.com](https://dash.cloudflare.com)
3. Add a Site → enter your domain → Free plan
4. Update nameservers at your registrar to Cloudflare's
5. Wait for propagation (usually minutes, can take 24h)

## Step 2 — Create Tunnel

1. Go to [one.dash.cloudflare.com](https://one.dash.cloudflare.com) (Zero Trust)
2. Networks → Tunnels → Create
3. Name it (e.g., "home-server")
4. Copy the token
5. On your server:
```bash
sudo bash ~/server-kit/04-cloudflared-setup.sh
# Paste the token when asked
```

## Step 3 — Add Public Hostnames

In the tunnel config, add hostnames:

| Subdomain | Domain | Service |
|-----------|--------|---------|
| `app` | `yourdomain.com` | `http://npm:80` |
| `api` | `yourdomain.com` | `http://npm:80` |
| `admin` | `yourdomain.com` | `http://npm:80` |

Point everything at `http://npm:80` — NPM handles routing from there.

## Step 4 — Configure NPM Proxy Hosts

In NPM admin (`:81`):

| Domain | Forward To | Port |
|--------|-----------|------|
| `app.yourdomain.com` | `myapp` | `3000` |
| `api.yourdomain.com` | `supabase-kong` | `8000` |
| `admin.yourdomain.com` | `portainer` | `9443` |

---

## Security Features to Enable

### Cloudflare Access (login wall)

Put authentication in front of admin services:

1. Zero Trust → Access → Applications → Add
2. Self-Hosted → set domain
3. Add policy (allow specific emails)
4. Now that URL requires login before showing anything

**Put Access on:** Portainer, NPM admin, Netdata, Grafana, Adminer, Cockpit

### WAF (Web Application Firewall)

Security → WAF → Enable managed rules. Blocks known attack patterns.

### Bot Fight Mode

Security → Bots → ON. Blocks automated scrapers and bots.

### Rate Limiting

Security → WAF → Rate Limiting Rules. Prevent brute force on login pages.

---

## Multiple Domains

You can route multiple domains through the same tunnel:

1. Add both domains to Cloudflare
2. Add public hostnames for each
3. Add proxy hosts in NPM for each
4. One server, unlimited domains

---

## Tunnel Token Security

:::danger Keep your tunnel token secret
The tunnel token is in `/srv/docker/cloudflared/docker-compose.yml`. Never commit it to git. It's already in `.gitignore`.
:::
