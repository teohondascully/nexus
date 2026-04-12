# 📡 Signals MOC

> Raw signal → processed insight → action item. If it doesn't change how I build, it's noise.

---

## Signal Processing Workflow

```
1. CAPTURE — screenshot, link, or note in 00-Inbox/
2. CLASSIFY — is this a:
   - 🔴 Meta shift (changes HOW I build — e.g., harness engineering)
   - 🟡 Tool update (new version, new tool, deprecation)
   - 🟢 Interesting but not actionable (cool demo, research paper)
3. PROCESS
   - 🔴 → Write a Foundations note, update Templates if needed
   - 🟡 → Update Tools MOC table, test it, write impressions
   - 🟢 → Tag and file, or delete
4. ACT — what changes in my next project?
```

---

## Sources to Monitor

| Source | What to Watch For | Frequency |
|--------|------------------|-----------|
| r/vibecoding | Community meta, tool comparisons, workflow tips | Daily |
| Hacker News | Framework launches, deep technical posts, industry shifts | Daily |
| X/Twitter | Real-time takes from builders (Karpathy, swyx, Guillermo Rauch, etc.) | Daily |
| Anthropic Blog | Claude updates, agent research, harness patterns | Weekly |
| OpenAI Blog | Model releases, Codex updates, harness engineering | Weekly |
| Vercel Blog | Next.js, deployment, frontend meta | Weekly |
| ThePrimeagen / Fireship | Entertaining signal on what's gaining traction | Weekly |
| LinkedIn | Longer-form takes, company announcements | Low priority |

## Future: Automated Signal Pipeline
> Build a scraper/agent that monitors these sources and surfaces relevant updates.
> See [[04-Projects/Signal Scraper Project|Signal Scraper Project]] for the build plan.

**MVP approach:**
- RSS feeds for blogs (Anthropic, OpenAI, Vercel, Martin Fowler)
- Reddit API for r/vibecoding, r/LocalLLaMA, r/ChatGPT
- HN Algolia API for trending posts
- Filter by keywords: harness, agent, framework, Claude, coding tool, meta
- Daily digest → Obsidian daily note or email

**Don't over-build this.** The value is in the processing, not the capture. A simple RSS reader + 15 minutes/day beats a complex scraper you never check.

---

## Signal Log

### April 2026
- **2026-04-11** — [[Harness Engineering Overview|Harness Engineering]] is the current meta. Blog by John Davenport (CodeMySpec) synthesizing OpenAI Codex + Anthropic research. Key: "Not documented. Enforced." Three evolutions: prompt eng → context eng → harness eng.
- **2026-04-11** — r/vibecoding top post: "stop reinventing the wheel" — 15 tool recommendations for common layers. Good tools list but misses the *decision tree* behind tool selection. Captured in [[The 15 Universal Layers]].

---

#signals #meta #news
