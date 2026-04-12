# The Full Pipeline

> The complete system. Every step from opening your laptop to shipping production code, in order. Each step links to the detailed note. This is the one page you read to understand how everything connects.

---

## The Map

```
MACHINE SETUP (do once)
│
├─ Terminal ──────────── Ghostty (GPU-accelerated, native, fast)
├─ Shell ─────────────── Zsh + Starship prompt
├─ CLI Tools ─────────── ripgrep, bat, eza, zoxide, fzf, delta, lazygit, atuin, fd
├─ Font ──────────────── JetBrains Mono Nerd Font
├─ Version Manager ───── mise (replaces nvm/pyenv/rbenv)
├─ JS Packages ───────── pnpm (strict, fast, monorepo-native)
├─ JS Runtime ────────── Bun (new projects) / Node.js (existing)
├─ Python ────────────── uv (replaces pip/venv/pyenv)
├─ Docker ────────────── Docker Desktop + lazydocker
├─ Editor ────────────── Cursor (visual) + Claude Code (agentic)
└─ Git Config ────────── delta as pager, rebase on pull, rerere
│
│  → [[Template — Machine Bootstrap]]
│
───────────────────────────────────────────────────
│
NEW PROJECT (do per project)
│
├─ Phase 0: Interrogation
│  ├─ Q1: What is the core loop? ─── User does X → system does Y → user gets Z
│  ├─ Q2: Who are the actors? ────── Roles, trust levels, permissions
│  ├─ Q3: What are the entities? ─── ER diagram, access patterns
│  ├─ Q4: What are the failures? ─── Which ones would kill you?
│  └─ Q5: Deployment topology? ───── Monolith. Always start monolith.
│
│  → [[Template — Pre-Build Interrogation]]
│
├─ Phase 1: Foundation (1-2 days first time, afternoon by third project)
│  │
│  ├─ Layer 1:  Monorepo scaffold ──────── Turborepo + pnpm + .mise.toml
│  ├─ Layer 2:  Database schema ────────── Postgres + Drizzle + migrations + seed
│  ├─ Layer 3:  Auth ───────────────────── Clerk (identity) + can() (authorization)
│  ├─ Layer 4:  API routes ─────────────── tRPC or REST + Zod validation
│  ├─ Layer 5:  Background jobs ────────── Inngest (if needed)
│  ├─ Layer 6:  Env/config ─────────────── .env + Zod validation at startup
│  ├─ Layer 7:  Error tracking ─────────── Sentry + Axiom structured logs
│  ├─ Layer 8:  Testing ────────────────── TypeScript strict + Zod + integration tests
│  ├─ Layer 9:  CI/CD ──────────────────── GitHub Actions + Vercel preview deploys
│  ├─ Layer 10: File storage ───────────── UploadThing or S3/R2
│  ├─ Layer 11: Payments ───────────────── Stripe (idempotent webhooks)
│  ├─ Layer 12: Email ──────────────────── Resend + React Email (background job)
│  ├─ Layer 13: Feature flags ──────────── PostHog or DB table
│  ├─ Layer 14: Search ─────────────────── Typesense (if needed)
│  └─ Layer 15: Analytics ──────────────── PostHog (events, not pageviews)
│  │
│  ├─ Docker: services in docker-compose.yml (Postgres, Redis, Mailpit)
│  └─ Harness: CLAUDE.md + hooks + .mise.toml at project root
│
│  → [[Template — Monorepo Scaffold]]
│  → [[Template — CLAUDE.md]]
│  → [[Template — Database Schema Starter]]
│
├─ Phase 2: Build (the actual product)
│  │
│  ├─ Break features into vertical slices
│  │  └─ "Create login form" not "build auth"
│  │
│  ├─ Per session:
│  │  ├─ Define one slice + acceptance criteria
│  │  ├─ "Read CLAUDE.md first. [task]. Propose approach before coding."
│  │  ├─ Hooks run typecheck + lint + test after every change
│  │  ├─ Review every diff (this is THE skill)
│  │  ├─ Commit after each successful step (git as checkpoint)
│  │  └─ Update PROGRESS.md if multi-session
│  │
│  ├─ Per slice:
│  │  ├─ DB schema change → API endpoint → UI component → test
│  │  ├─ Each slice is deployable (behind feature flag if needed)
│  │  └─ Each slice gets its own commit or small PR
│  │
│  └─ Harness levels:
│     ├─ Level 2: CLAUDE.md + hooks ──── minimum for reliable output
│     ├─ Level 3: + PROGRESS.md + shift handoff ── multi-session work
│     └─ Level 4: + CI gates + preview deploys ── enterprise-grade
│
│  → [[Template — Feature Slice Breakdown]]
│  → [[Session Workflow]]
│  → [[Prompt Patterns That Work]]
│
├─ Phase 3: Audit
│  │
│  ├─ Can a new dev run it in one command?
│  ├─ Do types flow end-to-end with zero duplication?
│  ├─ Can you diagnose a production error in 5 minutes?
│  ├─ Can you roll back a bad deploy in 2 minutes?
│  └─ Is the core loop covered by E2E tests?
│
│  → [[Template — Audit Checklist]]
│  → [[Template — PR Review Checklist]]
│
├─ Phase 4: Ship
│  │
│  ├─ Production Dockerfile (multi-stage, non-root, health check)
│  ├─ DNS, SSL, CDN configured
│  ├─ Sentry + uptime monitoring active
│  ├─ Stripe live mode (if payments)
│  ├─ Analytics funnels tracking core loop
│  └─ Rollback plan documented
│
│  → [[Template — Launch Checklist]]
│
└─ Phase 5: Learn
   │
   ├─ Run project retro: what worked, what to change
   ├─ Feed insights back into Foundations notes
   ├─ Update Templates with improvements
   └─ Next project starts faster
   
   → [[Template — Project Retro]]

───────────────────────────────────────────────────

ONGOING (weekly)
│
├─ 15-min signal scan: r/vibecoding, HN, RSS feeds
├─ Classify: meta shift ([red]) vs tool update ([yellow]) vs noise ([green])
├─ Update Tools if anything changed
└─ Process Obsidian inbox
   
   → [[Template — Weekly Tools Review]]
```

