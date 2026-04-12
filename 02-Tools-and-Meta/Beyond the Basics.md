# Beyond the Basics — The IFYKYK Layer

> Tools, strategies, and decisions that most guides skip. Last audited: 2026-04-11.

---

## Browser

### Arc is Dead — Dia is Atlassian's Now
Arc browser was discontinued in May 2025. The Browser Company pivoted to **Dia**, an AI-first browser. In October 2025, **Atlassian acquired The Browser Company for $610M**. Dia is now broadly available on macOS with a free tier and Dia Pro at $20/mo. It integrates with Slack, Notion, Google Calendar, Gmail, and other services via its AI assistant.

If you're already using Arc, it still works but receives no updates and will fall behind.

**What to use instead:**
- **Zen Browser** — open-source, Firefox-based, closest to Arc's interface. Still in active beta (v1.19.8b as of April 2026), praised for fast iteration and responsive team. The community pick for Arc refugees.
- **Dia** — if you want AI-first browsing and don't mind paying $20/mo for Pro. Good Atlassian ecosystem integration.
- **Brave** — privacy-focused, Chromium-based, actively developed. Good if you don't need Arc's Spaces.
- **Chrome** — boring but universal. Extension ecosystem is unmatched. Sometimes boring is the right answer.

**Dev-specific browser setup (regardless of pick):**
- Separate profiles or spaces for: personal / work / client projects
- Extensions: uBlock Origin, React DevTools, JSON Formatter, Vimium (keyboard navigation)
- Bookmark bar: localhost:3000, Vercel dashboard, GitHub, Sentry, PostHog

---

## AI Coding Tool Deep Dive

### Claude Code — The Current Best for Solo Founders
**Plan recommendation:** Start with **Pro ($20/mo)**. Upgrade to **Max 5x ($100/mo)** when you're hitting limits during focused coding sessions. Max 20x ($200/mo) only if Claude Code is your full-time pair programmer.

Key insight: Claude Code and Claude chat share the same usage pool. Heavy Claude Code usage eats into your chat budget. Max plans multiply the entire pool.

One developer tracked 10 billion tokens over 8 months — API cost would have been $15,000+, but Max 5x at $100/mo totaled ~$800. The subscription is dramatically cheaper for heavy users because 90%+ of tokens are cache reads (re-reading your codebase), which are included in the flat rate.

**Model choice in Claude Code:**
- **Sonnet 4.6** — handles 80% of coding tasks. Fast, cheap.
- **Opus 4.6** — for complex multi-file refactors, architecture decisions, tricky debugging. Use selectively.
- Both models now support **1M token context window** (GA, no surcharge). Max/Team/Enterprise get 1M by default on Opus.
- Use Sonnet by default, switch to Opus when you need deeper reasoning.

**Major new features (March-April 2026):**
- **Computer Use** — Claude can point, click, and navigate your screen (Pro and Max)
- **Scheduled Tasks (/loop)** — run recurring jobs on Anthropic cloud, even when laptop is off
- **Remote Control** — send instructions from your phone via Claude App
- **Auto Mode** — smart auto-approval for safe actions, blocks risky ones
- **Agent Teams** — multi-threaded orchestrated work across sub-agents
- **Voice** — push-to-talk via spacebar, 20 languages

### Amp Code (Sourcegraph)
**What it is:** Rebranded from Cody to Amp. CLI and VS Code-based AI coding agent built on Sourcegraph's code search engine.

**Status (April 2026):** Amp discontinued its VS Code editor extension in February 2026 to focus on CLI and deep mode. Public free/Pro self-serve plans were also discontinued — now enterprise-oriented (contact sales). They stated they "need to grow more slowly so they can sprint on the frontier."

**Advantages over Claude Code:**
- Deep Mode with oracle capabilities for extended autonomous sessions
- GPT-5.4 integration alongside Claude models
- Strong at understanding large, complex codebases via Sourcegraph's search

