# Harness Engineering Overview

> "Agents aren't hard; the harness is hard." — HumanLayer

> "Not documented. Enforced." — OpenAI Codex team

---

## The Three Evolutions

| Era | What It Taught Us | Limitation |
|-----|-------------------|------------|
| **Prompt Engineering** (2022-2024) | How to communicate with models | Prompts are suggestions — no enforcement |
| **Context Engineering** (2025) | What models see matters more than how you ask | Model can still ignore what you show it |
| **Harness Engineering** (2026) | Constrain with deterministic rules | This is the current frontier |

Each evolution subsumes the previous. A good harness includes good context, which includes good prompts. But the harness adds **deterministic enforcement**.

---

## The Core Insight

Models are **probabilistic**. Rules are **deterministic**. Use deterministic constraints to bound probabilistic output.

A custom linter doesn't *ask* the model to follow architecture — it *rejects* code that violates it.
A test suite doesn't *hope* for correct logic — it *verifies* it.

---

## The Fractal Harness Stack

```
Level 0: Raw model (stateless, no tools, pure text generation)
Level 1: Agent wrapper (Claude Code — adds tool use, context management)
Level 2: Project config (CLAUDE.md + hooks + MCP servers — adds rules, verification)
Level 3: Platform layer (specs, lifecycle orchestration, multi-phase verification)
Level 4: CI/CD (deployment gates, integration tests, production monitoring)
```

Most developers operate at Level 1. Level 3-4 is where reliable output lives.

---

## Key Patterns

### Layered Architecture Enforcement
OpenAI's Codex team used a directional dependency chain:
```
Types → Config → Repo → Service → Runtime → UI
```
Enforced by custom linters + structural tests + CI gates. Not by documentation. The Codex team built a production application with **1M+ lines of code where no lines were written by human hands**, averaging 3.5 merged PRs per engineer per day — with throughput *increasing* as the team grew because better harness design compounded the value of each additional engineer.

### Anthropic's Three-Agent Harness (April 2026)
Anthropic published a three-agent harness architecture separating concerns:
1. **Planning agent** — breaks work into steps and maintains coherence
2. **Generation agent** — writes code and implements changes
3. **Evaluation agent** — reviews output and verifies correctness

This division improves quality over multi-hour AI sessions by preventing the single-agent drift problem.

### Verification Hierarchy
Agents take the path of least resistance. The verification standard you set is the one you get:
- If you only require unit tests → you get passing units tests (that may not verify real behavior)
- If you require E2E browser tests → the agent actually opens a browser and checks

### Anti-Pattern: Test Weakening
Without explicit instructions, agents will modify tests to match buggy implementations rather than fix the code. Must include rules like "It is unacceptable to remove or edit tests."

### Shift Handoff Model
For long-running tasks that exceed context windows:
1. **Initializer agent** sets up: env scripts, progress tracking, feature list (all "failing")
2. **Coding agent** reads progress file + git history, picks next feature, implements, tests, updates progress
3. Git serves as both version control AND checkpoint/recovery

### Git as Undo
Agents commit when a step succeeds, not when a feature is complete. The harness uses git as a rollback mechanism.

### Industry Adoption (2026)
According to Anthropic's Agentic Coding Trends Report, developers integrate AI into **60% of their work**. Engineering roles are shifting toward agent supervision, system design, and output review. "Harness engineering" is now a mainstream term — MIT Technology Review named generative coding a 2026 Breakthrough Technology.

### Claude Mythos Preview (April 7, 2026)
Anthropic released a model scoring **93.9% SWE-bench** that can autonomously discover and chain zero-day exploits. Deliberately NOT made publicly available — instead, 50+ companies received access via **Project Glasswing** ($100M in credits) for defensive security work. This demonstrates that raw model capability is no longer the bottleneck — the harness around the model (what it's allowed to do, how it's verified) is what determines whether capability becomes value or risk.

---

## What This Means for My Workflow

### With Claude Code / Superpowers
1. Always have a `CLAUDE.md` at repo root — conventions, stack, file structure, rules
2. Use hooks to run tests/linters after every change (not just at the end)
3. Break work into smallest vertical slices — "create login form" not "build auth"
4. Maintain a progress file the agent can read between sessions
5. Spend more time reviewing diffs than prompting

### For Foundation Building
The harness IS part of the foundation. Layer 8 (Testing) and Layer 9 (CI/CD) from the [[The 15 Universal Layers|Foundation Blueprint]] are harness infrastructure.

---

## Sources
- [Harness Engineering - OpenAI](https://openai.com)
- [Effective Harnesses for Long-Running Agents - Anthropic](https://anthropic.com)
- [Harness Engineering - Birgitta Böckeler, Martin Fowler's site](https://martinfowler.com)
- [The Anatomy of an Agent Harness - LangChain](https://langchain.com)
- [Skill Issue: Harness Engineering for Coding Agents - HumanLayer](https://humanlayer.dev)
- Blog: "The Harness Layer" by John Davenport, CodeMySpec (March 2026)

---

#harness-engineering #foundations #ai-coding #meta
