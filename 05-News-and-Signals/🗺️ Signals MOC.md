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
- **2026-04-11 (weekly audit)** — 🔴 **Claude Code 1M context GA.** Opus 4.6 and Sonnet 4.6 both support 1M tokens with no surcharge. This is a meta shift — context window is no longer the bottleneck for large codebases. Changes how you structure agent sessions.
- **2026-04-11 (weekly audit)** — 🔴 **Autonomous agent features converging.** Claude Code /loop (scheduled tasks on cloud), Copilot coding agent (issue→PR), Cursor 3.0 background agents — all three major tools now offer some form of "work while you sleep." Agent supervision becoming the core engineering skill.
- **2026-04-11 (weekly audit)** — 🔴 **Anthropic three-agent harness architecture.** Published research on separating planning, generation, and evaluation agents for long-running development. This aligns with and extends the builder-validator pattern already in [[Beyond the Basics]].
- **2026-04-11 (weekly audit)** — 🟡 **Cursor 3.0 shipped** (April 2). Background Agents, Cloud Agents, Composer 2.0, BugBot with learned rules, Design Mode, JetBrains integration. Major feature parity push against Claude Code.
- **2026-04-11 (weekly audit)** — 🟡 **GitHub Copilot agent mode GA.** Agent mode in VS Code + JetBrains, coding agent turns issues into PRs, .agent.md custom agents, agentic code review. Copilot is no longer just autocomplete.
- **2026-04-11 (weekly audit)** — 🟡 **Google Antigravity launched.** Agent-first IDE (VS Code fork) with Manager view for parallel agent orchestration. 6% developer adoption in 2 months. Multi-model (Gemini, Claude, OpenAI). Not yet reliable enough as only tool but architecturally interesting.
- **2026-04-11 (weekly audit)** — 🟡 **Windsurf acquired by Cognition (Devin).** ~$250M after failed OpenAI/Google bids. Plans to merge Devin + Windsurf IDE. Devin now $20/mo entry.
- **2026-04-11 (weekly audit)** — 🟡 **Zod 4 stable.** 14x faster parsing, 57% smaller core, @zod/mini for frontend. No breaking API changes for common patterns.
- **2026-04-11 (weekly audit)** — 🟡 **Next.js 16.2 LTS.** 400% faster dev startup, 50% faster rendering, Turbopack improvements.
- **2026-04-11 (weekly audit)** — 🟡 **Node.js release schedule changing (Oct 2026).** Every release becomes LTS. No more even/odd distinction. Node 24 is current LTS alongside Node 22.
- **2026-04-11 (weekly audit)** — 🟡 **Ghostty 1.3.** Scrollback search, native scrollbars, click-to-move-cursor, Unicode 17. Now in Ubuntu 26.04 repos.
- **2026-04-11 (weekly audit)** — 🟡 **Tailwind v4 + shadcn/ui.** CSS-first config (no more tailwind.config.js), OKLCH colors, all components updated for React 19.
- **2026-04-11 (weekly audit)** — 🟡 **Dia browser broadly available.** Atlassian acquired Browser Company ($610M). Free tier + Pro at $20/mo. AI assistant with Slack/Notion/Google integration.
- **2026-04-11 (weekly audit)** — 🟢 **Vercel pricing shifted.** Credit-based billing, Turbo machines default for Pro, add-ons (SAML, HIPAA) moved to Pro tier. $20/mo base + usage.
- **2026-04-11 (weekly audit)** — 🟢 **MIT Technology Review named generative coding a 2026 Breakthrough Technology.** Industry validation of the shift.
- **2026-04-11 (weekly audit)** — 🟢 **PlanetScale is NOT shut down.** Hobby tier deprecated but paid tiers operational with 99.88-99.99% uptime. AI models were falsely claiming it was dead.

---

#signals #meta #news
