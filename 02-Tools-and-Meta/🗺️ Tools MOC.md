# 🔧 Tools & Meta MOC

> The current best-in-class. This layer changes — [[🗺️ Foundations MOC|Foundations]] don't. When a tool here gets replaced, the Foundation pattern it serves stays the same.

---

## AI Coding Tools
- [[Claude Code]] — CLI agent, 1M context, hooks, CLAUDE.md, MCP, /loop, Computer Use
- [[Superpowers (GSD)]] — Claude Code wrapper with enhanced workflows
- [[Cursor]] — IDE with Cursor 3.0 agents, .cursor/rules/, Design Mode
- [[GitHub Copilot]] — AGENTS.md, agent mode GA, coding agent, .agent.md
- [[Tool Comparison Matrix]] — when to use which

## Current Meta (April 2026)
- [[Beyond the Basics]] — IFYKYK tools, browser choice, Claude plans, multi-agent strategies, niche picks
- **Harness > Model** — stop upgrading models, start building constraints ([[Harness Engineering Overview]])
- **Agent autonomy is real** — Claude Code /loop, Copilot coding agent, Cursor background agents all ship autonomous work
- **Vertical slices** — smallest testable feature, not big PRs
- **CLAUDE.md is mandatory** — project conventions in context, every session
- **Tests in the loop** — agent runs tests after every change, not at the end
- **Review > Prompt** — time spent reading diffs > time spent crafting prompts

## Stack Directory
> Link to the [[The 15 Universal Layers|Foundation Blueprint]] for which layer each serves

| Category | Current Pick | Runner-Up | Foundation Layer |
|----------|-------------|-----------|-----------------|
| Monorepo | Turborepo + pnpm | Nx | Layer 1 |
| Framework | Next.js 16 (App Router) | SvelteKit | — |
| Database | Postgres (Neon/Supabase) | PlanetScale | Layer 2 |
| ORM | Drizzle | Prisma | Layer 2 |
| Validation | Zod 4 | Valibot | Layer 4 |
| Auth | Clerk | Auth.js | Layer 3 |
| API | tRPC | Server Actions | Layer 4 |
| Styling | Tailwind v4 + shadcn/ui | Radix | — |
| Background Jobs | Inngest | Trigger.dev | Layer 5 |
| Payments | Stripe | — | Layer 11 |
| Email | Resend + React Email | Postmark | Layer 12 |
| Error Tracking | Sentry | — | Layer 7 |
| Logging | Axiom | Datadog | Layer 7 |
| Analytics | PostHog | Plausible | Layer 15 |
| CI/CD | GitHub Actions + Vercel | Railway | Layer 9 |
| File Uploads | UploadThing | Cloudinary | Layer 10 |
| Feature Flags | PostHog | Flagsmith | Layer 13 |
| Search | Typesense | Algolia | Layer 14 |

> ⚠️ Review this table quarterly. Tools rotate; patterns don't.

## Dev Environment Stack (Layer -1)
> See [[The Developer Machine]] for the full setup guide.

| Category | Pick | Replaces | Why |
|----------|------|----------|-----|
| Terminal | Ghostty 1.3 | iTerm2 / Terminal.app | GPU-accelerated, native, fastest in benchmarks, scrollback search, zero config |
| Prompt | Starship | Oh-My-Zsh prompt | Rust, fast, shows only what matters |
| Version mgr | mise | nvm + pyenv + rbenv + asdf | One tool, Rust, manages env vars + tasks too |
| JS packages | pnpm | npm / yarn | 3x faster, strict deps, best monorepo support |
| JS runtime | Bun (new) / Node (existing) | Node.js for everything | 3x throughput, native TS, 25x faster installs |
| Python packages | uv | pip + venv | 10-100x faster, Rust, replaces pip + venv + pyenv |
| Python linting | Ruff | pylint / flake8 | 100x faster, same team as uv |
| grep | ripgrep (rg) | grep | 10-100x faster, respects .gitignore |
| cat | bat | cat | Syntax highlighting, line numbers, git integration |
| ls | eza | ls | Icons, colors, git status, tree view |
| cd | zoxide (z) | cd | Learns your dirs, jump with partial names |
| find | fd | find | Simpler syntax, faster, respects .gitignore |
| git TUI | lazygit | git CLI for complex ops | Visual staging, rebasing, conflict resolution |
| docker TUI | lazydocker | docker CLI | Logs, restart, shell-in without flags |
| fuzzy search | fzf | ctrl+r / manual search | Fuzzy find anything: history, files, branches |
| git diffs | delta | git diff | Syntax-highlighted, side-by-side diffs |
| shell history | atuin | ctrl+r | SQLite-backed, syncs across machines |
| font | JetBrains Mono Nerd | whatever default | Ligatures, icons for eza/starship |

## Workflow Optimization
- [[My Claude Code Setup]] — CLAUDE.md template, hooks config, MCP servers
- [[Session Workflow]] — how to structure a coding session for max output
- [[Prompt Patterns That Work]] — tested prompts for common tasks

---

#tools #meta #stack
