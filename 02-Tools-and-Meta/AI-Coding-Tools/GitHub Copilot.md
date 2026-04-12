# GitHub Copilot

> GitHub's AI coding assistant. Agent mode GA (March 2026). VS Code, JetBrains, mobile. Last audited: 2026-04-11.

---

## What It Is
Inline code suggestions, chat panel, and now autonomous agent capabilities. Deep GitHub ecosystem integration (PRs, issues, actions, code review).

## Key Features

### Agent Mode (GA — March 2026)
Copilot autonomously plans and executes multi-step coding tasks: determines which files need to change, makes edits across multiple files, runs terminal commands, reviews output, and iterates until complete. Available in VS Code and JetBrains.

### Coding Agent
Turns issues into pull requests autonomously in the background — writes code, runs tests, and opens a PR for your review. Also works from GitHub Mobile (April 2026).

### AGENTS.md & .agent.md
Project-level instructions file (similar to CLAUDE.md). Plus: define specialized custom agents as `.agent.md` files in your repository.

### Agentic Code Review
Gathers full project context before suggesting changes. Can pass fix suggestions directly to the coding agent to generate fix PRs automatically.

### Copilot Chat
Chat panel in the IDE for longer questions and multi-step tasks. Semantic code search finds conceptually related code, not just keyword matches.

### Multi-Model Support
Choose between Claude Opus 4, Google Gemini 2.0 Flash, and OpenAI models via premium requests.

## Pricing
| Plan | Price |
|------|-------|
| Free | $0 (2000 completions, 50 chat requests) |
| Pro | $10/mo (300 premium requests) |
| Pro+ | $39/mo (1500 premium requests, all premium models) |
| Business | $19/user/mo |
| Enterprise | $39/user/mo |

## Best For
- Teams already on GitHub with existing CI/CD
- Autonomous issue-to-PR workflow via coding agent
- Quick inline completions (tab-complete style)
- Multi-model access without switching tools

## Limitations
- Hook/verification system not as mature as Claude Code
- Agent features newer and less battle-tested than Claude Code
- Credit-based premium requests can run out

## Harness Ceiling
Level 2-3. AGENTS.md + .agent.md + agentic code review provide more enforcement than before, but still behind Claude Code's hooks.

---

#tools #copilot
