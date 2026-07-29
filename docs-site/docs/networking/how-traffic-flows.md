---
sidebar_position: 1
title: How Traffic Flows
---

# How Traffic Flows

Understanding the path from "someone types a URL" to "your container responds."

---

## The Full Path

```
Internet User types: myapp.yourdomain.com
         │
         ▼
┌─────────────────┐
│    Cloudflare    │  DNS resolution + DDoS protection + SSL
│   (their edge)   │  Your server IP is HIDDEN here
└────────┬────────┘
         │ encrypted tunnel
         ▼
┌─────────────────┐
│   cloudflared    │  Receives traffic, passes to NPM
│   (your server)  │  No ports need to be open
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      NPM         │  Looks at the domain name
│  (reverse proxy) │  Routes to the right container
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Your Container  │  Handles the request
│  (myapp:3000)    │  Sends response back
└─────────────────┘
```

## Why This Architecture?

| Layer | What It Stops |
|-------|---------------|
| **Cloudflare** | DDoS attacks, bot traffic, known threats |
| **Tunnel** | Port scanning — there are no open ports to find |
| **NPM** | Direct IP access — routes only valid domain names |
| **Container** | Each app is isolated from the others |

## Local Access (no Cloudflare needed)

For services you only access from your local network:

```
Your Browser → http://SERVER-IP:PORT → Container
```

Example: `http://192.168.1.50:81` → NPM admin panel

No Cloudflare, no NPM routing — just direct port access on your LAN.
