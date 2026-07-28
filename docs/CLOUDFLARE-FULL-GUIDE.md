# Cloudflare — Full Guide

Everything about Cloudflare as it relates to your server: tunnel, domains, security, access control.

---

## Table of Contents

1. [What Cloudflare Does For You](#what-cloudflare-does-for-you)
2. [Initial Setup](#initial-setup)
3. [Tunnel Setup](#tunnel-setup)
4. [Adding Projects / Subdomains](#adding-projects--subdomains)
5. [Multiple Domains](#multiple-domains)
6. [Cloudflare Access (Login Wall)](#cloudflare-access-login-wall)
7. [Security Settings](#security-settings)
8. [WAF Rules](#waf-rules)
9. [SSL/TLS Settings](#ssltls-settings)
10. [DNS Management](#dns-management)
11. [Page Rules & Redirects](#page-rules--redirects)
12. [Monitoring & Analytics](#monitoring--analytics)
13. [Common Patterns](#common-patterns)
14. [Troubleshooting](#troubleshooting)

---

## What Cloudflare Does For You

Without Cloudflare:
```
User → your public IP → your server (exposed, vulnerable)
```

With Cloudflare:
```
User → Cloudflare (filters, protects, caches) → tunnel → your server (hidden)
```

Your server has NO open ports, NO public IP exposed. Cloudflare is the front door.

| Feature | What It Does | Free Tier |
|---------|-------------|-----------|
| DNS | Manages your domain's records | Yes |
| CDN | Caches static content globally | Yes |
| DDoS Protection | Blocks volumetric attacks | Yes |
| SSL/TLS | End-to-end encryption | Yes |
| Tunnel | Connects server without open ports | Yes |
| Access | Login wall for services | 50 users |
| WAF | Blocks web attacks | Basic rules |
| Bot Management | Blocks scrapers | Basic |
| Analytics | Traffic stats | Yes |
| Page Rules | Redirects, caching rules | 3 free |

---

## Initial Setup

### 1. Get a Domain
- Buy from Cloudflare Registrar (cheapest, no markup) or any registrar
- If bought elsewhere, change nameservers to Cloudflare's

### 2. Add Domain to Cloudflare
1. dash.cloudflare.com → Add a Site
2. Enter your domain
3. Select Free plan
4. Cloudflare gives you two nameservers
5. Go to your registrar → set nameservers to Cloudflare's
6. Wait for propagation (minutes to hours)

### 3. Verify
- Cloudflare dashboard shows domain as "Active"
- DNS tab shows your records

---

## Tunnel Setup

### Create the Tunnel
1. one.dash.cloudflare.com (Zero Trust dashboard)
2. Networks → Tunnels → Create a tunnel
3. Name it (e.g. "home-server")
4. Select "Cloudflared" as connector
5. Copy the token

### Connect Your Server
Run on your server:
```bash
cd ~/server-kit
./04-cloudflared-setup.sh
# Paste the token when prompted
```

Or manually:
```bash
# The token goes in /srv/docker/cloudflared/docker-compose.yml
docker compose up -d
```

### Verify Tunnel is Connected
- Cloudflare dashboard: Tunnels → your tunnel should show "HEALTHY"
- On server: `docker logs cloudflared`

---

## Adding Projects / Subdomains

Every project you deploy gets a subdomain routed through the same tunnel.

### Step 1 — Add Public Hostname in Cloudflare
1. Zero Trust → Tunnels → your tunnel → Configure
2. Public Hostname tab → Add a public hostname
3. Fill in:
   - **Subdomain:** taskmaster
   - **Domain:** yourdomain.com
   - **Service:** http://npm:80

### Step 2 — Add Proxy Host in NPM
1. Open NPM admin (http://server-ip:81)
2. Proxy Hosts → Add Proxy Host
3. Fill in:
   - **Domain Names:** taskmaster.yourdomain.com
   - **Forward Hostname:** taskmaster (container name)
   - **Forward Port:** 3000 (container's internal port)
   - **Block Common Exploits:** ON
   - **Websockets Support:** ON (if needed)

### Step 3 — Done
taskmaster.yourdomain.com now reaches your container.

### Traffic Flow
```
User types: taskmaster.yourdomain.com
  → Cloudflare DNS resolves it
  → Cloudflare routes through tunnel
  → cloudflared container receives it
  → Sends to NPM (port 80)
  → NPM sees the domain name, forwards to taskmaster:3000
  → Your app responds
```

---

## Multiple Domains

One tunnel handles multiple domains. You can have:

```
Tunnel: "home-server"
  ├── taskmaster.work-domain.com     → taskmaster:3000
  ├── warehouse.personal-domain.com  → pwarehouse:3100
  ├── api.another-domain.com         → supabase-kong:8000
  └── admin.work-domain.com          → portainer:9443
```

Just add each domain to Cloudflare (each domain needs to be in your Cloudflare account) and add public hostnames in the tunnel config.

---

## Cloudflare Access (Login Wall)

This is how you protect admin services. Free for up to 50 users.

### What It Does
Puts a login page in FRONT of any subdomain. User must authenticate before they can even reach your service.

```
User hits admin.yourdomain.com
  → Cloudflare shows login page
  → User authenticates (Google, email code, GitHub, etc.)
  → Cloudflare checks policy
  → If allowed → forwards to your service
  → If denied → blocked
```

### Setup

#### 1. Enable Access
1. one.dash.cloudflare.com → Access → Applications
2. Add an Application → Self-hosted

#### 2. Configure the Application
- **Application name:** Portainer Admin
- **Session Duration:** 24 hours (how long before re-login)
- **Application domain:** admin.yourdomain.com

#### 3. Add a Policy
- **Policy name:** Allow Me
- **Action:** Allow
- **Include rule:** Emails — your@email.com

#### 4. Authentication Methods
Under Settings → Authentication:
- **One-time PIN** — Cloudflare emails you a code (simplest)
- **Google** — Sign in with Google
- **GitHub** — Sign in with GitHub
- **SAML/OIDC** — Enterprise identity providers

### Recommended Access Policies

| Service | Subdomain | Who Gets Access |
|---------|-----------|----------------|
| Portainer | admin.yourdomain.com | Only you |
| NPM Admin | npm.yourdomain.com | Only you |
| Netdata | stats.yourdomain.com | Only you |
| Grafana | grafana.yourdomain.com | Only you |
| Dozzle | logs.yourdomain.com | Only you |
| Supabase Studio | db.yourdomain.com | Only you |
| n8n | auto.yourdomain.com | Only you |
| Wiki.js | wiki.yourdomain.com | You + team |
| Your apps | app.yourdomain.com | Public (no Access) |

### Service Tokens (for API/machine access)
If a service needs to call another service through Cloudflare:
1. Access → Service Auth → Create Service Token
2. Use the Client ID + Secret as headers in API calls
3. Add the service token to the Access policy

---

## Security Settings

### SSL/TLS Settings
Location: dash.cloudflare.com → your domain → SSL/TLS

| Setting | Recommended | Why |
|---------|------------|-----|
| Encryption mode | **Full (Strict)** | End-to-end encryption |
| Always Use HTTPS | **ON** | Redirect HTTP to HTTPS |
| Minimum TLS Version | **TLS 1.2** | Block old insecure versions |
| Automatic HTTPS Rewrites | **ON** | Fix mixed content |
| HSTS | **ON** (be careful) | Force browsers to always use HTTPS |

### Security Settings
Location: dash.cloudflare.com → your domain → Security

| Setting | Recommended | Why |
|---------|------------|-----|
| Security Level | **Medium** | Challenges suspicious traffic |
| Challenge Passage | **30 minutes** | How long a challenge is valid |
| Browser Integrity Check | **ON** | Blocks requests with bad headers |
| Privacy Pass | **ON** | Reduces challenges for legit users |

### Bot Protection
Location: Security → Bots

- **Bot Fight Mode:** ON — challenges known bots
- **Super Bot Fight Mode (Pro):** more aggressive bot blocking

---

## WAF Rules

Web Application Firewall — blocks common attacks.

Location: dash.cloudflare.com → your domain → Security → WAF

### Free Tier Rules
- Cloudflare Managed Ruleset (basic protection)
- Rate limiting (basic)

### Custom Rules (examples)

#### Block All Traffic Except Your Country
```
Rule name: Block foreign traffic
Expression: (not ip.geoip.country in {"US"})
Action: Block
```

#### Rate Limit Login Pages
```
Rule name: Rate limit auth
Expression: (http.request.uri.path contains "/login" or http.request.uri.path contains "/auth")
Action: Rate limit — 10 requests per minute
```

#### Block Known Bad Paths
```
Rule name: Block exploit paths
Expression: (http.request.uri.path contains "wp-admin" or http.request.uri.path contains ".env" or http.request.uri.path contains "phpinfo")
Action: Block
```

---

## DNS Management

Location: dash.cloudflare.com → your domain → DNS

### Record Types
| Type | Purpose | Example |
|------|---------|---------|
| A | Points domain to IP | Not needed with tunnels |
| CNAME | Points subdomain to another domain | Used by tunnels automatically |
| MX | Email routing | If you use custom email |
| TXT | Verification, SPF, DKIM | Email authentication |

### With Tunnels
You generally DON'T manually add DNS records for tunnel services. Cloudflare creates CNAME records automatically when you add public hostnames to the tunnel.

### Without Tunnels (if you ever open ports)
```
Type: A
Name: @
Content: your-server-public-IP
Proxy: ON (orange cloud)
```

---

## Page Rules & Redirects

Location: dash.cloudflare.com → your domain → Rules

### Redirect www to non-www
```
URL: www.yourdomain.com/*
Setting: Forwarding URL (301)
Destination: https://yourdomain.com/$1
```

### Force HTTPS
```
URL: http://yourdomain.com/*
Setting: Always Use HTTPS
```

### Cache Everything for Static Sites
```
URL: static.yourdomain.com/*
Setting: Cache Level → Cache Everything
Edge Cache TTL: 1 month
```

---

## Monitoring & Analytics

### Cloudflare Analytics
Location: dash.cloudflare.com → your domain → Analytics

Shows:
- Total requests
- Cached vs uncached
- Threats blocked
- Bandwidth saved
- Top countries / IPs
- HTTP status codes

### Zero Trust Analytics
Location: one.dash.cloudflare.com → Analytics

Shows:
- Access login attempts
- Tunnel health
- Active users
- Blocked requests

### Pairing with Your Server Monitoring
- **Uptime Kuma** monitors your services FROM inside the server
- **Cloudflare Analytics** monitors traffic FROM the outside
- Together you see both sides

---

## Common Patterns

### Pattern 1: Public App + Protected Admin
```
app.yourdomain.com        → Public (no Access policy)
admin.yourdomain.com      → Cloudflare Access (your email only)
api.yourdomain.com        → Public with rate limiting
```

### Pattern 2: Dev/Staging/Production
```
app.yourdomain.com        → Production container
staging.yourdomain.com    → Staging container (Access protected)
dev.yourdomain.com        → Dev container (Access protected)
```

### Pattern 3: Multiple Projects, One Server
```
project1.yourdomain.com   → project1:3000
project2.yourdomain.com   → project2:3100
project3.yourdomain.com   → project3:3200
shared-db.yourdomain.com  → Supabase Studio (Access protected)
```

### Pattern 4: API + Frontend Split
```
myapp.yourdomain.com      → Frontend container (React/Next)
api.myapp.yourdomain.com  → Backend/API container
```

---

## Troubleshooting

### "Site can't be reached"
1. Is the tunnel healthy? Check Cloudflare dashboard → Tunnels
2. Is cloudflared running? `docker ps | grep cloudflared`
3. Is the public hostname configured? Check tunnel config
4. Is NPM routing it? Check NPM proxy hosts
5. Is the container running? `docker ps | grep appname`

### "502 Bad Gateway"
- NPM can reach the domain but NOT the container
- Check container is running and on the `proxy` network
- Check the forward hostname/port in NPM matches the container

### "403 Forbidden"
- Cloudflare is blocking the request
- Check WAF rules — might be too aggressive
- Check Access policies — might require login
- Check Security Level — try lowering temporarily

### "SSL Error / Mixed Content"
- Set SSL mode to "Full (Strict)" in Cloudflare
- Make sure NPM isn't also trying to do SSL (double encryption)
- With tunnels: Cloudflare handles external SSL, internal traffic is HTTP

### "Tunnel disconnects frequently"
- Check server resources: `docker stats cloudflared`
- Check logs: `docker logs cloudflared --tail 50`
- Make sure `restart: always` is in the compose file
- Check internet connection stability

### "Access login loop"
- Clear browser cookies for the domain
- Check the Access policy allows your email/identity
- Check the application domain matches exactly
