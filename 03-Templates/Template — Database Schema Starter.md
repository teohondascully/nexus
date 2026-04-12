# Template — Database Schema Starter

> Base tables and conventions for every project. See [[Database Decision Tree]] for the full rationale.

---

## Base Schema (Drizzle + Postgres)

```typescript
// packages/db/schema/common.ts
import { pgTable, uuid, timestamp } from 'drizzle-orm/pg-core';

// Reusable column helpers
export const baseColumns = {
  id: uuid('id').primaryKey().defaultRandom(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  deletedAt: timestamp('deleted_at', { withTimezone: true }), // soft delete
};
```

```typescript
// packages/db/schema/users.ts
import { pgTable, uuid, text, timestamp, pgEnum } from 'drizzle-orm/pg-core';
import { baseColumns } from './common';

export const roleEnum = pgEnum('user_role', ['owner', 'admin', 'member', 'viewer']);

export const organizations = pgTable('organizations', {
  ...baseColumns,
  name: text('name').notNull(),
  slug: text('slug').notNull().unique(),
});

export const users = pgTable('users', {
  ...baseColumns,
  email: text('email').notNull().unique(),
  name: text('name'),
  authProviderId: text('auth_provider_id').notNull().unique(), // Clerk/Auth.js ID
  orgId: uuid('org_id').notNull().references(() => organizations.id),
  role: roleEnum('role').notNull().default('member'),
  lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
});

// Type exports (source of truth)
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Organization = typeof organizations.$inferSelect;
```

## Conventions

- All timestamps are `timestamptz` (with timezone), stored as UTC
- All IDs are UUIDs (no auto-incrementing integers — prevents enumeration attacks)
- Soft delete via `deleted_at` column (nullable = not deleted)
- Foreign keys always have an index
- Enums for fixed sets; lookup tables for dynamic sets

## Seed Script Template

```typescript
// packages/db/seed.ts
import { db } from './client';
import { organizations, users } from './schema';

async function seed() {
  console.log('🌱 Seeding...');

  const [org] = await db.insert(organizations).values({
    name: 'Acme Corp',
    slug: 'acme',
  }).returning();

  await db.insert(users).values([
    { email: 'admin@test.com', name: 'Admin User', authProviderId: 'test_admin', orgId: org.id, role: 'owner' },
    { email: 'member@test.com', name: 'Team Member', authProviderId: 'test_member', orgId: org.id, role: 'member' },
  ]);

  // Add 50 sample records for pagination/search testing
  // ...

  console.log('✅ Seed complete');
}

seed().catch(console.error);
```

---

#templates #database #schema
