# Cursor

> AI-native IDE (VS Code fork). Cursor 3.0 (April 2026) added background agents, cloud agents, and Design Mode. Last audited: 2026-04-11.

---

## What It Is
A fork of VS Code with AI deeply integrated: inline completions, multi-file editing with visual diffs, chat panel, project-level rules, and now autonomous agents.

## Key Features

### .cursor/rules/
Directory of rule files scoped by file pattern. More granular than CLAUDE.md — you can have rules that only apply to test files, API routes, components, etc.

### Composer 2.0 (Cursor 3.0)
Elevated from smart autocomplete to a genuine autonomous coding assistant. Multi-file editing mode with real-time RL — uses real user interactions to train and deploy improved checkpoints as often as every five hours.

### Agents Window (Cursor 3.0)
Standalone interface for running multiple AI agents in parallel across local machines, worktrees, SSH environments, and cloud setups — without interrupting main coding. Inherently multi-workspace.

### Design Mode (Cursor 3.0)
Annotate and target UI elements directly in the browser. Point the agent to exactly the part of the interface you're referring to for precise feedback.

### BugBot Code Review (Cursor 3.0)
AI code reviewer that learns from real PR feedback. Developer reactions, replies, and reviewer comments become rules that improve future reviews.

### Tab Completion
Context-aware autocomplete that predicts multi-line edits based on what you're doing.

### JetBrains Integration
Cursor's agentic capabilities now work directly inside JetBrains IDEs.

## Pricing
| Plan | Price |
|------|-------|
| Free (Hobby) | $0 |
| Pro | $20/mo ($16/mo annual) |
| Pro+ | $60/mo |
| Ultra | $200/mo |
| Teams | $40/user/mo |

Note: Cursor moved to **credit-based billing** — credits consumed based on model and complexity. This has been controversial.

## Best For
- Interactive editing where you want to see and approve each change
- Visual diff review across files
- Running parallel agents on multi-workspace projects
- Pair-programming style: you drive, AI assists

## Limitations
- Credit-based pricing can be unpredictable
- Agent features are new and still maturing vs. Claude Code's established hooks
- Heavier resource usage with agents running

## Harness Ceiling
Level 2-3. Rules files + BugBot provide context and review, but lifecycle hooks still not as mature as Claude Code.

---

#tools #cursor
