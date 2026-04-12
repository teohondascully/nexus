# Template — CLAUDE.md

> Drop this at your repo root and customize per project. This is your Level 2 harness.

---

```markdown
# CLAUDE.md

## Project Overview
<!-- One paragraph: what this app does, who it's for, what the core loop is -->

## Tech Stack
- **Framework:** 
- **Language:** TypeScript (strict mode)
- **Database:** Postgres via [ORM]
- **Auth:** 
- **Styling:** Tailwind + shadcn/ui
- **Deployment:** 

## Architecture Rules
<!-- These are ENFORCED by linters/tests, not just documented -->

### Dependency Direction
<!-- Example: Types → Config → Repo → Service → Runtime → UI -->
<!-- Code may only import "forward" in this chain -->

### File Structure
```
apps/web/src/
├── app/           # Next.js routes (thin — delegates to services)
├── components/    # UI components (no business logic)
├── services/      # Business logic (no HTTP, no DB direct)
├── repositories/  # Database queries (no business logic)
├── types/         # Shared types (generated from DB schema)
├── lib/           # Utilities, config, third-party wrappers
└── hooks/         # React hooks (client-side state only)
```

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
- Commit messages: `type(scope): description` (e.g., `feat(auth): add session handling`)
- Never commit `.env` files or secrets.

## When In Doubt
- Check existing code for patterns before inventing new ones.
- If a decision isn't covered here, ask — don't assume.
- Prefer boring technology over clever technology.
```

---

## Customization Notes
- Fill in the `Tech Stack` section for your specific project
- Define your `Dependency Direction` chain — this is the most important architectural rule
- Add project-specific conventions as you discover patterns
- This file should grow over the life of the project as you learn what the agent gets wrong

## Related
- [[Harness Engineering Overview]] — why this file matters
- [[The Fractal Harness Stack]] — this is Level 2
- [[Template — Pre-Build Interrogation]] — answer these before writing this file

---

#templates #harness-engineering #claude-code
