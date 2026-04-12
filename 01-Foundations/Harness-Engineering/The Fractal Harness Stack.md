# The Fractal Harness Stack

> Harnesses compose. They stack. Each level adds constraints and verification.

---

## The Five Levels

```
Level 0: Raw Model
├── Stateless. No tools. No memory. Pure text generation.
├── This is ChatGPT in a browser with no system prompt.
└── Useful for: brainstorming, one-off questions, nothing production.

Level 1: Agent Wrapper (e.g., Claude Code)
├── Adds: agent loop, tool use (file read/write, bash), context management
├── The model can now DO things, not just SAY things.
└── Most devs stop here. This is where bad output gets blamed on "the model."

Level 2: Project Config (CLAUDE.md + hooks + MCP)
├── Adds: project rules, coding conventions, verification triggers
├── CLAUDE.md injects your standards into every session.
├── Hooks run linters/tests after every change automatically.
├── MCP servers connect external tools (GitHub, DB, Sentry).
└── This is the minimum for reliable output.

Level 3: Platform Layer (specs + lifecycle orchestration)
├── Adds: feature specs, multi-phase verification, progress tracking
├── Initializer agent sets up environment + feature list.
├── Coding agent reads progress, picks next task, implements, tests, updates.
├── "Shift handoff" model — each session arrives to organized state.
└── This is where solo devs start looking like teams.

Level 4: CI/CD Wraps Everything
├── Adds: deployment gates, integration tests, production monitoring
├── PR preview deploys, automated test suites, rollback mechanisms.
├── The final deterministic layer — bad code literally cannot reach production.
└── This is "enterprise-grade" output from a solo founder.
```

## The Key Insight

"Using Claude Code" at Level 1 and "using Claude Code" at Level 3 are **fundamentally different systems**, even though the underlying model is identical.

The model is the same. The harness is the differentiator.

## How to Level Up

### Level 0 → 1
Install Claude Code or Cursor. This happens automatically.

### Level 1 → 2 (biggest ROI jump)
1. Write a [[Template — CLAUDE.md|CLAUDE.md]] for your project
2. Configure hooks to run `typecheck + lint + test` after every tool use
3. Connect MCP servers for tools the agent needs (GitHub, DB)
4. Add a `.cursorrules` or `AGENTS.md` if using those tools alongside

### Level 2 → 3
1. Write a feature spec / progress file (`PROGRESS.md`) the agent reads at session start
2. Break work into a numbered feature list, all initially "failing"
3. Have the agent update progress after each completed feature
4. Use git as checkpoint/recovery — commit after each successful step
5. Design sessions around the [[Harness Engineering Overview#Shift Handoff Model|shift handoff model]]

### Level 3 → 4
1. Set up GitHub Actions: lint → typecheck → test → build on every PR
2. Enable preview deploys (Vercel does this automatically)
3. Add integration tests that run against a test database in CI
4. Configure Sentry + uptime monitoring for production
5. Make rollback a one-command operation

---

## Related
- [[Harness Engineering Overview]]
- [[Deterministic Enforcement]]
- [[My Claude Code Setup]]

---

#harness-engineering #foundations #levels
