# Claude Code

> Anthropic's CLI agent for agentic coding. Terminal-first, tool-use driven, hook system for verification.

---

## What It Is
A command-line tool that wraps Claude with an agent loop, file system tools (read, write, edit), bash execution, and MCP server integration. You describe what you want, it plans, writes code, runs tests, and iterates.

## Key Features

### CLAUDE.md
Project-level rules file at repo root. Injected into context every session. This is your [[The Fractal Harness Stack|Level 2 harness]].

See [[Template — CLAUDE.md]] for the starter template.

### Hooks System
Lifecycle hooks that fire at specific points:
- **beforeToolUse** — before the agent reads/writes files
- **afterToolUse** — after any tool execution (run linters, tests here)
- **onStop** — before the agent finishes (final verification)

This is what enables [[Deterministic Enforcement]]. The agent can't move on until verification passes.

### MCP (Model Context Protocol) Servers
Connect external tools the agent can use:
- GitHub (create PRs, check CI)
- Database (read schema, run queries)
- Sentry (check errors)
- Custom servers for project-specific tools

### Sub-Agents
Claude Code can spawn sub-agents for focused tasks (e.g., a research sub-agent that reads docs, a verification sub-agent that runs tests). Enables [[The Fractal Harness Stack|Level 3]] patterns.

## Installation & Setup
See Anthropic docs for latest: https://docs.claude.com

## Best Practices
See [[My Claude Code Setup]] for the full configuration guide.

## Strengths
- Strongest hook/verification system of any AI coding tool
- Best for autonomous, multi-step workflows
- Terminal-native — composes with existing CLI tools
- MCP ecosystem growing fast

## Weaknesses
- No visual IDE — can't see diffs visually without external tool
- Learning curve for hook configuration
- Context window management is manual (no visual indicator)

---

## Related
- [[My Claude Code Setup]]
- [[Tool Comparison Matrix]]
- [[Session Workflow]]
- [[Prompt Patterns That Work]]

---

#tools #claude-code
