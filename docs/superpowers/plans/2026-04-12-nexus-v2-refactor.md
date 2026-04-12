# Nexus v2 Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor nexus from a project scaffolder (v1) into automated project infrastructure (v2) — invisible guardrails that enforce quality while AI agents write code, with section-level CLAUDE.md migration for evolving projects over time.

**Architecture:** Bash CLI dispatches to command scripts. Templates and scripts live in separate top-level directories. Vault moves under `vault/`. Zero-question init drops self-maintaining infrastructure. Doctor runs checks + recommendations. Update does section-level CLAUDE.md migration using HTML comment markers.

**Tech Stack:** Bash (CLI), TypeScript/Bun (import analysis scripts), lefthook (git hooks), Claude Code hooks API

---

## File Structure (end state)

```
~/.nexus/
├── nexus                              # CLI entry point (rewrites v1)
├── cli/
│   ├── helpers.sh                     # Shared utilities (updates v1 — adds section migration)
│   ├── init.sh                        # nexus init (rewrites v1 — zero questions)
│   ├── doctor.sh                      # nexus doctor (rewrites v1 — adds recommendations)
│   └── update.sh                      # nexus update (rewrites v1 — adds section migration)
├── templates/                         # NEW — files dropped into projects by nexus init
│   ├── CLAUDE.md                      # Single template with nexus-owned section markers
│   ├── justfile                       # Generic with doctor commands
│   ├── gitignore
│   ├── env.example
│   ├── mise.toml
│   ├── pr-template.md
│   ├── lefthook.yml
│   └── claude-settings.json
├── scripts/                           # NEW location — scripts dropped into projects
│   ├── sync-claude-md.sh             # (from v1, unchanged)
│   ├── check-env-sync.sh            # (from v1, unchanged)
│   ├── check-deps-direction.ts       # (from v1, unchanged)
│   ├── check-dead-exports.ts        # (from v1, unchanged)
│   ├── check-hallucinated-imports.ts # NEW
│   ├── check-orphaned-files.ts       # NEW
│   └── validate-startup.sh          # (from v1, unchanged)
├── vault/                             # Obsidian vault (moved from root)
│   ├── HOME.md
│   ├── foundations/
│   ├── tools/
│   ├── templates/                     # vault documentation templates (not nexus templates)
│   ├── signals/
│   ├── projects/
│   ├── daily/
│   ├── inbox/
│   ├── .obsidian/
│   └── Vault Maintenance System.md
├── bootstrap.sh                       # (updated — welcome screen note)
├── install.sh                         # (updated — uninstall tier 3)
├── VERSION
├── CHANGELOG.md
├── VAULT_UPDATE_PROMPT.md
├── README.md
├── LICENSE
└── docs/superpowers/                  # specs and plans
```

---

### Task 1: Restructure Repo

Move vault files under `vault/`, delete v1-only files, create new directory structure.

**Files:**
- Move: `foundations/` → `vault/foundations/`
- Move: `tools/` → `vault/tools/`
- Move: `templates/` → `vault/templates/`
- Move: `signals/` → `vault/signals/`
- Move: `projects/` → `vault/projects/`
- Move: `daily/` → `vault/daily/`
- Move: `inbox/` → `vault/inbox/`
- Move: `HOME.md` → `vault/HOME.md`
- Move: `Vault Maintenance System.md` → `vault/Vault Maintenance System.md`
- Move: `.obsidian/` → `vault/.obsidian/`
- Move: `init-templates/scripts/*` → `scripts/`
- Delete: `init-templates/` (entire directory)
- Delete: `cli/add-db.sh`, `cli/add-auth.sh`, `cli/add-api.sh`, `cli/add-hooks.sh`, `cli/add-ci.sh`
- Create: `templates/` (empty, populated in Task 2)

- [ ] **Step 1: Create vault/ and move vault files**

```bash
cd /Users/thondascully/all/projects/nexus
mkdir -p vault
git mv foundations vault/foundations
git mv tools vault/tools
git mv templates vault/templates
git mv signals vault/signals
git mv projects vault/projects
git mv daily vault/daily
git mv inbox vault/inbox
git mv HOME.md vault/HOME.md
git mv "Vault Maintenance System.md" "vault/Vault Maintenance System.md"
git mv .obsidian vault/.obsidian
```

- [ ] **Step 2: Move scripts to root level and delete init-templates**

```bash
mkdir -p scripts
cp init-templates/scripts/* scripts/
chmod +x scripts/*
git rm -rf init-templates/
git add scripts/
```

- [ ] **Step 3: Delete v1 add commands**

```bash
git rm cli/add-db.sh cli/add-auth.sh cli/add-api.sh cli/add-hooks.sh cli/add-ci.sh
```

- [ ] **Step 4: Create empty templates directory**

```bash
mkdir -p templates
```

- [ ] **Step 5: Verify structure**

```bash
ls vault/
# Expected: HOME.md, Vault Maintenance System.md, .obsidian, foundations, tools, templates, signals, projects, daily, inbox

ls scripts/
# Expected: sync-claude-md.sh, check-env-sync.sh, check-deps-direction.ts, check-dead-exports.ts, validate-startup.sh

ls cli/
# Expected: helpers.sh, init.sh, doctor.sh, update.sh (add-*.sh gone)
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: restructure repo — vault under vault/, scripts to root, delete v1 add commands"
```

---

### Task 2: Templates

Create all template files that `nexus init` drops into projects.

**Files:**
- Create: `templates/CLAUDE.md`
- Create: `templates/justfile`
- Create: `templates/gitignore`
- Create: `templates/env.example`
- Create: `templates/mise.toml`
- Create: `templates/pr-template.md`
- Create: `templates/lefthook.yml`
- Create: `templates/claude-settings.json`

- [ ] **Step 1: Write templates/CLAUDE.md**

This is the single CLAUDE.md template with nexus-owned section markers. User-owned sections have placeholder comments. Nexus-owned sections are wrapped in `<!-- nexus:name -->` / `<!-- nexus:end -->`.

