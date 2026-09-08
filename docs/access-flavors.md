# Access Flavor Guide

Every combination of how you can reach ServerHub, ntfy alerts, and the server itself — from the simplest single-network setup to a hardened zero-open-ports mesh. Each flavor is a complete recipe. Read one, know exactly what to install, and know exactly what you end up with.

---

## Quick Pick — Start Here

```
Are you only ever on your home network?
  → Flavor 1 (LAN Only)

Do you need remote access and already use Tailscale?
  → Flavor 2 (Tailscale Only)

Do you want ntfy alerts on your phone without installing a VPN app?
  → Flavor 3 (Cloudflare Tunnel Only)  or  Flavor 4 (Tailscale + Cloudflare)

Do you have a domain pointed at Cloudflare?
  → Flavor 3 or Flavor 4

Do you use Tailscale from a work laptop on a different account?
  → Flavor 5 (Two Tailscale Accounts)

Are you running more than one server?
  → Flavor 6 (Multi-Server Mesh)

Does your corporate network block outbound SSH?
  → Flavor 7 (Cloudflare SSH Proxy)

Want the most locked-down setup with zero open ports?
  → Flavor 7
```

---

## Flavor 1 — LAN Only

### What you get

The simplest possible setup. After the server-kit install completes you can open a browser on any device connected to your home network and reach the hub immediately. ntfy push notifications work as long as your phone is on the same WiFi. SSH works with a standard client. Nothing extra to install, no accounts to create, no domain required. The only cost is that the moment you leave home, everything goes dark.

### What to set up

1. Run the server-kit installer on your Ubuntu machine.
2. Note the server's local IP address (shown at the end of the install, or run `hostname -I`).
3. On any device on your LAN, open `http://SERVER_IP:8765` to reach the hub.
4. On your phone, install the ntfy app and subscribe to `http://SERVER_IP:8085/your-topic` while on WiFi.
5. For SSH, open a terminal and run `ssh USER@SERVER_IP`.

That is the entire setup. No step 6.

### Port/access table

| Service   | How to reach it                    | Requires              |
|-----------|------------------------------------|-----------------------|
| Hub       | `http://SERVER_IP:8765`            | LAN connection        |
| ntfy      | `http://SERVER_IP:8085`            | LAN connection        |
| SSH       | `ssh USER@SERVER_IP`               | LAN connection        |
| Portainer | `https://SERVER_IP:9443`           | LAN connection        |
| NPM       | `http://SERVER_IP:81`              | LAN connection        |

### Best for

Home lab experimenters who never need remote access. Developers running a local dev server. Anyone who wants to evaluate server-kit before deciding on a remote-access strategy.

### Combine with

Any other flavor — Flavors 2 through 7 all add remote access on top of what you already have with Flavor 1. You can always start here and upgrade later without reinstalling anything.

---

## Flavor 2 — Tailscale Only

### What you get

Tailscale creates an encrypted overlay network that makes all your devices act as if they are on the same LAN, regardless of where they physically are. Once Tailscale is installed on your server and your other devices, you reach the hub at the server's Tailscale IP on the same ports as LAN access. SSH works the same way — just swap the local IP for the Tailscale IP. ntfy alerts reach your phone anywhere in the world, but the phone needs the Tailscale app running in the background. This is a strong general-purpose setup for solo operators who control all their own devices.

### What to set up

1. Create a free Tailscale account at tailscale.com.
2. On the server, run:
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```
   Follow the authentication link that appears.
3. Install the Tailscale app on every device you want to have access: laptop, phone, work PC.
4. On each device, authenticate with the same Tailscale account.
5. Find the server's Tailscale IP in the Tailscale admin console (tailscale.com/admin) — it looks like `100.x.x.x`.
6. Open `http://TAILSCALE_IP:8765` from any device on your tailnet to reach the hub.
7. On your phone, subscribe to `http://TAILSCALE_IP:8085/your-topic` in the ntfy app.
8. SSH: `ssh USER@TAILSCALE_IP` from any device on your tailnet.

### Port/access table

