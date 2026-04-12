# Nexus CLI Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the prompt-builder nexus CLI with a project initializer + maintenance system that drops conventions into any project and keeps them enforced over time.

**Architecture:** Bash CLI entry point (`nexus`) dispatches to command scripts in `cli/`. Template files live in `init-templates/` and get copied into target projects. TypeScript scripts (via Bun) handle import parsing for dependency direction and dead export checks.

**Tech Stack:** Bash (CLI), TypeScript/Bun (import analysis scripts), lefthook (git hooks), Claude Code hooks API

---

## File Structure

```
~/.nexus/
├── nexus                              # Main entry point — dispatches to cli/ commands
├── cli/
│   ├── helpers.sh                     # Shared: colors, file conflict handler, prereq checks, checksum utils
│   ├── init.sh                        # nexus init — wizard + core file drops
│   ├── add-db.sh                      # nexus add db
│   ├── add-auth.sh                    # nexus add auth
│   ├── add-api.sh                     # nexus add api
│   ├── add-hooks.sh                   # nexus add hooks
│   ├── add-ci.sh                      # nexus add ci
│   ├── doctor.sh                      # nexus doctor (--quick, --fix)
│   └── update.sh                      # nexus update — vault sync
├── init-templates/
│   ├── core/
│   │   ├── CLAUDE.md.web-app          # CLAUDE.md template for web apps
│   │   ├── CLAUDE.md.other            # CLAUDE.md template for generic projects
│   │   ├── justfile.web-app           # justfile with full web app commands
│   │   ├── justfile.other             # justfile with generic commands
│   │   ├── gitignore                  # .gitignore (no dot prefix to avoid self-ignoring)
│   │   ├── env.example                # .env.example starter
│   │   ├── mise.toml                  # .mise.toml
│   │   └── pull_request_template.md   # PR checklist
│   ├── scripts/
│   │   ├── sync-claude-md.sh          # Regenerates CLAUDE.md file structure section
│   │   ├── check-env-sync.sh          # Warns on env var mismatches
│   │   ├── check-deps-direction.ts    # Import direction linter (Bun)
│   │   ├── check-dead-exports.ts      # Dead export detector (Bun)
│   │   └── validate-startup.sh        # Crashes if required env vars missing
│   ├── hooks/
│   │   ├── lefthook.yml               # Pre-commit config
│   │   ├── claude-settings.json       # Claude Code hooks (standalone)
│   │   └── claude-settings-superpowers.json  # Claude Code hooks (with Superpowers)
│   ├── db/
│   │   ├── docker-compose.yml         # Postgres + Redis + Mailpit
│   │   ├── schema.ts                  # Drizzle starter schema
│   │   ├── migrate.ts                 # Migration runner
│   │   └── seed.ts                    # Seed script skeleton
│   ├── auth/
│   │   ├── middleware.ts              # Clerk middleware
│   │   └── auth.ts                    # Auth helpers
│   ├── api/
│   │   ├── trpc.ts                    # tRPC initialization
│   │   ├── health.ts                  # /api/health endpoint
│   │   ├── _app.ts                    # Root router
│   │   └── api-error.ts              # Error format
│   └── ci/
│       └── ci.yml                     # GitHub Actions workflow
├── bootstrap.sh                       # (existing — untouched)
├── install.sh                         # (existing — untouched)
└── docs/superpowers/specs/...         # (existing — untouched)
```

---

### Task 1: CLI Skeleton + Helpers

**Files:**
- Rewrite: `nexus`
- Create: `cli/helpers.sh`

- [ ] **Step 1: Create cli/ directory**

```bash
mkdir -p /Users/thondascully/all/projects/nexus/cli
```

- [ ] **Step 2: Write cli/helpers.sh — shared utilities**

Create `cli/helpers.sh` with these functions:
- Colors and formatting (RED, GREEN, YELLOW, BLUE, CYAN, DIM, BOLD, NC)
- `has_cmd <name>` — checks if a command exists
- `check_git` — exits with error if git isn't available
- `check_prereq <cmd> <message>` — warns if a command is missing, returns 1
- `drop_file <source> <dest>` — copies a template file, handling conflicts (Overwrite/Skip/Diff)
- `append_to_file <file> <marker> <content>` — appends content to a file if marker not already present
- `update_checksum <file>` — stores md5 hash in `.nexus-checksums`
- `is_customized <file>` — checks if file differs from stored checksum
- `print_header <text>` — prints a formatted section header
- `print_ok <text>` — prints green checkmark
- `print_fail <text>` — prints red X
- `print_warn <text>` — prints yellow warning
- `print_skip <text>` — prints dim skip message

```bash
#!/bin/bash
# cli/helpers.sh — shared utilities for nexus commands

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── Resolve vault directory ─────────────────────────────────────
resolve_vault_dir() {
  local source="${BASH_SOURCE[0]}"
  while [ -L "$source" ]; do
    local dir="$(cd "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source"
  done
  echo "$(cd "$(dirname "$source")/.." && pwd)"
}

VAULT_DIR="$(resolve_vault_dir)"
TEMPLATES="$VAULT_DIR/init-templates"

# ── Prereq Checks ───────────────────────────────────────────────
has_cmd() {
  command -v "$1" &> /dev/null
}

check_git() {
  if ! has_cmd git; then
    echo -e "${RED}git not found.${NC} Run: curl -fsSL https://www.teonnaise.com/install | bash"
    exit 1
  fi
}

check_prereq() {
  local cmd="$1"
  local msg="$2"
  if ! has_cmd "$cmd"; then
    echo -e "  ${YELLOW}!${NC} $cmd not found. $msg"
    return 1
  fi
  return 0
}

# ── Output Helpers ───────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "  ${BOLD}$1${NC}"
  echo ""
}

print_ok() {
  echo -e "  ${GREEN}ok${NC}  $1"
}

print_fail() {
  echo -e "  ${RED}FAIL${NC}  $1"
}

print_warn() {
  echo -e "  ${YELLOW}!${NC}  $1"
}

print_skip() {
  echo -e "  ${DIM}skip${NC}  $1"
}

# ── File Conflict Handler ────────────────────────────────────────
# Usage: drop_file <source_template> <dest_path>
# If dest exists, asks Overwrite/Skip/Diff
drop_file() {
  local src="$1"
  local dest="$2"
  local dest_dir="$(dirname "$dest")"

  mkdir -p "$dest_dir"

  if [ -f "$dest" ]; then
    local basename="$(basename "$dest")"
    echo -e "  ${YELLOW}$basename${NC} already exists. [${BOLD}O${NC}]verwrite / [${BOLD}S${NC}]kip / [${BOLD}D${NC}]iff?"
    while true; do
      printf "  "
      read -n 1 -r choice
      echo ""
      case $choice in
        [oO]) cp "$src" "$dest"; update_checksum "$dest"; echo -e "  ${GREEN}overwrote${NC} $basename"; return 0 ;;
        [sS]) echo -e "  ${DIM}skipped${NC} $basename"; return 1 ;;
        [dD]) diff --color=always "$dest" "$src" | head -40; echo ""; ;;
        *) echo "  o/s/d?" ;;
      esac
    done
  else
    cp "$src" "$dest"
    update_checksum "$dest"
    echo -e "  ${GREEN}created${NC} $(basename "$dest")"
    return 0
  fi
}

# ── Checksum Tracking ────────────────────────────────────────────
CHECKSUM_FILE=".nexus-checksums"

update_checksum() {
  local file="$1"
  local hash
  hash=$(md5 -q "$file" 2>/dev/null || md5sum "$file" | cut -d' ' -f1)
  local rel_path="$file"

  # Remove existing entry
  if [ -f "$CHECKSUM_FILE" ]; then
    grep -v "^$rel_path " "$CHECKSUM_FILE" > "$CHECKSUM_FILE.tmp" 2>/dev/null || true
    mv "$CHECKSUM_FILE.tmp" "$CHECKSUM_FILE"
  fi

  echo "$rel_path $hash" >> "$CHECKSUM_FILE"
}

is_customized() {
  local file="$1"
  if [ ! -f "$CHECKSUM_FILE" ]; then
    return 0  # no checksums = assume customized
  fi
  local stored_hash
  stored_hash=$(grep "^$file " "$CHECKSUM_FILE" 2>/dev/null | awk '{print $2}')
  if [ -z "$stored_hash" ]; then
    return 0  # not tracked = assume customized
  fi
  local current_hash
  current_hash=$(md5 -q "$file" 2>/dev/null || md5sum "$file" | cut -d' ' -f1)
  [ "$stored_hash" != "$current_hash" ]
}

# ── Pending Installs Tracker ─────────────────────────────────────
PENDING_INSTALLS=""

add_pending_install() {
  PENDING_INSTALLS="${PENDING_INSTALLS}    $1\n"
}

# ── Append with Marker ───────────────────────────────────────────
# Usage: append_to_file <file> <marker> <content>
# Only appends if marker is not already in the file
append_to_file() {
  local file="$1"
  local marker="$2"
  local content="$3"

  if [ -f "$file" ] && grep -q "$marker" "$file" 2>/dev/null; then
    return 1  # already present
  fi

  echo "$content" >> "$file"
  return 0
}
```

