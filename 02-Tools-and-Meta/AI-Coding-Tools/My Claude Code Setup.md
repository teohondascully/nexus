# My Claude Code Setup

> How to operate at Level 3+ of the [[Harness Engineering Overview#The Fractal Harness Stack|harness stack]] with Claude Code / Superpowers.

---

## Level 1 → Level 2: The Basics

### CLAUDE.md (non-negotiable)
Every repo gets a `CLAUDE.md` at root. See [[Template — CLAUDE.md]] for the starter.

This single file is the highest-ROI thing you can do. Without it, every session starts from zero. With it, the agent has your conventions, stack, file structure, and rules in context from the first message.

### Hooks
Claude Code hooks fire at lifecycle points. Set these up:

```jsonc
// .claude/hooks.json (or however your wrapper configures them)
{
  "afterToolUse": [
    "pnpm typecheck",     // catch type errors immediately
    "pnpm lint --quiet",  // enforce conventions
    "pnpm test --bail"    // run tests, stop on first failure
  ]
}
```

**Why this matters:** Without hooks, the agent writes code → moves on → compounds errors. With hooks, every change gets validated before the next step. The agent self-corrects in the same session.

### MCP Servers
Connect external tools the agent can use:
- **GitHub** — create issues, read PRs, check CI status
- **Database** — inspect schema, run read-only queries
- **Sentry** — check for errors in production
- **Linear/Jira** — read tickets for context

---

## Level 2 → Level 3: Session Structure

### Before Starting a Session
1. Pull latest, make sure tests pass
2. Define the task as a **vertical slice** (not "build auth" — "create the login form with email/password validation")
3. If continuing multi-session work, update the progress file

### During a Session
1. Start with: "Read CLAUDE.md, then [task description with acceptance criteria]"
2. Let the agent propose an approach before coding
3. **Review every diff.** This is the skill. Time spent reviewing > time spent prompting.
4. If the agent goes off-track, don't try to fix in-place — revert and re-prompt with better constraints

### After a Session
1. Run the full test suite
2. Review the git log — are commits granular and well-messaged?
3. Update CLAUDE.md if you discovered a new convention or anti-pattern
4. Note what worked / didn't in your project retro

### The "Shift Handoff" Pattern
For tasks that span multiple sessions:
1. Maintain a `PROGRESS.md` that tracks: what's done, what's next, what's blocked
2. The agent reads this at session start instead of you re-explaining context
3. Git history + progress file = agent can pick up where it (or you) left off

---

## Superpowers / GSD Specific
<!-- Fill in as you learn the specific optimizations for your wrapper -->

### What It Adds Over Raw Claude Code
- 
- 
- 

### Configuration Tips
- 
- 

### When to Use Superpowers vs. Raw Claude Code
- 
- 

---

## Anti-Patterns to Avoid
1. **Marathon sessions** — after ~30 min of continuous generation, quality degrades. Commit, reset context, start fresh.
2. **Vague prompts** — "make it better" → garbage. "Add input validation to the signup form using Zod, reject emails without @" → good.
3. **Accepting without reviewing** — the whole point of Level 3 is verification. If you're auto-accepting, you're back at Level 1.
4. **Fixing agent code by hand silently** — if you fix something, add the pattern to CLAUDE.md so it doesn't happen again.
5. **Huge PRs** — if the diff is 500+ lines, the slice was too big. Break it down.

---

## Tracking What's New
Tools in this space change fast. Check [[🗺️ Signals MOC]] for:
- New Claude Code features (hooks, MCP support, context window changes)
- Alternative wrappers and when they're better
- Community workflows from r/vibecoding and HN

---

#tools #claude-code #workflow #harness-engineering
