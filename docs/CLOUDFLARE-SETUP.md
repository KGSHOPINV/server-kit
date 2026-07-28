# Cloudflare Setup

## Prerequisites

1. A domain name (buy one at Cloudflare, Namecheap, etc.)
2. A Cloudflare account (free tier works)
3. Domain nameservers pointed to Cloudflare

## Step 1 — Add Domain to Cloudflare

1. Log into dash.cloudflare.com
2. Add a Site → enter your domain
3. Select Free plan
4. Cloudflare gives you nameservers (e.g. ada.ns.cloudflare.com)
5. Go to your domain registrar → update nameservers to Cloudflare's
6. Wait for DNS propagation (can take up to 24 hours, usually minutes)

## Step 2 — Create a Tunnel

1. Go to one.dash.cloudflare.com (Zero Trust dashboard)
2. Networks → Tunnels
3. Create a tunnel
4. Name it (e.g. "home-server")
5. Copy the tunnel token
6. Run the setup script: `./04-cloudflared-setup.sh`
7. Paste the token when prompted

## Step 3 — Add Public Hostnames

In the tunnel config (Cloudflare dashboard):

| Subdomain | Domain | Service |
|-----------|--------|---------|
| app1 | yourdomain.com | http://npm:80 |
| app2 | yourdomain.com | http://npm:80 |
| portainer | yourdomain.com | https://portainer:9443 |

Point everything at NPM (http://npm:80) and let NPM handle the routing.

Exception: services with their own HTTPS (like Portainer) can be pointed at directly.

## Step 4 — Configure NPM

In NPM admin (port 81), create Proxy Hosts:

| Domain | Forward Host | Forward Port | SSL |
|--------|-------------|-------------|-----|
| app1.yourdomain.com | app1-container | 3000 | Cloudflare handles it |
| app2.yourdomain.com | app2-container | 3100 | Cloudflare handles it |

When using Cloudflare tunnel, NPM doesn't need to do SSL — Cloudflare handles the HTTPS on the public side.

## Security Notes

- The tunnel token is sensitive — don't commit it to git
- Use Cloudflare Access (Zero Trust) to add authentication to admin services
- Consider restricting Portainer, NPM admin, etc. behind Cloudflare Access
