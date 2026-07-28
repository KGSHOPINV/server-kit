# Sharing Access With Other People

How to let other people access your services — securely, selectively, and without exposing your server.

---

## The Layers of Access

You control who sees what at multiple levels:

```
Layer 1: Cloudflare Access   — WHO can reach the service (login wall)
Layer 2: NPM Access Lists    — IP-level restrictions
Layer 3: App-level Auth      — The app's own login (Supabase auth, etc.)
```

You can use one, two, or all three depending on the service.

---

## Option 1: Cloudflare Access (Recommended)

Best for: giving specific people access to specific services.

### Add a Person

1. one.dash.cloudflare.com → Access → Applications
2. Pick the application (e.g. "Wiki")
3. Edit the policy
4. Add their email to the Allow rule:
   - Include: Emails — person@gmail.com
5. Save

They visit wiki.yourdomain.com → Cloudflare sends them a one-time code → they're in.

### Group Access

Instead of adding emails one by one:

- **Email domain:** Allow everyone@company.com
- **Google Workspace:** Allow anyone in your Google org
- **GitHub org:** Allow anyone in your GitHub organization
- **IP range:** Allow a specific network

### Access Levels Per Service

| Service | Who | How |
|---------|-----|-----|
| Your public apps | Everyone | No Access policy (open) |
| Wiki.js | You + team | Access policy: list of emails |
| Portainer | Only you | Access policy: your email only |
| Supabase Studio | Only you | Access policy: your email only |
| Grafana dashboards | You + specific people | Access policy: email list |
| n8n | Only you | Access policy: your email only |

### Temporary Access

1. Add their email to the policy
2. They do their work
3. Remove their email when done

Or set a shorter session duration:
- Default: 24 hours
- For temp access: 1 hour or 30 minutes
- They get kicked out and need to re-authenticate

---

## Option 2: NPM Access Lists

Best for: IP-based restrictions (allow only certain networks).

### Create an Access List

1. Open NPM admin (port 81)
2. Access Lists → Add
3. Name: "My Home Network"
4. Authorization: add username/password (basic auth)
5. Access: add allowed IPs/CIDRs

### Apply to a Proxy Host

1. Proxy Hosts → Edit the host
2. Access List → select your list
3. Save

Now that service requires the username/password AND the right IP.

---

## Option 3: App-Level Authentication

Each service has its own auth built in:

| Service | How to Add Users |
|---------|-----------------|
| **Portainer** | Settings → Users → Add User |
| **Grafana** | Admin → Users → Invite |
| **Wiki.js** | Admin → Users → Create |
| **n8n** | Settings → Users (Enterprise only, or use Access) |
| **Supabase** | Auth → Users (for app users, not admin) |
| **Uptime Kuma** | Settings → change password |
| **Supabase Studio** | .env file credentials (admin only) |

---

## Common Scenarios

### "I want a developer to see my project but not admin tools"

```
app.yourdomain.com       → Public or Access (developer's email)
admin.yourdomain.com     → Access (your email ONLY)
db.yourdomain.com        → Access (your email ONLY)
logs.yourdomain.com      → Access (your email ONLY)
```

### "I want to show a client a demo"

1. Deploy the app on a subdomain
2. Add Cloudflare Access with their email
3. Set session to 4 hours
4. Send them the link
5. Remove their email after the demo

### "I want a team wiki"

1. Wiki.js on wiki.yourdomain.com
2. Cloudflare Access: allow team emails
3. Wiki.js also has its own user roles (admin, editor, viewer)
4. Double protection: Cloudflare login + Wiki login

### "I want a public status page"

1. Uptime Kuma has a built-in public status page feature
2. Put it on status.yourdomain.com
3. NO Cloudflare Access (public)
4. People can see if services are up/down without logging in

### "I want to give someone SSH access"

DON'T open SSH to the internet. Instead:
1. Cloudflare Access for SSH (Zero Trust → Applications → Self-hosted → SSH)
2. Or: add their SSH key to ~/.ssh/authorized_keys and use Cloudflare's browser-based SSH
3. They connect through Cloudflare — your SSH port stays closed

---

## Security Checklist for Sharing

Before giving anyone access:

- [ ] Is Cloudflare Access in front of the service?
- [ ] Did you set the right session duration?
- [ ] Are admin tools on SEPARATE subdomains from public services?
- [ ] Does the person need access to the DATABASE or just the APP?
- [ ] Did you use the principle of least privilege (minimum access needed)?
- [ ] Do you have a plan to REMOVE their access when done?

---

## Revoking Access

### Remove from Cloudflare Access
1. Access → Applications → Edit policy
2. Remove their email
3. They're immediately blocked (even active sessions)

### Force Logout
1. Access → Active Sessions
2. Revoke specific user sessions

### Emergency: Disable Everything
1. Cloudflare → Tunnels → Disable tunnel
2. Everything goes offline immediately
3. Re-enable when ready