- [ ] **Step 3: Rewrite the nexus entry point**

Replace the entire contents of `nexus` with a clean dispatcher:

```bash
#!/bin/bash
# nexus — Project initializer + maintenance system
# https://github.com/teohondascully/nexus

set -e

# Resolve through symlinks to find the real vault location
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
NEXUS_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"

# Source helpers
source "$NEXUS_DIR/cli/helpers.sh"

# ── Help ─────────────────────────────────────────────────────────
cmd_help() {
  echo ""
  echo -e "  ${BOLD}nexus${NC} — project initializer + maintenance"
  echo ""
  echo -e "  ${BOLD}Setup${NC}"
  echo -e "    ${GREEN}init${NC} [name]       Create or configure a project"
  echo -e "    ${GREEN}add${NC}  <layer>      Add a layer: db, auth, api, hooks, ci"
  echo ""
  echo -e "  ${BOLD}Maintain${NC}"
  echo -e "    ${GREEN}doctor${NC}            Run all maintenance checks"
  echo -e "    ${GREEN}doctor${NC} --quick    Fast checks only (no network/DB)"
  echo -e "    ${GREEN}doctor${NC} --fix      Auto-fix what it can"
  echo -e "    ${GREEN}update${NC}            Sync project against latest vault templates"
  echo ""
}

# ── Dispatch ─────────────────────────────────────────────────────
case "${1:-}" in
  init)       shift; source "$NEXUS_DIR/cli/init.sh"; cmd_init "$@" ;;
  add)        shift; 
              case "${1:-}" in
                db)    source "$NEXUS_DIR/cli/add-db.sh";    cmd_add_db ;;
                auth)  source "$NEXUS_DIR/cli/add-auth.sh";  cmd_add_auth ;;
                api)   source "$NEXUS_DIR/cli/add-api.sh";   cmd_add_api ;;
                hooks) source "$NEXUS_DIR/cli/add-hooks.sh"; cmd_add_hooks ;;
                ci)    source "$NEXUS_DIR/cli/add-ci.sh";    cmd_add_ci ;;
                "")    echo -e "${RED}Usage: nexus add <db|auth|api|hooks|ci>${NC}" ;;
                *)     echo -e "${RED}Unknown layer: $1${NC}. Options: db, auth, api, hooks, ci" ;;
              esac ;;
  doctor)     shift; source "$NEXUS_DIR/cli/doctor.sh"; cmd_doctor "$@" ;;
  update)     source "$NEXUS_DIR/cli/update.sh"; cmd_update ;;
  help|--help|-h) cmd_help ;;
  "")         cmd_help ;;
  *)          echo -e "${RED}Unknown command: $1${NC}"; cmd_help ;;
esac
```

- [ ] **Step 4: Test the skeleton**

```bash
cd /Users/thondascully/all/projects/nexus && ./nexus
./nexus help
./nexus add
./nexus add bogus
```

Expected: help output for first three, "Unknown layer" for the last.

- [ ] **Step 5: Commit**

```bash
git add nexus cli/helpers.sh
git commit -m "feat(nexus): rewrite CLI skeleton with modular command dispatch"
```

---

### Task 2: Core Templates — CLAUDE.md, justfile, gitignore, env, mise, PR template

**Files:**
- Create: `init-templates/core/CLAUDE.md.web-app`
- Create: `init-templates/core/CLAUDE.md.other`
- Create: `init-templates/core/justfile.web-app`
- Create: `init-templates/core/justfile.other`
- Create: `init-templates/core/gitignore`
- Create: `init-templates/core/env.example`
- Create: `init-templates/core/mise.toml`
- Create: `init-templates/core/pull_request_template.md`

- [ ] **Step 1: Create init-templates/core/ directory**

```bash
mkdir -p /Users/thondascully/all/projects/nexus/init-templates/core
```

- [ ] **Step 2: Write CLAUDE.md.web-app**

This is the vault's CLAUDE.md template with the web app stack pre-filled. The `<!-- FILE_STRUCTURE -->` marker is what `sync-claude-md.sh` will replace:

```markdown
# CLAUDE.md

## Project Overview
<!-- One paragraph: what this app does, who it's for, what the core loop is -->

## Tech Stack
- **Framework:** Next.js (App Router)
- **Language:** TypeScript (strict mode)
- **Database:** Postgres via Drizzle ORM
- **Auth:** Clerk
- **API:** tRPC
- **Styling:** Tailwind + shadcn/ui
- **Deployment:** Vercel

## Architecture Rules

### Dependency Direction
Types → Config → Repo → Service → Runtime → UI
Code may only import "forward" in this chain. Enforced by `scripts/check-deps-direction.ts`.

### File Structure
<!-- FILE_STRUCTURE_START -->
<!-- Auto-generated by scripts/sync-claude-md.sh — do not edit this section manually -->
<!-- FILE_STRUCTURE_END -->

### Conventions
- All API responses follow: `{ data, error, metadata }`
- All errors follow: `{ code, message, details }`
- All database tables have: `id`, `created_at`, `updated_at`, `deleted_at`
- No `any` types. No `@ts-ignore`. No `eslint-disable` without a comment explaining why.
- No business logic in route handlers or components.
- No direct database calls outside `/repositories`.

## Testing Requirements
- Run `pnpm test` after every change.
- **Never remove or weaken existing tests.** If a test fails, fix the implementation.
- New features require at least one integration test.
- Core loop changes require E2E coverage.

## Code Style
- Prefer named exports over default exports.
- Prefer `const` arrow functions for components.
- Prefer early returns over nested conditionals.
- Max function length: 30 lines. If longer, extract.
- Max file length: 200 lines. If longer, split.

## Git Conventions
- Commit after each successful step, not after a feature is complete.
- Commit messages: `type(scope): description`
- Never commit `.env` files or secrets.

## When In Doubt
- Check existing code for patterns before inventing new ones.
- If a decision isn't covered here, ask — don't assume.
- Prefer boring technology over clever technology.
```

- [ ] **Step 3: Write CLAUDE.md.other**

Same structure but with blank stack and generic file structure:

```markdown
# CLAUDE.md

## Project Overview
<!-- One paragraph: what this app does, who it's for, what the core loop is -->

## Tech Stack
<!-- Fill in your stack here -->

## Architecture Rules

### Dependency Direction
<!-- Define your dependency chain here. Example: Types → Config → Repo → Service → Runtime → UI -->
<!-- Enforced by scripts/check-deps-direction.ts if configured -->

### File Structure
<!-- FILE_STRUCTURE_START -->
<!-- Auto-generated by scripts/sync-claude-md.sh — do not edit this section manually -->
<!-- FILE_STRUCTURE_END -->

### Conventions
<!-- Add project-specific conventions here -->
- No `any` types. No `@ts-ignore`. No `eslint-disable` without a comment explaining why.

## Testing Requirements
- Run tests after every change.
- **Never remove or weaken existing tests.** If a test fails, fix the implementation.

## Code Style
- Prefer early returns over nested conditionals.

## Git Conventions
- Commit after each successful step, not after a feature is complete.
- Commit messages: `type(scope): description`
- Never commit `.env` files or secrets.

## When In Doubt
- Check existing code for patterns before inventing new ones.
- If a decision isn't covered here, ask — don't assume.
```

- [ ] **Step 4: Write justfile.web-app**

```just
# justfile — project commands
# Run with: just <command>

dev:
    docker compose up -d
    pnpm dev

build:
    pnpm build

test:
    pnpm test

typecheck:
    pnpm typecheck

lint:
    pnpm lint

# ── Database ─────────────────────────────────────────────
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
    pnpm drizzle-kit studio

# ── Quality ──────────────────────────────────────────────
doctor:
    nexus doctor

doctor-fix:
    nexus doctor --fix

outdated:
    pnpm outdated

dead-code:
    bun scripts/check-dead-exports.ts

audit:
    just doctor && just outdated && just dead-code
```

- [ ] **Step 5: Write justfile.other**

```just
# justfile — project commands
# Run with: just <command>

dev:
    echo "Configure your dev command here"

build:
    echo "Configure your build command here"

test:
    echo "Configure your test command here"

# ── Quality ──────────────────────────────────────────────
doctor:
    nexus doctor

doctor-fix:
    nexus doctor --fix

audit:
    just doctor
```

- [ ] **Step 6: Write gitignore**

```
node_modules/
.next/
dist/
build/
.env
.env.local
.env.*.local
.turbo/
*.tsbuildinfo
.DS_Store
.nexus-checksums
coverage/
.vercel/
```

- [ ] **Step 7: Write env.example**

```bash
# App
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- [ ] **Step 8: Write mise.toml**

```toml
[tools]
node = "24"

