# Database Decision Tree

> Layer 2 of [[The 15 Universal Layers]]. The database defines your world. Everything downstream derives from it.

---

## The Decision

```
Start here: Is your data relational? (users have orgs, orgs have resources, etc.)
├── Yes (95% of apps) → Postgres
│   ├── Need serverless/branching? → Neon or Supabase
│   ├── Need MySQL compat? → PlanetScale
│   └── Self-hosting? → Plain Postgres on Fly.io/Railway
├── Mostly documents/flexible schema? → MongoDB (but probably still Postgres with JSONB)
└── Real-time sync to client? → Supabase (Postgres + realtime) or Firebase
```

**Default answer:** Postgres. It handles relational data, JSON documents (JSONB), full-text search, and time-series data. You almost never need a second database at the start.

## ORM Decision

| | Drizzle | Prisma |
|---|---------|--------|
| **Philosophy** | SQL-like, lightweight | Higher abstraction, more magic |
| **Type generation** | From your schema file | From introspection or schema |
| **Query style** | Looks like SQL | Object-oriented |
| **Raw SQL** | Easy to drop down | Possible but awkward |
| **Bundle size** | Small | Large (query engine) |
| **When to pick** | You know SQL, want control | You want convenience, large team |

**My preference:** Drizzle — closer to SQL, lighter, less magic to debug.

## Schema Conventions

### Every Table Gets These

```sql
id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
deleted_at  TIMESTAMPTZ          -- soft delete (nullable = not deleted)
```

### Naming
- Tables: `snake_case`, plural (`users`, `organizations`, `order_items`)
- Columns: `snake_case` (`first_name`, `stripe_customer_id`)
- Foreign keys: `[referenced_table_singular]_id` (`user_id`, `organization_id`)
- Indexes: `idx_[table]_[columns]` (`idx_orders_user_id`)
- Enums: `[table]_[column]_enum` or a lookup table

### Indexing Rules
- Every foreign key gets an index (Postgres doesn't do this automatically)
- Every column you `WHERE` on frequently gets an index
- Every column you `ORDER BY` frequently gets an index
- Composite indexes for common multi-column queries
- Don't over-index — each index slows writes

### Enums: Postgres Enum vs. Lookup Table

**Postgres enum** — when values are truly fixed and few:
```sql
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
```

**Lookup table** — when values might change or you need metadata:
```sql
CREATE TABLE order_statuses (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  sort_order INT NOT NULL
);
```

**Never:** magic strings in application code.

## Migration Discipline

- Naming: `YYYYMMDD_HHMMSS_descriptive_name.sql`
- Every migration must be reversible (have an `up` and `down`)
- Migrations run in CI before deploy — if a migration fails, the deploy is blocked
- Never edit a migration that's been applied to production — create a new one
- Test migrations against a copy of production data before applying

## Seed Script

Must exist. Must create a realistic dev environment:

```typescript
// packages/db/seed.ts
async function seed() {
  // Create a realistic set of test data
  const org = await createOrg({ name: 'Acme Corp' });
  const admin = await createUser({ email: 'admin@test.com', role: 'admin', orgId: org.id });
  const member = await createUser({ email: 'member@test.com', role: 'member', orgId: org.id });
  
  // Create enough data to test pagination, search, filtering
  for (let i = 0; i < 50; i++) {
    await createOrder({ userId: member.id, orgId: org.id, status: randomStatus() });
  }
}
```

Run with: `pnpm db:seed`

## When You Need More Than Postgres

| Need | Solution | When to Add |
|------|----------|-------------|
| Full-text search with typo tolerance | Typesense / Algolia | When `ILIKE` queries get slow or you need facets |
| Caching | Redis | When you're hitting the DB too often for the same read |
| Time-series data | TimescaleDB (Postgres extension) | When you have millions of time-stamped events |
| Real-time subscriptions | Supabase Realtime or websockets | When users need live updates |
| Vector search | pgvector (Postgres extension) | When you're building AI/semantic search features |

---

## Related
- [[The 15 Universal Layers#Layer 2 Type-Safe Database Layer]]
- [[Types Flow Downstream]]
- [[Template — Database Schema Starter]]

---

#foundations #stack-decisions #database