```markdown
# CLAUDE.md

## Project Overview
<!-- This is yours — describe your app, who it's for, what the core loop is -->

## Tech Stack
<!-- This is yours — list your specific stack here -->

## Architecture Rules

### Dependency Direction
<!-- This is yours — define your chain. Example: -->
<!-- Types → Config → Repo → Service → Runtime → UI -->
<!-- Enforced by scripts/check-deps-direction.ts on every commit -->

<!-- nexus:file-structure -->
## File Structure
<!-- Auto-generated by scripts/sync-claude-md.sh — do not edit manually -->
<!-- nexus:end -->

<!-- nexus:conventions -->
## Conventions
- All API responses follow: `{ data, error, metadata }`
- All errors follow: `{ code, message, details }`
- All database tables have: `id`, `created_at`, `updated_at`, `deleted_at`
- No `any` types. No `@ts-ignore`. No `eslint-disable` without a comment explaining why.
- No business logic in route handlers or components.
- No direct database calls outside repositories.
<!-- nexus:end -->

<!-- nexus:testing -->
## Testing Requirements
- Run tests after every change.
- **Never remove or weaken existing tests.** If a test fails, fix the implementation.
- New features require at least one integration test.
- Core loop changes require E2E coverage.
<!-- nexus:end -->

<!-- nexus:git -->
## Git Conventions
- Commit after each successful step, not after a feature is complete.
- Commit messages: `type(scope): description`
- Never commit `.env` files or secrets.
<!-- nexus:end -->

## When In Doubt
- Check existing code for patterns before inventing new ones.
- If a decision isn't covered here, ask — don't assume.
```

- [ ] **Step 2: Write templates/justfile**

```just
# justfile — project commands
# Run with: just <command>

# ── Dev ──────────────────────────────────────────────────
dev:
    echo "Configure: just --edit → replace this with your dev command"

build:
    echo "Configure: just --edit → replace this with your build command"

test:
    echo "Configure: just --edit → replace this with your test command"

# ── Quality (managed by nexus) ───────────────────────────
doctor:
    nexus doctor

doctor-fix:
    nexus doctor --fix
```

- [ ] **Step 3: Write templates/gitignore**

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
.nexus-version
coverage/
.vercel/
```

- [ ] **Step 4: Write templates/env.example**

```bash
# App
NODE_ENV=development
```

- [ ] **Step 5: Write templates/mise.toml**

```toml
[tools]
node = "24"

[settings]
auto_install = true
```

- [ ] **Step 6: Write templates/pr-template.md**

Use the same PR checklist from v1 (already proven good — sourced from the vault's PR Review Checklist):

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
- [ ] New API inputs validated at the boundary
- [ ] Types derive from source of truth, not manually duplicated

### Testing
- [ ] No existing tests removed or weakened
- [ ] At least one test for the happy path
- [ ] Core loop changes have E2E coverage

### Security
- [ ] Auth check on every new endpoint
- [ ] No secrets hardcoded
- [ ] No unsanitized user input in queries or HTML

### Agent Red Flags
- [ ] No hallucinated imports (packages not in package.json)
- [ ] No over-abstracted code for simple operations
- [ ] No TODO comments left behind
```

- [ ] **Step 7: Write templates/lefthook.yml**

```yaml
# lefthook.yml — pre-commit hooks (managed by nexus)
# Install: brew install lefthook && lefthook install

pre-commit:
  parallel: true
  commands:
    env-sync:
      run: bash scripts/check-env-sync.sh
    deps-direction:
      run: "[ -f scripts/check-deps-direction.ts ] && bun scripts/check-deps-direction.ts || true"
    hallucinated-imports:
      run: "[ -f scripts/check-hallucinated-imports.ts ] && bun scripts/check-hallucinated-imports.ts || true"
    typecheck:
      run: "[ -f package.json ] && pnpm typecheck || true"
    lint:
      run: "[ -f package.json ] && pnpm lint || true"
```

- [ ] **Step 8: Write templates/claude-settings.json**

This is the full version (with onStop). `nexus init` will strip onStop if Superpowers is detected.

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

- [ ] **Step 9: Verify all 8 template files**

```bash
ls templates/
# Expected: CLAUDE.md, justfile, gitignore, env.example, mise.toml, pr-template.md, lefthook.yml, claude-settings.json
```

- [ ] **Step 10: Commit**

```bash
git add templates/
git commit -m "feat(v2): add project templates with CLAUDE.md section markers"
```

---

### Task 3: New Scripts (hallucinated imports + orphaned files)

**Files:**
- Create: `scripts/check-hallucinated-imports.ts`
- Create: `scripts/check-orphaned-files.ts`

- [ ] **Step 1: Write scripts/check-hallucinated-imports.ts**

```typescript
#!/usr/bin/env bun
// scripts/check-hallucinated-imports.ts
// Catches packages imported in code but not in package.json
// Called by lefthook pre-commit and nexus doctor

import { readFileSync, readdirSync, statSync, existsSync } from "fs";
import { join, relative } from "path";
import { builtinModules } from "module";

const root = process.cwd();

// ── Load package.json deps ──────────────────────────────────────
const pkgPath = join(root, "package.json");
if (!existsSync(pkgPath)) {
  // No package.json = nothing to check against
  process.exit(0);
}

const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
const allDeps = new Set([
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.devDependencies || {}),
  ...Object.keys(pkg.peerDependencies || {}),
]);

// ── Node built-ins ──────────────────────────────────────────────
const builtins = new Set([
  ...builtinModules,
  ...builtinModules.map((m) => `node:${m}`),
]);

// ── Collect source files ────────────────────────────────────────
function collectFiles(dir: string, files: string[] = []): string[] {
  const skip = ["node_modules", ".next", "dist", ".git", "build", ".turbo", "scripts"];
  for (const entry of readdirSync(dir)) {
    if (skip.includes(entry)) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      collectFiles(full, files);
    } else if (/\.(ts|tsx|js|jsx)$/.test(entry)) {
      files.push(full);
    }
  }
  return files;
}

// ── Extract package names from imports ──────────────────────────
function extractPackageImports(content: string): string[] {
  const packages: string[] = [];
  const patterns = [
    /from\s+['"]([^'"]+)['"]/g,
    /import\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
    /require\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(content)) !== null) {
      const spec = match[1];
      // Skip relative, alias, and URL imports
      if (spec.startsWith(".") || spec.startsWith("@/") || spec.startsWith("~/") || spec.startsWith("http")) {
        continue;
      }
      // Extract package name (handle scoped packages)
      let pkgName: string;
      if (spec.startsWith("@")) {
        const parts = spec.split("/");
        pkgName = parts.length >= 2 ? `${parts[0]}/${parts[1]}` : spec;
      } else {
        pkgName = spec.split("/")[0];
      }
      packages.push(pkgName);
    }
  }
  return packages;
}

// ── Main ────────────────────────────────────────────────────────
const files = collectFiles(root);

if (files.length === 0) {
  process.exit(0);
}

const hallucinated: { file: string; pkg: string }[] = [];

for (const file of files) {
  const content = readFileSync(file, "utf-8");
  const imports = extractPackageImports(content);

  for (const pkg of imports) {
    if (allDeps.has(pkg) || builtins.has(pkg)) continue;
    hallucinated.push({ file: relative(root, file), pkg });
  }
}

// Deduplicate by package name
const seen = new Set<string>();
const unique = hallucinated.filter(({ file, pkg }) => {
  const key = `${file}:${pkg}`;
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});

if (unique.length > 0) {
  console.log(`Hallucinated imports (${unique.length}):`);
  for (const { file, pkg } of unique) {
    console.log(`  ${file} imports "${pkg}" (not in package.json)`);
  }
  process.exit(1);
}

process.exit(0);
```

