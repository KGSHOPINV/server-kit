# SH -> FlareVault Build Status

| Item | Status | Notes |
|------|--------|-------|
| `GET /api/status` | LIVE | CPU, RAM, disk, load, container count |
| `GET /api/receipt` | LIVE | Full server snapshot |
| `POST /api/activity` (FV writes) | LIVE | Any system can write to SH activity log |
| Docker event watcher | LIVE | All container events logged, ntfy on die |
| FV node container watch | LIVE | flarevault-node at :7777 watched automatically |
| `GET /api/ports` | NOT BUILT | Data exists, endpoint not exposed — NEXT |
| Push container events to FV | NOT BUILT | Callback URL undefined — after /api/ports |
| Push runtime confirmation to FV | NOT BUILT | Same blocker |
| Credential receipt pull on boot | NOT BUILT | FV-side not yet built |

Current gate: /api/ports. FV needs this before any deploy. Building next.
