# Cloudflare Setup Checklist

Print this out or keep it open. Check off each step as you go.

---

## Phase 1 — Domain + Tunnel (do this first)

- [ ] Buy or transfer domain to Cloudflare
- [ ] Domain shows "Active" in Cloudflare dashboard
- [ ] Create tunnel in Zero Trust → Networks → Tunnels
- [ ] Copy tunnel token
- [ ] Run `./04-cloudflared-setup.sh` on server, paste token
- [ ] Tunnel shows "HEALTHY" in dashboard

## Phase 2 — Security Baseline (do this before adding services)

- [ ] SSL/TLS → Encryption mode: Full (Strict)
- [ ] SSL/TLS → Always Use HTTPS: ON
- [ ] SSL/TLS → Minimum TLS: 1.2
- [ ] SSL/TLS → Automatic HTTPS Rewrites: ON
- [ ] Security → Security Level: Medium
- [ ] Security → Browser Integrity Check: ON
- [ ] Security → Bot Fight Mode: ON

## Phase 3 — Protect Admin Services (do this before exposing them)

For EACH admin service (Portainer, NPM, Netdata, Grafana, Dozzle, Supabase Studio, n8n):

- [ ] Zero Trust → Access → Applications → Add Application
- [ ] Set subdomain (e.g. admin.yourdomain.com)
- [ ] Add policy: Allow — your email only
- [ ] Choose auth method (One-time PIN is simplest)
- [ ] Test: visit the subdomain, should see login page

## Phase 4 — Add Your Projects

For EACH project:

- [ ] Container is running (`docker ps`)
- [ ] Add public hostname in tunnel config → http://npm:80
- [ ] Add proxy host in NPM → container:port
- [ ] Test: visit subdomain, should see your app
- [ ] Add monitor in Uptime Kuma
- [ ] Decide: public or Access-protected?

## Phase 5 — WAF Rules (optional but recommended)

- [ ] Block bad paths (wp-admin, .env, phpinfo)
- [ ] Rate limit auth/login endpoints
- [ ] Consider country blocking if relevant

## Phase 6 — Verify Everything

- [ ] All admin services require login
- [ ] All public apps are reachable
- [ ] Uptime Kuma shows all green
- [ ] `health` command on server shows all OK
- [ ] Run `ports` — no unexpected open ports