- [ ] **Step 2: Write scripts/check-orphaned-files.ts**

```typescript
#!/usr/bin/env bun
// scripts/check-orphaned-files.ts
// Detects files that nothing imports (agent leftovers)
// Called by nexus doctor

import { readFileSync, readdirSync, statSync } from "fs";
import { join, relative, basename, dirname } from "path";

const root = process.cwd();

// ── Next.js / framework convention files (never orphaned) ───────
const conventionFiles = new Set([
  "page.tsx", "page.ts", "page.jsx", "page.js",
  "layout.tsx", "layout.ts", "layout.jsx", "layout.js",
  "loading.tsx", "loading.ts",
  "error.tsx", "error.ts",
  "not-found.tsx", "not-found.ts",
  "route.ts", "route.js",
  "middleware.ts", "middleware.js",
  "global-error.tsx", "global-error.ts",
  "default.tsx", "default.ts",
  "template.tsx", "template.ts",
  "opengraph-image.tsx", "twitter-image.tsx",
  "sitemap.ts", "robots.ts",
  "manifest.ts",
]);

// ── Config files (never orphaned) ───────────────────────────────
const configPatterns = [
  /\.config\.(ts|js|mjs|cjs)$/,
  /tailwind/,
  /postcss/,
  /next\.config/,
  /drizzle\.config/,
  /vitest\.config/,
  /jest\.config/,
  /playwright\.config/,
  /eslint/,
  /prettier/,
  /tsconfig/,
];

// ── Collect source files ────────────────────────────────────────
function collectFiles(dir: string, files: string[] = []): string[] {
  const skip = ["node_modules", ".next", "dist", ".git", "build", ".turbo", "scripts", ".claude"];
  for (const entry of readdirSync(dir)) {
    if (skip.includes(entry)) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      collectFiles(full, files);
    } else if (/\.(ts|tsx|js|jsx)$/.test(entry)) {
      files.push(full);
    }
  }
  return files;
}

function isConventionFile(filePath: string): boolean {
  const name = basename(filePath);
  if (conventionFiles.has(name)) return true;
  if (name === "index.ts" || name === "index.tsx" || name === "index.js") return true;
  for (const pattern of configPatterns) {
    if (pattern.test(filePath)) return true;
  }
  return false;
}

function isReferencedByOtherFile(filePath: string, allFiles: string[]): boolean {
  const rel = relative(root, filePath);
  const nameNoExt = basename(filePath).replace(/\.(ts|tsx|js|jsx)$/, "");
  const dirName = basename(dirname(filePath));

  for (const other of allFiles) {
    if (other === filePath) continue;
    const content = readFileSync(other, "utf-8");
    // Check for various import patterns that could resolve to this file
    if (content.includes(nameNoExt) || content.includes(rel)) {
      return true;
    }
  }
  return false;
}

// ── Main ────────────────────────────────────────────────────────
const files = collectFiles(root);

// Skip if project is too small
if (files.length < 10) {
  process.exit(0);
}

const orphaned: string[] = [];

for (const file of files) {
  if (isConventionFile(file)) continue;
  if (!isReferencedByOtherFile(file, files)) {
    orphaned.push(relative(root, file));
  }
}

if (orphaned.length > 0) {
  console.log(`Orphaned files (${orphaned.length}):`);
  for (const f of orphaned) {
    console.log(`  ${f}`);
  }
  process.exit(1);
}

process.exit(0);
```

- [ ] **Step 3: Make executable**

```bash
chmod +x scripts/check-hallucinated-imports.ts scripts/check-orphaned-files.ts
```

- [ ] **Step 4: Commit**

```bash
git add scripts/check-hallucinated-imports.ts scripts/check-orphaned-files.ts
git commit -m "feat(v2): add hallucinated import and orphaned file detection scripts"
```

---

### Task 4: CLI Helpers

Update `cli/helpers.sh` — keep all v1 functions, update `TEMPLATES` path, add section migration utilities.

**Files:**
- Modify: `cli/helpers.sh`

- [ ] **Step 1: Update TEMPLATES path and add section migration helpers**

The v1 helpers.sh sets `TEMPLATES="$VAULT_DIR/init-templates"`. Change to `TEMPLATES="$VAULT_DIR/templates"` and `SCRIPTS="$VAULT_DIR/scripts"`.

Add these new functions:

`drop_file_silent` — like `drop_file` but skips silently (no O/S/D prompt):
```bash
drop_file_silent() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ]; then
    print_skip "$(basename "$dest") (already exists)"
    return 1
  fi

  cp "$src" "$dest"
  update_checksum "$dest"
  echo -e "  ${GREEN}created${NC} $(basename "$dest")"
  return 0
}
```

`migrate_claude_md` — section-level CLAUDE.md migration:
```bash
# Parses nexus-owned sections from a CLAUDE.md file
# Returns lines of "section_name" for each <!-- nexus:name --> found
parse_nexus_sections() {
  local file="$1"
  grep -o '<!-- nexus:\([a-z-]*\) -->' "$file" 2>/dev/null | sed 's/<!-- nexus:\(.*\) -->/\1/'
}

# Extracts content between <!-- nexus:name --> and <!-- nexus:end -->
extract_section() {
  local file="$1"
  local name="$2"
  awk -v name="$name" '
    $0 ~ "<!-- nexus:" name " -->" { found=1; next }
    /<!-- nexus:end -->/ { if(found) { found=0; next } }
    found { print }
  ' "$file"
}

# Replaces a nexus-owned section in a file with new content
replace_section() {
  local file="$1"
  local name="$2"
  local new_content="$3"

  awk -v name="$name" -v content="$new_content" '
    $0 ~ "<!-- nexus:" name " -->" { print; printf "%s\n", content; skip=1; next }
    /<!-- nexus:end -->/ { if(skip) { print; skip=0; next } }
    !skip { print }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

# Appends a new nexus section to the end of CLAUDE.md
append_section() {
  local file="$1"
  local name="$2"
  local content="$3"

  printf "\n<!-- nexus:%s -->\n%s\n<!-- nexus:end -->\n" "$name" "$content" >> "$file"
}
```

