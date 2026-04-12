# Tool Comparison Matrix

> When to use which AI coding tool. Last audited: 2026-04-12.

---

## Quick Comparison

| Feature | Claude Code | Cursor 3.0 | GitHub Copilot | Superpowers/GSD |
|---------|------------|--------|----------------|-----------------|
| **Interface** | CLI + VS Code (beta) | IDE (VS Code fork) | IDE plugin + CLI | CLI (wraps Claude Code) |
| **Rules file** | CLAUDE.md | .cursor/rules/ | AGENTS.md + .agent.md | CLAUDE.md |
| **Hooks/verification** | Yes (lifecycle hooks, Auto Mode) | BugBot (78% resolution) | Agentic code review + CodeQL | Yes (inherits Claude Code) |
| **MCP support** | Yes (500K result storage) | Yes (marketplace + BugBot) | Partial | Yes |
| **Autonomous agents** | /loop, Agent Teams, sub-agents | Background/Cloud Agents, /worktree | Cloud Agent (issue→PR), CLI Autopilot | Yes (inherits Claude Code) |
| **Context window** | 1M tokens (Opus/Sonnet 4.6) | Varies by model | Varies | 1M (inherits Claude) |
| **Best for** | Agentic workflows, automation, CI | Interactive editing, parallel agents, visual diffs | Issue→PR automation, CLI Autopilot, inline completions | Enhanced agentic workflows |
| **Harness ceiling** | Level 4 | Level 2-3 | Level 3 | Level 4 |

## When to Use What

### Claude Code (or Superpowers)
**Use when:**
- Building new features end-to-end (DB → API → UI)
- Running multi-step workflows with verification
- Need hooks to enforce quality automatically
- Working from terminal, not an IDE
- Tasks that benefit from agent autonomy (scaffolding, refactoring)
- Fully autonomous background work (/loop, scheduled tasks)
- Large codebases that benefit from 1M context

**Skip when:**
- Quick inline edits to a specific function
- Visual review of changes across many files simultaneously
- You want inline autocomplete while typing

### Cursor 3.0
**Use when:**
- Editing specific files with visual context
- Need to see diffs across files side-by-side
- Running parallel agents across multiple workspaces
- Want Design Mode for precise UI feedback
- Want inline completions while writing
- Pair-programming style workflow

**Skip when:**
- Need mature lifecycle hooks for verification
- CI/CD integration
- Want predictable pricing (credit-based billing can surprise you)

### GitHub Copilot
**Use when:**
- Already in VS Code/JetBrains and want inline suggestions
- Want issue-to-PR automation via cloud agent
- Terminal-first workflows via Copilot CLI with Autopilot mode
- Quick completions for boilerplate code
- Team already standardized on it
- Need multi-model access (Claude, Gemini, OpenAI) in one tool

**Skip when:**
- Need strong verification/hooks (Copilot CLI is newer than Claude Code)
- Complex multi-agent orchestration
- Need 1M context window
- Data privacy concerns (April 24 policy change — training on user data)

## Combining Tools

These aren't mutually exclusive. A practical workflow:

1. **Claude Code / Superpowers** for building new features (agentic, autonomous)
2. **Cursor** for reviewing and refining agent output (visual, interactive)
3. **Copilot** for small edits while reviewing in VS Code (inline, fast)

The key is matching the tool to the task, not picking one for everything.

## What to Watch For

The AI coding tool space moves fast. Things that could shift this matrix:
- **Claude Mythos Preview** — 93.9% SWE-bench, not publicly available (Project Glasswing for security research). If Anthropic ships this capability to Claude Code, it changes everything.
- **Copilot CLI + Autopilot** — GitHub now has a real Claude Code competitor. Terminal-first, fully autonomous. Watch for ecosystem maturity and hook support.
- **Google Antigravity** — agent-first IDE with Manager view for parallel agents. 6% adoption in 2 months. Still maturing but architecturally interesting.
- **Windsurf + Devin merger** — Cognition acquired Windsurf, plans to merge Devin's agent capabilities into the IDE. Could create a strong IDE+agent combo.
- **OpenAI Codex CLI** — free, open-source, supports Anthropic too. GPT-5.4 integration. Worth watching.
- **Cursor's credit model** — if pricing stabilizes, Cursor 3.0's agent features (/worktree, /best-of-n) rival Claude Code for IDE-first workflows.
- **Node.js 26** — releasing April 22. Last under old cadence before one-major-per-year shift.

Track shifts in [[🗺️ Signals MOC]].

---

## Related
- [[Claude Code]]
- [[Cursor]]
- [[GitHub Copilot]]
- [[Superpowers (GSD)]]
- [[My Claude Code Setup]]

---

#tools #comparison #ai-coding
