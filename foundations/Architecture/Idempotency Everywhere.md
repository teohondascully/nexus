# Idempotency Everywhere

> Safe to retry, safe to double-submit. Every write operation should produce the same result if executed twice.

---

## The Principle

Users double-click buttons. Networks retry failed requests. Webhooks fire twice. Background jobs restart mid-execution. Your system must handle all of this gracefully.

## Where to Apply

### API Endpoints (Create Operations)
Use idempotency keys:

```typescript
async function createOrder(idempotencyKey: string, input: CreateOrderInput) {
  // Check if already completed
  const existing = await db.query.orders.findFirst({
    where: eq(orders.idempotencyKey, idempotencyKey)
  });
  if (existing) return existing; // same result
  
  return db.insert(orders).values({ ...input, idempotencyKey });
}
```

Frontend generates the idempotency key (UUID) on form load, not on submit. Same key = same result.

### Webhook Handlers
Stripe sends duplicates. Handle it:

```typescript
async function handleStripeWebhook(event: Stripe.Event) {
  const processed = await db.query.processedEvents.findFirst({
    where: eq(processedEvents.eventId, event.id)
  });
  if (processed) return; // already handled
  
  await processEvent(event);
  await db.insert(processedEvents).values({ eventId: event.id });
}
```

### Background Jobs
Every job must be safe to retry:

```typescript
async function processUpload(jobData: { fileId: string }) {
  const file = await db.query.files.findFirst({ where: eq(files.id, jobData.fileId) });
  if (file.status === 'processed') return; // already done
  
  await optimizeImage(file.url);
  await db.update(files).set({ status: 'processed' }).where(eq(files.id, file.id));
}
```

### Database Operations
Use upsert patterns:

```sql
INSERT INTO user_preferences (user_id, theme, language)
VALUES ($1, $2, $3)
ON CONFLICT (user_id) DO UPDATE SET theme = $2, language = $3;
```

## The Quick Test

For every write endpoint or job, ask: **"What happens if this runs twice with the same input?"**

- If "duplicate data" → add idempotency key
- If "an error" → add existence check
- If "same result" → you're good

---

## Related
- [[The 15 Universal Layers#Layer 5 Background Jobs Async Processing]]
- [[The 15 Universal Layers#Layer 11 Payments Billing]]
- [[Crash Early]]

---

#foundations #design-principles #idempotency
