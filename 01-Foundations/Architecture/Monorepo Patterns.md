# Monorepo Patterns

> Layer 1 of [[The 15 Universal Layers]]. One repo, one CI, shared types.

---

## Why Monorepo (for Solo / Small Team)

- One `git clone` to get everything
- Shared TypeScript types — change the DB schema, get compile errors in the frontend immediately
- One CI pipeline to maintain
- Atomic commits across frontend + backend
- No dependency version drift between packages

## The Canonical Structure

```
/
├── apps/
│   ├── web/                  # Next.js / SvelteKit frontend
│   │   ├── src/
│   │   │   ├── app/          # Routes (thin — delegates to services)
│   │   │   ├── components/   # UI only, no business logic
│   │   │   ├── services/     # Business logic (no HTTP, no DB)
│   │   │   ├── repositories/ # DB queries (no business logic)
│   │   │   ├── hooks/        # React hooks (client state only)
│   │   │   ├── lib/          # Utils, config, third-party wrappers
│   │   │   └── types/        # Generated from DB schema
│   │   ├── public/
│   │   └── package.json
│   ├── api/                  # If backend is separate from web
│   └── mobile/               # If applicable
├── packages/
│   ├── db/                   # Schema, migrations, seed data
│   │   ├── schema/           # Drizzle/Prisma schema files
│   │   ├── migrations/       # Version-controlled migrations
│   │   ├── seed.ts           # Realistic dev data
│   │   └── package.json
│   ├── auth/                 # Auth logic shared across apps
│   ├── config/               # Shared env validation (Zod)
│   │   ├── env.ts            # Validated, typed config
│   │   └── constants.ts      # App-wide constants
│   ├── types/                # Shared TypeScript types / Zod schemas
│   │   ├── api.ts            # Request/response types
│   │   ├── domain.ts         # Business domain types
│   │   └── index.ts          # Re-exports
│   ├── utils/                # Pure functions, no side effects
│   └── ui/                   # Shared component library (if multi-app)
├── tooling/
│   ├── eslint/               # Shared lint config
│   │   └── base.js
│   └── tsconfig/             # Shared TS config
│       ├── base.json
│       ├── nextjs.json
│       └── library.json
├── scripts/                  # One-off scripts (migration helpers, seed, etc.)
├── docker-compose.yml        # Local dev: Postgres, Redis, etc.
├── turbo.json                # Monorepo task orchestration
├── pnpm-workspace.yaml       # Workspace definition
├── CLAUDE.md                 # Agent rules (see [[Template — CLAUDE.md]])
└── .github/
    └── workflows/
        ├── ci.yml            # Lint → typecheck → test → build
        └── deploy.yml        # Deploy to staging/prod
```

## Tooling Setup

### Turborepo (`turbo.json`)
```json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "typecheck": {},
    "test": {
      "dependsOn": ["^build"]
    }
  }
}
```

### pnpm workspace (`pnpm-workspace.yaml`)
```yaml
packages:
  - "apps/*"
  - "packages/*"
  - "tooling/*"
```

### TypeScript strict (`tooling/tsconfig/base.json`)
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "incremental": true
  }
}
```

## Dependency Direction Rule

This is the most important architectural constraint. Code can only import "forward" in this chain:

```
Types → Config → DB/Repo → Service → API Routes → UI Components → Pages
```

- A Service can import from Repo, but Repo can NEVER import from Service
- UI Components can import from Services, but Services can NEVER import from Components
- Types are at the root — everything can import types, types import nothing

Enforce this with a custom ESLint rule or `eslint-plugin-boundaries`. See [[Deterministic Enforcement]].

## One-Command Dev Setup

The goal: a new developer (or future you after 6 months) runs this and is working in 2 minutes:

```bash
git clone <repo>
pnpm install
cp .env.example .env.local  # fill in local values
docker compose up -d         # Postgres, Redis, etc.
pnpm db:migrate              # run migrations
pnpm db:seed                 # populate dev data
pnpm dev                     # start all apps
```

Put this in your README verbatim.

---

## Related
- [[The 15 Universal Layers#Layer 1 Repository Structure|Layer 1]]
- [[Types Flow Downstream]]
- [[Template — Monorepo Scaffold]]
- [[Deterministic Enforcement]] — how to enforce the dependency direction

---

#foundations #architecture #monorepo
