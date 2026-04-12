## Summary

<!-- What does this PR do? Why? -->

-

## Architecture

- [ ] Dependency direction is respected (`Types → Config → Repo → Service → Runtime → UI`)
- [ ] Business logic lives in services, not route handlers
- [ ] Naming is consistent with the rest of the codebase

## Types & Validation

- [ ] No `any`, `@ts-ignore`, or `eslint-disable` without a comment
- [ ] Zod (or equivalent) validates all external input at the boundary
- [ ] Types are derived from the DB schema, not hand-written duplicates

## Testing

- [ ] No existing tests have been removed or weakened
- [ ] Happy path is covered
- [ ] E2E test added or updated for any core user flow touched

## Security

- [ ] All new endpoints have authentication/authorization checks
- [ ] No secrets or credentials are present in the diff
- [ ] No unsanitized user input reaches the database or shell

## Agent Red Flags

<!-- Check these if an AI agent contributed to this PR -->

- [ ] No hallucinated imports or packages
- [ ] No over-abstraction introduced for a single use case
- [ ] No unresolved `TODO` or `FIXME` left in shipped code
