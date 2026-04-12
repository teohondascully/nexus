# Beyond the Basics — The IFYKYK Layer

> Tools, strategies, and decisions that most guides skip. Researched and verified as of April 2026.

---

## Browser

### Arc is Dead
Arc browser was officially discontinued in May 2025. The Browser Company stopped all development and pivoted to building **Dia**, an AI-first browser. If you're already using Arc, it still works but receives no updates and will fall behind.

**What to use instead:**
- **Zen Browser** — open-source, Firefox-based, closest to Arc's interface. 40k+ GitHub stars. The community pick for Arc refugees.
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
- Use Sonnet by default, switch to Opus when you need deeper reasoning.

### Amp Code (Sourcegraph)
**What it is:** A Claude Code competitor with better sub-agent orchestration out of the box. Built on Sourcegraph's code search engine — strong at understanding large, complex codebases.

**Advantages over Claude Code:**
- Sub-agents work without manual configuration
- Deep Mode for extended autonomous sessions
- Persistent threads that track naming conventions, test structures, API patterns across sessions
- Built-in code review agent, diagram generator

**Disadvantages:**
- More expensive (pay-per-token, no flat rate equivalent to Max)
- Smaller ecosystem — Claude Code has more community tooling, skills, hooks
- Debugging experience is less documented

**When to consider:** If you're working on a very large codebase where code search and context are the bottleneck. For solo greenfield projects, Claude Code is more cost-effective.

### Aider
**What it is:** Open-source, terminal-first AI coding tool. BYOM (bring your own model) — works with Claude, GPT, local models.

**Advantages:**
- Free (you pay for model API only)
- Git-aware — commits changes with sensible messages automatically
- Works with any model (including local via Ollama)
- Good for privacy-sensitive work

**When to consider:** When you want to use local models, when cost is a major constraint, or when you want full control over which model handles which task.

### Cline
**What it is:** Open-source VS Code agent. BYOM. Always asks for confirmation before risky actions.

**Advantages:**
- Transparency — you see exactly what it's about to do
- Visual diffs in the editor
- MCP support

**When to consider:** If you want agent capabilities inside VS Code without paying for Cursor, and you value explicit control over actions.

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

**Subagents:** Claude Code can spawn specialized sub-agents with separate context windows. The main agent delegates focused tasks (research, testing, review) and gets results back.

**Swarms (experimental):** A hidden feature discovered in early 2026 — a team lead agent delegates to specialist agents (frontend, backend, testing, docs) with a shared task board. Still maturing.

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
