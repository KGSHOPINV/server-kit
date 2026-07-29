---
sidebar_position: 4
title: Databases & Storage
---

# Databases & Storage

All the data services available on your server.

---

## Supabase (Self-Hosted)

**What:** Backend-in-a-box — Postgres database + auth + auto-generated REST API + admin dashboard.

**Ports:** `:8000` (Studio), `:5432` (Postgres), `:8100` (API gateway)

**Containers:** 5 — db, auth, rest, studio, kong

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Studio** | Web dashboard — manage tables, users, storage visually |
| **PostgREST** | Auto-generates a REST API from your database tables |
| **GoTrue** | Handles user auth — signup, login, JWT tokens |
| **Kong** | API gateway that ties the pieces together |
| **RLS** | Row Level Security — database rules controlling who sees/edits what |
| **Anon Key** | Public API key (safe to expose, limited by RLS) |
| **Service Role Key** | Admin API key — **NEVER expose this** |

### Can I Run Multiple Instances?

**Yes.** One per project, different ports, separate data. Copy the compose file, change ports, deploy.

### Commands

```bash
# Check Supabase containers
docker ps | grep supabase

# Access Studio
http://YOUR-IP:8000

# Connect to Postgres directly
docker exec -it supabase-db psql -U postgres

# Restart everything
cd /srv/docker/supabase && docker compose restart
```

---

## PostgreSQL

**What:** The most reliable open source relational database. Comes with Supabase or standalone.

**Port:** `:5432`

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Database** | A collection of tables |
| **Schema** | Namespace within a database (public, auth, storage) |
| **Table** | Rows and columns of data |
| **Migration** | A versioned SQL change to the schema |

### Commands

```bash
# Connect to Postgres
docker exec -it supabase-db psql -U postgres

# List databases
\l

# Connect to a specific database
\c my_database

# List tables
\dt

# Exit
\q
```

---

## SurrealDB

**What:** Multi-model database — relational + document + graph in one.

**Port:** `:8181`

**Default creds:** `root` / `root` — **change this**

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Namespace** | Top-level container |
| **Database** | Within a namespace |
| **Table** | Schemaless by default — create data, table appears |
| **SurrealQL** | Its query language (SQL-like but more flexible) |
| **Record links** | Built-in graph relationships between records |

### When to Use Instead of Postgres

- You want document storage (JSON-like, no fixed schema)
- You need graph relationships (users → follows → users)
- You want one DB that does relational + document + graph
- You want to prototype fast without migrations

### Commands

```bash
# Access SurrealDB
docker exec -it surrealdb /surreal sql --conn http://localhost:8000 --user root --pass root

# Or use Surrealist (web UI):
# https://surrealist.app — connect to http://YOUR-IP:8181
```

---

## Redis

**What:** In-memory data store — ultra-fast cache and message queue.

**Ports:** `:6379` (Redis), `:8082` (Redis Commander web UI)

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Key-Value** | Store data as `key:value` pairs |
| **TTL** | Time-to-live — data auto-expires after a duration |
| **Pub/Sub** | Real-time messaging between services |
| **Maxmemory** | When memory fills, evicts least-recently-used data |

### Common Uses

- **Caching** — speed up repeated database queries
- **Sessions** — store user login state
- **Queues** — background job processing
- **Rate limiting** — track API request counts

### Commands

```bash
# Connect to Redis CLI
docker exec -it redis redis-cli

# Set a value
SET mykey "hello"

# Get a value
GET mykey

# Set with expiry (60 seconds)
SET temp "data" EX 60

# List all keys
KEYS *

# Browse visually
http://YOUR-IP:8082   # Redis Commander
```

---

## MinIO

**What:** S3-compatible object/file storage — self-hosted alternative to AWS S3.

**Ports:** `:9000` (API), `:9001` (console)

**Default creds:** `minioadmin` / `minioadmin` — **change this**

### Key Concepts

| Term | What It Means |
|------|---------------|
| **Bucket** | A container for files (like a top-level folder) |
| **Object** | A file stored in a bucket |
| **S3 API** | Industry standard — any app that works with AWS S3 works with MinIO |
| **Presigned URL** | Temporary link to download/upload a file |

### Commands

```bash
# Access console
http://YOUR-IP:9001

# Using mc (MinIO client) — install first
mc alias set local http://localhost:9000 minioadmin minioadmin
mc ls local/
mc mb local/my-bucket
mc cp myfile.txt local/my-bucket/
```
