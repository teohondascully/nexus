#!/bin/bash
# cli/add-db.sh — nexus add db

cmd_add_db() {
  print_header "Adding database layer"

  mkdir -p packages/db/schema

  drop_file "$TEMPLATES/db/docker-compose.yml"  "docker-compose.yml"
  drop_file "$TEMPLATES/db/schema.ts"           "packages/db/schema/index.ts"
  drop_file "$TEMPLATES/db/migrate.ts"          "packages/db/migrate.ts"
  drop_file "$TEMPLATES/db/seed.ts"             "packages/db/seed.ts"

  append_to_file ".env.example" "DATABASE_URL" "
# Database
DATABASE_URL=postgresql://dev:dev@localhost:5432/myproject
REDIS_URL=redis://localhost:6379" || true

  append_to_file "justfile" "db-migrate" "
# Database
db-migrate:
    pnpm drizzle-kit migrate

db-seed:
    bun packages/db/seed.ts

db-reset:
    docker compose down -v
    docker compose up -d
    sleep 2
    just db-migrate
    just db-seed

db-studio:
    pnpm drizzle-kit studio" || true

  check_prereq docker "Install Docker: https://docs.docker.com/get-docker/" || true

  add_pending_install "pnpm add drizzle-orm postgres"
  add_pending_install "pnpm add -D drizzle-kit"

  print_ok "Database layer ready"
}
