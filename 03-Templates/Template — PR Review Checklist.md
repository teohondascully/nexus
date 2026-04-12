# Template — PR Review Checklist

> What to look for when reviewing agent-generated diffs. The real skill is reviewing, not prompting.

---

## Before Looking at Code
- [ ] Does the PR description explain WHAT changed and WHY?
- [ ] Is this a single vertical slice, or a grab bag of changes?
- [ ] Is the diff under 300 lines? If not, should it be split?

## Architecture
- [ ] Does the dependency direction hold? (no backward imports in the layer chain)
- [ ] Is business logic in services, NOT in route handlers or components?
- [ ] Are DB queries in repositories, NOT scattered through services?
- [ ] Any new files — do they follow the existing naming convention?

## Types & Validation
- [ ] Any `any` types introduced? Any `@ts-ignore`?
- [ ] Are new API inputs validated with Zod at the boundary?
- [ ] Do types derive from the DB schema, or are they manually duplicated?

## Error Handling
- [ ] Are errors handled at the right layer? (not swallowed, not over-caught)
- [ ] Do new endpoints return consistent error format?
- [ ] Are edge cases handled? (null, empty array, missing optional fields)

## Testing
- [ ] Were any existing tests removed or weakened? (🚨 red flag)
- [ ] Does the change include at least one test for the happy path?
- [ ] If this touches the core loop, is there E2E coverage?

## Security
- [ ] Auth check on every new endpoint?
- [ ] No secrets hardcoded?
- [ ] No user input passed unsanitized to DB queries or HTML?
- [ ] File uploads validated (type, size)?

## Agent-Specific Red Flags
- [ ] Hallucinated imports (packages that don't exist in package.json)?
- [ ] Over-abstracted code (unnecessary classes, patterns for simple operations)?
- [ ] Copy-paste patterns that should be a shared utility?
- [ ] Comments that describe WHAT code does (useless) vs. WHY (useful)?
- [ ] TODO comments the agent left behind?

---

#templates #review #checklist
