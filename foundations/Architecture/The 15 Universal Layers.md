# The 15 Universal Layers

> Every serious product converges on these same layers. They're listed in dependency order — each builds on the ones above it.

---

## The Build Sequence

Build in this order for a new project. Total foundation before the actual product: ~1-2 days first time, afternoon by the third project.

```
1. Monorepo scaffold + tooling (30 min)
2. Database schema + migrations + seed (2-4 hrs)
3. Auth integration (1-2 hrs)
4. Core API routes with validation (2-4 hrs)
5. CI pipeline — lint, type check, test (1 hr)
6. Basic frontend with auth flow (2-4 hrs)
7. Core loop — the one thing your app does (the actual work)
8. Error tracking + structured logging (1 hr)
9. Background jobs for async work (as needed)
10. Preview deployments + production deploy (1-2 hrs)
11. Everything else — payments, email, search, analytics — as needed
```

---

## Layer 1: Repository Structure

**Decision:** Monorepo. Always. One `git clone`, one CI pipeline, shared types.

See [[Monorepo Patterns]] for the full directory structure and tooling.

**Tools:** Turborepo or Nx. pnpm workspaces.

**Non-negotiable:** Types flow from database schema → API → client. One source of truth. Zero manual type duplication. See [[Types Flow Downstream]].

---

## Layer 2: Type-Safe Database Layer

**Decision:** Database schema defines the world. Everything downstream derives from it.

**Stack:** Postgres (unless you have a specific reason not to) + Prisma or Drizzle.

See [[Database Decision Tree]] for the full decision framework.

**What "done right" looks like:**
- Every table has: `id`, `created_at`, `updated_at`, `deleted_at` (soft delete)
- Every foreign key has an index
- Every enum is a Postgres enum or lookup table, never a magic string
- Seed script populates a realistic dev environment in one command
- Migration naming: `YYYYMMDD_HHMMSS_descriptive_name`
- Migrations are version-controlled, reversible, and run in CI before deploy

See [[Template — Database Schema Starter]] for the base table template.

---

## Layer 3: Authentication & Authorization

**Decision:** Buy the auth layer. Build the authorization logic.

See [[Auth Build vs Buy]] for the full breakdown.

**Auth (identity):** Clerk, Supabase Auth, or Auth.js — signup, login, OAuth, MFA, sessions.

**Authorization (permissions):** YOUR code. Encodes your business logic.

**The pattern that scales:**
```
User → belongs to → Organization → has role → (owner | admin | member | viewer)
Resource → belongs to → Organization
Permission check: can(user, action, resource) → boolean
```

**What "done right" looks like:**
- Auth middleware runs on every request, no exceptions
- Authorization is a single function, not scattered `if` checks
- Roles stored in database, not hardcoded
- Every API endpoint documents its required permission
- Session invalidation works (can force-logout a compromised account)

---

## Layer 4: API Design

**Decision:** REST vs. GraphQL vs. tRPC?

See [[API Design Patterns]] for the full decision framework.

**Non-negotiables regardless of choice:**
- Consistent error format: `{ code, message, details }`
- Pagination on every list endpoint (cursor-based, not offset)
- Rate limiting from day 1
- Request validation at the boundary (Zod schemas)
- Versioning strategy decided before v1 ships

**What "done right" looks like:**
- Every endpoint: input validation → auth check → business logic → response serialization (in that order)
- No business logic in route handlers. Handlers are thin wrappers around service functions
- Service functions are testable without HTTP

See [[Template — API Route Checklist]].

---

## Layer 5: Background Jobs & Async Processing

**Trigger:** sending emails, processing uploads, syncing with third parties, generating reports, scheduled tasks → you need this.

**Stack:** Inngest, Trigger.dev, or BullMQ + Redis.

**What "done right" looks like:**
- Every job is idempotent (safe to retry). See [[Idempotency Everywhere]]
- Every job has a timeout and max retry count
- Failed jobs go to a dead letter queue you can inspect
- Job status is queryable (user sees "processing..." → "done")
- Scheduled jobs (cron) defined in code, not in a dashboard

---

## Layer 6: Environment & Configuration

**The pattern:**
```
.env.local          → local dev (git-ignored)
.env.example        → template committed to git (no real values)
Environment vars    → staging/production (set in deployment platform)
Zod schema          → validates all env vars at startup
```

**What "done right" looks like:**
- App crashes on startup if a required env var is missing. See [[Crash Early]]
- One `env.ts` file exports validated, typed config. Everything imports from there
- Secrets never logged, never in error messages, never in client bundles
- Different configs for dev/staging/prod are explicit, not implicit

---

## Layer 7: Error Handling & Observability

