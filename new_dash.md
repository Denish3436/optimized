# **FINAL PRODUCTION-READY BRADESCO ONBOARDING MONITORING**

---

## **📋 TICKET 1: Setup new monitor for Bradesco onboarding failures**

### **A) Plain-English Summary**

**What we're doing:** Creating 4 monitors to track when each step of Bradesco onboarding fails. We use APM Trace Analytics (NOT Log monitors) because the ticket shows APM data.

**Why it matters:** Every failed onboarding = lost customer = lost revenue. We need to know immediately which step is breaking.

**The 4 Steps:**
1. **Data Dump** - User enters their info
2. **User Existence Check** - System checks if user already exists
3. **User Claim** - User completes the claim process
4. **Account Creation** - Ascend creates the final account

### **B) Critical Configuration**

**Monitor Type:** APM → Trace Analytics (**NOT Logs!**)  
**Required filters:** Always include `kube_namespace:bradesco` and `env:<environment>`  
**Service filter:** Only add `service:bradesco` if you see it in the Bradesco Production Activity Overview dashboard

### **C) Step-by-Step Implementation**

#### **MONITOR 1: Data Dump**

**1. Navigate to Creation:**
```
Monitors → New Monitor → APM → Trace Analytics
```

**2. Enter Query:**
```
status:error kube_namespace:bradesco env:dev resource_name:POST./api/onboarding/data-dump
```
> ⚠️ **IMPORTANT:** Replace `/api/onboarding/data-dump` with the EXACT endpoint from your Bradesco dashboard

**3. Configure Settings:**
- **Measure:** `Count`
- **Multi-alert:** Toggle ON
- **Group by:** `resource_name` (and optionally `kube_pod_name`)
- **Alert threshold:** `≥ 5` errors
- **Time window:** `last 5 minutes`
- **Advanced options:**
  - **Require:** `2 consecutive failures` (prevents flapping)
  - **Evaluation delay:** `60 seconds`
- **Warning threshold:** `≥ 2` errors
- **No-data:** Leave OFF (APM can be bursty)

**4. Name & Message:**
```
Name: [DEV] [FINTRON] [BRADESCO] - Onboarding Data Dump error spikes

Message:
Onboarding Data Dump errors spiking for {{resource_name.name}} in {{env.name}}.
{{#is_present kube_pod_name.name}}Pod: {{kube_pod_name.name}}{{/is_present}}

Dashboard: https://app.datadoghq.com/dashboard/abc-123-your-actual-id
Runbook: https://wiki.company.com/runbooks/bradesco-onboarding

@slack-fintron-dev-alerts
```
> ⚠️ **Replace URLs with your ACTUAL dashboard and runbook links - no placeholders!**

**5. Add Tags:**
- `env:dev`
- `team:fintron`
- `service:bradesco`
- `severity:p3`
- `owner:fintron-onboarding`
- `step:data-dump`

**6. Click "Create" and SAVE THE MONITOR ID**

---

#### **MONITOR 2: User Existence Check**

Repeat above with these changes:

**Query:**
```
status:error kube_namespace:bradesco env:dev resource_name:"/userclaim.pb.v1.UserClaimService/CheckUserExists"
```
> ✅ This exact endpoint is from your ticket

**Name:** `[DEV] [FINTRON] [BRADESCO] - Onboarding User Check error spikes`  
**Tag:** `step:existence-check`

---

#### **MONITOR 3: User Claim**

**Query:**
```
status:error kube_namespace:bradesco env:dev resource_name:"/userclaim.pb.v1.UserClaimService/ProcessClaim"
```
> ⚠️ Replace with your actual claim endpoint from dashboard

**Name:** `[DEV] [FINTRON] [BRADESCO] - Onboarding User Claim error spikes`  
**Tag:** `step:user-claim`

---

#### **MONITOR 4: Account Creation**

**Query:**
```
status:error kube_namespace:bradesco env:dev resource_name:"/account.pb.v1.AccountService/CreateAccount"
```
> ⚠️ Replace with your actual Ascend endpoint from dashboard

**Name:** `[DEV] [FINTRON] [BRADESCO] - Onboarding Account Creation error spikes`  
**Tag:** `step:account-creation`

### **D) Testing (DEV/UAT)**