[settings]
auto_install = true
```

- [ ] **Step 9: Write pull_request_template.md**

Extract the checklist from the vault's PR Review Checklist template (`templates/Template — PR Review Checklist.md`):

```markdown
## Summary
<!-- What changed and why -->

## Checklist

### Architecture
- [ ] Dependency direction holds (no backward imports)
- [ ] Business logic in services, not route handlers or components
- [ ] New files follow existing naming conventions

### Types & Validation
- [ ] No `any` types or `@ts-ignore` introduced
- [ ] New API inputs validated with Zod at the boundary
- [ ] Types derive from DB schema, not manually duplicated

### Testing
- [ ] No existing tests removed or weakened
- [ ] At least one test for the happy path
- [ ] Core loop changes have E2E coverage

### Security
- [ ] Auth check on every new endpoint
- [ ] No secrets hardcoded
- [ ] No unsanitized user input in DB queries or HTML

### Agent Red Flags
- [ ] No hallucinated imports (packages not in package.json)
- [ ] No over-abstracted code for simple operations
- [ ] No TODO comments left behind
```

- [ ] **Step 10: Verify all files exist**

```bash
ls -la /Users/thondascully/all/projects/nexus/init-templates/core/
```

Expected: 8 files (CLAUDE.md.web-app, CLAUDE.md.other, justfile.web-app, justfile.other, gitignore, env.example, mise.toml, pull_request_template.md)

- [ ] **Step 11: Commit**

```bash
git add init-templates/core/
git commit -m "feat(nexus): add core project templates"
```

---

### Task 3: Maintenance Scripts (Bash)

**Files:**
- Create: `init-templates/scripts/sync-claude-md.sh`
- Create: `init-templates/scripts/check-env-sync.sh`
- Create: `init-templates/scripts/validate-startup.sh`

- [ ] **Step 1: Create scripts directory**

```bash
mkdir -p /Users/thondascully/all/projects/nexus/init-templates/scripts
```

- [ ] **Step 2: Write sync-claude-md.sh**

This script reads the current directory tree and replaces the `FILE_STRUCTURE_START/END` section in CLAUDE.md:

```bash
#!/bin/bash
# scripts/sync-claude-md.sh — Regenerates CLAUDE.md file structure section
# Called by Claude Code PostToolUse hook and nexus doctor --fix

set -e

CLAUDE_MD="CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  echo "No CLAUDE.md found. Skipping file structure sync."
  exit 0
fi

# Check for markers
if ! grep -q "FILE_STRUCTURE_START" "$CLAUDE_MD"; then
  exit 0
fi

# Generate tree, excluding common noise directories
TREE=$(find . -type f \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -not -path './.next/*' \
  -not -path './dist/*' \
  -not -path './build/*' \
  -not -path './.turbo/*' \
  -not -path './coverage/*' \
  -not -path './.vercel/*' \
  -not -path './.DS_Store' \
  -not -name '*.tsbuildinfo' \
  | sort \
  | head -80 \
  | sed 's|^\./||' \
  | awk '{
    n = split($0, parts, "/")
    indent = ""
    for (i = 1; i < n; i++) indent = indent "  "
    print indent parts[n]
  }')

# If tree is too long, fall back to directory-only view
if [ $(echo "$TREE" | wc -l) -gt 60 ]; then
  TREE=$(find . -type d \
    -not -path './node_modules/*' \
    -not -path './.git/*' \
    -not -path './.next/*' \
    -not -path './dist/*' \
    -not -path './.turbo/*' \
    -not -name 'node_modules' \
    | sort \
    | head -40 \
    | sed 's|^\./||' \
    | awk '{print $0 "/"}')
fi

# Build replacement block
REPLACEMENT="<!-- FILE_STRUCTURE_START -->\n<!-- Auto-generated by scripts/sync-claude-md.sh — do not edit this section manually -->\n\`\`\`\n${TREE}\n\`\`\`\n<!-- FILE_STRUCTURE_END -->"

# Replace between markers using awk
awk -v replacement="$REPLACEMENT" '
  /FILE_STRUCTURE_START/ { print replacement; skip=1; next }
  /FILE_STRUCTURE_END/ { skip=0; next }
  !skip { print }
' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"

mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
```

- [ ] **Step 3: Write check-env-sync.sh**

Scans source code for `process.env.` references and checks they're in `.env.example`:

```bash
#!/bin/bash
# scripts/check-env-sync.sh — Warns when env vars are referenced but not in .env.example
# Called by lefthook pre-commit and nexus doctor

set -e

ENV_EXAMPLE=".env.example"

if [ ! -f "$ENV_EXAMPLE" ]; then
  echo "No .env.example found. Skipping env sync check."
  exit 0
fi

# Extract env var names from .env.example (ignore comments and blank lines)
DECLARED=$(grep -v '^#' "$ENV_EXAMPLE" | grep -v '^$' | cut -d'=' -f1 | sort -u)

# Find env var references in source code
REFERENCED=$(grep -roh 'process\.env\.\([A-Z_][A-Z0-9_]*\)' \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist \
  . 2>/dev/null \
  | sed 's/process\.env\.//' \
  | sort -u)

# Also check for Bun.env references
BUN_REFERENCED=$(grep -roh 'Bun\.env\.\([A-Z_][A-Z0-9_]*\)' \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist \
  . 2>/dev/null \
  | sed 's/Bun\.env\.//' \
  | sort -u)

ALL_REFERENCED=$(echo -e "$REFERENCED\n$BUN_REFERENCED" | sort -u | grep -v '^$')

if [ -z "$ALL_REFERENCED" ]; then
  exit 0
fi

# Find missing vars
MISSING=""
EXIT_CODE=0
while IFS= read -r var; do
  if ! echo "$DECLARED" | grep -q "^${var}$"; then
    MISSING="${MISSING}  ${var}\n"
    EXIT_CODE=1
  fi
done <<< "$ALL_REFERENCED"

if [ $EXIT_CODE -ne 0 ]; then
  echo "Environment variables referenced in code but missing from .env.example:"
  echo -e "$MISSING"
  echo "Add them to .env.example to keep the template complete."
  exit 1
fi

exit 0
```

- [ ] **Step 4: Write validate-startup.sh**

```bash
#!/bin/bash
# scripts/validate-startup.sh — Crashes on boot if required env vars are missing
# Source this from your app's entry point or run before starting

set -e

REQUIRED_VARS=""

# Read required vars from .env.example (lines without default values)
if [ -f ".env.example" ]; then
  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    
    var_name=$(echo "$line" | cut -d'=' -f1)
    var_value=$(echo "$line" | cut -d'=' -f2-)
    
    # If the value is empty, it's required
    if [ -z "$var_value" ]; then
      REQUIRED_VARS="$REQUIRED_VARS $var_name"
    fi
  done < .env.example
fi

MISSING=""
for var in $REQUIRED_VARS; do
  if [ -z "${!var:-}" ]; then
    MISSING="$MISSING  $var\n"
  fi
done

if [ -n "$MISSING" ]; then
  echo "FATAL: Required environment variables are not set:"
  echo -e "$MISSING"
  echo "Copy .env.example to .env and fill in the values."
  exit 1
