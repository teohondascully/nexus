# Claude Code

> Anthropic's CLI agent for agentic coding. Terminal-first, tool-use driven, hook system for verification.

---

## What It Is
A command-line tool that wraps Claude with an agent loop, file system tools (read, write, edit), bash execution, and MCP server integration. You describe what you want, it plans, writes code, runs tests, and iterates.

## Key Features

### CLAUDE.md
Project-level rules file at repo root. Injected into context every session. This is your [[The Fractal Harness Stack|Level 2 harness]].

See [[Template — CLAUDE.md]] for the starter template.

### 1M Context Window (GA)
Both Opus 4.6 and Sonnet 4.6 now support **1 million token context windows** — no surcharge, no beta headers, no waiting list. Standard per-token pricing applies across the full window. Max/Team/Enterprise get 1M on Opus by default. Up to 600 images or PDF pages per request.

### Hooks System
Lifecycle hooks that fire at specific points:
- **PreToolUse / PostToolUse** — before/after the agent reads/writes files
- **afterToolUse** — after any tool execution (run linters, tests here)
- **onStop** — before the agent finishes (final verification)
- **PermissionDenied** — fires after Auto Mode classifier denials
- New "defer" permission decision for headless sessions (pause and resume)

This is what enables [[Deterministic Enforcement]]. The agent can't move on until verification passes.

### MCP (Model Context Protocol) Servers
Connect external tools the agent can use:
- GitHub (create PRs, check CI)
- Database (read schema, run queries)
- Sentry (check errors)
- Custom servers for project-specific tools
- Result storage increased to 500K characters. Non-blocking connections in headless mode.

### Sub-Agents & Agent Teams
Claude Code can spawn sub-agents for focused tasks (e.g., a research sub-agent that reads docs, a verification sub-agent that runs tests). Named subagents appear in @ mention typeahead. **Agent Teams** (Feb 2026) enable multi-threaded orchestrated work. Enables [[The Fractal Harness Stack|Level 3]] patterns.

### Scheduled Tasks (/loop)
Run recurring jobs on Anthropic-managed cloud infrastructure — even when your laptop is off. Attach repos, set a schedule, add environment and connectors. Fully autonomous background work.

### Computer Use
Claude can open files, run dev tools, point, click, and navigate the screen with no setup required. Available for Pro and Max users.

### Checkpoints
Automatically saves code state before each change. Rewind instantly with Esc×2 or `/rewind`. Choose to restore code, conversation, or both. Safety net for agent-driven changes.

### Auto Mode
Smart auto-approval: safe actions run automatically, risky ones get blocked and Claude is pushed toward safer alternatives. Cuts permission prompt fatigue (93% of prompts were already being approved).

### VS Code Extension (Beta)
Claude Code is now available as a VS Code extension from the marketplace, in addition to the terminal CLI.

### Remote Control
Send instructions from the Claude App on your phone — Claude Code executes desktop operations on your Mac. Code never leaves your computer.

## Installation & Setup
See Anthropic docs for latest: https://docs.claude.com

## Best Practices
See [[My Claude Code Setup]] for the full configuration guide.

## Strengths
- Strongest hook/verification system of any AI coding tool
- Best for autonomous, multi-step workflows
- 1M token context window — largest in the space
- Terminal-native — composes with existing CLI tools
- MCP ecosystem growing fast
- /loop enables fully autonomous background work

## Weaknesses
- No visual IDE — can't see diffs visually without external tool (use Cursor for review)
- Learning curve for hook configuration
- Auto Mode is new and occasionally over-blocks safe actions

---

## Related
- [[My Claude Code Setup]]
- [[Tool Comparison Matrix]]
- [[Session Workflow]]
- [[Prompt Patterns That Work]]

---

#tools #claude-code
