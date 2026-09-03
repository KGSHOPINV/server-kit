# SH -> FlareVault Build Status

| Item | Status | Notes |
|------|--------|-------|
| `GET /api/status` | LIVE | CPU, RAM, disk, load, container count |
| `GET /api/receipt` | LIVE | Full server snapshot |
| `POST /api/activity` (FV writes) | LIVE | Any system can write to SH activity log |
| Docker event watcher | LIVE | All container events logged, ntfy on die |
| FV node container watch | LIVE | flarevault-node at :7777 watched automatically |
| `GET /api/ports` | LIVE | Port landscape with protocol, state, assigned_by (FV-BI-SH schema) |
| Push container events to FV | NOT BUILT | Callback URL undefined — after /api/ports |
| Push runtime confirmation to FV | NOT BUILT | Same blocker |
| Credential receipt pull on boot | NOT BUILT | FV-side not yet built |

Gate cleared: /api/ports is LIVE. Next gate: push container events to FV (callback URL needed from FV).
