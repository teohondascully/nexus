# Template — Feature Slice Breakdown

> Break every feature into the smallest possible vertical slice. Each slice is testable independently.

---

## The Principle

Instead of "build auth," break it into:
1. Create the login form (UI only, hardcoded submit)
2. Add email/password validation (Zod schema)
3. Wire up auth provider (Clerk/Auth.js)
4. Add session handling (middleware)
5. Add protected routes
6. Add logout flow
7. Add password reset flow

Each of these is a single PR. Each is testable. Each can be reviewed in 5 minutes.

## The Decomposition Template

For any feature, answer:

```markdown
## Feature: [Name]

### What's the user story?
As a [role], I want to [action], so that [outcome].

### What are the vertical slices?

Slice 1: [Thinnest possible end-to-end path]
- DB: [schema changes?]
- API: [endpoints?]
- UI: [components?]
- Test: [how to verify?]

Slice 2: [Next layer of functionality]
...

### What's the order?
Build data layer → API → UI. Each slice builds on the previous.

### What can be deferred?
- Nice-to-have features pushed to a later slice
- Edge cases handled after happy path works
- Polish and animations after functionality
```

## Example: "Add Order Management"

```
Slice 1: Display orders list
  DB: orders table + migration + seed data
  API: GET /api/orders (list, paginated)
  UI: OrdersPage with OrderCard component
  Test: Integration test for list endpoint

Slice 2: Create order
  DB: (already exists)
  API: POST /api/orders
  UI: CreateOrderForm with Zod validation
  Test: Integration test for create endpoint

Slice 3: Order details
  API: GET /api/orders/:id
  UI: OrderDetailPage
  Test: Integration test for get endpoint

Slice 4: Update order status
  API: PATCH /api/orders/:id/status
  UI: Status dropdown on OrderDetailPage
  Test: Integration test + auth check (only admin+)

Slice 5: Delete order (soft delete)
  API: DELETE /api/orders/:id
  UI: Delete button with confirmation modal
  Test: Integration test + verify soft delete

Slice 6: Order search/filter
  API: Query params on GET /api/orders
  UI: Search bar + filter dropdowns
  Test: Integration test with filters
```

## Rules
- If a slice takes more than 2 hours, it's too big — split further
- Every slice must be deployable (even if behind a feature flag)
- Each slice gets its own commit or small PR
- Slice 1 is always the thinnest end-to-end path (read-only is fine)

---

#templates #workflow #slicing