Also update `TEMPLATES` and add `SCRIPTS`:
```bash
VAULT_DIR="$(resolve_vault_dir)"
TEMPLATES="$VAULT_DIR/templates"
SCRIPTS="$VAULT_DIR/scripts"
```

- [ ] **Step 2: Verify helpers still load**

```bash
cd /Users/thondascully/all/projects/nexus && source cli/helpers.sh && echo "ok"
```

- [ ] **Step 3: Commit**

```bash
git add cli/helpers.sh
git commit -m "feat(v2): update helpers — new template paths, section migration utilities"
```

---

### Task 5: Rewrite nexus Entry Point

Default to doctor. Remove `add` command entirely.

**Files:**
- Rewrite: `nexus`

- [ ] **Step 1: Rewrite nexus**

```bash
#!/bin/bash
# nexus — Automated project infrastructure
# https://github.com/teohondascully/nexus

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
NEXUS_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"

source "$NEXUS_DIR/cli/helpers.sh"

cmd_help() {
  echo ""
  echo -e "  ${BOLD}nexus${NC} — automated project infrastructure"
  echo ""
  echo -e "  ${GREEN}nexus${NC}                Run doctor (default)"
  echo -e "  ${GREEN}nexus init${NC}           Drop self-maintaining infrastructure"
  echo -e "  ${GREEN}nexus doctor${NC}         Checks + recommendations"
  echo -e "  ${GREEN}nexus doctor --fix${NC}   Auto-fix what it can"
  echo -e "  ${GREEN}nexus doctor --quick${NC} Fast checks (for hooks)"
  echo -e "  ${GREEN}nexus update${NC}         Evolve project infrastructure"
  echo -e "  ${GREEN}nexus version${NC}        Show version"
  echo -e "  ${GREEN}nexus uninstall${NC}      Remove nexus"
  echo ""
}

case "${1:-}" in
  init)       shift; source "$NEXUS_DIR/cli/init.sh"; cmd_init "$@" ;;
  doctor)     shift; source "$NEXUS_DIR/cli/doctor.sh"; cmd_doctor "$@" ;;
  update)     source "$NEXUS_DIR/cli/update.sh"; cmd_update ;;
  version)    echo "nexus v$(cat "$NEXUS_DIR/VERSION" 2>/dev/null || echo "unknown")" ;;
  uninstall)  exec bash "$NEXUS_DIR/install.sh" --uninstall ;;
  help|--help|-h) cmd_help ;;
  "")         source "$NEXUS_DIR/cli/doctor.sh"; cmd_doctor ;;
  *)          echo -e "  ${RED}Unknown: $1${NC}"; cmd_help ;;
esac
```

- [ ] **Step 2: Test**

```bash
./nexus help
./nexus version
```

- [ ] **Step 3: Commit**

```bash
git add nexus
git commit -m "feat(v2): rewrite entry point — default to doctor, remove add command"
```

---

### Task 6: Rewrite `nexus init`

Zero questions. Drop files, skip what exists, offer to commit.

**Files:**
- Rewrite: `cli/init.sh`

- [ ] **Step 1: Write cli/init.sh**

```bash
#!/bin/bash
# cli/init.sh — nexus init (zero questions)

cmd_init() {
  check_git

  # Detect or create project
  if [ -n "${1:-}" ]; then
    if [ ! -d "$1" ]; then
      mkdir -p "$1"
      cd "$1"
      git init --quiet
      echo -e "  ${GREEN}created${NC} $1/"
    else
      cd "$1"
    fi
  fi

  if [ ! -d ".git" ]; then
    git init --quiet
    echo -e "  ${GREEN}initialized${NC} git"
  fi

  echo ""
  echo -e "  ${BOLD}nexus init${NC}"
  echo ""

  # ── Drop templates ──────────────────────────────────────────────
  drop_file_silent "$TEMPLATES/CLAUDE.md" "CLAUDE.md"
  drop_file_silent "$TEMPLATES/justfile" "justfile"
  drop_file_silent "$TEMPLATES/gitignore" ".gitignore"
  drop_file_silent "$TEMPLATES/env.example" ".env.example"
  drop_file_silent "$TEMPLATES/mise.toml" ".mise.toml"

  mkdir -p .github
  drop_file_silent "$TEMPLATES/pr-template.md" ".github/pull_request_template.md"

  # ── Drop scripts ────────────────────────────────────────────────
  mkdir -p scripts
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
    if [ -f "$SCRIPTS/$script" ]; then
      drop_file_silent "$SCRIPTS/$script" "scripts/$script"
    fi
  done
  chmod +x scripts/*.sh scripts/*.ts 2>/dev/null || true

  # ── Drop hooks ──────────────────────────────────────────────────
  drop_file_silent "$TEMPLATES/lefthook.yml" "lefthook.yml"

  # Claude Code hooks — strip onStop if Superpowers detected
  if [ ! -f ".claude/settings.json" ]; then
    mkdir -p .claude
    if [ -d "$HOME/.claude/plugins" ] && ls "$HOME/.claude/plugins" 2>/dev/null | grep -q superpowers; then
      # Strip onStop block — Superpowers handles it
      grep -v '"onStop"' "$TEMPLATES/claude-settings.json" | \
        grep -v 'nexus doctor' | \
        grep -v '"command":' | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
data.pop('hooks', {}).pop('onStop', None)
# Rebuild clean
out = {'hooks': {'PostToolUse': data.get('hooks', {}).get('PostToolUse', [])}}
json.dump(out, sys.stdout, indent=2)
" > .claude/settings.json 2>/dev/null || cp "$TEMPLATES/claude-settings.json" .claude/settings.json
      echo -e "  ${GREEN}created${NC} settings.json ${DIM}(superpowers mode)${NC}"
    else
      cp "$TEMPLATES/claude-settings.json" .claude/settings.json
      echo -e "  ${GREEN}created${NC} settings.json"
    fi
    update_checksum ".claude/settings.json"
  else
    print_skip "settings.json (already exists)"
  fi

  # ── Post-setup ──────────────────────────────────────────────────

  # Add .nexus-checksums and .nexus-version to gitignore
  append_to_file ".gitignore" ".nexus-checksums" ".nexus-checksums" > /dev/null 2>&1 || true
  append_to_file ".gitignore" ".nexus-version" ".nexus-version" > /dev/null 2>&1 || true

  # Stamp version
  cp "$NEXUS_DIR/VERSION" ".nexus-version"

  # Sync CLAUDE.md file structure
  if [ -f "scripts/sync-claude-md.sh" ] && [ -f "CLAUDE.md" ]; then
    bash scripts/sync-claude-md.sh 2>/dev/null && echo -e "  ${GREEN}synced${NC} CLAUDE.md file structure" || true
  fi

  # Install lefthook if available
  if has_cmd lefthook && [ -f "lefthook.yml" ]; then
    lefthook install > /dev/null 2>&1 && echo -e "  ${GREEN}activated${NC} pre-commit hooks" || true
  fi

  # ── Summary ─────────────────────────────────────────────────────
  echo ""
  printf "  Commit? [Y/n]: "
  read -r commit_ans || true
  if [ "${commit_ans:-y}" != "n" ] && [ "${commit_ans:-y}" != "N" ]; then
    git add -A
    git commit -m "chore: initialize project with nexus" --quiet 2>/dev/null || true
    echo -e "  ${GREEN}committed${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Done.${NC} Hooks are active. Run ${GREEN}nexus${NC} to check project health."
  echo ""
}
```