**Generate Test Errors (coordinate with QA):**
```bash
# Use test accounts only - NO real user data
for i in {1..6}; do
  curl -X POST https://dev-api.bradesco.com/test/force-error \
    -H "Content-Type: application/json" \
    -d '{"step":"data-dump","test_user":"dummy_'$i'"}'
  sleep 30
done
```

**If Too Noisy:**
- Increase threshold: 5 → 8-10
- Widen window: 5m → 10m  
- Require 3 consecutive evaluations
- Mute temporarily: Monitor → Mute → 1 hour

### **E) Promote to PRODUCTION**

**For each of the 4 monitors:**
1. Open monitor → Gear icon → **Clone**
2. Change in query: `env:dev` → `env:prod`
3. Change name: `[DEV]` → `[PROD]`
4. Update tags: `env:dev` → `env:prod`, `severity:p3` → `severity:p2`
5. Keep Slack only initially (add PagerDuty after 24-48h stable or use composite)
6. Create

---

## **📋 TICKET 2: Make Username, Email, Phone searchable in APM**

### **A) What We're Doing**

Making user fields searchable so support can find specific users having issues. We'll add `usr.id`, `usr.name`, `usr.email`, `usr.phone` as searchable facets.

### **B) Code Changes (Give to Dev Team)**

**Add to EVERY onboarding endpoint:**

```javascript
// Node.js example
const tracer = require('dd-trace');

app.post('/api/onboarding/data-dump', (req, res) => {
  const span = tracer.scope().active();
  
  if (span && req.body) {
    // Pre-claim: from request
    if (req.body.email) span.setTag('usr.email', req.body.email);
    if (req.body.phone) span.setTag('usr.phone', req.body.phone);
    
    // Post-claim: from database
    if (user?.id) span.setTag('usr.id', user.id);
    if (user?.name) span.setTag('usr.name', user.name);
    
    // Privacy options for PROD (if required by compliance):
    // span.setTag('usr.email_domain', req.body.email.split('@')[1]);
    // span.setTag('usr.phone_last4', req.body.phone.slice(-4));
  }
  
  // Your existing code...
});
```

**Java example:**
```java
Span span = GlobalTracer.get().activeSpan();
if (span != null) {
    span.setTag("usr.email", request.getEmail());
    span.setTag("usr.phone", request.getPhone());
    span.setTag("usr.id", user.getId());
    span.setTag("usr.name", user.getName());
}
```

### **C) Create Facets (Makes Fields Searchable)**

**1. Navigate to Facets:**
```
APM → Traces → (left sidebar) → Facets section → "+ Add"
```

**2. Create these 4 facets:**

| Field Path | Display Name | Type |
|------------|--------------|------|
| @usr.id | User ID | String |
| @usr.name | User Name | String |
| @usr.email | User Email | String |
| @usr.phone | User Phone | String |

**3. Optional Privacy Facets (if needed):**
- `@usr.email_domain` - Email Domain
- `@usr.phone_last4` - Phone Last 4

### **D) Testing**

**1. Deploy code to DEV/UAT**

**2. Generate test traces (dummy users only!):**
```bash
curl -X POST https://dev-api.bradesco.com/api/onboarding/data-dump \
  -d '{"email":"test@example.com","phone":"555-0100","username":"testuser1"}'
```

**3. Verify search works:**
- Go to APM → Traces
- Search: `@usr.email:test@example.com`
- Should see the test trace

**4. Create optional monitor for testing:**
```
Query: error:true kube_namespace:bradesco env:dev @usr.email:*
Group by: @usr.email
Alert: ≥3 errors in 10m per user
Slack only
```

### **E) Production Deployment**

1. Deploy code via normal release process
2. Facets are global - they'll work in PROD automatically
3. Test with internal accounts only
4. **NEVER use real customer PII for testing**

---

## **📋 TICKET 3: Setup alert delivery (Slack + PagerDuty routing)**

### **A) What We're Building**

A **Composite Monitor** that only pages when MULTIPLE steps fail. This prevents alert fatigue while ensuring critical issues wake people up.

### **B) Prerequisites**

Get the 4 Monitor IDs from Ticket 1:
- Data Dump Monitor ID: _______
- User Check Monitor ID: _______  
- User Claim Monitor ID: _______
- Account Creation ID: _______

### **C) Create Composite Monitor (UAT First)**

**1. Navigate:**
```
Monitors → New Monitor → Composite
```