**Disadvantages:**
- No longer has a self-serve plan — enterprise sales only
- Killed the editor extension, limiting accessibility
- Smaller ecosystem — Claude Code has more community tooling, skills, hooks

**When to consider:** Enterprise teams with very large codebases where Sourcegraph's code intelligence is already in use. Less relevant for solo founders now.

### Aider
**What it is:** Open-source, terminal-first AI coding tool. BYOM (bring your own model) — works with Claude, GPT, local models.

**Advantages:**
- Free (you pay for model API only)
- Git-aware — commits changes with sensible messages automatically
- Works with any model (including local via Ollama)
- Good for privacy-sensitive work

**When to consider:** When you want to use local models, when cost is a major constraint, or when you want full control over which model handles which task.

### Cline
**What it is:** Open-source VS Code agent (formerly Claude Dev). BYOM. 5M+ installs. Now also on JetBrains, Zed, Neovim, and CLI.

**Advantages:**
- Transparency — Plan mode (analyze) and Act mode (execute with approval at each step)
- Visual diffs in the editor
- MCP support, browser automation
- Free (you pay only API costs, typically $3-15/mo)

**When to consider:** If you want agent capabilities inside VS Code without paying for Cursor, and you value explicit control over actions.

### Windsurf (Cognition/ex-Codeium)
**What it is:** Agentic AI code editor. Acquired by Cognition AI (Devin's maker) for ~$250M in December 2025 after a complex saga involving failed OpenAI and Google bids. $82M ARR at acquisition.

**Key features:**
- SWE-1.5 proprietary model (13x faster than Sonnet 4.5, approaching Claude-level performance)
- Arena Mode — compare models side-by-side in the IDE
- Parallel agents, browser integration, voice commands
- $20/mo (quota-based billing since March 2026)

**When to consider:** If you want an IDE-first experience similar to Cursor with strong autonomous agent features. Watch for Devin integration.

### Devin (Cognition)
**What it is:** Autonomous AI coding agent. Slashed pricing from $500-only to **$20/mo Core plan** in January 2026.

**Pricing:**
- Core: $20/mo + $2.25/ACU (1 ACU ≈ 15 min of active work)
- Team: $500/mo with 250 ACUs included ($2.00/ACU after)

**When to consider:** For tasks you want to fully delegate — Devin works asynchronously, turns issues into PRs. Good for maintenance tasks, bug fixes, and well-defined features. Now actually affordable for solo founders at $20/mo entry.

### Google Antigravity (NEW)
**What it is:** Google's agent-first IDE, announced November 2025 alongside Gemini 3. A heavily modified VS Code fork with a unique "Manager view" for orchestrating parallel agents.

**Key features:**
- Editor view (standard IDE + agent sidebar) and Manager view (multi-agent control center)
- Multi-model support (Gemini 3.1 Pro, Claude Opus/Sonnet 4.6, GPT-OSS-120B)
- 6% developer adoption within 2 months of launch — fast-growing

**When to consider:** Worth watching but not yet reliable enough to be your only tool. The Manager view for parallel agent orchestration is the most interesting differentiator.

---

## Multi-Agent Strategies

### The Builder-Validator Pattern
Your instinct about "one Claude instance validating another" is exactly right. This is called the **builder-validator pattern** and it's the highest-ROI multi-agent strategy for solo founders.

**How it works:**
1. **Builder agent** writes the code (Claude Code in normal mode)
2. **Validator agent** reviews the output (a sub-agent or separate Claude Code instance with a review-focused prompt)

In practice with Claude Code:
```bash
# Builder session: write the feature
claude "Read CLAUDE.md. Implement the order creation endpoint following the pattern in users.route.ts"

# Validator session: review the output
claude "Read CLAUDE.md. Review the changes in the last 3 commits. Check for: 
- Dependency direction violations
- Missing input validation
- Authorization gaps
- Test coverage
Do NOT make changes. Only report issues."
```

### Claude Code's Built-In Multi-Agent Features

**Subagents:** Claude Code can spawn specialized sub-agents with separate context windows. The main agent delegates focused tasks (research, testing, review) and gets results back. Named subagents now appear in @ mention typeahead.

**Agent Teams:** Shipped in February 2026 — multi-threaded orchestrated work across sub-agents. More mature than the earlier experimental swarms. Code Kit v5.0 supports this.

**Scheduled Tasks (/loop):** Claude Code can now run recurring jobs on Anthropic cloud infrastructure even when your computer is off. Attach repos, set a schedule, add connectors — fully autonomous background work.

**Code Review (Teams/Enterprise):** Anthropic's built-in multi-agent code review. Runs automatically on PRs, dispatches parallel review agents.

### Practical Multi-Agent Rules

1. **Start with one agent, add specialists when you hit pain points** — Code Reviewer or Debugger first
2. **Max 3-4 specialized agents** — more than that and you spend more time orchestrating than building
3. **Use builder-validator for implementation, single agent for exploration**
4. **Don't over-invest in orchestration** — a well-configured single Claude Code instance with good CLAUDE.md and hooks beats a poorly configured multi-agent setup

---

## Niche Dev Tools Worth Knowing

### Terminal Multiplexing
**tmux** — split your terminal into panes. One pane for Claude Code, one for your dev server, one for lazygit. Sessions persist if you disconnect.

```bash
brew install tmux
# Ctrl+B then % = vertical split
# Ctrl+B then " = horizontal split
# Ctrl+B then D = detach (session keeps running)
# tmux attach = reattach
```

**Alternative:** Ghostty has native splits. If you use Ghostty, you may not need tmux.

### Yazi — Terminal File Manager
When you need to browse, preview, and manage files without leaving the terminal. Has image preview, bulk rename, and plugin support.

```bash
brew install yazi
```

### just — Command Runner
A modern replacement for Makefiles. Simpler syntax, better error messages.

```
# justfile
dev:
    docker compose up -d
    pnpm dev

test:
    pnpm typecheck && pnpm lint && pnpm test

deploy:
    pnpm build && vercel --prod

db-reset:
    docker compose down -v
    docker compose up -d
    pnpm db:migrate
    pnpm db:seed
```

Run with: `just dev`, `just test`, `just deploy`

### direnv (if not using mise for env vars)
Auto-loads `.envrc` when you enter a directory. If you're using mise with `[env]` blocks, you don't need this.

### gh — GitHub CLI
Official GitHub CLI. Create PRs, check CI, manage issues without leaving terminal.

```bash
brew install gh
gh pr create --fill   # create PR from current branch
gh pr view --web      # open PR in browser
gh run list           # check CI status
```

### Raycast (macOS)
Spotlight replacement with superpowers. Clipboard history, window management, snippets, quick calculations. Free tier is generous.

Replace: Spotlight + Rectangle + clipboard managers

---

## What NOT to Use (Overhyped / Outdated)

| Tool | Why Not | Use Instead |
|------|---------|-------------|
| Oh-My-Zsh | Bloated, 200+ files on startup | Starship + manual plugins |
| pip | 10-100x slower, no lockfile | uv |
| npm | Slower, allows phantom deps | pnpm |
| nvm / pyenv / rbenv | Three tools for one job | mise |
| Midnight Commander | Learn terminal navigation instead | zoxide + fzf |
| Docker Desktop GUI | Slow, resource-heavy | lazydocker (TUI) |
| Postman | Heavy Electron app for API testing | httpie (CLI) or Bruno (lighter GUI) |

---

## Related
- [[Tool Comparison Matrix]] — AI coding tools specifically
- [[The Developer Machine]] — full machine setup
- [[Version and Runtime Management]] — mise, uv, Bun
- [[🗺️ Tools MOC]]

---

#tools #research #ifykyk