- [ ] **Step 2: Test**

```bash
cd /tmp && mkdir nexus-v2-test && cd nexus-v2-test
/Users/thondascully/all/projects/nexus/nexus init
ls -la CLAUDE.md scripts/ .claude/ lefthook.yml justfile
rm -rf /tmp/nexus-v2-test
```

- [ ] **Step 3: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/init.sh
git commit -m "feat(v2): rewrite nexus init — zero questions, silent skip"
```

---

### Task 7: Rewrite `nexus doctor`

Checks + recommendations tier. `--fix`, `--quick`.

**Files:**
- Rewrite: `cli/doctor.sh`

- [ ] **Step 1: Write cli/doctor.sh**

```bash
#!/bin/bash
# cli/doctor.sh — nexus doctor

cmd_doctor() {
  local quick=false
  local fix=false

  for arg in "$@"; do
    case "$arg" in
      --quick) quick=true ;;
      --fix)   fix=true ;;
    esac
  done

  if [ ! -d ".git" ]; then
    echo ""
    echo -e "  ${RED}Not a git repository.${NC} Run nexus doctor from inside a project."
    echo ""
    return 1
  fi

  echo ""
  echo -e "  ${BOLD}nexus doctor${NC}"
  echo ""

  local passed=0
  local failed=0
  local skipped=0

  # ── 1. CLAUDE.md file structure sync ─────────────────────────────
  if [ -f "CLAUDE.md" ] && grep -q "nexus:file-structure" "CLAUDE.md" 2>/dev/null && [ -f "scripts/sync-claude-md.sh" ]; then
    local backup="CLAUDE.md.doctor-backup"
    cp "CLAUDE.md" "$backup"
    bash scripts/sync-claude-md.sh 2>/dev/null || true
    if diff -q "$backup" "CLAUDE.md" > /dev/null 2>&1; then
      print_ok "CLAUDE.md file structure"
      ((passed++))
    else
      if $fix; then
        print_ok "CLAUDE.md file structure ${DIM}(fixed)${NC}"
        ((passed++))
      else
        cp "$backup" "CLAUDE.md"
        print_fail "CLAUDE.md file structure out of sync"
        echo -e "        ${DIM}Run: nexus doctor --fix${NC}"
        ((failed++))
      fi
    fi
    rm -f "$backup"
  else
    print_skip "CLAUDE.md file structure"
    ((skipped++))
  fi

  # ── 2. .env.example coverage ─────────────────────────────────────
  if [ -f "scripts/check-env-sync.sh" ]; then
    local env_output
    env_output=$(bash scripts/check-env-sync.sh 2>&1)
    local env_exit=$?
    if [ $env_exit -eq 0 ]; then
      print_ok ".env.example coverage"
      ((passed++))
    else
      if $fix && [ -f ".env.example" ]; then
        echo "$env_output" | grep "^  " | tr -d ' ' | while IFS= read -r varname; do
          [ -n "$varname" ] && echo "${varname}= # TODO: set value" >> ".env.example"
        done
        print_ok ".env.example coverage ${DIM}(fixed)${NC}"
        ((passed++))
      else
        print_fail ".env.example coverage"
        echo "$env_output" | head -3 | while IFS= read -r line; do
          echo -e "        ${DIM}${line}${NC}"
        done
        ((failed++))
      fi
    fi
  elif $fix && [ ! -f ".env.example" ]; then
    # Create .env.example from code references
    echo "# Auto-generated by nexus doctor --fix" > .env.example
    grep -roh 'process\.env\.\([A-Z_][A-Z0-9_]*\)' --include='*.ts' --include='*.tsx' --include='*.js' . 2>/dev/null \
      | sed 's/process\.env\.//' | sort -u | while IFS= read -r var; do
        echo "${var}=" >> .env.example
      done
    print_ok ".env.example ${DIM}(created)${NC}"
    ((passed++))
  else
    print_skip ".env.example coverage"
    ((skipped++))
  fi

  # ── 3. Dependency direction ──────────────────────────────────────
  if has_cmd bun && [ -f "scripts/check-deps-direction.ts" ]; then
    local deps_output
    deps_output=$(bun scripts/check-deps-direction.ts 2>&1)
    if [ $? -eq 0 ]; then
      print_ok "Dependency direction"
      ((passed++))
    else
      print_fail "Dependency direction"
      echo "$deps_output" | head -5 | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    print_skip "Dependency direction"
    ((skipped++))
  fi

  # ── 4. Hallucinated imports ──────────────────────────────────────
  if has_cmd bun && [ -f "scripts/check-hallucinated-imports.ts" ]; then
    local hall_output
    hall_output=$(bun scripts/check-hallucinated-imports.ts 2>&1)
    if [ $? -eq 0 ]; then
      print_ok "Hallucinated imports"
      ((passed++))
    else
      print_fail "Hallucinated imports"
      echo "$hall_output" | head -5 | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    print_skip "Hallucinated imports"
    ((skipped++))
  fi

  # ── 5. Dead exports (skip if --quick) ────────────────────────────
  if $quick; then
    : # silent skip
  elif has_cmd bun && [ -f "scripts/check-dead-exports.ts" ]; then
    local dead_output
    dead_output=$(bun scripts/check-dead-exports.ts 2>&1)
    if [ $? -eq 0 ]; then
      print_ok "Dead exports"
      ((passed++))
    else
      print_fail "Dead exports"
      echo "$dead_output" | head -5 | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    if ! $quick; then print_skip "Dead exports"; ((skipped++)); fi
  fi

  # ── 6. Orphaned files (skip if --quick) ──────────────────────────
  if $quick; then
    : # silent skip
  elif has_cmd bun && [ -f "scripts/check-orphaned-files.ts" ]; then
    local orph_output
    orph_output=$(bun scripts/check-orphaned-files.ts 2>&1)
    if [ $? -eq 0 ]; then
      print_ok "Orphaned files"
      ((passed++))
    else
      print_fail "Orphaned files"
      echo "$orph_output" | head -5 | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    if ! $quick; then print_skip "Orphaned files"; ((skipped++)); fi
  fi

  # ── 7. Nexus version (skip if --quick) ───────────────────────────
  if $quick; then
    : # silent skip
  elif [ -f "$HOME/.nexus/VERSION" ]; then
    local local_ver
    local_ver=$(cat "$HOME/.nexus/VERSION" 2>/dev/null || echo "unknown")
    git -C "$HOME/.nexus" fetch --quiet origin main 2>/dev/null || true
    local remote_ver
    remote_ver=$(git -C "$HOME/.nexus" show origin/main:VERSION 2>/dev/null || echo "")
    if [ -z "$remote_ver" ] || [ "$local_ver" = "$remote_ver" ]; then
      print_ok "Nexus v${local_ver}"
      ((passed++))
    else
      print_fail "Nexus outdated (v${local_ver} → v${remote_ver})"
      echo -e "        ${DIM}Run: curl -fsSL https://www.teonnaise.com/install | bash${NC}"
      ((failed++))
    fi
  else
    if ! $quick; then print_skip "Nexus version"; ((skipped++)); fi
  fi

  # ── Summary ──────────────────────────────────────────────────────
  local total=$((passed + failed))
  echo ""
  if [ $failed -eq 0 ] && [ $total -gt 0 ]; then
    echo -e "  ${GREEN}${passed}/${total} passed${NC}  ${DIM}${skipped} skipped${NC}"
  elif [ $total -gt 0 ]; then
    echo -e "  ${passed}/${total} passed  ${RED}${failed} failed${NC}  ${DIM}${skipped} skipped${NC}"
  fi

  # ── Recommendations ──────────────────────────────────────────────
  if ! $quick; then
    local recs=0
    local rec_lines=""

    # No linter
    if [ -f "package.json" ] && ! grep -q '"eslint"\|"biome"\|"@biomejs"' package.json 2>/dev/null; then
      rec_lines="${rec_lines}   ~  No linter. Run: pnpm add -D eslint\n"
      ((recs++))
    fi

    # TypeScript strict off
    if [ -f "tsconfig.json" ] && ! grep -q '"strict":\s*true' tsconfig.json 2>/dev/null; then
      rec_lines="${rec_lines}   ~  TypeScript strict mode is off\n"
      ((recs++))
    fi

    # No formatter
    if [ -f "package.json" ] && ! ls .prettierrc* biome.json 2>/dev/null | grep -q .; then
      rec_lines="${rec_lines}   ~  No formatter. Run: pnpm add -D prettier\n"
      ((recs++))
    fi

    # No test runner
    if [ -f "package.json" ] && ! grep -q '"vitest"\|"jest"\|"playwright"\|"@testing-library"' package.json 2>/dev/null; then
      rec_lines="${rec_lines}   ~  No test runner. Run: pnpm add -D vitest\n"
      ((recs++))
    fi

    # No pre-commit hooks
    if [ ! -f "lefthook.yml" ] && [ ! -d ".husky" ]; then
      rec_lines="${rec_lines}   ~  No pre-commit hooks. Run: nexus init\n"
      ((recs++))
    fi

    # No CLAUDE.md
    if [ ! -f "CLAUDE.md" ]; then
      rec_lines="${rec_lines}   ~  No CLAUDE.md. Run: nexus init\n"
      ((recs++))
    fi

    # No .env.example
    if [ ! -f ".env.example" ] && [ -f "package.json" ]; then
      rec_lines="${rec_lines}   ~  No .env.example. Run: nexus doctor --fix\n"
      ((recs++))
    fi

    # No engines field
    if [ -f "package.json" ] && ! grep -q '"engines"' package.json 2>/dev/null; then
      rec_lines="${rec_lines}   ~  No engines field in package.json. Pin your Node version.\n"
      ((recs++))
    fi

    # CommonJS
    if [ -f "package.json" ] && ! grep -q '"type":\s*"module"' package.json 2>/dev/null && [ -f "package.json" ]; then
      rec_lines="${rec_lines}   ~  No \"type\": \"module\" in package.json\n"
      ((recs++))
    fi

    if [ $recs -gt 0 ]; then
      echo ""
      echo -e "  ${BOLD}Recommendations${NC}"
      printf "$rec_lines"
      echo ""
      echo -e "  ${DIM}${recs} recommendation(s)${NC}"
    fi
  fi

  echo ""
  return $failed
}
```

- [ ] **Step 2: Test**

```bash
cd /tmp && mkdir doctor-test && cd doctor-test && git init
echo "test" > CLAUDE.md
/Users/thondascully/all/projects/nexus/nexus doctor
rm -rf /tmp/doctor-test
```

- [ ] **Step 3: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/doctor.sh
git commit -m "feat(v2): rewrite doctor — checks + recommendations + --fix"
```

