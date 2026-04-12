# Nexus CLI Redesign — Project Initializer + Maintenance System

> Approved 2026-04-12. Replaces the old prompt-builder CLI with a project initializer that drops conventions into any project and hooks that maintain them over time.

---

## Problem

The old nexus CLI was an interactive prompt builder — a middleman between you and Claude Code. With a good CLAUDE.md, you can just talk to Claude Code directly. The CLI didn't add information Claude didn't already have.

## Solution

Nexus becomes a project initializer + ongoing maintenance system. `nexus init` makes the first commit good. Hooks make every commit after that good too. `nexus doctor` catches drift before it becomes debt.

---

## Command Structure

```
nexus                     — help (lists all commands)
nexus init                — stack wizard, drops core files, offers to run all add commands
nexus add db              — Postgres + Drizzle + docker-compose + migrations
nexus add auth            — Clerk config + middleware template
nexus add api             — tRPC setup + health endpoint + error format
nexus add hooks           — lefthook + Claude Code hooks + maintenance scripts
nexus add ci              — GitHub Actions workflow + PR template
nexus doctor              — runs all maintenance checks, reports pass/fail scorecard
nexus doctor --quick      — fast subset (no network/DB), used by Claude Code onStop hook
nexus doctor --fix        — auto-fixes what it can (CLAUDE.md sync, env sync)
nexus update              — pulls latest templates/hooks from ~/.nexus vault into project
```

---

## Implementation Language

- `nexus` CLI itself: **bash**. Zero dependencies, same as bootstrap.sh.
- Hooks/scripts: **language per job**. Bash for file checks, TypeScript (via Bun) for import parsing.

---

## Project Types

The init wizard asks what you're building:

```
What are you building?
  1  Web app (Next.js + Postgres + the works)
  2  Other (just give me the conventions)
```

**Web app** gets the full stack: all `nexus add` commands available, tailored CLAUDE.md, docker-compose, CI.

**Other** gets just the core files with a generic CLAUDE.md skeleton. Fill in your own stack and file structure.

v2 can expand to: API-only, CLI tool, library/package.

---

## Init Flow

### New project (`nexus init my-project`)

1. Creates directory, runs `git init`
2. Asks project type (web app / other)
3. If web app, asks per-layer questions:
   - Database? [Y/n] (default Postgres + Drizzle)
   - Auth? [Y/n] (default Clerk)
   - API style? [tRPC / REST / skip]
   - CI? [Y/n] (default GitHub Actions)
4. Drops core files (see Core Files section)
5. Asks: "Set up everything based on your choices? [Y/n]"
   - Yes: runs all relevant `nexus add` commands in sequence
   - No: drops only core files, prints available `nexus add` commands
6. Asks: "Commit these changes? [Y/n]"

### Existing project (`nexus init` inside a repo)

1. Detects existing project (has `.git/`, maybe has `package.json`)
2. Same wizard, but for each file that already exists, asks:
   - "CLAUDE.md already exists. Overwrite / Skip / Diff?"
3. Same flow otherwise

---

## Core Files (every project)

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project conventions, dependency direction, file structure (auto-synced by hook) |
| `justfile` | Standard commands: dev, test, build, lint, typecheck, doctor, outdated, audit |
| `.gitignore` | Comprehensive for the detected/chosen stack |
| `.env.example` | All required env vars documented |
| `.mise.toml` | Pinned runtime versions (node, python if applicable) |
| `scripts/sync-claude-md.sh` | Regenerates CLAUDE.md file structure section from actual directory tree |
| `scripts/check-env-sync.sh` | Warns when code references env vars not in .env.example |
| `scripts/check-deps-direction.ts` | Scans imports for dependency direction violations. Chain is configurable in CLAUDE.md |
| `scripts/check-dead-exports.ts` | Flags exported symbols that nothing imports |
| `scripts/validate-startup.sh` | Crashes app on boot if required env vars are missing |
| `.claude/settings.json` | Claude Code hooks for agent-time guardrails |
| `lefthook.yml` | Pre-commit hooks: typecheck, lint, env sync, dep direction |
| `.github/pull_request_template.md` | PR checklist from the vault's review template |

---

## Web App Add Commands

### `nexus add db`

Drops:
- `docker-compose.yml` — Postgres 17, Redis 7, Mailpit (email testing), healthchecks
- `packages/db/schema/` — starter schema with id, created_at, updated_at, deleted_at conventions
- `packages/db/migrate.ts` — Drizzle migration runner
- `packages/db/seed.ts` — seed script skeleton
- Updates `justfile` with: db:migrate, db:seed, db:reset
- Updates `.env.example` with DATABASE_URL, REDIS_URL

Prerequisites: Docker, pnpm/bun. If missing, drops files anyway and warns.

### `nexus add auth`

Drops:
- `src/middleware.ts` — Clerk middleware template
- `src/lib/auth.ts` — auth helper (currentUser, requireAuth)
- Updates `.env.example` with CLERK_SECRET_KEY, NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY

Prerequisites: pnpm/bun. If missing, drops files and prints install command.

### `nexus add api`

Drops:
- `src/server/trpc.ts` — tRPC initialization with context
- `src/server/routers/health.ts` — `/api/health` endpoint (checks DB connectivity, returns uptime)
- `src/server/routers/_app.ts` — root router
- `src/lib/api-error.ts` — consistent error format: `{ code, message, details }`
- Updates `justfile` with: api:health

