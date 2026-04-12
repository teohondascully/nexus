# API Design Patterns

> Layer 4 of [[The 15 Universal Layers]]. How your frontend talks to your backend.

---

## The Decision Tree

```
Building full-stack TypeScript (solo/small team)?
├── Yes → tRPC (end-to-end type safety, zero codegen)
│   └── Need public API later? → Add REST endpoints alongside
└── No, or need public API from day 1?
    └── REST + OpenAPI spec → Generate client SDKs from spec
```

GraphQL is powerful but adds complexity (schema stitching, N+1 queries, caching) that solo founders rarely need. Consider it when you have many different clients consuming the same API with very different data needs.

## Comparison

| | tRPC | REST + OpenAPI | GraphQL |
|---|------|---------------|---------|
| **Type safety** | Automatic, end-to-end | Via codegen from spec | Via codegen from schema |
| **Learning curve** | Low (if you know TS) | Low | Medium-high |
| **Public API** | Not designed for it | Yes | Yes |
| **Caching** | Manual | HTTP caching works natively | Complex (Apollo, Relay) |
| **Best for** | Full-stack TS apps | Public APIs, multi-language | Complex data graphs, mobile |

## Non-Negotiables (Any Choice)

### Consistent Error Format
```typescript
type ApiError = {
  code: string;        // machine-readable: 'NOT_FOUND', 'VALIDATION_ERROR', 'FORBIDDEN'
  message: string;     // human-readable: "Order not found"
  details?: unknown;   // optional: validation errors, field-level info
};
```

### Cursor-Based Pagination
Offset pagination breaks with concurrent writes. Use cursors:
```typescript
type PaginatedResponse<T> = {
  data: T[];
  nextCursor: string | null;
  hasMore: boolean;
};
```

### Rate Limiting from Day 1
Even internal APIs. Prevents accidental DDoS from your own frontend bugs.

### Input Validation at the Boundary
Zod schemas validate before business logic runs:
```typescript
const CreateOrderSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive().max(100),
  notes: z.string().max(500).optional(),
});
```

### Versioning Strategy
Decide before v1: URL-based (`/api/v1/orders`), header-based, or content negotiation. Pick one and document it.

## The Route Handler Pattern

Every endpoint follows this exact order:

```typescript
// 1. Validate input
const input = CreateOrderSchema.parse(req.body);

// 2. Check auth
if (!can(req.user, 'create', 'order')) throw new ForbiddenError();

// 3. Business logic (delegated to service)
const order = await orderService.create(req.user, input);

// 4. Response serialization
return Response.json({ data: order });
```

Route handlers are THIN. All logic lives in services. Services are testable without HTTP. See [[Template — API Route Checklist]].

---

## Related
- [[The 15 Universal Layers#Layer 4 API Design]]
- [[Auth Build vs Buy]] — the auth check step
- [[Template — API Route Checklist]]

---

#foundations #stack-decisions #api
