# State Management Patterns

> Where does state live? Get this wrong and you'll fight the framework forever.

---

## The Four Buckets

Every piece of state in your app belongs to exactly one bucket:

### 1. Server State (the source of truth)
Data that lives in your database and is fetched/mutated via API.

**Tool:** TanStack Query (React Query) — handles caching, revalidation, optimistic updates, loading/error states.

**Rule:** Never duplicate server state in local state. Fetch it, cache it with React Query, let it revalidate.

```typescript
// Good — server state managed by React Query
const { data: orders } = useQuery({ queryKey: ['orders'], queryFn: fetchOrders });

// Bad — copying server data into useState
const [orders, setOrders] = useState([]);
useEffect(() => { fetchOrders().then(setOrders); }, []);
```

### 2. Client State (UI-only)
State that only exists in the browser: modals open/closed, sidebar expanded, selected tab, form input before submission.

**Tool:** React `useState` / `useReducer`. No library needed for most cases.

**Rule:** If it resets on page refresh and that's fine, it's client state.

### 3. URL State (shareable, navigational)
Filters, search queries, pagination cursor, selected tab — anything the user should be able to bookmark or share.

**Tool:** URL search params via `nuqs` or `useSearchParams`.

**Rule:** If a user sends the URL to someone else, should that person see the same view? If yes, it belongs in the URL.

```typescript
// Filters belong in URL, not useState
const [search, setSearch] = useQueryState('q');
const [status, setStatus] = useQueryState('status');
```

### 4. Persistent Client State (survives refresh)
Theme preference, onboarding completion, dismissed banners.

**Tool:** `localStorage` wrapped in a hook, or a cookie.

**Rule:** Non-sensitive, user-preference data only. Never auth tokens in localStorage.

## The Decision

```
Does this data come from the server? → Server State (React Query)
Should it survive navigation / be shareable? → URL State (search params)
Should it survive page refresh? → Persistent Client State (localStorage)
Everything else → Client State (useState)
```

## Common Mistakes

1. **Storing server data in useState** — you lose caching, revalidation, loading states. Use React Query.
2. **Storing filters in useState** — URL state is lost on refresh, can't be shared. Use URL params.
3. **Global state for everything** — Zustand/Redux for client state is fine, but most apps need less global state than they think.
4. **Prop drilling fear** — 2-3 levels of prop passing is fine. Only reach for context/global state when it's genuinely painful.

---

## Related
- [[The 15 Universal Layers#Layer 4 API Design]]
- [[Types Flow Downstream]]

---

#foundations #stack-decisions #state-management
