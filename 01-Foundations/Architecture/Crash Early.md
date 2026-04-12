# Crash Early

> Validate at startup, fail fast, never silently swallow errors.

---

## The Principle

If something is going to fail, fail immediately with a clear error message — not halfway through a request, not silently, not in production at 3am.

## Where to Apply

### Startup Validation
Your app should crash on boot if a required env var is missing:

```typescript
// packages/config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  RESEND_API_KEY: z.string().min(1),
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

// Runs at import time — app won't start if invalid
export const env = envSchema.parse(process.env);
```

**Don't:** `const dbUrl = process.env.DATABASE_URL || ''` — silently uses empty string, fails later with a cryptic connection error.

### Request Boundaries
Validate input at the API boundary, before any business logic:

```typescript
const input = CreateOrderSchema.parse(req.body);
// Past this line, input is guaranteed valid
```

### Type Narrowing
Make invalid states unrepresentable:

```typescript
// Instead of: { status: string }
// Use: { status: 'pending' | 'processing' | 'shipped' | 'delivered' }
// Compiler catches invalid statuses
```

## The Error Hierarchy

Push errors UP this list. Earlier = cheaper.

1. **Compile-time** (TypeScript) — caught before code runs
2. **Startup** (env validation) — caught on deploy, before any user affected
3. **Request boundary** (Zod) — caught before business logic, clean error returned
4. **Business logic** (thrown errors) — caught in service layer, logged and reported
5. **Runtime** (unhandled) — Sentry catches it, you investigate later

---

## Related
- [[The 15 Universal Layers#Layer 6 Environment Configuration]]
- [[Idempotency Everywhere]]
- [[Verification Hierarchy]]

---

#foundations #design-principles
