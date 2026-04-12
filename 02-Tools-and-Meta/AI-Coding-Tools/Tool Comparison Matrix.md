# Tool Comparison Matrix

> When to use which AI coding tool. Updated April 2026.

---

## Quick Comparison

| Feature | Claude Code | Cursor | GitHub Copilot | Superpowers/GSD |
|---------|------------|--------|----------------|-----------------|
| **Interface** | CLI (terminal) | IDE (VS Code fork) | IDE plugin | CLI (wraps Claude Code) |
| **Rules file** | CLAUDE.md | .cursor/rules/ | AGENTS.md | CLAUDE.md |
| **Hooks/verification** | Yes (lifecycle hooks) | Limited | Limited | Yes (inherits Claude Code) |
| **MCP support** | Yes | Yes | Partial | Yes |
| **Multi-file editing** | Yes (via tools) | Yes (native) | Yes | Yes |
| **Context window** | Large (200k) | Varies by model | Varies | Large (inherits Claude) |
| **Best for** | Agentic workflows, automation, CI | Interactive editing, visual diffs | Quick completions, inline | Enhanced agentic workflows |
| **Harness ceiling** | Level 4 | Level 2-3 | Level 2 | Level 4 |

## When to Use What

### Claude Code (or Superpowers)
**Use when:**
- Building new features end-to-end (DB → API → UI)
- Running multi-step workflows with verification
- Need hooks to enforce quality automatically
- Working from terminal, not an IDE
- Tasks that benefit from agent autonomy (scaffolding, refactoring)

**Skip when:**
- Quick inline edits to a specific function
- Visual review of changes across many files simultaneously
- You want inline autocomplete while typing

### Cursor
**Use when:**
- Editing specific files with visual context
- Need to see diffs across files side-by-side
- Interactive back-and-forth on a focused area
- Want inline completions while writing
- Pair-programming style workflow

**Skip when:**
- Large autonomous tasks (agent loop is less mature than Claude Code)
- Need lifecycle hooks for verification
- CI/CD integration

### GitHub Copilot
**Use when:**
- Already in VS Code and want inline suggestions
- Quick completions for boilerplate code
- Tab-completion style workflow
- Team already standardized on it

**Skip when:**
- Autonomous multi-file generation
- Complex agent workflows
- Need strong verification/hooks

## Combining Tools

These aren't mutually exclusive. A practical workflow:

1. **Claude Code / Superpowers** for building new features (agentic, autonomous)
2. **Cursor** for reviewing and refining agent output (visual, interactive)
3. **Copilot** for small edits while reviewing in VS Code (inline, fast)

The key is matching the tool to the task, not picking one for everything.

## What to Watch For

The AI coding tool space moves fast. Things that could shift this matrix:
- Cursor adding better hook/verification systems
- Claude Code getting a visual IDE interface
- New entrants (Windsurf, Augment, Devin, etc.)
- Model improvements that make tool choice less important

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
