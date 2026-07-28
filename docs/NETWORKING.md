# Networking Reference

## Your Server's Network

```
Router (your home network)
  |
  └── Server (static IP recommended)
        |
        ├── Port 22: SSH
        ├── Port 80/443: NPM (HTTP/HTTPS)
        ├── Port 81: NPM Admin
        └── All other ports: internal services
```

## Static IP Setup

Your server should have a static IP so it doesn't change on reboot.

Option A — Set in router (DHCP reservation):
- Find server MAC address: `ip link show`
- In router admin, assign a fixed IP to that MAC

Option B — Set on server:
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```
```yaml
network:
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
  version: 2
```
```bash
sudo netplan apply
```

## Firewall (UFW)

The setup script configures these rules:

| Port | Service | Rule |
|------|---------|------|
| 22 | SSH | Allow |
| 80 | HTTP | Allow |
| 443 | HTTPS | Allow |
| 81 | NPM Admin | Allow |
| 3000-3003 | Homepage, Kuma, Grafana, Wiki | Allow |
| 5432 | PostgreSQL | Allow |
| 5678 | n8n | Allow |
| 6379 | Redis | Allow |
| 8000-8084 | Various services | Allow |
| 8181 | SurrealDB | Allow |
| 9000-9001 | MinIO | Allow |
| 9443 | Portainer | Allow |
| 19999 | Netdata | Allow |

Manage firewall:
```bash
sudo ufw status           # see rules
sudo ufw allow 8888       # open a port
sudo ufw deny 8888        # block a port
sudo ufw delete allow 8888  # remove a rule
```

## Cloudflare Tunnel vs Port Forwarding

| | Port Forwarding | Cloudflare Tunnel |
|---|---|---|
| Opens ports on router | Yes | No |
| Exposes server IP | Yes | No |
| DDoS protection | No | Yes |
| Works behind CGNAT | No | Yes |
| Speed | Direct | Slight overhead |
| Cost | Free | Free |

Cloudflare Tunnel is better for almost every home server use case.

## Docker Networks

```bash
docker network ls          # list networks
docker network inspect proxy  # see who's on the proxy network
```

The `proxy` network is the shared network. All public-facing containers join it.

Create isolated networks for projects that shouldn't talk to others:
```bash
docker network create myproject-internal
```
