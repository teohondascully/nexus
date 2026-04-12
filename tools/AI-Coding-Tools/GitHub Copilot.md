# GitHub Copilot

> GitHub's AI coding assistant. Agent mode GA, Copilot CLI GA, Autopilot mode. VS Code, JetBrains, CLI, mobile. Last audited: 2026-04-12.

---

## What It Is
Inline code suggestions, chat panel, and now autonomous agent capabilities. Deep GitHub ecosystem integration (PRs, issues, actions, code review).

## Key Features

### Agent Mode (GA — March 2026)
Copilot autonomously plans and executes multi-step coding tasks: determines which files need to change, makes edits across multiple files, runs terminal commands, reviews output, and iterates until complete. Available in VS Code and JetBrains.

### Copilot CLI (GA — February 2026)
Terminal-based coding agent — a direct competitor to Claude Code. Supports four modes including **Autopilot** for fully autonomous sessions where Copilot executes tools, runs commands, and iterates without stopping for approval. Ideal for well-defined tasks: writing tests, refactoring, fixing CI failures, long-running multi-step sessions.

### Cloud Agent (formerly Coding Agent)
Turns issues into pull requests autonomously in the background — writes code, runs tests, and opens a PR for your review. Also works from GitHub Mobile (April 2026). Now automatically runs GitHub security/quality tools (CodeQL, Advisory Database, secret scanning, Copilot code review) on generated code.

### AGENTS.md & .agent.md
Project-level instructions file (similar to CLAUDE.md). Plus: define specialized custom agents as `.agent.md` files in your repository.

### Agentic Code Review
Gathers full project context before suggesting changes. Can pass fix suggestions directly to the coding agent to generate fix PRs automatically.

### Copilot Chat
Chat panel in the IDE for longer questions and multi-step tasks. Semantic code search finds conceptually related code, not just keyword matches.

### Autopilot Mode (Public Preview — March 2026)
Fully autonomous agent sessions in VS Code and CLI. Choose per-session permission level: Default, Bypass Approvals, or Autopilot. Configurable thinking effort for reasoning models (Claude Sonnet 4.6, GPT-5.4).

### Multi-Model Support
Choose between Claude Sonnet 4.6, Google Gemini 2.0 Flash, GPT-5.4, and other models via premium requests.

## Pricing
| Plan | Price |
|------|-------|
| Free | $0 (2000 completions, 50 chat requests) |
| Pro | $10/mo (300 premium requests) |
| Pro+ | $39/mo (1500 premium requests, all premium models) |
| Business | $19/user/mo |
| Enterprise | $39/user/mo |

> Note: **Data policy change (April 24, 2026):** Interaction data from Free, Pro, and Pro+ users will be used to train AI models unless you opt out.

## Best For
- Teams already on GitHub with existing CI/CD
- Autonomous issue-to-PR workflow via cloud agent
- Terminal-first workflows via Copilot CLI (Autopilot mode)
- Quick inline completions (tab-complete style)
- Multi-model access without switching tools

## Limitations
- Hook/verification system not as mature as Claude Code
- Copilot CLI is newer and less ecosystem support than Claude Code
- Credit-based premium requests can run out
- Data policy change may concern privacy-sensitive users

## Harness Ceiling
Level 2-3. AGENTS.md + .agent.md + agentic code review provide more enforcement than before, but still behind Claude Code's hooks.

---

#tools #copilot