| Service   | How to reach it                       | Requires                          |
|-----------|---------------------------------------|-----------------------------------|
| Hub       | `http://TAILSCALE_IP:8765`            | Tailscale running on device       |
| ntfy      | `http://TAILSCALE_IP:8085`            | Tailscale running on phone        |
| SSH       | `ssh USER@TAILSCALE_IP`               | Tailscale running on device       |
| Portainer | `https://TAILSCALE_IP:9443`           | Tailscale running on device       |
| NPM       | `http://TAILSCALE_IP:81`              | Tailscale running on device       |

### Best for

Solo operators who control all their devices. Anyone who already has Tailscale set up for other purposes. Home labs where phone ntfy alerts are acceptable to be VPN-gated.

### Combine with

Flavor 6 (mesh) — add more servers to the same tailnet. Flavor 7 (Cloudflare SSH Proxy) — for environments where Tailscale is blocked.

---

## Flavor 3 — Cloudflare Tunnel Only (no Tailscale)

### What you get

Cloudflare Tunnel runs a small agent (`cloudflared`) on your server that opens an outbound connection to Cloudflare's network. Cloudflare then routes traffic from your public domain to that connection. The result is a real HTTPS URL — `https://hub.yourdomain.com` — that works in any browser anywhere in the world with no client software installed. The hub sits behind Cloudflare Access, which enforces a login (email OTP or SSO) before anyone reaches it. ntfy gets its own public URL (`https://ntfy.yourdomain.com`) authenticated by ntfy's own token system, which means the phone's ntfy app can receive alerts without any VPN. SSH can also go through the tunnel using the `cloudflared access ssh` proxy command. This flavor is the cleanest option for phone alerts and browser access from arbitrary devices.

### What to set up

1. Register a domain and point its nameservers to Cloudflare (free Cloudflare account).
2. On the server, install cloudflared:
   ```bash
   curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
   echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
   sudo apt update && sudo apt install cloudflared
   ```
3. Authenticate cloudflared to your Cloudflare account:
   ```bash
   cloudflared tunnel login
   ```
4. Create a named tunnel:
   ```bash
   cloudflared tunnel create my-server
   ```
5. Create `/etc/cloudflared/config.yml`:
   ```yaml
   tunnel: <TUNNEL-ID>
   credentials-file: /root/.cloudflared/<TUNNEL-ID>.json

   ingress:
     - hostname: hub.yourdomain.com
       service: http://localhost:8765
     - hostname: ntfy.yourdomain.com
       service: http://localhost:8085
     - hostname: ssh.yourdomain.com
       service: ssh://localhost:22
     - service: http_status:404
   ```
6. Create DNS records in Cloudflare:
   ```bash
   cloudflared tunnel route dns my-server hub.yourdomain.com
   cloudflared tunnel route dns my-server ntfy.yourdomain.com
   cloudflared tunnel route dns my-server ssh.yourdomain.com
   ```
7. Install cloudflared as a system service:
   ```bash
   sudo cloudflared service install
   sudo systemctl enable --now cloudflared
   ```
8. In the Cloudflare Zero Trust dashboard, create an Access Application for `hub.yourdomain.com` with an email OTP or SSO policy. Leave `ntfy.yourdomain.com` unprotected by Access (ntfy handles its own token auth).
9. In the ntfy app on your phone, add server `https://ntfy.yourdomain.com` and set the access token from your ntfy config.
10. For SSH via tunnel, install cloudflared on your client machine and run:
    ```bash
    ssh -o ProxyCommand='cloudflared access ssh --hostname ssh.yourdomain.com' USER@ssh.yourdomain.com
    ```

### Port/access table

| Service   | How to reach it                                  | Requires                              |
|-----------|--------------------------------------------------|---------------------------------------|
| Hub       | `https://hub.yourdomain.com`                     | Cloudflare Access login               |
| ntfy      | `https://ntfy.yourdomain.com`                    | ntfy token                            |
| SSH       | `ssh -o ProxyCommand='cloudflared access ssh...' USER@ssh.yourdomain.com` | cloudflared on client |
| Portainer | Not exposed by default (add tunnel route if needed) | —                                  |

### Best for

Anyone who wants ntfy push alerts on a phone without installing a VPN app. Users who access the hub from shared or corporate devices where installing Tailscale is not practical. Those who want a real HTTPS URL with a proper login screen.

