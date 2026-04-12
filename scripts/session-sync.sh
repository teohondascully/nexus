#!/usr/bin/env bash
# session-sync.sh — runs at Claude Code session start
# Detects ecosystem/stack, writes .nexus/context.md, syncs CLAUDE.md

set -euo pipefail

# ── Guard: skip if already synced this session (within 60s) ───
NEXUS_DIR=".nexus"
STAMP="$NEXUS_DIR/.last-sync"
mkdir -p "$NEXUS_DIR"

if [ -f "$STAMP" ]; then
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  now=$(date +%s)
  elapsed=$(( now - last ))
  if [ "$elapsed" -lt 60 ]; then
    exit 0
  fi
fi

# ── Detect ecosystem ────────────────────────────────────────────
ECOSYSTEM="generic"
if [ -f "package.json" ]; then
  ECOSYSTEM="node"
elif [ -f "go.mod" ]; then
  ECOSYSTEM="go"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  ECOSYSTEM="python"
elif [ -f "Cargo.toml" ]; then
  ECOSYSTEM="rust"
fi

# ── Detect stack (Node-specific) ────────────────────────────────
STACK_LINES=""

# Runtime from .mise.toml
if [ -f ".mise.toml" ]; then
  node_ver=$(grep -oE 'node = "[^"]*"' .mise.toml 2>/dev/null | sed 's/node = "//;s/"//' || true)
  if [ -n "$node_ver" ]; then
    STACK_LINES="${STACK_LINES}- Runtime: Node ${node_ver} (from .mise.toml)\n"
  fi
  python_ver=$(grep -oE 'python = "[^"]*"' .mise.toml 2>/dev/null | sed 's/python = "//;s/"//' || true)
  if [ -n "$python_ver" ]; then
    STACK_LINES="${STACK_LINES}- Runtime: Python ${python_ver} (from .mise.toml)\n"
  fi
  go_ver=$(grep -oE 'go = "[^"]*"' .mise.toml 2>/dev/null | sed 's/go = "//;s/"//' || true)
  if [ -n "$go_ver" ]; then
    STACK_LINES="${STACK_LINES}- Runtime: Go ${go_ver} (from .mise.toml)\n"
  fi
fi

if [ "$ECOSYSTEM" = "node" ] && [ -f "package.json" ]; then
  # Framework detection
  for fw in next express hono fastify koa nuxt remix svelte astro; do
    ver=$(grep -oE "\"$fw\": *\"[^\"]*\"" package.json 2>/dev/null | head -1 | sed 's/.*: *"//;s/"//' || true)
    if [ -n "$ver" ]; then
      STACK_LINES="${STACK_LINES}- Framework: ${fw} ${ver} (from package.json)\n"
      break
    fi
  done

  # Database detection
  for db in drizzle-orm prisma @prisma/client mongoose typeorm sequelize; do
    if grep -q "\"$db\"" package.json 2>/dev/null; then
      STACK_LINES="${STACK_LINES}- Database: ${db} (from package.json)\n"
      break
    fi
  done

  # Auth detection
  for auth in @clerk/nextjs next-auth lucia @auth/core @supabase/auth-helpers; do
    if grep -q "\"$auth\"" package.json 2>/dev/null; then
      STACK_LINES="${STACK_LINES}- Auth: ${auth} (from package.json)\n"
      break
    fi
  done
fi

if [ "$ECOSYSTEM" = "go" ] && [ -f "go.mod" ]; then
  go_module=$(head -1 go.mod | sed 's/module //')
  STACK_LINES="${STACK_LINES}- Module: ${go_module} (from go.mod)\n"
fi

if [ "$ECOSYSTEM" = "python" ] && [ -f "pyproject.toml" ]; then
  proj_name=$(grep -oE 'name = "[^"]*"' pyproject.toml 2>/dev/null | head -1 | sed 's/name = "//;s/"//' || true)
  if [ -n "$proj_name" ]; then
    STACK_LINES="${STACK_LINES}- Project: ${proj_name} (from pyproject.toml)\n"
  fi
fi

if [ -z "$STACK_LINES" ]; then
  STACK_LINES="- Ecosystem: ${ECOSYSTEM}\n"
fi

# ── Count files ─────────────────────────────────────────────────
FILE_COUNT=$(find . \
  -not \( -path "*/node_modules/*" -o -path "*/.git/*" -o -path "*/.next/*" -o -path "*/dist/*" -o -path "*/build/*" -o -path "*/.turbo/*" -o -path "*/coverage/*" -o -path "*/.vercel/*" -o -path "*/.nexus/*" -o -name ".DS_Store" \) \
  -type f -print 2>/dev/null | wc -l | tr -d ' ')

DIR_COUNT=$(find . \
  -not \( -path "*/node_modules/*" -o -path "*/.git/*" -o -path "*/.next/*" -o -path "*/dist/*" -o -path "*/build/*" -o -path "*/.turbo/*" -o -path "*/coverage/*" -o -path "*/.vercel/*" -o -path "*/.nexus/*" \) \
  -type d -print 2>/dev/null | wc -l | tr -d ' ')

# ── Read last health ────────────────────────────────────────────
HEALTH_LINES=""
if [ -f "$NEXUS_DIR/.last-doctor" ]; then
  HEALTH_LINES=$(cat "$NEXUS_DIR/.last-doctor")
else
  HEALTH_LINES="- No doctor run yet"
fi

# ── Write context.md ────────────────────────────────────────────
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")

cat > "$NEXUS_DIR/context.md" <<CONTEXT
# Project Context
<!-- Auto-maintained by nexus. Do not edit. -->

## Stack
$(printf "%b" "$STACK_LINES")
## Structure
- ${FILE_COUNT} files across ${DIR_COUNT} directories
- Last sync: ${NOW}

## Health
${HEALTH_LINES}
CONTEXT

# ── Sync CLAUDE.md file structure ───────────────────────────────
NEXUS_HOME="$HOME/.nexus"
if [ -f "CLAUDE.md" ] && [ -f "$NEXUS_HOME/scripts/sync-claude-md.sh" ]; then
  bash "$NEXUS_HOME/scripts/sync-claude-md.sh" > /dev/null 2>&1 || true
fi

# ── Stamp sync time ────────────────────────────────────────────
date +%s > "$STAMP"
