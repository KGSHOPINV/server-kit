# SH Integration Spec — FlareVault

> What ServerHub builds to fulfill its side of the FV-BI-SH bilateral contract.
> Mirror of: FV-MF-SH-integrations/contracts/FV-BI-SH.md (SH perspective)

---

## What FV Needs From SH

| What | SH provides | Endpoint |
|------|-------------|----------|
| Port availability | Full port landscape before deploy | `GET /api/ports` |
| Server capacity | CPU, RAM, disk before deploy | `GET /api/status` |
| Runtime confirmation | Container up + healthy after deploy | Push event to FV callback |
| Container death | Managed container dies | Push event to FV callback |
| FV node health | flarevault-node container watched automatically | Docker event watcher |
| Activity entries | FV can write deployment events | `POST /api/activity` |

---

## What SH Does NOT Provide

- Credentials of any kind
- Vault access or bypass
- Channel state management (FV owns that)
- DNS or tunnel configuration (FV owns that)

---

## SH Role in the Deployment Loop

```
FV deploys via vault_proxy_ssh
  -> SH sees containers appear (Docker event watcher)
  -> SH logs to activity feed
  -> SH confirms container healthy
  -> SH pushes confirmation to FV callback
  -> FV wires domain via CF
  -> SH port landscape updates
```

SH is the eye. FV is the hand.

---

## Boot Order

SH starts first — it is the bootstrap layer installed before anything else.
FV node starts inside Docker. SH watches it come up. SH does not depend on FV.
FV can query SH for port availability at any time after boot.

---

## Open Items (SH to resolve)

- FV callback URL for push events — FV provides endpoint spec
- Auth token for SH to FV push calls — FV to provision via credential receipt
- Port event format — align with FV-node port registry schema
