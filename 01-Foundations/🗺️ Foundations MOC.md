# 🏗️ Foundations MOC

> Patterns that are universal across every serious product. These don't change when the next framework drops.

---

## Dev Environment (Layer -1)
- [[The Developer Machine]] — terminal, shell, CLI tools, fonts, dotfiles
- [[Version and Runtime Management]] — mise, uv, Bun, pnpm (the 2026 stack)
- [[Docker for Local Dev]] — containerize infrastructure from day 1

## Architecture (Layers 1-15)
- [[The 15 Universal Layers]] — the foundation blueprint (every product converges here)
- [[The Pre-Build Interrogation]] — 5 questions before touching code
- [[The Audit Checklist]] — does this look like a 50-person team built it?
- [[Monorepo Patterns]] — structure, tooling, type flow

## Harness Engineering
- [[Harness Engineering Overview]] — prompt eng → context eng → harness eng
- [[The Fractal Harness Stack]] — Level 0 (raw model) → Level 4 (CI/CD wraps everything)
- [[Deterministic Enforcement]] — linters, structural tests, CI gates
- [[Agent-Friendly Codebases]] — CLAUDE.md, hooks, progress files, shift handoffs
- [[Verification Hierarchy]] — types → schema → integration → E2E → browser

## Stack Decisions
- [[Database Decision Tree]] — when SQL, when NoSQL, when both
- [[Auth Build vs Buy]] — identity (buy) vs authorization (build)
- [[API Design Patterns]] — REST vs GraphQL vs tRPC decision framework
- [[State Management Patterns]] — server state, client state, URL state

## Design Principles
- [[Core Loop First]] — every decision serves the atomic user action
- [[Types Flow Downstream]] — DB schema → API → client, one source of truth
- [[Crash Early]] — validate at startup, fail fast, never silently
- [[Idempotency Everywhere]] — safe to retry, safe to double-submit