---

### Task 8: Rewrite `nexus update` with Section Migration

**Files:**
- Rewrite: `cli/update.sh`

- [ ] **Step 1: Write cli/update.sh**

```bash
#!/bin/bash
# cli/update.sh — nexus update with section-level CLAUDE.md migration

cmd_update() {
  echo ""
  echo -e "  ${BOLD}nexus update${NC}"

  # ── Check vault exists ─────────────────────────────────────────
  if [ ! -d "$HOME/.nexus" ]; then
    echo ""
    echo -e "  ${RED}~/.nexus not found.${NC} Install: curl -fsSL https://www.teonnaise.com/install | bash"
    echo ""
    return 1
  fi

  # ── Pull latest ────────────────────────────────────────────────
  echo ""
  echo -e "  Pulling latest..."
  if [ -d "$HOME/.nexus/.git" ]; then
    git -C "$HOME/.nexus" pull --ff-only --quiet 2>/dev/null || {
      print_warn "Could not pull (not fast-forward or offline)"
    }
  fi

  # ── Compare versions ───────────────────────────────────────────
  local local_ver="unknown"
  local remote_ver="unknown"
  [ -f ".nexus-version" ] && local_ver=$(cat .nexus-version)
  [ -f "$HOME/.nexus/VERSION" ] && remote_ver=$(cat "$HOME/.nexus/VERSION")

  if [ "$local_ver" = "$remote_ver" ]; then
    echo -e "  ${GREEN}Up to date${NC} (v${local_ver})"
    echo ""
    return 0
  fi

  echo -e "  v${local_ver} → v${remote_ver}"
  echo ""

  local updates_available=false

  # ── Script migration ───────────────────────────────────────────
  echo -e "  ${BOLD}Scripts${NC}"
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
    local src="$SCRIPTS/$script"
    local dest="scripts/$script"

    if [ ! -f "$src" ]; then continue; fi

    if [ ! -f "$dest" ]; then
      echo -e "  ${CYAN}new${NC}   $script"
      updates_available=true
    elif is_customized "$dest"; then
      echo -e "  ${DIM}skip${NC}  $script ${DIM}(customized)${NC}"
    elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}up${NC}    $script"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}    $script"
    fi
  done

  # ── Hook migration ─────────────────────────────────────────────
  for hook in lefthook.yml; do
    local src="$TEMPLATES/$hook"
    local dest="$hook"
    if [ ! -f "$src" ] || [ ! -f "$dest" ]; then continue; fi

    if is_customized "$dest"; then
      echo -e "  ${DIM}skip${NC}  $hook ${DIM}(customized)${NC}"
    elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}up${NC}    $hook"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}    $hook"
    fi
  done

  # ── CLAUDE.md section migration ────────────────────────────────
  if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
    echo ""
    echo -e "  ${BOLD}CLAUDE.md${NC}"

    local template="$TEMPLATES/CLAUDE.md"

    # Get all nexus sections from template
    local template_sections
    template_sections=$(parse_nexus_sections "$template")

    # Get all nexus sections from project
    local project_sections
    project_sections=$(parse_nexus_sections "CLAUDE.md")

    for section in $template_sections; do
      if echo "$project_sections" | grep -q "^${section}$"; then
        # Section exists — compare content
        local template_content
        template_content=$(extract_section "$template" "$section")
        local project_content
        project_content=$(extract_section "CLAUDE.md" "$section")

        if [ "$template_content" = "$project_content" ]; then
          echo -e "  ${GREEN}ok${NC}    $section"
        else
          echo -e "  ${YELLOW}up${NC}    $section"
          updates_available=true
        fi
      else
        # New section
        echo -e "  ${CYAN}new${NC}   $section"
        updates_available=true
      fi
    done

    # Show user-owned sections as skipped
    # (anything in CLAUDE.md that's NOT between nexus markers)
    grep '^## ' "CLAUDE.md" | while IFS= read -r header; do
      local header_text="${header#\#\# }"
      # Check if this header is inside a nexus section
      local is_nexus=false
      for section in $template_sections; do
        local section_header
        section_header=$(awk -v name="$section" '
          $0 ~ "<!-- nexus:" name " -->" { found=1; next }
          /<!-- nexus:end -->/ { found=0; next }
          found && /^## / { print; exit }
        ' "$template")
        if [ "## $header_text" = "$section_header" ]; then
          is_nexus=true
          break
        fi
      done
      if [ "$is_nexus" = false ]; then
        echo -e "  ${DIM}skip${NC}  $header_text ${DIM}(yours)${NC}"
      fi
    done
  fi

  if ! $updates_available; then
    echo ""
    echo -e "  ${GREEN}Everything up to date.${NC}"
    echo ""
    cp "$HOME/.nexus/VERSION" ".nexus-version" 2>/dev/null || true
    return 0
  fi

  # ── Apply ──────────────────────────────────────────────────────
  echo ""
  printf "  Apply? [Y/n/diff]: "
  read -r apply_choice || true

  case "${apply_choice:-y}" in
    [dD])
      echo ""
      # Show diffs for scripts
      for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
        local src="$SCRIPTS/$script"
        local dest="scripts/$script"
        if [ -f "$src" ] && [ -f "$dest" ] && ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
          echo -e "  ${BOLD}--- $script ---${NC}"
          diff --color=always "$dest" "$src" 2>/dev/null | head -20
          echo ""
        fi
      done
      # Show diffs for CLAUDE.md sections
      if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
        for section in $(parse_nexus_sections "$TEMPLATES/CLAUDE.md"); do
          if echo "$(parse_nexus_sections "CLAUDE.md")" | grep -q "^${section}$"; then
            local t_content
            t_content=$(extract_section "$TEMPLATES/CLAUDE.md" "$section")
            local p_content
            p_content=$(extract_section "CLAUDE.md" "$section")
            if [ "$t_content" != "$p_content" ]; then
              echo -e "  ${BOLD}--- CLAUDE.md:$section ---${NC}"
              diff --color=always <(echo "$p_content") <(echo "$t_content") 2>/dev/null | head -20
              echo ""
            fi
          fi
        done
      fi
      printf "  Apply these? [Y/n]: "
      read -r apply_final || true
      [[ "${apply_final:-y}" =~ ^[nN]$ ]] && return 0
      ;;
    [nN]) return 0 ;;
  esac

  # ── Apply scripts ──────────────────────────────────────────────
  mkdir -p scripts
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
    local src="$SCRIPTS/$script"
    local dest="scripts/$script"
    if [ ! -f "$src" ]; then continue; fi

    if [ ! -f "$dest" ]; then
      cp "$src" "$dest"
      chmod +x "$dest" 2>/dev/null || true
      update_checksum "$dest"
      echo -e "  ${GREEN}added${NC} $script"
    elif ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      cp "$src" "$dest"
      chmod +x "$dest" 2>/dev/null || true
      update_checksum "$dest"
      echo -e "  ${GREEN}updated${NC} $script"
    fi
  done

  # ── Apply hook updates ─────────────────────────────────────────
  for hook in lefthook.yml; do
    local src="$TEMPLATES/$hook"
    local dest="$hook"
    if [ -f "$src" ] && [ -f "$dest" ] && ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      cp "$src" "$dest"
      update_checksum "$dest"
      echo -e "  ${GREEN}updated${NC} $hook"
    fi
  done

  # ── Apply CLAUDE.md section migration ──────────────────────────
  if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
    local template="$TEMPLATES/CLAUDE.md"

    for section in $(parse_nexus_sections "$template"); do
      local new_content
      new_content=$(extract_section "$template" "$section")

      if grep -q "<!-- nexus:${section} -->" "CLAUDE.md" 2>/dev/null; then
        local old_content
        old_content=$(extract_section "CLAUDE.md" "$section")
        if [ "$old_content" != "$new_content" ]; then
          replace_section "CLAUDE.md" "$section" "$new_content"
          echo -e "  ${GREEN}updated${NC} CLAUDE.md:$section"
        fi
      else
        # New section — get full block from template (including header)
        local full_block
        full_block=$(awk -v name="$section" '
          $0 ~ "<!-- nexus:" name " -->" { found=1 }
          found { print }
          /<!-- nexus:end -->/ { if(found) { found=0 } }
        ' "$template")
        printf "\n%s\n" "$full_block" >> "CLAUDE.md"
        echo -e "  ${GREEN}added${NC} CLAUDE.md:$section"
      fi
    done
  fi

  # ── Stamp version ──────────────────────────────────────────────
  cp "$HOME/.nexus/VERSION" ".nexus-version" 2>/dev/null || true

  echo ""
  echo -e "  ${GREEN}Updated to v${remote_ver}.${NC}"
  echo ""
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add cli/update.sh
git commit -m "feat(v2): rewrite update — section-level CLAUDE.md migration"
```

