# Template — Audit Checklist

> Before shipping, run this. If a 50-person team were reviewing your codebase, these are what they'd check.

---

## Developer Experience
- [ ] Can a new dev run the app locally with ONE command? (`pnpm dev` after setup)
- [ ] Is there a README that explains: what this is, how to run it, how to deploy it, how to test?
- [ ] Does `git clone → install → setup → dev` take under 5 minutes?

## Architecture
- [ ] Do types flow end-to-end from DB → API → client with zero manual duplication?
- [ ] Does every API endpoint validate input, check auth, and return consistent errors?
- [ ] Is business logic in services, not route handlers or components?
- [ ] Does the dependency direction hold across the entire codebase?

## Quality
- [ ] Is there a CI pipeline that blocks merging broken code?
- [ ] Do database migrations run forward and backward cleanly?
- [ ] Is the core loop covered by at least one E2E test?
- [ ] Does `pnpm test` pass with no flaky failures?
- [ ] Are there no `any` types, `@ts-ignore`, or unexplained `eslint-disable`?

## Operations
- [ ] Can you find the root cause of a production error within 5 minutes? (logs + error tracking)
- [ ] Is every secret in env vars, never in code, never logged?
- [ ] Can you deploy to production with confidence in under 5 minutes?
- [ ] Can you roll back a bad deploy in under 2 minutes?

## Resilience
- [ ] Are background jobs idempotent and retryable?
- [ ] Does the app handle double-submissions gracefully?
- [ ] Does the app crash on startup if a required env var is missing?
- [ ] Are webhook handlers idempotent?

## Authorization
- [ ] Is authorization centralized in a `can()` function, not scattered?
- [ ] Does every endpoint check permissions?
- [ ] Can you force-logout a compromised session?

## Shipping Readiness
- [ ] Are feature flags in place for anything you might need to kill quickly?
- [ ] Is error tracking (Sentry) configured and receiving events?
- [ ] Is there uptime monitoring?
- [ ] Are analytics tracking the core loop funnel?

---

## Scoring
Count the checked boxes. Total possible: 22.

- **20-22:** Ship with confidence. This looks professional.
- **15-19:** Ship, but schedule the gaps for next sprint.
- **10-14:** Fix the critical ones (Operations + Architecture) before shipping.
- **Below 10:** You're at [[The Fractal Harness Stack|Level 1]]. Work through the [[The 15 Universal Layers|Foundation layers]] first.

---

#templates #audit #checklist
