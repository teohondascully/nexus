# Prompt Patterns That Work

> Tested prompts for common tasks. These get reliably good output at [[The Fractal Harness Stack|Level 2+]].

---

## Session Openers

### New Feature
```
Read CLAUDE.md first.

Implement [feature name]. Here's the spec:

User story: As a [role], I want to [action], so that [outcome].

Acceptance criteria:
- [ ] [specific, testable criterion]
- [ ] [specific, testable criterion]
- [ ] [specific, testable criterion]

Follow the pattern in [existing similar file]. Propose your approach before writing code.
```

### Bug Fix
```
Read CLAUDE.md first.

Bug: [describe what's happening vs. what should happen]

Steps to reproduce:
1. [step]
2. [step]
3. [expected vs. actual]

Find the root cause before proposing a fix. Do NOT modify any existing tests.
```

### Refactor
```
Read CLAUDE.md first.

Refactor [file/module] to [goal]. Requirements:
- All existing tests must continue to pass
- No behavioral changes — this is a pure refactor
- Follow our dependency direction: [Types → Config → Repo → Service → UI]

Make changes incrementally. Commit after each step passes tests.
```

## Mid-Session Corrections

### Wrong Direction
```
Stop. That approach violates [specific rule]. Revert to the last commit and try this instead: [alternative approach].
```

### Over-Engineering
```
This is too complex for what we need. Simplify: [describe the simpler approach]. We can add complexity later if needed.
```

### Convention Violation
```
That doesn't follow our convention. Look at [existing file] for the pattern. Match that exactly.
```

### Test Weakening (critical)
```
Do NOT modify that test. The test is correct. Fix the implementation to make the test pass.
```

## Scaffolding Prompts

### New Entity End-to-End
```
Create the full stack for a new [entity name] entity:

1. DB schema in packages/db/schema/[entity].ts (follow the pattern in users.ts)
2. Repository in src/repositories/[entity].repository.ts
3. Service in src/services/[entity].service.ts  
4. API routes: GET (list + detail), POST, PATCH, DELETE
5. Zod validation schemas for create and update
6. Integration tests for each endpoint

Follow existing patterns exactly. Every table gets id, created_at, updated_at, deleted_at.
```

### New Page with Data Fetching
```
Create a page at /[route] that:
1. Fetches [data] from our API using [React Query / tRPC]
2. Displays it in a [table/grid/list] using our existing component patterns
3. Handles loading, error, and empty states
4. Includes [pagination/search/filter] (follow existing pattern in [reference page])

Use shadcn/ui components. Follow the component structure in src/components/.
```

## Meta-Prompts (Building the Harness)

### Generate a Custom Linter Rule
```
Write an ESLint rule that enforces our dependency direction:
[Types → Config → Repo → Service → Runtime → UI]

Files in src/repositories/ should NOT import from src/services/.
Files in src/services/ should NOT import from src/components/.

Output as a custom ESLint plugin. Include tests for the rule.
```

### Generate Structural Tests
```
Write architecture tests (in test/architecture.test.ts) that verify:
1. No route handler imports directly from repositories
2. No component file contains database imports
3. All service files export functions, not classes
4. Every API route file follows the validate → auth → logic → respond pattern

These tests should read file contents and use pattern matching.
```

## Anti-Patterns to Avoid

- **"Make it better"** — vague. The agent will change random things.
- **"Fix everything"** — too broad. Pick one thing.
- **"Do whatever you think is best"** — abdicating your role as the architect.
- **Marathon prompts with 10 requirements** — break into separate slices.
- **Prompts without referencing existing patterns** — the agent will invent new ones.

---

## Related
- [[Session Workflow]]
- [[My Claude Code Setup]]
- [[Agent-Friendly Codebases]]

---

#tools #prompts #patterns