**Stack:**
- **Error tracking:** Sentry (stack traces, breadcrumbs, user context)
- **Logging:** Structured JSON logs. Axiom, Datadog, or Logtail
- **Uptime:** Betterstack or health check endpoint + cron ping

**What "done right" looks like:**
- Every error has: timestamp, request ID, user ID, stack trace, reproduction context
- Errors categorized: operational (expected, handle gracefully) vs. programmer (bug, alert immediately)
- Single request ID flows through frontend → API → background jobs → third-party calls
- Alerted on Slack/SMS within 60 seconds of a production error
- Logs searchable by user ID

---

## Layer 8: Testing Strategy

**The pyramid that works for a solo founder:**

1. **Type system** (free) — TypeScript strict mode catches ~40% of bugs at compile time
2. **Schema validation** (cheap) — Zod at API boundaries catches malformed data
3. **Integration tests** (high ROI) — service functions against a real test DB. These catch real bugs
4. **E2E tests** (selective) — Playwright for core loop only. Don't E2E test settings pages
5. **Unit tests** (for complex logic) — pure functions with tricky logic, not CRUD

See [[Verification Hierarchy]] for how this connects to the harness engineering model.

**What "done right" looks like:**
- `pnpm test` runs in CI on every PR. Merging requires green
- Test DB spins up in Docker, migrates, seeds, tests, tears down
- Core loop has E2E coverage
- Tests run in under 2 minutes. Slow tests don't get run

---

## Layer 9: CI/CD & Deployment

**The pipeline:**
```
Push to main → Lint → Type check → Test → Build → Deploy to staging (auto)
                                                  → Deploy to prod (manual or auto)
```

**Stack:** GitHub Actions + Vercel/Railway/Fly.io. Preview deploys on every PR.

**What "done right" looks like:**
- Every PR gets a preview URL
- Production deploys are atomic — all succeed or nothing changes
- DB migrations run before new code goes live (not after)
- Rollback is one button or one command
- Deploy takes under 3 minutes

---

## Layer 10: File Storage & Media

**Stack:** UploadThing, Cloudinary, or direct to S3/R2 with signed URLs.

**What "done right" looks like:**
- Files never touch your server's disk — stream directly to object storage
- File type + size validation client-side AND server-side
- Every file has a UUID-based key (not user-provided filenames)
- Signed URLs for private files (expire after N minutes)
- Image optimization pipeline (resize, compress, WebP) runs async

---

## Layer 11: Payments & Billing

**Decision:** Stripe. That's the decision.

**What "done right" looks like:**
- Webhook handler is idempotent (Stripe sends duplicates)
- Sub state lives in Stripe; your DB stores `stripe_customer_id` and caches the plan
- Entitlement checks (`canUserDoX`) read from DB cache, not live Stripe calls
- Failed payment → grace period → downgrade is automated
- Pricing page values come from config, not hardcoded in frontend

---

## Layer 12: Transactional Email & Notifications

**Stack:** Resend or Postmark for email. React Email for templates.

**What "done right" looks like:**
- Email sending is a background job, never blocking the request
- Templates are React components (type-safe, previewable)
- Every email has: unsubscribe link, plain-text fallback, preview text
- Notification preferences are user-configurable from day 1

---

## Layer 13: Feature Flags & Gradual Rollout

**Stack:** LaunchDarkly, Flagsmith, or a `features` table in your DB.

**What "done right" looks like:**
- New features ship behind a flag. Enable for internal users first
- Flags evaluated server-side (not shipped in client bundle)
- Dead flags get cleaned up — stale flags are tech debt
- Core loop NEVER depends on feature flag service being up

---

## Layer 14: Search

**Stack:** Typesense (self-hostable, fast) or Algolia (managed, pricier).

**What "done right" looks like:**
- Search index syncs from DB via background job (not inline on write)
- Typo tolerance, faceted filtering, relevance tuning from day 1
- Search results respect authorization — users only see what they're allowed to

---

## Layer 15: Analytics & Product Intelligence

**Stack:** PostHog (open source, does analytics + session replay + feature flags).

**What "done right" looks like:**
- Track events, not pageviews. "User completed core loop" > "user visited /dashboard"
- Event schema is defined and consistent: `{ event, properties, user_id, timestamp }`
- Funnels for core loop set up before launch
- Can answer: "What % of signups complete the core action within 24 hours?"

---

## Related
- [[Template — Pre-Build Interrogation]] — Phase 0, before you touch these layers
- [[Template — Audit Checklist]] — Phase 3, verify all layers before shipping
- [[Tools]] — current best-in-class tool for each layer

---

#foundations #architecture #layers
