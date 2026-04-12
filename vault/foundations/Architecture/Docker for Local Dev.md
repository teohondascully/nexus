# Docker for Local Dev

> Containerize your infrastructure from day 1. Your app code runs locally (fast hot reload), your services run in Docker (reproducible, disposable).

---

## The Philosophy

Don't containerize everything. Containerize the right things:

| Run Locally | Run in Docker |
|-------------|--------------|
| Your app code (Next.js, API server) | Postgres |
| Tests | Redis |
| Linting/typechecking | Elasticsearch/Typesense |
| Claude Code / Superpowers | MinIO (S3-compatible storage) |
| | Mailpit (email testing) |

**Why:** Hot reload and debugging are faster running natively. But you don't want to install Postgres/Redis/etc on your actual machine — they conflict across projects, are hard to version, and pollute your system.

---

## The docker-compose.yml Template

```yaml
# docker-compose.yml — local dev services
services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: myproject
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  # Email testing (catches all outgoing email)
  mailpit:
    image: axllent/mailpit
    ports:
      - "8025:8025"  # Web UI
      - "1025:1025"  # SMTP
    environment:
      MP_MAX_MESSAGES: 500

  # S3-compatible storage (for file uploads in dev)
  minio:
    image: minio/minio
    ports:
      - "9000:9000"  # API
      - "9001:9001"  # Console
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

volumes:
  postgres_data:
  minio_data:
```

## Usage

```bash
# Start all services (background)
docker compose up -d

# Check status
docker compose ps

# View logs for a specific service
docker compose logs -f postgres

# Stop everything
docker compose down

# Nuclear option: stop + delete all data
docker compose down -v
```

## The dev startup script

```bash
#!/bin/bash
# scripts/dev.sh — one command to start everything

# Start Docker services
docker compose up -d

# Wait for Postgres to be healthy
echo "Waiting for Postgres..."
until docker compose exec postgres pg_isready -U dev 2>/dev/null; do
  sleep 1
done

# Run migrations
pnpm db:migrate

# Seed if empty
pnpm db:seed

# Start the app
pnpm dev
```

Put this in your `package.json`:
```json
{
  "scripts": {
    "dev:setup": "bash scripts/dev.sh",
    "dev": "next dev",
    "db:migrate": "drizzle-kit push",
    "db:seed": "tsx packages/db/seed.ts",
    "db:studio": "drizzle-kit studio"
  }
}
```

---

## Production Dockerfile (Multi-Stage)

When you're ready to deploy, use a multi-stage build:

```dockerfile
# Stage 1: Install dependencies
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Stage 2: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN corepack enable pnpm && pnpm build
RUN pnpm prune --prod

# Stage 3: Production
FROM node:22-alpine AS runner
WORKDIR /app

# Security: non-root user
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder --chown=app:app /app/dist ./dist
COPY --from=builder --chown=app:app /app/node_modules ./node_modules
COPY --from=builder --chown=app:app /app/package.json ./

USER app
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

CMD ["node", "dist/index.js"]
```

**Key points:**
- Multi-stage keeps the final image small (only production deps + built code)
- Non-root user (security)
- Health check built in
- `--frozen-lockfile` ensures reproducible installs

## .dockerignore

```
node_modules
.next
dist
.env
.env.local
.git
*.md
```

---

## lazydocker

The `lazygit` of Docker. TUI for managing containers without memorizing flags:

```bash
brew install lazydocker
lazydocker  # or alias: alias lzd="lazydocker"
```

View logs, restart containers, shell in, inspect volumes — all from a keyboard-driven interface.

## dive

Inspect Docker image layers to find bloat:

```bash
brew install dive
dive myapp:latest
```

Shows exactly what's in each layer and what's wasting space.

---

## When to Fully Containerize Your App

For **solo founder / early stage:** Run app locally, services in Docker (as described above). Fastest dev loop.

For **team / onboarding:** Consider Dev Containers (`.devcontainer/`) so `git clone → open in VS Code → everything works`. Tradeoff is slower hot reload on macOS due to filesystem layer.

For **production:** Always containerize. Multi-stage Dockerfile, health checks, non-root user.

---

## Related
- [[The Developer Machine]] — machine-level setup
- [[Template — Monorepo Scaffold]] — where docker-compose.yml lives
- [[The 15 Universal Layers#Layer 9 CI/CD Deployment]]

---

#foundations #docker #dev-environment
