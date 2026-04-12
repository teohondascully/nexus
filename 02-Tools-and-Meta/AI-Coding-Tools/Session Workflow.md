# Session Workflow

> How to structure a coding session with an AI agent for maximum reliable output.

---

## Pre-Session (2 min)

1. **Pull latest**, make sure main is clean
2. **Check tests pass** — don't start a session on a broken base
3. **Define the task** as a single [[Template — Feature Slice Breakdown|vertical slice]]
   - Bad: "Build the dashboard"
   - Good: "Create the OrdersTable component that fetches and displays paginated orders with status badges"
4. **Write acceptance criteria** — how will you know it's done?
5. **If continuing multi-session work:** update/review `PROGRESS.md`

## Session Start

Open Claude Code / Superpowers and start with:

```
Read CLAUDE.md first.

[Task description with acceptance criteria]

Acceptance criteria:
- [ ] ...
- [ ] ...
- [ ] ...

Start by proposing your approach before writing any code.
```

**Why "propose first":** Catching a bad approach before any code is written costs 30 seconds. Catching it after 200 lines costs 15 minutes.

## During Session

### The Review Loop
```
Agent writes code → Hooks run (typecheck, lint, test) → Agent self-corrects → You review diff
```

**Your job during the session:**
1. **Read every diff.** This is THE skill. Not prompting — reviewing.
2. **Check for:** hallucinated imports, over-abstraction, convention violations, subtle logic bugs
3. **If off-track:** Don't try to patch. Revert to last good commit, re-prompt with better constraints.
4. **If on-track:** Let it run. Don't micromanage.

### Prompt Patterns (see [[Prompt Patterns That Work]])

**For corrections:**
```
That violates our dependency direction — services can't import from components. 
Revert that change and move the logic to orderService instead.
```

**For expansion:**
```
Good. Now add input validation using Zod. Follow the pattern in src/app/api/orders/route.ts.
```

**For debugging:**
```
The test is failing because [specific reason]. Fix the implementation, do NOT modify the test.
```

### Session Health Checks
- **After ~30 min of continuous generation:** Context quality degrades. Commit what works, start a new session.
- **After 3+ correction cycles on the same issue:** The agent is stuck. Step back, think about the architecture, re-prompt with more context.
- **If you're accepting without reading:** Pause. You've dropped to [[The Fractal Harness Stack|Level 1]].

## Post-Session (5 min)

1. **Run full test suite** — not just the affected tests
2. **Review git log** — are commits granular and well-messaged?
3. **Update CLAUDE.md** if you discovered a new pattern or anti-pattern
4. **Update PROGRESS.md** if multi-session work
5. **Quick note:** anything to feed back into [[Template — Project Retro|project retro]]

## Session Metrics (track over time)

- Time spent prompting vs. reviewing (target: more reviewing)
- Number of reverts per session (target: decreasing)
- Lines shipped per session (trend, not absolute)
- Harness level operated at (target: Level 2+)

---

## Related
- [[My Claude Code Setup]]
- [[Prompt Patterns That Work]]
- [[The Fractal Harness Stack]]
- [[Template — Feature Slice Breakdown]]
- [[Agent-Friendly Codebases]]

---

#tools #workflow #session