fi
```

- [ ] **Step 5: Make scripts executable**

```bash
chmod +x /Users/thondascully/all/projects/nexus/init-templates/scripts/*.sh
```

- [ ] **Step 6: Commit**

```bash
git add init-templates/scripts/sync-claude-md.sh init-templates/scripts/check-env-sync.sh init-templates/scripts/validate-startup.sh
git commit -m "feat(nexus): add bash maintenance scripts (env sync, CLAUDE.md sync, startup validation)"
```

---

### Task 4: Maintenance Scripts (TypeScript — Bun)

**Files:**
- Create: `init-templates/scripts/check-deps-direction.ts`
- Create: `init-templates/scripts/check-dead-exports.ts`

- [ ] **Step 1: Write check-deps-direction.ts**

This script reads the dependency direction chain from CLAUDE.md and scans imports for violations:

```typescript
#!/usr/bin/env bun
// scripts/check-deps-direction.ts — Scans imports for dependency direction violations
// Called by lefthook pre-commit, Claude Code onStop hook, and nexus doctor

import { readFileSync, readdirSync, statSync } from "fs";
import { join, relative, resolve } from "path";

// ── Parse dependency chain from CLAUDE.md ────────────────────────
function parseChain(claudeMd: string): string[] {
  const lines = claudeMd.split("\n");
  for (const line of lines) {
    // Match lines like: Types → Config → Repo → Service → Runtime → UI
    if (line.includes("→") && !line.startsWith("<!--") && !line.startsWith("#")) {
      return line
        .split("→")
        .map((s) => s.trim().toLowerCase())
        .filter(Boolean);
    }
  }
  return [];
}

// ── Map directory names to chain positions ───────────────────────
function dirToLayer(dir: string, chain: string[]): number {
  const dirLower = dir.toLowerCase();
  for (let i = 0; i < chain.length; i++) {
    if (dirLower.includes(chain[i])) return i;
  }
  return -1; // unknown layer
}

// ── Collect .ts/.tsx files recursively ───────────────────────────
function collectFiles(dir: string, files: string[] = []): string[] {
  const skip = ["node_modules", ".next", "dist", ".git", "build", ".turbo"];
  for (const entry of readdirSync(dir)) {
    if (skip.includes(entry)) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      collectFiles(full, files);
    } else if (entry.endsWith(".ts") || entry.endsWith(".tsx")) {
      files.push(full);
    }
  }
  return files;
}

// ── Extract import paths from a file ─────────────────────────────
function extractImports(content: string): string[] {
  const imports: string[] = [];
  const patterns = [
    /from\s+['"]([^'"]+)['"]/g,
    /import\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
    /require\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
  ];
  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(content)) !== null) {
      const path = match[1];
      if (path.startsWith(".") || path.startsWith("@/") || path.startsWith("~/")) {
        imports.push(path);
      }
    }
  }
  return imports;
}

// ── Main ─────────────────────────────────────────────────────────
const root = process.cwd();
const claudePath = join(root, "CLAUDE.md");

if (!statSync(claudePath, { throwIfNoEntry: false })) {
  console.log("No CLAUDE.md found. Skipping dependency direction check.");
  process.exit(0);
}

const claudeMd = readFileSync(claudePath, "utf-8");
const chain = parseChain(claudeMd);

if (chain.length === 0) {
  console.log("No dependency chain found in CLAUDE.md. Skipping.");
  process.exit(0);
}

const files = collectFiles(root);
const violations: string[] = [];

for (const file of files) {
  const rel = relative(root, file);
  const content = readFileSync(file, "utf-8");
  const imports = extractImports(content);
  const fileLayer = dirToLayer(rel, chain);

  if (fileLayer === -1) continue; // file not in any known layer

  for (const imp of imports) {
    // Resolve the import to a layer
    const importLayer = dirToLayer(imp, chain);
    if (importLayer === -1) continue; // import not in any known layer

    // Violation: importing from a layer that comes AFTER you in the chain
    if (importLayer > fileLayer) {
      violations.push(`${rel} (${chain[fileLayer]}) imports from ${imp} (${chain[importLayer]})`);
    }
  }
}

if (violations.length > 0) {
  console.log(`Dependency direction violations (${violations.length}):`);
  for (const v of violations) {
    console.log(`  ${v}`);
  }
  process.exit(1);
} else {
  process.exit(0);
}
```

- [ ] **Step 2: Write check-dead-exports.ts**

```typescript
#!/usr/bin/env bun
// scripts/check-dead-exports.ts — Flags exported symbols that nothing imports
// Called by nexus doctor and just dead-code

import { readFileSync, readdirSync, statSync } from "fs";
import { join, relative } from "path";

// ── Collect .ts/.tsx files ───────────────────────────────────────
function collectFiles(dir: string, files: string[] = []): string[] {
  const skip = ["node_modules", ".next", "dist", ".git", "build", ".turbo", "scripts"];
  for (const entry of readdirSync(dir)) {
    if (skip.includes(entry)) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      collectFiles(full, files);
    } else if (entry.endsWith(".ts") || entry.endsWith(".tsx")) {
      files.push(full);
    }
  }
  return files;
}

// ── Extract exported names from a file ───────────────────────────
function extractExports(content: string): string[] {
  const exports: string[] = [];
  const patterns = [
    /export\s+(?:const|let|var|function|class|type|interface|enum)\s+(\w+)/g,
    /export\s+\{\s*([^}]+)\s*\}/g,
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(content)) !== null) {
      if (pattern === patterns[1]) {
        // Named exports: export { foo, bar, baz }
        match[1].split(",").forEach((name) => {
          const clean = name.trim().split(/\s+as\s+/)[0].trim();
          if (clean) exports.push(clean);
        });
      } else {
        exports.push(match[1]);
      }
    }
  }

  return exports;
}

// ── Check if a name is referenced in other files ─────────────────
function isReferenced(name: string, files: string[], sourceFile: string): boolean {
  for (const file of files) {
    if (file === sourceFile) continue;
    const content = readFileSync(file, "utf-8");
    // Check for import of the name or usage of the name
    if (content.includes(name)) return true;
  }
  return false;
}

// ── Main ─────────────────────────────────────────────────────────
const root = process.cwd();
const files = collectFiles(root);

// Skip if very few files (probably not a real project yet)
if (files.length < 5) {
  process.exit(0);
}

const dead: string[] = [];

for (const file of files) {
  const rel = relative(root, file);
  const content = readFileSync(file, "utf-8");
  const exports = extractExports(content);

  // Skip index/barrel files and config files
  if (rel.includes("index.ts") || rel.includes("config")) continue;

  for (const exp of exports) {
    // Skip common patterns that are often used dynamically
    if (["default", "metadata", "generateMetadata", "revalidate"].includes(exp)) continue;

    if (!isReferenced(exp, files, file)) {
      dead.push(`${rel}:export ${exp}`);
    }
  }
}

if (dead.length > 0) {
  console.log(`Dead exports (${dead.length}):`);
  for (const d of dead) {
    console.log(`  ${d}`);
  }
  process.exit(1);
} else {
  process.exit(0);
}
```

- [ ] **Step 3: Make scripts executable**

```bash
chmod +x /Users/thondascully/all/projects/nexus/init-templates/scripts/check-deps-direction.ts
chmod +x /Users/thondascully/all/projects/nexus/init-templates/scripts/check-dead-exports.ts
```

- [ ] **Step 4: Commit**

```bash
git add init-templates/scripts/check-deps-direction.ts init-templates/scripts/check-dead-exports.ts
git commit -m "feat(nexus): add TypeScript maintenance scripts (dep direction, dead exports)"
```

---

### Task 5: Hook Templates (lefthook + Claude Code)

**Files:**
- Create: `init-templates/hooks/lefthook.yml`
- Create: `init-templates/hooks/claude-settings.json`
- Create: `init-templates/hooks/claude-settings-superpowers.json`

- [ ] **Step 1: Create hooks directory**

```bash
mkdir -p /Users/thondascully/all/projects/nexus/init-templates/hooks
```

- [ ] **Step 2: Write lefthook.yml**

```yaml
# lefthook.yml — pre-commit hooks
# Install lefthook: brew install lefthook && lefthook install

pre-commit:
  parallel: true
  commands:
    typecheck:
      run: pnpm typecheck 2>/dev/null || echo "typecheck not configured — skipping"
    lint:
      run: pnpm lint 2>/dev/null || echo "lint not configured — skipping"
    env-sync:
      run: bash scripts/check-env-sync.sh
    deps-direction:
      run: bun scripts/check-deps-direction.ts 2>/dev/null || echo "bun not found — skipping deps check"
```

- [ ] **Step 3: Write claude-settings.json (standalone — no Superpowers)**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash scripts/sync-claude-md.sh 2>/dev/null || true"
      }
    ],
    "onStop": [
      {
        "command": "nexus doctor --quick 2>/dev/null || true"
      }
    ]
  }
}
```

- [ ] **Step 4: Write claude-settings-superpowers.json (with Superpowers)**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash scripts/sync-claude-md.sh 2>/dev/null || true"
      }
    ]
  }
}
```

Note: With Superpowers enabled, `onStop` is omitted because Superpowers' `verification-before-completion` skill handles the end-of-session checks. The CLAUDE.md workflow conventions (added by `nexus add hooks`) tell Claude Code to use `/brainstorm`, TDD, and `/review` — Superpowers handles enforcement.

- [ ] **Step 5: Commit**

```bash
git add init-templates/hooks/
git commit -m "feat(nexus): add lefthook and Claude Code hook templates"
```

---

### Task 6: Web App Layer Templates (db, auth, api, ci)

**Files:**
- Create: `init-templates/db/docker-compose.yml`
- Create: `init-templates/db/schema.ts`
- Create: `init-templates/db/migrate.ts`
- Create: `init-templates/db/seed.ts`
- Create: `init-templates/auth/middleware.ts`
- Create: `init-templates/auth/auth.ts`
- Create: `init-templates/api/trpc.ts`
- Create: `init-templates/api/health.ts`
- Create: `init-templates/api/_app.ts`
- Create: `init-templates/api/api-error.ts`
- Create: `init-templates/ci/ci.yml`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /Users/thondascully/all/projects/nexus/init-templates/{db,auth,api,ci}
```

- [ ] **Step 2: Write docker-compose.yml**

Use the template from the vault's Docker for Local Dev note:

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

  mailpit:
    image: axllent/mailpit
    ports:
      - "8025:8025"
      - "1025:1025"

volumes:
  postgres_data:
```

- [ ] **Step 3: Write schema.ts**

```typescript
// packages/db/schema/index.ts — Drizzle schema starter
// Every table gets: id, created_at, updated_at, deleted_at

import { pgTable, uuid, timestamp, text } from "drizzle-orm/pg-core";

// ── Base columns (reuse in every table) ─────────────────────────
const baseColumns = {
  id: uuid("id").defaultRandom().primaryKey(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  deletedAt: timestamp("deleted_at", { withTimezone: true }),
};

// ── Example: users table ────────────────────────────────────────
export const users = pgTable("users", {
  ...baseColumns,
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  role: text("role").notNull().default("member"),
});

// Add more tables here following the same pattern.
```

- [ ] **Step 4: Write migrate.ts**

```typescript
// packages/db/migrate.ts — Run migrations
import { drizzle } from "drizzle-orm/postgres-js";
import { migrate } from "drizzle-orm/postgres-js/migrator";
import postgres from "postgres";

const connection = postgres(process.env.DATABASE_URL!);
const db = drizzle(connection);

async function main() {
  console.log("Running migrations...");
  await migrate(db, { migrationsFolder: "./packages/db/migrations" });
  console.log("Migrations complete.");
  await connection.end();
}

main().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
```

- [ ] **Step 5: Write seed.ts**

```typescript
// packages/db/seed.ts — Create realistic test data
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { users } from "./schema";

const connection = postgres(process.env.DATABASE_URL!);
const db = drizzle(connection);

async function seed() {
  console.log("Seeding database...");

  // Clear existing data
  await db.delete(users);

  // Create test users
  await db.insert(users).values([
    { email: "admin@test.com", name: "Admin User", role: "admin" },
    { email: "member@test.com", name: "Test Member", role: "member" },
  ]);

  console.log("Seed complete.");
  await connection.end();
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
```

- [ ] **Step 6: Write auth/middleware.ts**

```typescript
// src/middleware.ts — Clerk auth middleware
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher(["/", "/sign-in(.*)", "/sign-up(.*)", "/api/health"]);

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};
```

- [ ] **Step 7: Write auth/auth.ts**

```typescript
// src/lib/auth.ts — Auth helpers
import { auth, currentUser } from "@clerk/nextjs/server";

export async function requireAuth() {
  const session = await auth();
  if (!session.userId) {
    throw new Error("Unauthorized");
  }
  return session;
}

export async function getCurrentUser() {
  const user = await currentUser();
  if (!user) return null;
  return {
    id: user.id,
    email: user.emailAddresses[0]?.emailAddress,
    name: `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim(),
    imageUrl: user.imageUrl,
  };
}
```

- [ ] **Step 8: Write api/trpc.ts**

```typescript
// src/server/trpc.ts — tRPC initialization
import { initTRPC, TRPCError } from "@trpc/server";
import { auth } from "@clerk/nextjs/server";

export const createTRPCContext = async () => {
  const session = await auth();
  return { userId: session.userId };
};

const t = initTRPC.context<typeof createTRPCContext>().create();

export const router = t.router;
export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx: { userId: ctx.userId } });
});
```

- [ ] **Step 9: Write api/health.ts**

```typescript
// src/server/routers/health.ts — Health check endpoint
import { publicProcedure, router } from "../trpc";
import postgres from "postgres";

const startTime = Date.now();

export const healthRouter = router({
  check: publicProcedure.query(async () => {
    const uptime = Math.floor((Date.now() - startTime) / 1000);

    // Check DB connectivity
    let dbOk = false;
    try {
      const sql = postgres(process.env.DATABASE_URL!);
      await sql`SELECT 1`;
      await sql.end();
      dbOk = true;
    } catch {
      dbOk = false;
    }

    return {
      status: dbOk ? "healthy" : "degraded",
      uptime,
      db: dbOk ? "connected" : "unreachable",
      timestamp: new Date().toISOString(),
    };
  }),
});
```

- [ ] **Step 10: Write api/_app.ts**

```typescript
// src/server/routers/_app.ts — Root router
import { router } from "../trpc";
import { healthRouter } from "./health";

export const appRouter = router({
  health: healthRouter,
});

export type AppRouter = typeof appRouter;
```

- [ ] **Step 11: Write api/api-error.ts**

```typescript
// src/lib/api-error.ts — Consistent error format
export type ApiError = {
  code: string;
  message: string;
  details?: unknown;
};

export class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 400,
    public details?: unknown
  ) {
    super(message);
    this.name = "AppError";
  }

  toJSON(): ApiError {
    return {
      code: this.code,
      message: this.message,
      ...(this.details ? { details: this.details } : {}),
    };
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super("NOT_FOUND", `${resource} not found`, 404);
  }
}

export class ForbiddenError extends AppError {
  constructor(message = "You do not have permission to perform this action") {
    super("FORBIDDEN", message, 403);
  }
}

export class ValidationError extends AppError {
  constructor(details: unknown) {
    super("VALIDATION_ERROR", "Invalid input", 400, details);
  }
}
```

- [ ] **Step 12: Write ci/ci.yml**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test
      - run: pnpm build
```

- [ ] **Step 13: Verify all template files exist**

```bash
find /Users/thondascully/all/projects/nexus/init-templates -type f | sort
```

Expected: all files from core/, scripts/, hooks/, db/, auth/, api/, ci/

- [ ] **Step 14: Commit**

```bash
git add init-templates/db/ init-templates/auth/ init-templates/api/ init-templates/ci/
git commit -m "feat(nexus): add web app layer templates (db, auth, api, ci)"
```

---

### Task 7: `nexus init` Command

**Files:**
- Create: `cli/init.sh`

- [ ] **Step 1: Write cli/init.sh**

```bash
#!/bin/bash
# cli/init.sh — nexus init command

cmd_init() {
  local project_name="${1:-}"
  local project_type=""
  local want_db=""
  local want_auth=""
  local api_style=""
  local want_ci=""
  local is_existing=false

  check_git

  # ── Detect new vs existing project ────────────────────────────
  if [ -n "$project_name" ]; then
    if [ -d "$project_name" ]; then
      echo -e "${YELLOW}Directory $project_name already exists.${NC}"
      cd "$project_name"
      is_existing=true
    else
      mkdir -p "$project_name"
      cd "$project_name"
      git init --quiet
      echo -e "  ${GREEN}created${NC} $project_name/"
    fi
  else
    # Running in current directory
    if [ -d ".git" ]; then
      is_existing=true
    else
      git init --quiet
    fi
  fi

  if $is_existing; then
    echo -e "  ${DIM}Existing project detected.${NC}"
  fi

  # ── Project type ──────────────────────────────────────────────
  print_header "What are you building?"
  echo -e "  ${BOLD}1${NC}  Web app ${DIM}(Next.js + Postgres + the works)${NC}"
  echo -e "  ${BOLD}2${NC}  Other ${DIM}(just give me the conventions)${NC}"
  echo ""
  printf "  [1/2]: "
  read -n 1 -r project_type
  echo ""

  case $project_type in
    1) project_type="web-app" ;;
    *) project_type="other" ;;
  esac

  # ── Stack questions (web app only) ────────────────────────────
  if [ "$project_type" = "web-app" ]; then
    echo ""
    printf "  Database? ${DIM}(Postgres + Drizzle)${NC} [Y/n]: "
    read -n 1 -r want_db
    echo ""
    want_db=${want_db:-y}

    printf "  Auth? ${DIM}(Clerk)${NC} [Y/n]: "
    read -n 1 -r want_auth
    echo ""
    want_auth=${want_auth:-y}

    echo -e "  API style?"
    echo -e "    ${BOLD}1${NC}  tRPC ${DIM}(default)${NC}"
    echo -e "    ${BOLD}2${NC}  REST"
    echo -e "    ${BOLD}3${NC}  Skip"
    printf "  [1/2/3]: "
    read -n 1 -r api_choice
    echo ""
    case $api_choice in
      2) api_style="rest" ;;
      3) api_style="skip" ;;
      *) api_style="trpc" ;;
    esac

    printf "  CI? ${DIM}(GitHub Actions)${NC} [Y/n]: "
    read -n 1 -r want_ci
    echo ""
    want_ci=${want_ci:-y}
  fi

  # ── Drop core files ───────────────────────────────────────────
  print_header "Dropping core files"

  drop_file "$TEMPLATES/core/CLAUDE.md.$project_type" "CLAUDE.md"
  drop_file "$TEMPLATES/core/justfile.$project_type" "justfile"
  drop_file "$TEMPLATES/core/gitignore" ".gitignore"
  drop_file "$TEMPLATES/core/env.example" ".env.example"
  drop_file "$TEMPLATES/core/mise.toml" ".mise.toml"

  mkdir -p .github
  drop_file "$TEMPLATES/core/pull_request_template.md" ".github/pull_request_template.md"

  # ── Offer to run add commands ─────────────────────────────────
  if [ "$project_type" = "web-app" ]; then
    echo ""
    printf "  Set up everything based on your choices? [Y/n]: "
    read -n 1 -r run_all
    echo ""
    run_all=${run_all:-y}

    if [[ $run_all =~ ^[Yy]$ ]]; then
      if [[ $want_db =~ ^[Yy]$ ]]; then
        source "$NEXUS_DIR/cli/add-db.sh"
        cmd_add_db
      fi
      if [[ $want_auth =~ ^[Yy]$ ]]; then
        source "$NEXUS_DIR/cli/add-auth.sh"
        cmd_add_auth
      fi
      if [ "$api_style" = "trpc" ]; then
        source "$NEXUS_DIR/cli/add-api.sh"
        cmd_add_api
      fi
      source "$NEXUS_DIR/cli/add-hooks.sh"
      cmd_add_hooks
      if [[ $want_ci =~ ^[Yy]$ ]]; then
        source "$NEXUS_DIR/cli/add-ci.sh"
        cmd_add_ci
      fi
    else
      echo ""
      echo -e "  Core files created. Add layers when ready:"
      [[ $want_db =~ ^[Yy]$ ]] && echo -e "    ${GREEN}nexus add db${NC}       Postgres + Drizzle + migrations"
      [[ $want_auth =~ ^[Yy]$ ]] && echo -e "    ${GREEN}nexus add auth${NC}     Clerk + middleware"
      [ "$api_style" = "trpc" ] && echo -e "    ${GREEN}nexus add api${NC}      tRPC + health endpoint"
      echo -e "    ${GREEN}nexus add hooks${NC}    lefthook + Claude Code hooks"
      [[ $want_ci =~ ^[Yy]$ ]] && echo -e "    ${GREEN}nexus add ci${NC}       GitHub Actions"
      echo -e "    ${GREEN}nexus doctor${NC}       Run all maintenance checks"
    fi
  else
    # "Other" project — just offer hooks
    echo ""
    printf "  Set up hooks? [Y/n]: "
    read -n 1 -r setup_hooks
    echo ""
    setup_hooks=${setup_hooks:-y}
    if [[ $setup_hooks =~ ^[Yy]$ ]]; then
      source "$NEXUS_DIR/cli/add-hooks.sh"
      cmd_add_hooks
    fi
  fi

  # ── Print pending install commands ────────────────────────────
  if [ -n "$PENDING_INSTALLS" ]; then
    echo ""
    echo -e "  ${BOLD}Run these when ready:${NC}"
    echo -e "$PENDING_INSTALLS"
  fi

  # ── Offer to commit ───────────────────────────────────────────
  echo ""
  printf "  Commit these changes? [Y/n]: "
  read -n 1 -r do_commit
  echo ""
  if [[ $do_commit =~ ^[Yy]$ ]] || [[ -z $do_commit ]]; then
    git add -A
    git commit -m "chore: initialize project with nexus conventions" --quiet
    echo -e "  ${GREEN}committed${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Done.${NC} Run ${GREEN}nexus doctor${NC} anytime to check project health."
  echo ""
}

# Note: PENDING_INSTALLS and add_pending_install are defined in helpers.sh
```

- [ ] **Step 2: Test init on a temp directory**

```bash
cd /tmp && /Users/thondascully/all/projects/nexus/nexus init test-project
```

Walk through the wizard. Verify files are created. Then clean up:

```bash
rm -rf /tmp/test-project
```

- [ ] **Step 3: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/init.sh
git commit -m "feat(nexus): implement nexus init wizard"
```

---

### Task 8: `nexus add` Commands (db, auth, api, hooks, ci)

**Files:**
- Create: `cli/add-db.sh`
- Create: `cli/add-auth.sh`
- Create: `cli/add-api.sh`
- Create: `cli/add-hooks.sh`
- Create: `cli/add-ci.sh`

- [ ] **Step 1: Write cli/add-db.sh**

```bash
#!/bin/bash
# cli/add-db.sh — nexus add db

cmd_add_db() {
  print_header "Adding database layer"

  drop_file "$TEMPLATES/db/docker-compose.yml" "docker-compose.yml"

  mkdir -p packages/db/schema packages/db/migrations
  drop_file "$TEMPLATES/db/schema.ts" "packages/db/schema/index.ts"
  drop_file "$TEMPLATES/db/migrate.ts" "packages/db/migrate.ts"
  drop_file "$TEMPLATES/db/seed.ts" "packages/db/seed.ts"

  # Append DB env vars to .env.example
  append_to_file ".env.example" "DATABASE_URL" "
# Database
DATABASE_URL=postgresql://dev:dev@localhost:5432/myproject
REDIS_URL=redis://localhost:6379"

  # Append DB commands to justfile if not already there
  append_to_file "justfile" "db-migrate" "
# ── Database (added by nexus add db) ─────────────────────
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
    pnpm drizzle-kit studio"

  check_prereq docker "Install Docker to start Postgres: https://docker.com" || true
  add_pending_install "pnpm add drizzle-orm postgres"
  add_pending_install "pnpm add -D drizzle-kit"
}
```

- [ ] **Step 2: Write cli/add-auth.sh**

```bash
#!/bin/bash
# cli/add-auth.sh — nexus add auth

cmd_add_auth() {
  print_header "Adding auth layer"

  mkdir -p src/lib
  drop_file "$TEMPLATES/auth/middleware.ts" "src/middleware.ts"
  drop_file "$TEMPLATES/auth/auth.ts" "src/lib/auth.ts"

  append_to_file ".env.example" "CLERK_SECRET_KEY" "
# Auth (Clerk — get keys from dashboard.clerk.com)
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="

  add_pending_install "pnpm add @clerk/nextjs"
}
```

- [ ] **Step 3: Write cli/add-api.sh**

```bash
#!/bin/bash
# cli/add-api.sh — nexus add api

cmd_add_api() {
  print_header "Adding API layer"

  mkdir -p src/server/routers src/lib
  drop_file "$TEMPLATES/api/trpc.ts" "src/server/trpc.ts"
  drop_file "$TEMPLATES/api/health.ts" "src/server/routers/health.ts"
  drop_file "$TEMPLATES/api/_app.ts" "src/server/routers/_app.ts"
  drop_file "$TEMPLATES/api/api-error.ts" "src/lib/api-error.ts"

  append_to_file "justfile" "api-health" "
# ── API (added by nexus add api) ─────────────────────────
api-health:
    curl -s localhost:3000/api/health | jq ."

  add_pending_install "pnpm add @trpc/server @trpc/client @trpc/next"
}
```

- [ ] **Step 4: Write cli/add-hooks.sh**

```bash
#!/bin/bash
# cli/add-hooks.sh — nexus add hooks

cmd_add_hooks() {
  print_header "Adding hooks"

  # ── Scripts ────────────────────────────────────────────────────
  mkdir -p scripts
  drop_file "$TEMPLATES/scripts/sync-claude-md.sh" "scripts/sync-claude-md.sh"
  drop_file "$TEMPLATES/scripts/check-env-sync.sh" "scripts/check-env-sync.sh"
  drop_file "$TEMPLATES/scripts/check-deps-direction.ts" "scripts/check-deps-direction.ts"
  drop_file "$TEMPLATES/scripts/check-dead-exports.ts" "scripts/check-dead-exports.ts"
  drop_file "$TEMPLATES/scripts/validate-startup.sh" "scripts/validate-startup.sh"
  chmod +x scripts/*.sh scripts/*.ts 2>/dev/null || true

  # ── lefthook ───────────────────────────────────────────────────
  drop_file "$TEMPLATES/hooks/lefthook.yml" "lefthook.yml"

  if ! has_cmd lefthook; then
    echo ""
    printf "  Install lefthook? [Y/n]: "
    read -n 1 -r install_lh
    echo ""
    install_lh=${install_lh:-y}
    if [[ $install_lh =~ ^[Yy]$ ]]; then
      if has_cmd brew; then
        echo "  Installing lefthook..."
        brew install lefthook > /dev/null 2>&1
        echo -e "  ${GREEN}installed${NC} lefthook"
      else
        print_warn "brew not found. Install lefthook manually: https://github.com/evilmartians/lefthook"
      fi
    fi
  fi

  if has_cmd lefthook; then
    lefthook install > /dev/null 2>&1
    echo -e "  ${GREEN}activated${NC} lefthook git hooks"
  fi

  # ── Claude Code hooks ──────────────────────────────────────────
  echo ""
  printf "  Use Superpowers (Claude Code plugin)? [Y/n]: "
  read -n 1 -r use_superpowers
  echo ""
  use_superpowers=${use_superpowers:-y}

  mkdir -p .claude
  if [[ $use_superpowers =~ ^[Yy]$ ]]; then
    drop_file "$TEMPLATES/hooks/claude-settings-superpowers.json" ".claude/settings.json"

    # Add Superpowers workflow conventions to CLAUDE.md
    append_to_file "CLAUDE.md" "## Workflow" "
## Workflow
- Use /brainstorm before implementing any new feature
- Use TDD — write failing tests first, then implement
- Use /review after completing each major step
- Let Superpowers verification-before-completion run before declaring done"

  else
    drop_file "$TEMPLATES/hooks/claude-settings.json" ".claude/settings.json"
  fi

  # ── .nexus-checksums to .gitignore ─────────────────────────────
  append_to_file ".gitignore" ".nexus-checksums" "
.nexus-checksums"

  # ── Run initial CLAUDE.md sync ─────────────────────────────────
  if [ -f "scripts/sync-claude-md.sh" ] && [ -f "CLAUDE.md" ]; then
    bash scripts/sync-claude-md.sh 2>/dev/null || true
    echo -e "  ${GREEN}synced${NC} CLAUDE.md file structure"
  fi
}
```

- [ ] **Step 5: Write cli/add-ci.sh**

```bash
#!/bin/bash
# cli/add-ci.sh — nexus add ci

cmd_add_ci() {
  print_header "Adding CI"

  mkdir -p .github/workflows
  drop_file "$TEMPLATES/ci/ci.yml" ".github/workflows/ci.yml"

  check_prereq gh "Install GitHub CLI: brew install gh" || true
  if has_cmd gh; then
    if ! gh auth status &>/dev/null; then
      print_warn "GitHub CLI not authenticated. Run: gh auth login"
    fi
  fi
}
```

- [ ] **Step 6: Test nexus add hooks in a temp project**

```bash
cd /tmp && mkdir test-hooks && cd test-hooks && git init
echo "# CLAUDE.md" > CLAUDE.md
echo "# test" > .gitignore
/Users/thondascully/all/projects/nexus/nexus add hooks
ls -la scripts/ .claude/ lefthook.yml
```

Clean up:

```bash
rm -rf /tmp/test-hooks
```

- [ ] **Step 7: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/add-db.sh cli/add-auth.sh cli/add-api.sh cli/add-hooks.sh cli/add-ci.sh
git commit -m "feat(nexus): implement all nexus add commands (db, auth, api, hooks, ci)"
```

---

### Task 9: `nexus doctor` Command

**Files:**
- Create: `cli/doctor.sh`

- [ ] **Step 1: Write cli/doctor.sh**

```bash
#!/bin/bash
# cli/doctor.sh — nexus doctor

cmd_doctor() {
  local quick=false
  local fix=false
  local passed=0
  local failed=0
  local skipped=0
  local total=0

  # Parse flags
  for arg in "$@"; do
    case $arg in
      --quick) quick=true ;;
      --fix) fix=true ;;
    esac
  done

  echo ""
  echo -e "  ${BOLD}nexus doctor${NC}"
  echo ""

  # ── Check 1: CLAUDE.md file structure sync ─────────────────────
  total=$((total + 1))
  if [ -f "CLAUDE.md" ] && grep -q "FILE_STRUCTURE_START" "CLAUDE.md"; then
    # Generate current tree and compare
    if [ -f "scripts/sync-claude-md.sh" ]; then
      cp CLAUDE.md CLAUDE.md.backup
      bash scripts/sync-claude-md.sh 2>/dev/null
      if diff -q CLAUDE.md CLAUDE.md.backup > /dev/null 2>&1; then
        print_ok "CLAUDE.md file structure"
        passed=$((passed + 1))
      else
        if $fix; then
          print_ok "CLAUDE.md file structure ${DIM}(fixed)${NC}"
          passed=$((passed + 1))
        else
          mv CLAUDE.md.backup CLAUDE.md
          print_fail "CLAUDE.md file structure out of date"
          failed=$((failed + 1))
        fi
      fi
      rm -f CLAUDE.md.backup
    else
      print_skip "CLAUDE.md sync (scripts/sync-claude-md.sh not found)"
      skipped=$((skipped + 1))
    fi
  else
    print_skip "CLAUDE.md sync (no markers found)"
    skipped=$((skipped + 1))
  fi

  # ── Check 2: .env.example coverage ─────────────────────────────
  total=$((total + 1))
  if [ -f "scripts/check-env-sync.sh" ]; then
    if bash scripts/check-env-sync.sh > /dev/null 2>&1; then
      print_ok ".env.example coverage"
      passed=$((passed + 1))
    else
      if $fix; then
        # Extract missing vars and add them
        local missing
        missing=$(bash scripts/check-env-sync.sh 2>&1 | grep "^  " | tr -d ' ')
        for var in $missing; do
          echo "$var= # TODO: set value" >> .env.example
        done
        print_ok ".env.example coverage ${DIM}(fixed)${NC}"
        passed=$((passed + 1))
      else
        print_fail ".env.example coverage"
        bash scripts/check-env-sync.sh 2>&1 | head -5 | sed 's/^/       /'
        failed=$((failed + 1))
      fi
    fi
  else
    print_skip ".env.example sync (script not found)"
    skipped=$((skipped + 1))
  fi

  # ── Check 3: Dependency direction ──────────────────────────────
  total=$((total + 1))
  if [ -f "scripts/check-deps-direction.ts" ] && has_cmd bun; then
    if bun scripts/check-deps-direction.ts > /dev/null 2>&1; then
      print_ok "Dependency direction"
      passed=$((passed + 1))
    else
      print_fail "Dependency direction"
      bun scripts/check-deps-direction.ts 2>&1 | head -5 | sed 's/^/       /'
      failed=$((failed + 1))
    fi
  else
    print_skip "Dependency direction (bun or script not found)"
    skipped=$((skipped + 1))
  fi

  # ── Check 4: Dead exports ──────────────────────────────────────
  total=$((total + 1))
  if [ -f "scripts/check-dead-exports.ts" ] && has_cmd bun; then
    local dead_output
    dead_output=$(bun scripts/check-dead-exports.ts 2>&1)
    if [ $? -eq 0 ]; then
      print_ok "Dead exports"
      passed=$((passed + 1))
    else
      local dead_count
      dead_count=$(echo "$dead_output" | head -1 | grep -o '[0-9]*')
      print_fail "Dead exports ($dead_count found)"
      echo "$dead_output" | tail -n +2 | head -5 | sed 's/^/       /'
      failed=$((failed + 1))
    fi
  else
    print_skip "Dead exports (bun or script not found)"
    skipped=$((skipped + 1))
  fi

  # ── Checks 5-6: Skip if --quick ───────────────────────────────
  if ! $quick; then

    # ── Check 5: Startup validation ────────────────────────────
    total=$((total + 1))
    if [ -f "scripts/validate-startup.sh" ]; then
      if bash scripts/validate-startup.sh > /dev/null 2>&1; then
        print_ok "Startup validation"
        passed=$((passed + 1))
      else
        print_fail "Startup validation (missing env vars)"
        bash scripts/validate-startup.sh 2>&1 | grep "^  " | head -5 | sed 's/^/     /'
        failed=$((failed + 1))
      fi
    else
      print_skip "Startup validation (script not found)"
      skipped=$((skipped + 1))
    fi

    # ── Check 6: Outdated dependencies ─────────────────────────
    total=$((total + 1))
    if has_cmd pnpm && [ -f "package.json" ]; then
      local outdated_output
      outdated_output=$(pnpm outdated 2>&1)
      if [ $? -eq 0 ]; then
        print_ok "Dependencies up to date"
        passed=$((passed + 1))
      else
        local outdated_count
        outdated_count=$(echo "$outdated_output" | grep -c "│" 2>/dev/null || echo "?")
        print_fail "Outdated dependencies ($outdated_count)"
        failed=$((failed + 1))
      fi
    else
      print_skip "Outdated dependencies (pnpm or package.json not found)"
      skipped=$((skipped + 1))
    fi
  fi

  # ── Check 7: lefthook installed ────────────────────────────────
  total=$((total + 1))
  if [ -f "lefthook.yml" ]; then
    if has_cmd lefthook && [ -f ".git/hooks/pre-commit" ]; then
      print_ok "lefthook installed"
      passed=$((passed + 1))
    else
      print_fail "lefthook not active (run: lefthook install)"
      failed=$((failed + 1))
    fi
  else
    print_skip "lefthook (no lefthook.yml)"
    skipped=$((skipped + 1))
  fi

  # ── Check 8: Claude Code hooks present ─────────────────────────
  total=$((total + 1))
  if [ -f ".claude/settings.json" ]; then
    print_ok "Claude Code hooks present"
    passed=$((passed + 1))
  else
    print_fail "Claude Code hooks missing (.claude/settings.json)"
    failed=$((failed + 1))
  fi

  # ── Check 9: PR template present ───────────────────────────────
  total=$((total + 1))
  if [ -f ".github/pull_request_template.md" ]; then
    print_ok "PR template present"
    passed=$((passed + 1))
  else
    print_fail "PR template missing (.github/pull_request_template.md)"
    failed=$((failed + 1))
  fi

  # ── Summary ────────────────────────────────────────────────────
  local check_total=$((passed + failed))
  echo ""
  if [ $failed -eq 0 ]; then
    echo -e "  ${GREEN}${check_total}/${check_total} passed${NC}"
  else
    echo -e "  ${passed}/${check_total} passed. ${RED}${failed} issue(s)${NC} found."
  fi
  if [ $skipped -gt 0 ]; then
    echo -e "  ${DIM}${skipped} check(s) skipped${NC}"
  fi
  echo ""

  [ $failed -eq 0 ]
}
```

- [ ] **Step 2: Test nexus doctor in a temp project**

```bash
cd /tmp && mkdir test-doctor && cd test-doctor && git init
echo "test" > CLAUDE.md
/Users/thondascully/all/projects/nexus/nexus doctor
```

Expected: mostly skips and fails (no scripts present). Clean up:

```bash
rm -rf /tmp/test-doctor
```

- [ ] **Step 3: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/doctor.sh
git commit -m "feat(nexus): implement nexus doctor with scorecard, --quick, --fix"
```

---

### Task 10: `nexus update` Command

**Files:**
- Create: `cli/update.sh`

- [ ] **Step 1: Write cli/update.sh**

```bash
#!/bin/bash
# cli/update.sh — nexus update (vault sync)

cmd_update() {
  local nexus_home="$HOME/.nexus"

  print_header "nexus update"

  # ── Pull latest vault ──────────────────────────────────────────
  if [ -d "$nexus_home/.git" ]; then
    echo -e "  Pulling latest from ~/.nexus..."
    git -C "$nexus_home" pull --ff-only --quiet 2>/dev/null || {
      print_warn "Pull failed (local changes?). Using existing version."
    }
    echo -e "  ${GREEN}done${NC}"
  else
    print_warn "~/.nexus is not a git repo. Run: curl -fsSL https://www.teonnaise.com/install | bash"
    return 1
  fi

  # ── Compare project files against templates ────────────────────
  local templates_dir="$nexus_home/init-templates"
  local updates_available=false

  echo ""
  echo -e "  ${BOLD}Comparing project files against latest templates:${NC}"
  echo ""

  # Check scripts
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts validate-startup.sh; do
    local src="$templates_dir/scripts/$script"
    local dest="scripts/$script"

    if [ ! -f "$src" ]; then continue; fi

    if [ ! -f "$dest" ]; then
      echo -e "  ${CYAN}+${NC}  $dest ${DIM}(new)${NC}"
      updates_available=true
    elif is_customized "$dest"; then
      echo -e "  ${DIM}skip${NC}  $dest ${DIM}(customized)${NC}"
    elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}↑${NC}  $dest ${DIM}(update available)${NC}"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}  $dest"
    fi
  done

  # Check hook configs
  for hook_file in lefthook.yml; do
    local src="$templates_dir/hooks/$hook_file"
    local dest="$hook_file"

    if [ ! -f "$src" ] || [ ! -f "$dest" ]; then continue; fi

    if is_customized "$dest"; then
      echo -e "  ${DIM}skip${NC}  $dest ${DIM}(customized)${NC}"
    elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}↑${NC}  $dest ${DIM}(update available)${NC}"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}  $dest"
    fi
  done

  # Check PR template
  local pr_src="$templates_dir/core/pull_request_template.md"
  local pr_dest=".github/pull_request_template.md"
  if [ -f "$pr_src" ] && [ -f "$pr_dest" ]; then
    if is_customized "$pr_dest"; then
      echo -e "  ${DIM}skip${NC}  $pr_dest ${DIM}(customized)${NC}"
    elif ! diff -q "$pr_src" "$pr_dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}↑${NC}  $pr_dest ${DIM}(update available)${NC}"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}  $pr_dest"
    fi
  fi

  # Always skip CLAUDE.md and justfile (user-customized by nature)
  if [ -f "CLAUDE.md" ]; then
    echo -e "  ${DIM}skip${NC}  CLAUDE.md ${DIM}(customized)${NC}"
  fi
  if [ -f "justfile" ]; then
    echo -e "  ${DIM}skip${NC}  justfile ${DIM}(customized)${NC}"
  fi

  if ! $updates_available; then
    echo ""
    echo -e "  ${GREEN}Everything up to date.${NC}"
    echo ""
    return 0
  fi

  # ── Apply updates ──────────────────────────────────────────────
  echo ""
  printf "  Apply updates? [Y/n/diff]: "
  read -n 1 -r apply_choice
  echo ""

  case $apply_choice in
    [dD])
      # Show diffs for all updatable files
      for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts validate-startup.sh; do
        local src="$templates_dir/scripts/$script"
        local dest="scripts/$script"
        if [ -f "$src" ] && [ -f "$dest" ] && ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
          echo -e "\n  ${BOLD}--- $dest ---${NC}"
          diff --color=always "$dest" "$src" | head -30
        fi
      done
      echo ""
      printf "  Apply these updates? [Y/n]: "
      read -n 1 -r apply_final
      echo ""
      [[ ! $apply_final =~ ^[Yy]$ ]] && [[ -n $apply_final ]] && return 0
      ;;
    [nN]) return 0 ;;
  esac

  # Apply the updates
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts validate-startup.sh; do
    local src="$templates_dir/scripts/$script"
    local dest="scripts/$script"
    if [ -f "$src" ]; then
      if [ ! -f "$dest" ]; then
        mkdir -p scripts
        cp "$src" "$dest"
        chmod +x "$dest" 2>/dev/null || true
        update_checksum "$dest"
        echo -e "  ${GREEN}added${NC} $dest"
      elif ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
        cp "$src" "$dest"
        chmod +x "$dest" 2>/dev/null || true
        update_checksum "$dest"
        echo -e "  ${GREEN}updated${NC} $dest"
      fi
    fi
  done

  echo ""
  echo -e "  ${GREEN}Updates applied.${NC}"
  echo ""
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/update.sh
git commit -m "feat(nexus): implement nexus update (vault sync with checksum tracking)"
```

---

### Task 11: End-to-End Integration Test

**Files:** None (testing only)

- [ ] **Step 1: Full test — new web app project**

```bash
cd /tmp
/Users/thondascully/all/projects/nexus/nexus init e2e-test
```

Walk through: web app, yes to all layers, yes to commit.

Verify:
```bash
cd /tmp/e2e-test
ls CLAUDE.md justfile .gitignore .env.example .mise.toml
ls scripts/
ls .claude/settings.json
ls .github/pull_request_template.md
ls docker-compose.yml
ls packages/db/schema/index.ts
ls src/middleware.ts
ls src/server/trpc.ts
ls .github/workflows/ci.yml
git log --oneline
```

Expected: all files present, one commit.

- [ ] **Step 2: Test nexus doctor in the test project**

```bash
cd /tmp/e2e-test
/Users/thondascully/all/projects/nexus/nexus doctor
```

Expected: scorecard with passes and skips (no node_modules yet so some checks skip).

- [ ] **Step 3: Test nexus init on existing project**

```bash
cd /tmp/e2e-test
/Users/thondascully/all/projects/nexus/nexus init
```

Expected: detects existing project, asks Overwrite/Skip/Diff per file.

- [ ] **Step 4: Test "other" project type**

```bash
cd /tmp
/Users/thondascully/all/projects/nexus/nexus init other-test
```

Choose "Other". Verify only core files are dropped (no docker-compose, no src/).

- [ ] **Step 5: Clean up test projects**

```bash
rm -rf /tmp/e2e-test /tmp/other-test
```

- [ ] **Step 6: Fix any bugs found during testing, then commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add -A
git commit -m "fix(nexus): fixes from end-to-end integration testing"
```

---

### Task 12: Clean Up Old CLI + Final Commit

**Files:**
- Modify: `nexus` (already done in Task 1)
- Delete: old prompt-builder code is already replaced

- [ ] **Step 1: Verify the old prompt-builder functions are gone**

The `nexus` file should only contain the new dispatcher from Task 1. Verify no old `cmd_feature`, `cmd_bug`, `cmd_menu` functions remain.

```bash
grep -c "cmd_feature\|cmd_bug\|cmd_menu\|cmd_scaffold\|cmd_page" /Users/thondascully/all/projects/nexus/nexus
```

Expected: 0

- [ ] **Step 2: Update bootstrap.sh to install lefthook**

The bootstrap script should add lefthook to the brew install list so new machines get it. Check if it's already there:

```bash
grep "lefthook" /Users/thondascully/all/projects/nexus/bootstrap.sh
```

If not present, add `brew_install "lefthook" "git hooks manager"` to the Advanced CLI Tools section (Step 5).

- [ ] **Step 3: Final commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add -A
git commit -m "feat(nexus): complete CLI redesign — initializer + maintenance system

Replaces the old prompt-builder CLI with:
- nexus init: project initializer with stack wizard
- nexus add: modular layer commands (db, auth, api, hooks, ci)
- nexus doctor: maintenance scorecard with --quick and --fix
- nexus update: vault template sync with checksum tracking

Includes maintenance scripts (CLAUDE.md sync, env sync, dep direction
linter, dead export detection) and three-layer hook system (lefthook,
Claude Code hooks, justfile commands)."
```
