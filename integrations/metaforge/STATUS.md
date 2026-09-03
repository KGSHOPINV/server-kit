# SH -> Metaforge Build Status

| Item | Status | Notes |
|------|--------|-------|
| `GET /api/context` | LIVE | Primary MF handoff — hostname, OS, CPU, RAM, disk, containers |
| `GET /api/status` | LIVE | Live system stats |
| `GET /api/receipt` | LIVE | Full server snapshot for MF registration |
| `GET /api/containers` | LIVE | Running containers with name, ports, status |
| `GET /api/activity` | LIVE | Full event log, filterable |
| `POST /api/activity` (MF writes) | LIVE | MF can write entity events to SH log |
| `GET /api/ports` | LIVE | Port landscape with protocol, state, assigned_by (FV-BI-SH schema) |
| Push container events to MF | NOT BUILT | Callback URL not defined |
| Drift detection | NOT BUILT | Needs /api/ports + MF expected manifest |
| Server registration handshake | NOT BUILT | SH->MF flow to register server as entity |

All read endpoints live. Remaining gaps: push events, drift detection, server registration handshake.
