# Verification Hierarchy

> Agents take the path of least resistance. The verification standard you set is the verification standard you get.

---

## The Hierarchy

Each level catches a different class of bug. Higher levels catch more but cost more to run.

```
Level 5: Browser E2E        — "Does it actually work for a real user?"
Level 4: Integration tests  — "Do the pieces work together correctly?"
Level 3: Schema validation  — "Is the data shaped correctly at boundaries?"
Level 2: Linting            — "Does it follow conventions and architecture?"
Level 1: Type checking       — "Are the types consistent?"
Level 0: Syntax             — "Does it parse?"
```

## What Each Level Catches

| Level | Tool | Catches | Misses |
|-------|------|---------|--------|
| Types | TypeScript strict | Wrong arguments, missing fields, null errors | Logic bugs, race conditions |
| Lint | ESLint + custom rules | Convention violations, dependency direction | Behavioral correctness |
| Schema | Zod at boundaries | Malformed data, missing fields, wrong types | Business logic errors |
| Integration | Vitest + test DB | Service logic, query errors, edge cases | UI bugs, visual regressions |
| E2E | Playwright + browser | User-facing bugs, flow breakage, visual issues | Performance, security |

## The Agent Verification Problem

Anthropic's research found that Claude would mark features as "complete" without verifying they worked — unless the harness explicitly required browser-based E2E testing.

Once browser automation tools were added, the agent identified and fixed bugs that weren't visible from the code alone.

**Key insight:** If you only require unit tests, agents will write passing unit tests for buggy code. If you require E2E verification, agents actually open a browser and check.

### The Test-Weakening Anti-Pattern
Without explicit instructions, agents will **modify tests to match buggy implementations** rather than fix the code.

**Mitigation:** Add to your [[Template — CLAUDE.md|CLAUDE.md]]:
```
NEVER remove or weaken existing tests.
If a test fails, fix the implementation, not the test.
```

## Practical Setup for Solo Founder

### Minimum Viable Verification (run on every agent change)
```bash
pnpm typecheck     # Level 1 — 5 seconds
pnpm lint          # Level 2 — 5 seconds
pnpm test --bail   # Level 3+4 — under 30 seconds
```

### Full Verification (run before merge / deploy)
```bash
pnpm typecheck
pnpm lint
pnpm test
pnpm test:e2e      # Level 5 — Playwright on core loop
```

### What Gets E2E Coverage
Only the core loop. Don't E2E test settings pages or admin panels. Test:
- Signup → first core action → success state
- The main happy path users repeat daily
- Payment flow (if applicable)

Everything else gets integration tests at most.

---

## Related
- [[Harness Engineering Overview#Verification the missing piece]]
- [[Deterministic Enforcement]]
- [[The 15 Universal Layers#Layer 8 Testing Strategy]]
- [[Template — CLAUDE.md]] — test rules section

---

#harness-engineering #testing #verification
