# SH Interface — Endpoints FV Calls

---

## GET /api/ports
Status: NOT YET LIVE — building next

Full port landscape. Every bound port with service name and lane.
FV queries before any deployment to confirm target port is free.

Response shape:
{
  "ports": [
    { "port": 7000, "service": "hub", "lane": "server", "proto": "tcp", "state": "LISTEN" },
    { "port": 7777, "service": "flarevault-node", "lane": "server", "proto": "tcp", "state": "LISTEN" }
  ],
  "scanned_at": "<iso timestamp>"
}

---

## GET /api/status
Status: LIVE

Live server capacity. FV runs this as pre-deployment capacity check.

Response: online, hostname, cpu_cores, ram_total_gb, ram_used_mb, disk_used, containers, load

---

## GET /api/receipt
Status: LIVE

Full point-in-time server snapshot. FV can use to verify post-deployment state.

---

## GET /api/activity
Status: LIVE

Full event log, filterable. FV pulls runtime history for managed containers.

---

## POST /api/activity
Status: LIVE

FV writes deployment events and channel state changes into SH activity log.

Body: { "source": "flarevault", "type": "deploy", "message": "...", "meta": {} }

---

## Push: SH -> FV on container events
Status: NOT YET BUILT

When a managed container dies or comes healthy, SH pushes to FV callback.
FV to define callback endpoint and auth in their integrations/serverhub/INTERFACE.md.
