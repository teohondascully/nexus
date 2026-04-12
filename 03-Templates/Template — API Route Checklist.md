# Template — API Route Checklist

> Every endpoint follows this exact order. See [[API Design Patterns]].

---

## The Four Steps (in order)

### 1. Validate Input
```typescript
const input = CreateOrderSchema.parse(req.body);
// If parse fails → 400 with Zod error details
// If parse passes → input is typed and safe
```
- Use Zod schemas for all input
- Validate path params, query params, and body separately
- Return field-level errors to the client

### 2. Check Auth
```typescript
if (!req.user) throw new UnauthorizedError();
if (!can(req.user, 'create', 'order')) throw new ForbiddenError();
```
- Auth middleware should already have attached `req.user`
- Use the centralized `can()` function from [[Auth Build vs Buy]]
- 401 for "who are you?" — 403 for "you can't do this"

### 3. Business Logic (delegate to service)
```typescript
const order = await orderService.create(req.user, input);
```
- Route handler does NOT contain business logic
- Service function is testable without HTTP
- Service handles: validation of business rules, DB operations, side effects (email, webhooks)

### 4. Response Serialization
```typescript
return Response.json({ data: order }, { status: 201 });
```
- Consistent response wrapper: `{ data, error, metadata }`
- Correct HTTP status codes (201 for create, 200 for read, 204 for delete)
- Don't leak internal fields (password hashes, internal IDs)

## Quick Reference

```typescript
// Complete example
export async function POST(req: Request) {
  try {
    // 1. Validate
    const body = await req.json();
    const input = CreateOrderSchema.parse(body);

    // 2. Auth
    const user = await getAuthUser(req);
    if (!can(user, 'create', 'order')) throw new ForbiddenError();

    // 3. Logic
    const order = await orderService.create(user, input);

    // 4. Respond
    return Response.json({ data: order }, { status: 201 });
  } catch (error) {
    return handleApiError(error); // centralized error handler
  }
}
```

## Endpoint Documentation Template

For each endpoint, document in comments or CLAUDE.md:

```
POST /api/orders
  Auth: member+
  Input: { productId: uuid, quantity: int, notes?: string }
  Returns: { data: Order }
  Errors: 400 (validation), 401, 403, 404 (product not found)
```

---

#templates #api #checklist
