# Adding Projects

## Quick Way (Wizard)

```bash
add-project
```

Follow the prompts. It creates the compose file, optionally adds a database, and starts it.

## Manual Way

1. Create project directory:
```bash
mkdir -p /srv/docker/myproject
cd /srv/docker/myproject
```

2. Create docker-compose.yml:
```yaml
services:
  myproject:
    image: myimage:latest       # or use build: .
    container_name: myproject
    restart: always
    ports:
      - "3100:3000"             # host:container
    volumes:
      - myproject-data:/data
    networks:
      - proxy

volumes:
  myproject-data:

networks:
  proxy:
    external: true
```

3. Start it:
```bash
docker compose up -d
```

4. Add to NPM (http://server-ip:81):
   - Proxy Hosts → Add
   - Domain: myproject.yourdomain.com
   - Forward: myproject / port 3000
   - SSL: Request new certificate

5. Add to Cloudflare tunnel:
   - Zero Trust → Tunnels → Configure
   - Public Hostname → Add
   - Subdomain: myproject
   - Service: http://npm:80

6. Add monitoring (http://server-ip:3001):
   - Add New Monitor
   - Type: HTTP
   - URL: http://myproject:3000
   - Name: myproject

## With a Dedicated Supabase

If your project needs its own Supabase instance:

1. Copy the Supabase compose:
```bash
cp -r /srv/docker/supabase /srv/docker/myproject-supabase
```

2. Edit the compose file — change:
   - All container names (add project prefix)
   - Ports (e.g. Studio: 8002, Postgres: 5433)
   - Volume names

3. Create a new .env with unique passwords and keys

4. Start it:
```bash
cd /srv/docker/myproject-supabase
docker compose up -d
```

## With Shared Services

Your project can use existing shared services:

- **Redis:** Connect to `redis:6379` (on proxy network)
- **SurrealDB:** Connect to `surrealdb:8000` (on proxy network)
- **Supabase Postgres:** Connect to `supabase-db:5432` (on supabase-net)
- **MinIO:** Connect to `minio:9000` (on proxy network)
- **Mailpit SMTP:** Connect to `mailpit:1025` (on proxy network)

Just make sure your project's compose file joins the right network.
