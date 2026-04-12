# Deterministic Enforcement

> Models are probabilistic. Rules are deterministic. Use deterministic constraints to bound probabilistic output.

---

## The Principle

A README says "please follow the architecture." A linter **rejects** code that violates it. The difference is enforcement.

"Not documented. Enforced." — OpenAI Codex team

## The Enforcement Toolkit

### 1. Custom Linters
Enforce architectural rules the agent can't ignore:

**Dependency direction** — code can only import "forward":
```
Types → Config → Repo → Service → Runtime → UI
```
Use `eslint-plugin-boundaries` or write a custom ESLint rule that flags reverse imports.

**No business logic in routes** — lint for route files that import from DB or contain complex conditionals.

**No raw SQL** — if you're using an ORM, lint for direct `pg` or `sql` calls outside the repository layer.

### 2. Structural Tests
Tests that validate architecture, not behavior:

```typescript
// test/architecture.test.ts
import { readdirSync } from 'fs';

test('route handlers do not import from repositories directly', () => {
  const routeFiles = getFilesInDir('src/app/api');
  for (const file of routeFiles) {
    const content = readFileSync(file, 'utf-8');
    expect(content).not.toMatch(/from ['"].*\/repositories/);
  }
});

test('services do not import from UI components', () => {
  const serviceFiles = getFilesInDir('src/services');
  for (const file of serviceFiles) {
    const content = readFileSync(file, 'utf-8');
    expect(content).not.toMatch(/from ['"].*\/components/);
  }
});
```

### 3. CI Gates
PRs that violate rules literally cannot merge:

```yaml
# .github/workflows/ci.yml
- name: Type check
  run: pnpm typecheck
- name: Lint (includes architectural rules)
  run: pnpm lint
- name: Structural tests
  run: pnpm test:architecture
- name: Unit + Integration tests
  run: pnpm test
```

### 4. Pre-commit Hooks
Catch violations before they even reach CI:

```bash
# .husky/pre-commit
pnpm lint-staged
```

```json
// package.json
"lint-staged": {
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md}": ["prettier --write"]
}
```

### 5. Claude Code Hooks
The agent-specific enforcement layer:

```jsonc
{
  "afterToolUse": [
    "pnpm typecheck",
    "pnpm lint --quiet",
    "pnpm test --bail"
  ]
}
```

Every time the agent writes code, these run automatically. The agent gets immediate feedback and self-corrects.

## The Meta-Move

Use the agent to build the harness that constrains the agent. This is recursive and powerful:

1. Ask Claude Code to write a custom ESLint rule enforcing your dependency direction
2. Ask it to write structural tests validating your architecture
3. Ask it to set up the CI pipeline that gates on all of the above
4. Now the agent operates inside the constraints it built

## What Gets Enforced

| Rule | Tool | Layer |
|------|------|-------|
| Type safety | TypeScript strict | Compile time |
| Dependency direction | eslint-plugin-boundaries | Lint time |
| No magic strings | Custom ESLint rule | Lint time |
| Schema validation | Zod | Runtime boundary |
| Architectural layers | Structural tests | Test time |
| All of the above | CI pipeline | Merge time |

---

## Related
- [[Harness Engineering Overview]] — the philosophy
- [[The Fractal Harness Stack]] — where enforcement sits in the stack
- [[Verification Hierarchy]] — enforcement of correctness specifically
- [[Monorepo Patterns#Dependency Direction Rule]]

---

#harness-engineering #enforcement #foundations
