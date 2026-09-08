# n8n Workflow Catalog

Ready-to-import n8n automation workflows for the ksgcohub server stack.

## Workflows

### health-alert.json

**Trigger:** Every 5 minutes
**What it does:** Polls the Hub API for container status. For each container that is not running, fires an ntfy push alert.
**Alert topic:** `alerts`
**ntfy priority:** high
**Node chain:** Schedule Trigger → Get Containers → Split Containers (Code) → Is Down? (IF) → Send Alert (HTTP POST)

### disk-alert.json

**Trigger:** Every 30 minutes
**What it does:** Polls the Hub API for system status. Splits the `disks` array and checks each disk's `pct` field. Fires an ntfy alert for any disk above 85% capacity.
**Alert topic:** `alerts`
**ntfy priority:** high
**Node chain:** Schedule Trigger → Get Status → Split Disks (Code) → Over 85%? (IF) → Send Disk Alert (HTTP POST)

### weekly-digest.json

**Trigger:** Every Sunday at 08:00
**What it does:** Fetches both `/api/status` and `/api/containers` from the Hub API, builds a plain-text summary (container count, uptime, disk usage per device), and posts it to the ntfy digest topic.
**Alert topic:** `digest`
**ntfy priority:** default
**Node chain:** Schedule Trigger → Get Status → Get Containers → Build Summary (Code) → Send Digest (HTTP POST)

---

## Dependencies

| Service | Address | Required by |
|---------|---------|-------------|
| Hub API | http://localhost:8765 | all workflows |
| ntfy | http://localhost:8085 | all workflows |
| n8n | http://localhost:5678 | (runs the workflows) |

Hub API endpoints used: `/api/status`, `/api/containers`

---

## How to Import

1. Open n8n at **http://localhost:5678**
2. In the left sidebar click **Workflows**
3. Click **Add Workflow** (top-right), then the menu icon → **Import from File**
   - Older n8n versions: **Settings** → **Import from File**
4. Select the `.json` file from this `workflows/` folder
5. Review the nodes — no credentials needed (all requests are localhost)
6. Toggle **Active** (top-right switch) to enable the schedule

Repeat for each workflow file.

---

## Notes

- All workflows target `localhost` and must run inside the server network
- The `health-alert` and `disk-alert` workflows use a **Code** node to split the API array response into individual n8n items before the IF check. If your API returns the array directly (not nested under a key), the Code node handles both shapes
- The `weekly-digest` **Build Summary** Code node references the earlier `Get Status` node output via `$("Get Status").first().json` — this requires n8n's v1 execution order (set in workflow settings)
- To adjust the disk threshold, open `disk-alert` in n8n, click the **Over 85%?** IF node, and change the value from `85`
- To change the weekly digest day/time, click the **Schedule Trigger** node and edit `triggerAtDay` (0=Sun, 1=Mon … 6=Sat) and `triggerAtHour`