### Combine with

Flavor 2 (Tailscale) — keep Tailscale for SSH and direct admin access while Cloudflare handles browser and phone. This is Flavor 4. Flavor 6 (mesh) — HQ node uses Cloudflare; branch nodes stay LAN/Tailscale only.

---

## Flavor 4 — Tailscale + Cloudflare (belt and suspenders)

### What you get

Two completely independent paths to the same server, each optimized for a different use case. Tailscale handles all private admin work: SSH, direct hub access at the Tailscale IP, and anything else where you want a trusted encrypted tunnel between known devices. Cloudflare handles all public-facing access: the hub at a real HTTPS domain with an Access login, and ntfy at a public URL so your phone gets alerts without running a VPN. The two paths never interfere with each other. If Tailscale goes down, Cloudflare still works. If Cloudflare has a hiccup, Tailscale still works. SSH never touches Cloudflare — it stays on the Tailscale private path. This is the recommended setup for anyone who wants both convenience and resilience.

### What to set up

Follow Flavor 2 steps 1–8 to set up Tailscale.

Then follow Flavor 3 steps 1–9 to set up Cloudflare Tunnel. You can skip the SSH tunnel route in Flavor 3 step 5 (the `ssh.yourdomain.com` ingress line) since SSH goes over Tailscale.

Once both are running:
- Admin and SSH work via Tailscale IP.
- Browser access works at `https://hub.yourdomain.com`.
- Phone ntfy works at `https://ntfy.yourdomain.com` with no VPN required.

### Port/access table

| Service   | Tailscale path                     | Cloudflare path                          | Requires                            |
|-----------|-------------------------------------|------------------------------------------|-------------------------------------|
| Hub       | `http://TAILSCALE_IP:8765`          | `https://hub.yourdomain.com`             | Tailscale OR Cloudflare Access login|
| ntfy      | `http://TAILSCALE_IP:8085`          | `https://ntfy.yourdomain.com`            | Tailscale OR ntfy token             |
| SSH       | `ssh USER@TAILSCALE_IP`             | Not exposed via Cloudflare               | Tailscale                           |
| Portainer | `https://TAILSCALE_IP:9443`         | Not exposed by default                   | Tailscale                           |

### Best for

Anyone running a serious home lab who wants phone alerts without a VPN and admin access without exposing a public SSH port. The default recommendation for most users who have a domain on Cloudflare.

### Combine with

Flavor 6 (mesh) — this becomes the HQ configuration in a multi-server setup. Flavor 5 (two Tailscale accounts) — use the Cloudflare path for cross-account browser access.

---

## Flavor 5 — Two Tailscale Accounts

### What you get

Your personal server is on your personal Tailscale account. Your work laptop is on your employer's Tailscale account. These are separate tailnets and by default cannot see each other. You have two options for bridging them. Option A is Tailscale's node-sharing feature: you share the server node from your personal account and invite your work email to accept the shared node — your work laptop then sees the server as if it were on its own tailnet. Option B is simpler and requires no Tailscale coordination: use Cloudflare (Flavor 3 or 4) for the hub browser UI and ntfy, and keep SSH over the personal Tailscale path from devices you personally control.

### What to set up

**Option A — Node Sharing:**
1. In your personal Tailscale admin console, go to the server's machine page.
2. Click "Share" and enter your work email address.
3. On your work laptop, accept the shared node invitation.
4. The server now appears in your work laptop's tailnet. Access it at the Tailscale IP.
5. Note: sharing grants access to all ports on the server. There is no port-level restriction in node sharing.

**Option B — Cloudflare for cross-account access:**
1. Set up Flavor 3 or Flavor 4 on the server.
2. Use `https://hub.yourdomain.com` from your work laptop — no Tailscale involved.
3. Keep SSH restricted to personal Tailscale (never expose port 22 publicly).

### Port/access table

