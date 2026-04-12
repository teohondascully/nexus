# Core Loop First

> Every product has one atomic action that users repeat. Every architectural decision serves this loop.

---

## The Pattern

**Format:** `User does X → system does Y → user gets Z`

**Examples:**
- Twitter: compose → post → read timeline
- Stripe: create charge → settle → payout
- Uber: request ride → match driver → ride → pay
- Linear: create issue → assign → close
- Notion: create page → write → share

## Why This Matters

The core loop determines:
- **Database schema** — what entities exist and how they relate
- **API design** — which endpoints are hot paths
- **Testing priority** — E2E tests cover the core loop first
- **Performance budget** — the core loop must be fast, everything else can be acceptable
- **Error handling** — failures in the core loop are critical, failures elsewhere are tolerable
- **Analytics** — "% of signups who complete the core loop within 24h" is THE metric

## How to Use It

### During [[Template — Pre-Build Interrogation|Pre-Build Interrogation]]
Write it in one sentence. If you can't, you don't understand your product yet.

### During Architecture
For every decision, ask: "Does this make the core loop faster, more reliable, or more observable?" If not, defer it.

### During Testing
The core loop gets E2E coverage. Settings pages get nothing. See [[Verification Hierarchy]].

### During Analytics
Set up funnel tracking for the core loop before launch. See [[The 15 Universal Layers#Layer 15 Analytics Product Intelligence]].

---

#foundations #design-principles