---

### Task 9: Update Uninstall + Bootstrap

**Files:**
- Modify: `install.sh` (add tier 3 config undo guide)
- Modify: `bootstrap.sh` (add "fully reversible" note to welcome)

- [ ] **Step 1: Add tier 3 config undo guide to install.sh uninstall flow**

After the package uninstall section in install.sh (the `fi` closing the "uninstall packages" block), add:

```bash
  # ── Tier 3: Config undo guide ──────────────────────────────────
  echo ""
  echo -e "  ${BOLD}Config changes made by bootstrap:${NC}"
  echo ""
  echo -e "  ${CYAN}Shell${NC}"
  echo -e "    ~/.zshrc — remove the block between:"
  echo -e "      ${DIM}# === Nexus Shell Config ===${NC}"
  echo -e "      ${DIM}# === End Nexus Shell Config ===${NC}"
  echo ""
  echo -e "  ${CYAN}Terminal${NC}"
  echo -e "    ~/.config/ghostty/config — delete or restore backup"
  echo -e "    ~/.config/ghostty/themes/catppuccin-mocha — delete"
  echo ""
  echo -e "  ${CYAN}Prompt${NC}"
  echo -e "    ~/.config/starship.toml — delete"
  echo ""
  echo -e "  ${CYAN}Runtimes${NC}"
  echo -e "    ~/.config/mise/config.toml — delete"
  echo ""
  echo -e "  ${CYAN}Git${NC} ${DIM}(~/.gitconfig — reset any with: git config --global --unset <key>)${NC}"
  echo -e "    core.pager = delta"
  echo -e "    interactive.diffFilter = delta --color-only"
  echo -e "    delta.navigate = true"
  echo -e "    delta.side-by-side = true"
  echo -e "    init.defaultBranch = main"
  echo -e "    pull.rebase = true"
  echo -e "    push.autoSetupRemote = true"
  echo -e "    rerere.enabled = true"
  echo ""
  echo -e "  ${DIM}None of these are destructive. Your data and projects are untouched.${NC}"
```