| Access path      | Service   | How to reach it                           | Requires                            |
|------------------|-----------|-------------------------------------------|-------------------------------------|
| Personal Tailscale | Hub     | `http://PERSONAL_TAILSCALE_IP:8765`       | Personal Tailscale on device        |
| Personal Tailscale | SSH     | `ssh USER@PERSONAL_TAILSCALE_IP`          | Personal Tailscale on device        |
| Node sharing     | Hub       | `http://SHARED_TAILSCALE_IP:8765`         | Work laptop accepted node share     |
| Node sharing     | SSH       | `ssh USER@SHARED_TAILSCALE_IP`            | Work laptop accepted node share     |
| Cloudflare       | Hub       | `https://hub.yourdomain.com`              | Cloudflare Access login             |
| Cloudflare       | ntfy      | `https://ntfy.yourdomain.com`             | ntfy token                          |

### Best for

People whose work and personal devices are on different Tailscale accounts. Anyone who needs to give a colleague temporary access to the hub without adding them to their personal tailnet permanently.

### Combine with

Flavor 4 — use Cloudflare as the default cross-account access path, with Tailscale reserved for your personal devices. This avoids the complexity of node sharing.

---

## Flavor 6 — Multi-Server Mesh (HQ + Nodes)

### What you get

One server acts as HQ — it has the full public-facing stack: Cloudflare tunnel for browser access, ntfy with a public URL for phone alerts, and Tailscale for private admin. All other servers are nodes — they can be LAN-only or on the same tailnet as HQ. During node installation, you specify the HQ address so the hub on HQ can pull status from every node. The HQ hub dashboard shows all servers in one view. ntfy alerts from nodes are forwarded through HQ so you only need one public ntfy URL on the phone, no matter how many servers you run. You SSH to nodes either via Tailscale (if they are on the tailnet) or by jumping through HQ using SSH ProxyJump. No node needs its own Cloudflare tunnel.

### What to set up

**On HQ (one time):**
1. Run server-kit install normally.
2. Set up Flavor 4 (Tailscale + Cloudflare) on HQ.
3. During install or in the hub config, set `ROLE=hq` and note the HQ Tailscale IP.

**On each node:**
1. Run server-kit install.
2. During install, set `ROLE=node` and `HQ_ADDRESS=HQ_TAILSCALE_IP` (or HQ LAN IP if nodes are on the same LAN).
3. Install Tailscale on the node and join the same tailnet as HQ (recommended) or leave it LAN-only.
4. The node registers itself with HQ. HQ hub dashboard now shows the node.

