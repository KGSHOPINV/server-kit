---
sidebar_position: 7
title: GitHub Auto-Deploy
---

# How Do I Auto-Deploy from GitHub?

Push code → it's live on your server. Four levels of automation.

---

## Level 1: Manual (simplest)

SSH in and pull:
```bash
cd /srv/docker/myproject
git pull
docker compose up -d --build
```

Or use the deploy tool:
```bash
deploy
```

## Level 2: GitHub Container Registry (GHCR)

Build Docker images, push to GitHub, pull on server.

**On your dev machine:**
```bash
docker build -t ghcr.io/KGSHOPINV/myproject:latest .
docker push ghcr.io/KGSHOPINV/myproject:latest
```

**On your server:**
```bash
cd /srv/docker/myproject
docker compose pull
docker compose up -d
```

## Level 3: GitHub Actions (auto-build)

GitHub builds your Docker image automatically on every push.

Add `.github/workflows/deploy.yml` to your repo (template in `~/server-kit/deploy-templates/`).

Push to main → GitHub Actions builds → pushes to GHCR → you pull on server.

## Level 4: Webhook (fully automatic)

GitHub notifies your server on push, server auto-deploys.

```
You push → GitHub → webhook → your server pulls + restarts
```

### Setup
1. Webhook container runs at `/srv/docker/webhook/`
2. Route through Cloudflare + NPM: `deploy.yourdomain.com → webhook:9000`
3. Add webhook in GitHub repo: Settings → Webhooks → URL: `https://deploy.yourdomain.com/hooks/deploy`
4. **Secure it:** Put Cloudflare Access on the webhook endpoint

### Full Pipeline Diagram
```
Your PC          GitHub              Your Server
────────         ──────              ───────────
git push ──→     Receives code
                 Actions builds
                 Pushes to GHCR ──→  (image stored)
                 Sends webhook  ──→  Webhook receives
                                     docker compose pull
                                     docker compose up -d
                                     ✓ App is live
```

## Rollback

```bash
cd /srv/docker/myproject

# See recent commits
git log --oneline -10

# Go back to a working version
git checkout COMMIT_HASH
docker compose up -d --build
```