Prerequisites: pnpm/bun. If missing, drops files and prints install command.

### `nexus add hooks`

Drops/configures:
- `lefthook.yml` — pre-commit hooks
- `.claude/settings.json` — Claude Code hooks
- All `scripts/` files from the core set
- Asks: "Use Superpowers (Claude Code plugin)? [Y/n]"
  - If yes: CLAUDE.md gets workflow conventions (/brainstorm before features, TDD, /review after steps). Hooks complement Superpowers skills rather than duplicating them.
  - If no: hooks are self-contained, same checks without the workflow layer.

Prerequisites: lefthook. Offers to install via brew. If no brew, warns.

### `nexus add ci`

Drops:
- `.github/workflows/ci.yml` — typecheck, lint, test, build on PR

Note: `.github/pull_request_template.md` is dropped by core files, not this command.

Prerequisites: gh CLI + auth for repo creation. Drops workflow file regardless, warns if gh not authenticated.

---

## Hook System (Three Layers)

### Layer 1: lefthook (pre-commit)

Catches problems before they enter the repo.

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    typecheck:
      run: pnpm typecheck
    lint:
      run: pnpm lint
    env-sync:
      run: bash scripts/check-env-sync.sh
    deps-direction:
      run: bun scripts/check-deps-direction.ts
```

### Layer 2: Claude Code hooks (.claude/settings.json)

Catches problems while the agent is writing code.

- **PostToolUse** (on file write): runs `scripts/sync-claude-md.sh` to keep file structure section current
- **PostToolUse** (on file write): runs tests for changed modules
- **onStop**: runs `scripts/check-deps-direction.ts` before agent declares done
- **onStop**: runs `nexus doctor --quick` (fast checks only)

If Superpowers is enabled, `onStop` defers to its verification-before-completion skill instead of rolling its own.

### Layer 3: justfile commands (manual)

Run when you want, not automated.

```just
# justfile
doctor:
    nexus doctor

outdated:
    pnpm outdated

schema-check:
    # compares Drizzle schema against actual DB
    bun scripts/check-schema-drift.ts

dead-code:
    bun scripts/check-dead-exports.ts

audit:
    just doctor && just outdated && just schema-check && just dead-code
```

---

## `nexus doctor` — Maintenance Scorecard

Runs all checks, reports pass/fail:

```
$ nexus doctor

  nexus doctor

  CLAUDE.md file structure .............. ok
  .env.example coverage ................ ok
  Dependency direction ................. ok
  Dead exports ......................... FAIL (3 found)
  Schema drift ......................... ok
  Startup validation ................... ok
  Outdated dependencies ................ FAIL (7 outdated, 2 major)
  lefthook installed ................... ok
  Claude Code hooks present ............ ok
  PR template present .................. ok

  8/10 passed
```

**`--quick`** skips: schema drift, outdated deps (no network/DB). Used by Claude Code onStop hook.

**`--fix`** auto-repairs:
- Regenerates CLAUDE.md file structure section
- Adds missing vars to `.env.example` with `# TODO: set value` placeholder
- Does NOT auto-update deps or delete dead code (just reports)

---

## `nexus update` — Vault Sync

Pulls latest `~/.nexus` vault, then diffs project files against current templates:

- Files you've customized (CLAUDE.md, justfile): flagged as skipped, never auto-overwritten
- Scripts and hooks you haven't hand-edited: updated
- `diff` option shows what would change before applying
- Asks: "Apply updates? [Y/n/diff]"

Detection of "customized" vs "untouched": nexus stores a hash of the original template content in `.nexus-checksums` (gitignored). If the file's current content doesn't match the original hash, it's been customized.

---

## Prerequisite Handling

**Hard requirement:** `git`. Without it, nexus exits with "run bootstrap first."

**Everything else degrades gracefully:**

| Dependency | If missing |
|------------|------------|
| brew | Warns, suggests manual install for lefthook |
| pnpm / bun | Drops config/template files anyway, prints install commands at the end |
| Docker | Drops docker-compose.yml anyway, warns "start Docker when ready" |
| lefthook | Offers to install via brew. Falls back to warning. |
| gh CLI | Drops `.github/` files regardless, warns "run `gh auth login` to connect" |
| Superpowers | Falls back to self-contained hooks |

Package installs (Drizzle, Clerk, tRPC) are never run by nexus. It drops files and prints a summary:

```
Done. Run these when ready:
  pnpm add drizzle-orm postgres
  pnpm add @clerk/nextjs
  pnpm add @trpc/server @trpc/client
```

---

## File Conflict Handling (Existing Projects)

When `nexus init` or `nexus add` encounters a file that already exists:

```
CLAUDE.md already exists. [O]verwrite / [S]kip / [D]iff?
```

- **Overwrite**: replaces with nexus template
- **Skip**: leaves existing file untouched
- **Diff**: shows side-by-side diff, then asks again

---

## Out of Scope (v1)

- Additional project types beyond web app and "other" (API-only, CLI, library)
- GUI / TUI beyond simple terminal prompts
- Nexus as a runtime daemon or background service
- Auto-updating dependencies (doctor reports, humans decide)
- Custom template authoring (use the vault directly)
