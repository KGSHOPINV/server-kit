---
sidebar_position: 2
title: Add a Domain
---

# How Do I Add a Domain to a Service?

Make `myapp.yourdomain.com` point to a container on your server.

---

## Prerequisites

- Domain added to Cloudflare (nameservers pointed)
- Cloudflare tunnel running (`docker ps | grep cloudflared`)
- NPM running (`docker ps | grep npm`)

## Steps

### 1. Add Public Hostname in Cloudflare

1. Go to [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
2. Networks → Tunnels → your tunnel → Public Hostnames
3. Add:
   - **Subdomain:** `myapp`
   - **Domain:** `yourdomain.com`
   - **Service:** `http://npm:80`

### 2. Add Proxy Host in NPM

1. Open `http://YOUR-IP:81`
2. Proxy Hosts → Add Proxy Host
3. Fill in:
   - **Domain:** `myapp.yourdomain.com`
   - **Forward Hostname:** `myapp-container` (the container name)
   - **Forward Port:** `3000` (the container's internal port)

### 3. Test It

```bash
curl -I https://myapp.yourdomain.com
```

Or just open it in your browser.

:::tip Point everything at NPM
In Cloudflare, always point to `http://npm:80`. Let NPM handle routing to the right container. This keeps one layer of routing instead of two.

Exception: services with their own HTTPS (like Portainer) can be pointed at directly in Cloudflare.
:::
