# Signal Scraper Project

> A practice project to build using the Foundation Blueprint. Monitors AI/dev news sources and delivers a daily digest. Uses the full pipeline as training.

---

## Pre-Build Interrogation (Phase 0)

### 1. Core Loop
`Sources publish content → scraper captures and filters → I review a digest`

### 2. Actors
| Actor | Type | Can Read | Can Write | Can Delete |
|-------|------|----------|-----------|------------|
| Me (admin) | End user | Everything | Sources, filters, notes | Anything |
| Scraper agent | Background process | External sources | Raw entries | Nothing |
| Digest generator | Background process | Raw entries, filters | Digests | Nothing |

### 3. Core Entities
1. **Sources** — RSS feeds, API endpoints (Reddit, HN, Twitter)
2. **Entries** — raw captured items (title, url, content snippet, source, timestamp)
3. **Digests** — daily summaries with classified entries (🔴🟡🟢)
4. **Filters** — keyword rules, source weights, classification criteria
5. **Notes** — my annotations on entries (links to Obsidian notes)

### 4. Failure Modes
| Scenario | Severity | Mitigation |
|----------|----------|------------|
| API rate limit hit | Low | Exponential backoff, stagger requests |
| Source goes down | Low | Skip, try next cycle |
| Duplicate entries | Medium | Dedupe by URL hash |
| Scraper misses important news | Medium | Multiple overlapping sources |
| LLM classification wrong | Low | Manual override in digest review |

### 5. Deployment
- Single region, single instance
- Environments: local → production (no staging needed for personal tool)
- Monolith — this is a background job runner with a simple dashboard

---

## Stack (applying the Blueprint)

| Layer | Choice | Why |
|-------|--------|-----|
| Runtime | Bun | Fast, native TS, good for scripts |
| Framework | Next.js (App Router) | Dashboard UI + API routes |
| Database | Postgres (Neon free tier) | Relational, entries + sources + filters |
| ORM | Drizzle | Type-safe, SQL-like |
| Background Jobs | Inngest | Scheduled scraping runs |
| Deployment | Vercel + Inngest Cloud | Serverless, free tier covers this |

## Features (Vertical Slices)

### MVP (practice the foundation)
- [ ] Monorepo scaffold with CLAUDE.md
- [ ] Database schema: sources, entries tables
- [ ] Inngest cron job: fetch RSS feeds every 6 hours
- [ ] Dedupe entries by URL hash
- [ ] Simple dashboard: list entries, newest first
- [ ] Basic keyword filtering (match against watchlist)

### V2 (add intelligence)
- [ ] Reddit API integration (r/vibecoding, r/LocalLLaMA)
- [ ] HN Algolia API integration (trending posts)
- [ ] LLM classification: 🔴 meta shift / 🟡 tool update / 🟢 noise
- [ ] Daily digest email via Resend
- [ ] Mark entries as read/starred/archived

### V3 (connect to Obsidian)
- [ ] Export digest as Obsidian daily note (markdown file)
- [ ] Auto-append to Signal Log in vault
- [ ] One-click "create note from entry" with template

### V4 (X/Twitter — harder)
- [ ] Twitter/X API or scraping (explore options)
- [ ] Follow specific accounts (Karpathy, swyx, Guillermo Rauch, etc.)
- [ ] Filter by engagement threshold

---

## Source Config

```typescript
// packages/db/schema/sources.ts
const sources = [
  // RSS Feeds (easiest)
  { type: 'rss', name: 'Anthropic Blog', url: 'https://www.anthropic.com/feed.xml' },
  { type: 'rss', name: 'OpenAI Blog', url: 'https://openai.com/blog/rss/' },
  { type: 'rss', name: 'Vercel Blog', url: 'https://vercel.com/atom' },
  { type: 'rss', name: 'Martin Fowler', url: 'https://martinfowler.com/feed.atom' },
  
  // Reddit API
  { type: 'reddit', name: 'r/vibecoding', subreddit: 'vibecoding', sort: 'hot', limit: 25 },
  { type: 'reddit', name: 'r/LocalLLaMA', subreddit: 'LocalLLaMA', sort: 'hot', limit: 25 },
  
  // HN Algolia API
  { type: 'hn', name: 'Hacker News', query: 'AI coding agent framework', minPoints: 50 },
];

// Keyword watchlist
const watchlist = [
  'harness', 'agent', 'claude code', 'cursor', 'copilot',
  'framework', 'meta', 'paradigm', 'architecture',
  'bun', 'drizzle', 'turborepo', 'inngest',
  'mcp', 'context engineering', 'prompt engineering',
];
```

---

## Why This Project

1. **Practices the full foundation** — monorepo, DB, background jobs, deployment, the whole blueprint
2. **Immediately useful** — replaces manual signal scanning with an automated pipeline
3. **Small enough to finish** — MVP is a weekend project
4. **Expandable** — each version adds a new Foundation layer (email, LLM integration, file export)
5. **Portfolio piece** — shows you can architect a real system, not just build demos

---

## Related
- [[🗺️ Signals MOC]] — where the output of this project goes
- [[Template — Pre-Build Interrogation]] — Phase 0 applied here
- [[The 15 Universal Layers]] — which layers this project practices
- [[The Full Pipeline]] — this project follows the full pipeline

---

#projects #practice #signal-scraper