**2. Build the Formula:**

Click "Pick a monitor" and build this logic:
```
(DataDump AND UserExistence) OR (UserClaim AND AccountCreation)
```

This means: Alert if steps 1&2 BOTH fail, OR if steps 3&4 BOTH fail

**3. Settings:**
- **Evaluation window:** `last 10 minutes`
- **Recovery:** When monitors recover

**4. Name & Message:**
```
Name: [UAT] [FINTRON] [BRADESCO] - MULTI-STEP failure (composite)

Message:
🔴 Multiple onboarding steps failing - potential system outage!

Dashboard: https://app.datadoghq.com/dashboard/your-actual-id
Runbook: https://wiki.company.com/runbooks/bradesco-critical

@slack-fintron-uat-alerts
```

**5. Tags:**
- `env:uat`
- `team:fintron`
- `severity:p2`
- `owner:fintron-onboarding`

**6. Create**

### **D) Test Composite**

Trigger two monitors simultaneously:
```bash
# Trigger both Data Dump AND User Check
for i in {1..6}; do
  curl -X POST https://uat-api.bradesco.com/test/force-error \
    -d '{"step":"data-dump"}'
  curl -X POST https://uat-api.bradesco.com/test/force-error \
    -d '{"step":"user-check"}'
  sleep 30
done
```

Expected: Individual Slack alerts + Composite Slack alert

### **E) Production Setup**

**1. Clone per-step monitors to PROD:**
- Change `env:uat` → `env:prod`
- Keep Slack only initially
- Set `severity:p2`

**2. Clone composite to PROD:**
- Swap in PROD monitor IDs
- Add PagerDuty: `@slack-fintron-prod-alerts @pagerduty-fintron`
- Set `severity:p1`

**3. Wait 24-48 hours before enabling PagerDuty**

### **F) Final Alert Routing Matrix**

| Monitor Type | Environment | Severity | Slack | PagerDuty |
|-------------|-------------|----------|-------|-----------|
| Individual Steps | DEV/UAT | P3 | ✅ | ❌ |
| Composite | DEV/UAT | P2 | ✅ | ❌ |
| Individual Steps | PROD | P2 | ✅ | ❌ |
| Composite | PROD | P1 | ✅ | ✅ (after 24h) |

---

## **🚨 CRITICAL PRODUCTION SAFETY RULES**

### **Must Do:**
1. ✅ Use APM Trace Analytics, NOT Log monitors
2. ✅ Always include `kube_namespace:bradesco` in queries
3. ✅ Use EXACT resource names from your dashboard
4. ✅ Replace placeholder URLs with actual dashboard/runbook links
5. ✅ Test with dummy data only (never real PII)
6. ✅ Require 2+ consecutive failures (prevents flapping)
7. ✅ Start conservative (high thresholds), tune down gradually

### **Must NOT Do:**
1. ❌ Don't use Log monitors for APM data
2. ❌ Don't enable PagerDuty immediately
3. ❌ Don't store full email/phone in PROD (use masked versions)
4. ❌ Don't skip DEV/UAT testing
5. ❌ Don't use placeholder URLs like `{{dashboard_link}}`
6. ❌ Don't set "no-data" alerting for APM monitors

---

## **✅ FINAL CHECKLIST**

### **Ticket 1 Complete:**
- [ ] 4 APM Trace Analytics monitors created (NOT Logs)
- [ ] Each uses `status:error kube_namespace:bradesco env:dev`
- [ ] Multi-alert ON, grouped by `resource_name`
- [ ] 2 consecutive failures required
- [ ] Actual dashboard/runbook URLs in messages
- [ ] Monitor IDs documented

### **Ticket 2 Complete:**
- [ ] Code deployed with `usr.id/name/email/phone` tags
- [ ] 4 facets created in APM → Traces
- [ ] Search by user works
- [ ] Only dummy data used for testing

### **Ticket 3 Complete:**
- [ ] Composite monitor created with correct logic
- [ ] UAT tested successfully
- [ ] PROD setup with Slack (PagerDuty pending 24h)
- [ ] Alert routing documented

### **Production Ready:**
- [ ] 24-48 hour observation period complete
- [ ] No false positives
- [ ] Thresholds tuned appropriately
- [ ] Team trained on response
- [ ] Rollback procedure documented

