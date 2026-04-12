# Auth Build vs Buy

> Layer 3 of [[The 15 Universal Layers]]. Buy the identity layer. Build the authorization logic.

---

## The Two Halves

### Authentication (Identity) — BUY THIS
"Who are you?"

Signup, login, OAuth, MFA, session management, JWTs, password reset, email verification, rate-limiting login attempts, bot detection.

**Why buy:** This is security-critical, commodity infrastructure. Every hour you spend building auth is an hour not spent on your product. And you will get it wrong — the edge cases (token rotation, session invalidation, OAuth state management) are endless.

| Provider | Strengths | Tradeoffs |
|----------|-----------|-----------|
| **Clerk** | Best DX, pre-built components, webhooks | Vendor lock-in, pricing at scale |
| **Auth.js (NextAuth)** | Open source, self-hosted, flexible | More setup, you manage sessions |
| **Supabase Auth** | Bundled with Supabase DB, generous free tier | Tied to Supabase ecosystem |
| **Firebase Auth** | Google ecosystem, good mobile support | Google ecosystem lock-in |

**My default:** Clerk for speed, Auth.js if I want full control or need to self-host.

### Authorization (Permissions) — BUILD THIS
"What are you allowed to do?"

This encodes your business logic. No third-party service knows your permission model.

## The Permission Pattern That Scales

### Role-Based Access Control (RBAC)

```
User → belongs to → Organization → has role → (owner | admin | member | viewer)
Resource → belongs to → Organization
```

### The `can()` Function

Centralize ALL permission checks into one function:

```typescript
// packages/auth/permissions.ts
type Action = 'read' | 'create' | 'update' | 'delete' | 'manage';
type Resource = 'order' | 'user' | 'settings' | 'billing';

export function can(
  user: { role: Role; orgId: string },
  action: Action,
  resource: Resource,
  resourceOrgId?: string
): boolean {
  // Must be in the same org
  if (resourceOrgId && user.orgId !== resourceOrgId) return false;
  
  const permissions: Record<Role, Partial<Record<Resource, Action[]>>> = {
    owner:  { order: ['read','create','update','delete','manage'], user: ['read','create','update','delete','manage'], settings: ['read','update','manage'], billing: ['read','update','manage'] },
    admin:  { order: ['read','create','update','delete'], user: ['read','create','update'], settings: ['read','update'], billing: ['read'] },
    member: { order: ['read','create','update'], user: ['read'], settings: ['read'], billing: [] },
    viewer: { order: ['read'], user: ['read'], settings: ['read'], billing: [] },
  };
  
  return permissions[user.role]?.[resource]?.includes(action) ?? false;
}
```

### Use It Everywhere

```typescript
// In a service function
export async function deleteOrder(user: AuthUser, orderId: string) {
  const order = await orderRepo.findById(orderId);
  if (!order) throw new NotFoundError('Order');
  if (!can(user, 'delete', 'order', order.orgId)) throw new ForbiddenError();
  return orderRepo.softDelete(orderId);
}
```

**Never** scatter `if (user.role === 'admin')` checks across your codebase. That's unmaintainable and unauditable.

## Auth Middleware Pattern

```typescript
// middleware.ts — runs on every request
export async function authMiddleware(req: Request) {
  const session = await getSession(req); // from Clerk/Auth.js/etc
  if (!session) return unauthorized();
  
  // Attach user to request context
  req.user = {
    id: session.userId,
    role: session.role,
    orgId: session.orgId,
  };
}
```

## Checklist

- [ ] Auth middleware runs on every request, no exceptions
- [ ] `can()` function is the single source of truth for permissions
- [ ] Roles stored in database, not hardcoded
- [ ] Every API endpoint documents its required permission
- [ ] Session invalidation works (force-logout capability)
- [ ] OAuth state parameter validated (CSRF protection)
- [ ] Rate limiting on login/signup endpoints
- [ ] Password reset tokens expire

---

## Related
- [[The 15 Universal Layers#Layer 3 Authentication Authorization]]
- [[Template — API Route Checklist]] — auth check is step 2

---

#foundations #stack-decisions #auth
