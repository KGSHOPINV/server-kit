# SH Interface — Endpoints MF Calls

---

## GET /api/context
Status: LIVE — primary MF handoff endpoint

Structured server context designed for MF consumption.

Response: hostname, os, cpu_cores, ram_total_mb, disk_total_gb, docker_version, running_containers[]

---

## GET /api/status
Status: LIVE

Live system stats — CPU, RAM, disk, load, container count.

---

## GET /api/receipt
Status: LIVE

Full point-in-time server snapshot. MF uses to register server as barcoded infrastructure entity.

---

## GET /api/containers
Status: LIVE

All running containers with name, image, ports, status.

---

## GET /api/activity
Status: LIVE

Event log. MF filters by source, type, time to build entity timelines.

---

## POST /api/activity
Status: LIVE

MF writes entity registration and fuse state events to SH log.

Body: { "source": "metaforge", "type": "entity_registered", "message": "...", "meta": {} }

---

## GET /api/ports
Status: NOT YET LIVE — building next

Full port landscape. MF uses for drift detection — registered service ports vs actually bound.

---

## Push: SH -> MF on container events
Status: NOT YET BUILT

Container start/die events pushed to MF callback for real-time fuse color updates.
MF to define callback endpoint and auth.
