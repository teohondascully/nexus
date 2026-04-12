# Template — Monorepo Scaffold

> Run these commands to scaffold a new project in ~30 minutes. See [[Monorepo Patterns]] for the full rationale.

---

## Quick Setup Script

```bash
# 1. Initialize monorepo
mkdir my-project && cd my-project
git init
pnpm init

# 1.5. Pin runtime versions with mise
cat > .mise.toml << 'EOF'
[tools]
node = "22"
# python = "3.12"  # uncomment if using Python

[env]
NODE_ENV = "development"
EOF
mise install

# 2. Create workspace config
cat > pnpm-workspace.yaml << 'EOF'
packages:
  - "apps/*"
  - "packages/*"
  - "tooling/*"
EOF

# 3. Create directory structure
mkdir -p apps/web/src/{app,components,services,repositories,hooks,lib,types}
mkdir -p packages/{db/{schema,migrations},config,types,utils}
mkdir -p tooling/{eslint,tsconfig}
mkdir -p scripts
mkdir -p .github/workflows

# 4. Create base TypeScript config
cat > tooling/tsconfig/base.json << 'EOF'
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
    "incremental": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
EOF

# 5. Create docker-compose for local dev
cat > docker-compose.yml << 'EOF'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: myproject
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
EOF

# 6. Create .env.example
cat > .env.example << 'EOF'
DATABASE_URL=postgresql://dev:dev@localhost:5432/myproject
REDIS_URL=redis://localhost:6379

# Auth (fill in from provider dashboard)
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=

# Email
RESEND_API_KEY=

# Error tracking
SENTRY_DSN=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF

# 7. Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
.next/
dist/
.env
.env.local
.turbo/
*.tsbuildinfo
EOF

# 8. Create CLAUDE.md (see Template — CLAUDE.md for content)
touch CLAUDE.md
```

## After Scaffolding

1. `pnpm install` in root
2. Set up `turbo.json` (see [[Monorepo Patterns]])
3. Initialize your web app (`npx create-next-app apps/web` or similar)
4. Set up DB schema in `packages/db/` (see [[Template — Database Schema Starter]])
5. Write your [[Template — CLAUDE.md|CLAUDE.md]]
6. Set up CI (see [[The 15 Universal Layers#Layer 9 CI/CD Deployment]])

---

#templates #monorepo #scaffold
