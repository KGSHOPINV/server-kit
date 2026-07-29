# GitHub Deploy — Full Guide

How to deploy projects from GitHub to your server, automatically or manually.

---

## Table of Contents

1. [Overview — How It Works](#overview)
2. [Manual Deploy (simplest)](#manual-deploy)
3. [GitHub Container Registry (GHCR)](#github-container-registry)
4. [GitHub Actions (auto-build)](#github-actions)
5. [Webhook Auto-Deploy](#webhook-auto-deploy)
6. [Full Pipeline (everything connected)](#full-pipeline)
7. [Deploy Tool](#deploy-tool)
8. [Multiple Environments](#multiple-environments)
9. [Rollback](#rollback)
10. [Troubleshooting](#troubleshooting)

---

## Overview

There are 4 levels of automation. Pick what fits:

| Level | How It Works | Effort |
|-------|-------------|--------|
| Manual | SSH in, git pull, docker compose up | You do everything |
| GHCR | Push image to GitHub, server pulls it | You pull manually |
| Actions | GitHub builds image on push automatically | You just push code |
| Webhook | GitHub notifies server, server pulls automatically | Fully automatic |

You can mix these per-project. Some projects might be manual, others fully automatic.

---

## Manual Deploy

The simplest approach. SSH into your server and run commands.

### First Time
```bash
# On your server
cd /srv/docker
git clone https://github.com/KGSHOPINV/myproject.git
cd myproject
docker compose up -d
```

### Update
```bash
cd /srv/docker/myproject
git pull
docker compose pull    # if using pre-built images
docker compose up -d   # restart with new code
```

### Or Use the Deploy Tool
```bash
deploy
# Pick option 1 for new, option 2 for update
```

---

## GitHub Container Registry

GHCR lets you store Docker images on GitHub — free for public repos, included with GitHub Pro for private.

### Setup (one time on server)
```bash
# Login Docker to GHCR
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

The token needs `read:packages` scope. Create at: https://github.com/settings/tokens

### Build and Push (from your dev machine)
```bash
# Build your image
docker build -t ghcr.io/KGSHOPINV/myproject:latest .

# Push to GHCR
docker push ghcr.io/KGSHOPINV/myproject:latest
```

### Pull on Server
```bash
# On your server
docker pull ghcr.io/KGSHOPINV/myproject:latest
docker compose up -d
```

### In docker-compose.yml
```yaml
services:
  myapp:
    image: ghcr.io/KGSHOPINV/myproject:latest
    # ... rest of config
```

---

## GitHub Actions

Automatically builds a Docker image and pushes to GHCR every time you push to main.

### Setup

1. Copy the workflow template into your project:
```bash
# From server
cp /srv/docker/_deploy-templates/.github/workflows/docker-build-push.yml \
   /srv/docker/myproject/.github/workflows/
```

Or create `.github/workflows/deploy.yml` in your repo with the template content.

2. Push to GitHub. The action runs automatically.

3. Check it: `https://github.com/KGSHOPINV/myproject/actions`

### What the Action Does
1. Checks out your code
2. Logs into GHCR
3. Builds your Docker image
4. Pushes to `ghcr.io/KGSHOPINV/myproject:latest`
5. (Optional) Triggers webhook to auto-deploy

### Your Server Pulls the New Image
Manual:
```bash
cd /srv/docker/myproject
docker compose pull
docker compose up -d
```

Or automatic via webhook (see next section).

---

## Webhook Auto-Deploy

A webhook receiver on your server that GitHub calls when you push code.

### How It Works
```
You push to GitHub
  → GitHub sends POST to deploy.yourdomain.com/hooks/deploy
  → Webhook container receives it
  → Runs deploy.sh
  → Pulls latest code/image
  → Restarts the container
```

### Setup

1. Webhook container is installed by `13-github-deploy-setup.sh`

2. Route it through Cloudflare + NPM:
   - Cloudflare tunnel: `deploy.yourdomain.com → http://npm:80`
   - NPM proxy host: `deploy.yourdomain.com → webhook:9000`
   - **PUT CLOUDFLARE ACCESS ON THIS** (only allow GitHub IPs or use a secret)

3. Add webhook in GitHub:
   - Repo → Settings → Webhooks → Add
   - URL: `https://deploy.yourdomain.com/hooks/deploy`
   - Content type: `application/json`
   - Secret: (set a secret for security)
   - Events: `Just the push event`

4. Make sure your project is in `/srv/docker/REPONAME/` (matching the repo name)

### Securing the Webhook

Option A — Cloudflare Access:
- Put the webhook behind Cloudflare Access
- Add a Service Token for GitHub to use

Option B — Webhook Secret:
- Set a secret in GitHub webhook settings
- Update hooks.json to verify the secret:
```json
{
  "trigger-rule": {
    "match": {
      "type": "payload-hmac-sha256",
      "secret": "your-webhook-secret",
      "parameter": {
        "source": "header",
        "name": "X-Hub-Signature-256"
      }
    }
  }
}
```

### Adding More Projects to Webhook

The webhook already handles multiple projects — it reads the repo name from the payload and deploys to `/srv/docker/REPONAME/`. Just add the webhook URL to each GitHub repo.

---

## Full Pipeline

Everything connected — push code, auto-deploy, zero manual steps.

```
Your PC                    GitHub                     Your Server
─────────                  ──────                     ───────────
git push ──────────────→  Receives code
                          Actions triggers
                          Builds Docker image
                          Pushes to GHCR ──────────→  (image stored)
                          Sends webhook ───────────→  Webhook receives
                                                      Runs deploy.sh
                                                      docker compose pull
                                                      docker compose up -d
                                                      App is live with new code
```

### Setup Checklist for Full Pipeline
- [ ] Project has a Dockerfile
- [ ] Project has docker-compose.yml (using GHCR image)
- [ ] `.github/workflows/deploy.yml` in the repo
- [ ] Server logged into GHCR
- [ ] Webhook container running
- [ ] GitHub webhook configured in repo settings
- [ ] Cloudflare + NPM routing for webhook
- [ ] Cloudflare Access protecting webhook endpoint
- [ ] Project directory exists at `/srv/docker/REPONAME/`

---

## Deploy Tool

The `deploy` command on your server:

```bash
deploy
```

Options:
1. **Deploy NEW** — clone from GitHub, set up compose, start
2. **Update EXISTING** — git pull, rebuild, restart
3. **List deployed** — show all projects with status

---

## Multiple Environments

### Dev / Staging / Production on One Server

```
/srv/docker/
├── myapp/              ← production (main branch)
├── myapp-staging/      ← staging (develop branch)
└── myapp-dev/          ← dev (feature branches)
```

Each with different ports and subdomains:
```
myapp.yourdomain.com          → myapp:3000 (production)
staging.myapp.yourdomain.com  → myapp-staging:3001 (staging)
dev.myapp.yourdomain.com      → myapp-dev:3002 (dev)
```

### Branch-Based Deploys

Update hooks.json to handle different branches:
```json
{
  "id": "deploy-staging",
  "trigger-rule": {
    "match": {
      "value": "refs/heads/develop",
      "parameter": {"source": "payload", "name": "ref"}
    }
  }
}
```

---

## Rollback

### Quick Rollback (previous image)
```bash
cd /srv/docker/myproject

# See available image tags
docker images | grep myproject

# Use a specific version
# Edit docker-compose.yml: image: ghcr.io/KGSHOPINV/myproject:sha-abc123
docker compose up -d
```

### Git Rollback
```bash
cd /srv/docker/myproject
git log --oneline -10          # find the good commit
git checkout COMMIT_HASH       # go back to it
docker compose up -d --build   # rebuild from that code
```

### Emergency Rollback
```bash
# Stop the broken version
cd /srv/docker/myproject
docker compose down

# If you have the old image cached
docker run -d --name myproject-emergency \
  -p 3000:3000 --network proxy \
  ghcr.io/KGSHOPINV/myproject:previous-tag
```

---

## Troubleshooting

### GitHub Action fails
- Check: https://github.com/KGSHOPINV/myproject/actions
- Common issues: Dockerfile syntax, missing files in .dockerignore

### Webhook not triggering
```bash
# Check webhook container logs
docker logs webhook

# Check deploy log
cat /var/log/deploy.log

# Test manually
curl -X POST http://localhost:9000/hooks/deploy \
  -H "Content-Type: application/json" \
  -d '{"repository":{"name":"myproject"},"ref":"refs/heads/main"}'
```

### Image won't pull
```bash
# Check GHCR auth
docker pull ghcr.io/KGSHOPINV/myproject:latest

# Re-login if expired
echo "TOKEN" | docker login ghcr.io -u USERNAME --password-stdin
```

### Wrong version deployed
```bash
# Check what's running
docker ps | grep myproject
docker inspect myproject | grep Image

# Check what image tag
docker images | grep myproject
```
