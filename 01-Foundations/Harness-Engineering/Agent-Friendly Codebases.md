# Agent-Friendly Codebases

> Structure your project so AI agents produce reliable output. The codebase IS the context.

---

## Core Idea

The model performs dramatically better when given a clear plan to follow rather than asked to invent one. Your codebase structure, naming conventions, and documentation ARE the plan.

## The Config Files

### CLAUDE.md (Claude Code)
Project root file describing conventions, stack, file structure, and rules. Injected into context every session. See [[Template — CLAUDE.md]].

### .cursor/rules/ (Cursor)
Directory of rule files. Can be scoped to file patterns (e.g., rules that only apply to test files or API routes).

### AGENTS.md (GitHub Copilot)
Similar to CLAUDE.md. Project-level instructions for Copilot agents.

**Best practice:** Maintain all three if you or collaborators switch between tools. They share 90% of content.

## Structural Patterns That Help Agents

### 1. Consistent File Naming
Agents pattern-match aggressively. If every service file is `[entity].service.ts` and every repo file is `[entity].repository.ts`, the agent extracts the pattern and follows it.

Bad: `userHelpers.ts`, `handleProducts.ts`, `orderStuff.ts`
Good: `user.service.ts`, `product.service.ts`, `order.service.ts`

### 2. Colocation
Keep related files together. When the agent opens a feature folder, everything it needs is right there.

```
features/
├── orders/
│   ├── order.service.ts
│   ├── order.repository.ts
│   ├── order.types.ts
│   ├── order.test.ts
│   └── order.routes.ts
```

### 3. Barrel Exports with Boundaries
`index.ts` files define what's public from a module. This teaches the agent what it can and can't import.

```typescript
// features/orders/index.ts
export { OrderService } from './order.service';
export type { Order, CreateOrderInput } from './order.types';
// NOT exporting order.repository — it's internal
```

### 4. Example-Driven Conventions
The single best way to teach an agent a pattern: have one perfect example it can reference.

In CLAUDE.md:
```
When creating a new API route, follow the pattern in `src/app/api/orders/route.ts`
When creating a new service, follow the pattern in `src/services/order.service.ts`
```

## Progress Tracking for Multi-Session Work

### PROGRESS.md
A file the agent reads at the start of each session:

```markdown
# Progress

## Completed
- [x] User auth (signup, login, session management)
- [x] Organization CRUD
- [x] Invite flow

## Current
- [ ] Order creation (service layer done, need routes + UI)

## Blocked
- Payment integration (waiting on Stripe test keys)

## Decisions Made
- Using cursor-based pagination (not offset)
- Soft deletes on all entities
- UTC timestamps everywhere
```

### Git as Agent Memory
Agents commit after each successful step, not after a feature is complete. This provides:
- **Recovery:** roll back to last good state if agent goes off track
- **Context:** git log tells the next session what happened
- **Checkpoints:** each commit is a known-good state

## Anti-Patterns

### 1. Monolith Files
A 2000-line file overwhelms context. Agent tries to hold all of it in working memory and makes mistakes in distant parts of the file. Split at 200 lines.

### 2. Implicit Conventions
If it's not in CLAUDE.md or visible in existing code, the agent will invent its own pattern. And it'll be different every session.

### 3. Complex Inheritance Hierarchies
Agents struggle with deep inheritance chains. Prefer composition and simple interfaces.

### 4. Scattered State
If state management is spread across hooks, context providers, URL params, and local storage with no clear pattern, the agent will make inconsistent choices. Centralize and document.

---

## Related
- [[Template — CLAUDE.md]]
- [[The Fractal Harness Stack#Level 2 → 3]]
- [[Harness Engineering Overview#Shift Handoff Model]]
- [[Session Workflow]]

---

#harness-engineering #foundations #agent-workflow