Find the right insertion point: after the `fi` that closes the "uninstall packages" if-block, before the final "Done." message.

- [ ] **Step 2: Add "fully reversible" note to bootstrap welcome**

In bootstrap.sh, after the `Safe to re-run.` line in the welcome screen, add:

```bash
echo -e "  ${DIM}Fully reversible. Run nexus uninstall for details.${NC}"
```

- [ ] **Step 3: Commit**

```bash
git add install.sh bootstrap.sh
git commit -m "feat(v2): uninstall tier 3 config guide + bootstrap reversibility note"
```

---

### Task 10: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite README to reflect v2**

Key changes from current README:
- Remove `nexus add` commands from CLI section
- Default command is `nexus doctor`, not help
- Describe the hook system (automatic enforcement)
- Update file structure to show `vault/`, `scripts/`, `templates/`
- Emphasize "automated project infrastructure" not "project initializer"
- Add "How it works" section: vault → artifacts → hooks → enforcement

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for v2 — automated project infrastructure"
```

---

### Task 11: End-to-End Test

**Files:** None (testing only)

- [ ] **Step 1: Test nexus help**

```bash
cd /Users/thondascully/all/projects/nexus
./nexus help
./nexus version
```

- [ ] **Step 2: Test nexus init on fresh project**

```bash
cd /tmp && mkdir e2e-v2 && cd e2e-v2
/Users/thondascully/all/projects/nexus/nexus init
```

Verify: CLAUDE.md (with nexus section markers), scripts/ (7 files), .claude/settings.json, lefthook.yml, justfile, .gitignore, .env.example, .mise.toml, .github/pull_request_template.md, .nexus-version

- [ ] **Step 3: Test nexus (default = doctor)**

```bash
cd /tmp/e2e-v2
/Users/thondascully/all/projects/nexus/nexus
```

Expected: doctor runs, shows checks + recommendations.

- [ ] **Step 4: Test nexus doctor --fix**

```bash
/Users/thondascully/all/projects/nexus/nexus doctor --fix
```

- [ ] **Step 5: Test nexus init on existing project (skips existing files)**

```bash
/Users/thondascully/all/projects/nexus/nexus init
```

Expected: all files show "skip (already exists)".

- [ ] **Step 6: Test nexus update**

```bash
/Users/thondascully/all/projects/nexus/nexus update
```

Expected: shows comparison, "up to date" or offers migration.

- [ ] **Step 7: Clean up**

```bash
rm -rf /tmp/e2e-v2
```

- [ ] **Step 8: Fix any issues found, commit**

```bash
cd /Users/thondascully/all/projects/nexus
git add -A
git commit -m "fix(v2): fixes from e2e testing"
```

---

### Task 12: Final Cleanup

- [ ] **Step 1: Verify no v1 remnants**

```bash
# Should find nothing:
ls cli/add-*.sh 2>/dev/null
ls init-templates/ 2>/dev/null

# Vault should be under vault/:
ls vault/HOME.md vault/foundations/ vault/tools/

# Root should be clean:
ls foundations/ tools/ templates/ 2>/dev/null
# templates/ should exist (nexus templates), foundations/ and tools/ should NOT exist at root
```

- [ ] **Step 2: Bump VERSION**

```bash
echo "2.0.0" > VERSION
git add VERSION
git commit -m "chore: bump to v2.0.0"
```

- [ ] **Step 3: Verify vault wikilinks still work**

Open `vault/HOME.md` and spot-check that `[[foundations/Foundations]]`, `[[tools/Tools]]`, `[[signals/Signals]]` links are valid (files exist at those relative paths within vault/).

```bash
ls "vault/foundations/Foundations.md" "vault/tools/Tools.md" "vault/signals/Signals.md"
```

- [ ] **Step 4: Update CHANGELOG.md**

Append v2 entry to CHANGELOG.md.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: nexus v2.0.0 — automated project infrastructure

Complete rewrite from project scaffolder to automated infrastructure:
- Zero-question nexus init drops self-maintaining conventions
- Doctor with checks + recommendations + --fix
- Section-level CLAUDE.md migration via nexus update
- Hallucinated import + orphaned file detection
- Full undo path in nexus uninstall
- Vault moved under vault/ for clean separation"
```
