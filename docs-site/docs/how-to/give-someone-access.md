---
sidebar_position: 6
title: Give Someone Access
---

# How Do I Give Someone Access to a Service?

---

## Public Access (anyone on the internet)

1. Set up domain in Cloudflare tunnel + NPM (see [Add a Domain](/how-to/add-a-domain))
2. Share the URL

## Authenticated Access (specific people)

Use **Cloudflare Access** — puts a login wall in front of any service.

### Setup

1. Go to [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
2. Access → Applications → Add an Application
3. Pick "Self-Hosted"
4. Set the domain (e.g., `admin.yourdomain.com`)
5. Add a policy:
   - **Name:** "Team access"
   - **Action:** Allow
   - **Rule:** Emails ending in `@yourdomain.com`
   - Or: Specific email addresses
6. Save

Now that URL requires login before showing anything. The person gets a one-time code via email.

### Revoking Access

1. Access → Applications → your app → Policies
2. Remove the person's email or change the rule
3. Access → Active Sessions → revoke their session

---

## SSH Access (server admin)

```bash
# Create a user for them
sudo adduser theirname

# Give them sudo (optional — be careful)
sudo usermod -aG sudo theirname

# They connect with:
ssh theirname@YOUR-SERVER-IP
```

### Revoking SSH Access

```bash
sudo deluser theirname
sudo rm -rf /home/theirname
```
