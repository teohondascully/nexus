#!/bin/bash
# cli/add-auth.sh — nexus add auth

cmd_add_auth() {
  print_header "Adding auth layer"

  mkdir -p src/lib

  drop_file "$TEMPLATES/auth/middleware.ts"  "src/middleware.ts"
  drop_file "$TEMPLATES/auth/auth.ts"        "src/lib/auth.ts"

  append_to_file ".env.example" "CLERK_SECRET_KEY" "
# Clerk Auth
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/" || true

  add_pending_install "pnpm add @clerk/nextjs"

  print_ok "Auth layer ready"
}
