---
sidebar_position: 3
title: Set Up a Database
---

# How Do I Set Up a Database for My Project?

Pick the option that fits your needs.

---

## Option A: Use Shared Supabase

The simplest — use the Supabase instance already running on your server.

1. Open Studio at `http://YOUR-IP:8000`
2. Create tables in the visual editor
3. Your app connects via the auto-generated API

**Connection for apps on the same Docker network:**
```
SUPABASE_URL=http://supabase-kong:8000
SUPABASE_ANON_KEY=your-anon-key
```

## Option B: Dedicated Supabase Instance

For projects that need their own isolated database + auth:

```bash
sudo cp -r /srv/docker/supabase /srv/docker/myproject-supabase
cd /srv/docker/myproject-supabase
# Edit .env — change ports, passwords, keys
# Change Studio port from 8000 to something else (e.g., 8001)
docker compose up -d
```

## Option C: Standalone Postgres

Add to your project's `docker-compose.yml`:

```yaml
services:
  db:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: change-this-password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - proxy

volumes:
  db-data:
```

Your app connects with: `postgresql://myapp:change-this-password@db:5432/myapp`

## Option D: SurrealDB

Already running at `:8181`. Connect your app:

```
SURREALDB_URL=http://surrealdb:8000
SURREALDB_USER=root
SURREALDB_PASS=root
```

## Option E: SQLite

No setup needed — just mount a volume. Good for small projects.

```yaml
volumes:
  - ./data:/app/data    # SQLite file lives here
```

## Browsing Your Database

- **Adminer** (`http://YOUR-IP:8083`) — works with Postgres, MySQL, SQLite
- **Supabase Studio** (`http://YOUR-IP:8000`) — for Supabase databases
- **Redis Commander** (`http://YOUR-IP:8082`) — for Redis
- **Surrealist** (`https://surrealist.app`) — for SurrealDB (connect to your IP)
