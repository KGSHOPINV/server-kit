# SH Integration Spec — Metaforge

> What ServerHub builds to fulfill its side of the MF-BI-SH bilateral contract.
> Mirror of: FV-MF-SH-integrations/contracts/MF-BI-SH.md (SH perspective)

---

## What MF Needs From SH

| What | SH provides | Endpoint |
|------|-------------|----------|
| Container state | Live Docker events | Push to MF callback (fuse color updates) |
| Server registration | Full server snapshot | `GET /api/receipt` |
| Port landscape | All bound ports | `GET /api/ports` |
| Health observations | CPU, RAM, disk, load | `GET /api/status` |
| Activity feed | All server events | `GET /api/activity` |
| Context payload | Structured MF handoff payload | `GET /api/context` |

---

## What SH Does NOT Provide

- Entity classification or barcoding (MF owns that)
- Fuse color decisions (MF decides from SH data)
- Tenant management or registry (MF owns that)
- Credentials (FlareVault owns that)

---

## SH Role With Metaforge

MF tells SH what SHOULD be running (expected containers).
SH tells MF what IS running (actual containers).
SH pushes events when containers die or come up.
MF updates fuse colors. SH never touches those decisions.

---

## The Hard Boundary

SH monitors ALL Metaforge containers. SH NEVER restarts, reconfigures, or modifies them.
SH reports. MF and the user decide. This is absolute.

---

## Drift Detection (planned)

SH compares MF expected container list against actual running containers.
If expected container is missing for > threshold, SH flags drift and pushes alert.
Threshold TBD — MF to define.

---

## Open Items (SH to resolve)

- MF callback URL for container push events — MF to provide
- Auth token for SH to MF push calls — MF to provision
- Expected container manifest format — align with MF entity schema
- Drift detection threshold — MF to define acceptable lag