---

## The Design Principles (apply everywhere)

| Principle | One-liner | Note |
|-----------|-----------|------|
| [[Core Loop First]] | Every decision serves the atomic user action | |
| [[Types Flow Downstream]] | DB schema → API → client, one source of truth | |
| [[Crash Early]] | Validate at startup, fail fast, never silently | |
| [[Idempotency Everywhere]] | Safe to retry, safe to double-submit | |
| [[Deterministic Enforcement]] | Enforce with linters, not documentation | |
| [[Verification Hierarchy]] | The verification standard you set is the one you get | |

---

## The Harness (apply to every agent session)

| Level | What You Add | Result |
|-------|-------------|--------|
| 0 | Nothing (raw model) | Garbage output |
| 1 | Claude Code (agent loop + tools) | Demo-quality |
| **2** | **CLAUDE.md + hooks** | **Reliable output (minimum bar)** |
| 3 | + PROGRESS.md + shift handoff | Multi-session consistency |
| 4 | + CI gates + preview deploys | Production-grade |

---

## Why This Works

The system is fractal. Every layer wraps the previous one and adds constraints:

- Your **machine setup** constrains which tools are available
- Your **project scaffold** constrains file structure and conventions
- Your **CLAUDE.md** constrains agent behavior within the project
- Your **hooks** constrain code quality within each change
- Your **CI pipeline** constrains what reaches production
- Your **monitoring** constrains how long bugs survive

More constraints = more reliable output. The person who builds the best harness ships the best product, regardless of which model they're using.

This is the system. Fork it for every project. Answer Phase 0, build Phase 1 in order, audit with Phase 3 before shipping, retro with Phase 5 after. Each cycle makes the next one faster.

---

#foundations #pipeline #master-note
