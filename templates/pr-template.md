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
