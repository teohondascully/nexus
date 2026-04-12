#!/bin/bash
# cli/add-api.sh — nexus add api

cmd_add_api() {
  print_header "Adding API layer"

  mkdir -p src/server/routers src/lib

  drop_file "$TEMPLATES/api/trpc.ts"       "src/server/trpc.ts"
  drop_file "$TEMPLATES/api/health.ts"     "src/server/routers/health.ts"
  drop_file "$TEMPLATES/api/_app.ts"       "src/server/routers/_app.ts"
  drop_file "$TEMPLATES/api/api-error.ts"  "src/lib/api-error.ts"

  append_to_file "justfile" "api-health" "
# API
api-health:
    curl -s http://localhost:3000/api/trpc/health | jq ." || true

  add_pending_install "pnpm add @trpc/server @trpc/client @trpc/next"

  print_ok "API layer ready"
}
