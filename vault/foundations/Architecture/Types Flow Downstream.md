# Types Flow Downstream

> DB schema → API types → Client types. One source of truth. Zero manual duplication.

---

## The Principle

The database schema is the canonical definition of your data. Every type in your application is derived from it, never manually duplicated.

```
Postgres schema
    ↓ (Drizzle/Prisma generates)
TypeScript types (packages/types/)
    ↓ (imported by)
API layer (request/response types, Zod schemas)
    ↓ (imported by or inferred via tRPC)
Frontend components (props, state)
```

## Why This Matters

When you add a field to the database:
- **With type flow:** You add it to the schema, run codegen, and TypeScript errors show you every place that needs updating. Compile-time safety.
- **Without type flow:** You add it to the schema, manually update the API types, manually update the frontend types, hope you didn't miss anything, find out in production that you did.

## Implementation with Drizzle

```typescript
// packages/db/schema/orders.ts (source of truth)
export const orders = pgTable('orders', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  status: orderStatusEnum('status').notNull().default('pending'),
  total: integer('total').notNull(), // cents
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});

// Infer the TypeScript type FROM the schema
export type Order = typeof orders.$inferSelect;
export type NewOrder = typeof orders.$inferInsert;
```

```typescript
// packages/types/api.ts (derived from DB types)
import type { Order } from '@acme/db';

export type OrderResponse = Pick<Order, 'id' | 'status' | 'total' | 'createdAt'>;
export type CreateOrderInput = Pick<NewOrder, 'total'> & { productId: string };
```

```typescript
// apps/web/src/components/OrderCard.tsx (uses the same types)
import type { OrderResponse } from '@acme/types';

function OrderCard({ order }: { order: OrderResponse }) { ... }
```

## The Monorepo Makes This Work

This pattern requires shared packages — which is why [[Monorepo Patterns|monorepo]] is Layer 1. In a polyrepo setup, you'd need to publish packages or use code generation, both of which add friction.

## Anti-Patterns

- **Manual type duplication** — same interface defined in `/api/types.ts` and `/web/types.ts`
- **`any` as escape hatch** — defeats the entire system
- **Separate Zod schemas that don't derive from DB types** — two sources of truth that drift

---

## Related
- [[Monorepo Patterns]]
- [[Database Decision Tree]]
- [[The 15 Universal Layers#Layer 1 Repository Structure]]

---

#foundations #design-principles #types
