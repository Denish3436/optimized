

# Quick Map (what → where to use)

* **`resource_name` strings** → *Ticket 1* (each APM monitor query) + *Ticket 3* (to know which per-step monitor you added).
* **Slack & PagerDuty handles** → *Ticket 1* (monitor messages) + *Ticket 3* (composite paging in PROD).
* **Dashboard URL** → *Ticket 1 & 3* (put in every monitor message).
* **Runbook URL** → *Ticket 1 & 3* (put in every monitor message).
* **Pre-prod checklist** → Do before promoting Ticket 1 monitors and Ticket 3 composite.
* **Verify you grabbed the right endpoint** → After creating each Ticket 1 monitor (in DEV/UAT).

---

# 1) Get the exact `resource_name` strings (use in **Ticket 1**)

You’ll paste these into each APM monitor’s **query**.

### Method A — From the Bradesco dashboard (fastest)

1. Open **Bradesco Production Activity Overview**.
2. Click the widget showing **top endpoints/errors** for onboarding.
3. Click an endpoint row → a trace or resource opens.
4. Find **`resource_name`** in the details → **copy exactly** (case/spacing matters):

   * gRPC example: `/userclaim.pb.v1.UserClaimService/CheckUserExists`
   * HTTP example: `POST /api/onboarding/data-dump` (note the space)

### Method B — From APM Traces

1. Go to **APM → Traces**.
2. Search:

   ```
   kube_namespace:bradesco env:dev error:true
   ```
3. Click **Group by** → choose **`resource_name`**.
4. Copy the exact value you need.

### Method C — From APM Services → Resources

1. **APM → Services** → pick the onboarding service (e.g., user-claim).
2. **Resources** tab → copy the **Resource** (that’s `resource_name`).

> **Use now in Ticket 1 queries** (DEV first):
>
> ```
> status:error kube_namespace:bradesco env:dev resource_name:"<PASTE EXACT VALUE>"
> ```
>
> **Tip:** Put quotes around values with spaces (e.g., `"POST /..."`).
> If you’re unsure about `service:…`, **omit** it—`kube_namespace + resource_name` is safe.

---

# 2) Get Slack & PagerDuty handles (use in **Ticket 1** & **Ticket 3**)

### Easiest way (auto-complete in the Message box)

1. In any monitor’s **Message** field, type **`@`** and pause.
2. Pick your **Slack channel** from the popup (Datadog inserts the correct handle, e.g., `@slack-bradesco-alerts`).
3. Do the same for **PagerDuty** (e.g., `@pagerduty-bradesco`).

### Where to check integrations (if you don’t see them)

* **Integrations → Slack** (connected workspaces/channels).
* **Integrations → PagerDuty** (linked services).

> **Use now:**
>
> * *Ticket 1 (DEV/UAT)*: add **Slack only** to each per-step monitor.
> * *Ticket 3 (PROD composite)*: add **Slack + PagerDuty** to the composite message (after your 24–48h observation window).

---

# 3) Get the Dashboard URL (use in **Ticket 1 & 3** messages)

1. Open **Bradesco Production Activity Overview**.
2. Set the time/env controls as you want responders to land (e.g., **Past 1 hour**, env=prod).
3. Copy the **browser URL**.
4. Paste this **exact** URL into the **Message** of every per-step monitor and the composite.

---

# 4) Get (or create) the Runbook URL (use in **Ticket 1 & 3** messages)

### If it exists

* Open it in your wiki (Confluence/Notion/etc.) → **copy URL** → paste into all monitor messages.

### If it doesn’t exist (quick stub you can publish now)

Create a page titled **“Runbook: Bradesco Onboarding Failures”** with:

* **Summary** (4 steps + user impact)
* **Dashboards** (link)
* **Monitors** (4 per-step + composite)
* **Common causes by step**
* **First 5 checks** (timeline, dashboard panel, recent deploys, upstream/Ascend status, `kube_pod_name` restarts)
* **Rollback/mitigation**
* **Escalation** (on-call, Slack, PD)
* **Appendix** (sample queries, test endpoint, known issues)

Publish → **copy URL** → paste into all monitor messages.

---

# 6) Verify each endpoint (use after building **Ticket 1** monitors)

**Quick confidence check**

1. Go to **APM → Traces**.
2. Paste the monitor’s full query, e.g.:

   ```
   status:error kube_namespace:bradesco env:dev resource_name:"/userclaim.pb.v1.UserClaimService/CheckUserExists"
   ```
3. If results = **0**, your `resource_name` is off—copy it again from Dashboard / Traces / Services → Resources.
4. For HTTP endpoints, remember to quote the space: `"POST /path"`.

---

# 7) Where each thing goes (at a glance)

* **`resource_name`** → *Ticket 1* monitor **query** (x4).
* **Slack handle** → *Ticket 1* monitor **Message** (DEV/UAT & PROD); *Ticket 3* composite **Message**.
* **PagerDuty handle** → *Ticket 3* composite **Message** (PROD; after observation).
* **Dashboard URL** → *Ticket 1* & *Ticket 3* monitor **Message**.
* **Runbook URL** → *Ticket 1* & *Ticket 3* monitor **Message**.

---


---

If you paste the **4 `resource_name` values**, your **Slack channel**, **PD service**, and the **2 URLs**, I’ll hand back **ready-to-paste** final monitor names/messages and the composite expression referencing your real monitor IDs.