**ntfy routing:**
- Each node's services publish alerts to the local ntfy on HQ via the Tailscale or LAN path.
- Your phone subscribes only to `https://ntfy.yourdomain.com` (HQ's public URL).
- No per-node ntfy public exposure needed.

**SSH to nodes:**
```bash
# Direct (if node is on tailnet)
ssh USER@NODE_TAILSCALE_IP

# Via HQ jump host (if node is LAN-only)
ssh -J USER@HQ_TAILSCALE_IP USER@NODE_LAN_IP
```

### Port/access table

| Server | Service   | How to reach it                             | Requires                         |
|--------|-----------|---------------------------------------------|----------------------------------|
| HQ     | Hub       | `https://hub.yourdomain.com`                | Cloudflare Access login          |
| HQ     | Hub       | `http://HQ_TAILSCALE_IP:8765`               | Tailscale                        |
| HQ     | ntfy      | `https://ntfy.yourdomain.com`               | ntfy token (all nodes' alerts)   |
| HQ     | SSH       | `ssh USER@HQ_TAILSCALE_IP`                  | Tailscale                        |
| Node   | Hub       | `http://NODE_TAILSCALE_IP:8765`             | Tailscale (direct) or via HQ hub |
| Node   | SSH       | `ssh USER@NODE_TAILSCALE_IP`                | Tailscale                        |
| Node   | SSH       | `ssh -J USER@HQ_TAILSCALE_IP USER@NODE_LAN_IP` | Tailscale (to HQ)             |

### Best for

Anyone running two or more servers — home lab plus a VPS, two home machines, or a home server plus an offsite backup node. Operators who want a single dashboard and a single ntfy URL covering the whole fleet.

### Combine with

Flavor 4 — HQ uses this as its base. Flavor 7 — if any node is in a locked-down network environment.

---

## Flavor 7 — Cloudflare SSH Proxy

### What you get

Standard SSH requires the server to have port 22 (or a custom port) open to incoming connections. Cloudflare SSH Proxy eliminates that requirement entirely. Instead, `cloudflared` on the server maintains an outbound connection to Cloudflare, and `cloudflared` on your client machine intercepts your SSH command and routes it through that tunnel. To an observer on the network — corporate firewall, ISP, anyone — no SSH connection is visible. The server has zero open inbound ports. Access is gated by Cloudflare Access (requires a login before the SSH session is established). This is the most locked-down configuration available and works even from corporate networks that block ports 22 and 443.

### What to set up

**On the server:**
1. Complete Flavor 3 steps 1–7, including the `ssh.yourdomain.com` ingress line in the config.
2. Ensure port 22 is NOT open in your firewall (or close it if it was open):
   ```bash
   sudo ufw deny 22
   sudo ufw status
   ```
3. In Cloudflare Zero Trust dashboard, create an Access Application for `ssh.yourdomain.com` with your preferred policy (email OTP, SSO, or certificate-based).

**On each client machine (laptop, work PC, etc.):**
1. Install cloudflared:
   - macOS: `brew install cloudflare/cloudflare/cloudflared`
   - Windows: download from the Cloudflare releases page
   - Linux: same apt install as the server
2. Add to `~/.ssh/config` (Linux/macOS) or `%USERPROFILE%\.ssh\config` (Windows):
   ```
   Host ssh.yourdomain.com
     ProxyCommand cloudflared access ssh --hostname %h
     User YOUR_SERVER_USER
   ```
3. SSH normally:
   ```bash
   ssh ssh.yourdomain.com
   ```
   On first use, `cloudflared` opens a browser window for Cloudflare Access authentication. After authenticating, the SSH session opens.
4. Short-term certificates: in the Cloudflare SSH config you can enable short-lived certificates so no SSH key management is needed — Cloudflare issues a certificate valid for the session duration only.

**One-liner without config file:**
```bash
ssh -o ProxyCommand='cloudflared access ssh --hostname ssh.yourdomain.com' USER@ssh.yourdomain.com
```

### Port/access table

| Service | How to reach it                                                              | Requires                                      |
|---------|------------------------------------------------------------------------------|-----------------------------------------------|
| SSH     | `ssh ssh.yourdomain.com` (with ProxyCommand in config)                       | cloudflared on client + Cloudflare Access auth|
| SSH     | `ssh -o ProxyCommand='cloudflared access ssh --hostname ssh.yourdomain.com' USER@ssh.yourdomain.com` | cloudflared on client |
| Hub     | `https://hub.yourdomain.com`                                                 | Cloudflare Access login                       |
| ntfy    | `https://ntfy.yourdomain.com`                                                | ntfy token                                   |

### Best for

Security-focused operators who want zero open inbound ports. Anyone working from corporate networks that block outbound SSH. Situations where the server IP should never be publicly associated with SSH. Compliance environments where you need an audit trail of who authenticated to SSH and when (Cloudflare Access logs every authentication).

### Combine with

Flavor 2 (Tailscale) — keep Tailscale as a fallback SSH path in case cloudflared has issues. Flavor 4 — this replaces the Tailscale SSH path with a fully public but strongly authenticated path.

---

## Notes on Port Numbers

All port references in this guide use server-kit defaults:

| Service       | Default port |
|---------------|-------------|
| Hub (backend) | 8765         |
| ntfy          | 8085         |
| SSH           | 22           |
| Portainer     | 9443 (https) |
| NPM admin     | 81           |
| Cockpit       | 9090 (https) |

If you changed these during install, substitute your custom ports throughout.

---

## Picking a Flavor: Decision Matrix

| I want…                                              | Best flavor     |
|------------------------------------------------------|-----------------|
| Simplest possible setup, home network only           | 1               |
| Remote access, I control all devices                 | 2               |
| Phone ntfy alerts without a VPN app                 | 3 or 4          |
| Real HTTPS URL with a login screen                  | 3 or 4          |
| Both Tailscale admin AND public browser access      | 4               |
| Work laptop on different Tailscale account           | 5 or 4          |
| Multiple servers under one dashboard                | 6               |
| Zero open inbound ports on the server               | 7               |
| Works from corporate networks that block SSH        | 7               |
| Maximum resilience (two independent access paths)   | 4               |
