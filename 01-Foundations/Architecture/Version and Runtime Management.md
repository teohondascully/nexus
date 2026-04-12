# Version and Runtime Management

> One tool per concern. No more nvm + pyenv + rbenv. No more pip. No more npm. Last audited: 2026-04-12.

---

## The 2026 Stack

| Concern | Old Way | Modern Way | Speedup |
|---------|---------|------------|---------|
| Runtime versions (Node, Python, Go) | nvm + pyenv + rbenv | **mise** | One tool for everything, 10x faster |
| JavaScript packages | npm / yarn | **pnpm** | 3x faster, strict, disk-efficient |
| JavaScript runtime | Node.js | **Bun 1.3.12** (new projects) / Node.js (existing) | 3x HTTP throughput, native TypeScript |
| Python packages | pip + venv | **uv** | 10-100x faster, replaces pip + venv + pyenv |
| Python linting | pylint / flake8 | **Ruff** | 100x faster (same team as uv) |

---

## mise — One Version Manager to Rule Them All

Replaces: nvm, pyenv, rbenv, goenv, jenv, asdf, direnv

Written in Rust. Reads `.tool-versions`, `.nvmrc`, `.python-version` files natively. Also manages env vars and tasks.

### Install
```bash
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

### Usage
```bash
# Install and set versions per-project
mise use node@22       # Node.js 22 LTS for this directory
mise use node@24       # Node.js 24 LTS (latest) for this directory
mise use python@3.12   # Python 3.12 for this directory
mise use go@1.22       # Go 1.22 for this directory

# Global defaults
mise use --global node@24

# Project config (.mise.toml at project root)
cat .mise.toml
```

> **Note (April 2026):** Node 22 and Node 24 are both active LTS. Starting October 2026, Node.js is changing its release schedule — one major release per year (April), every release becomes LTS. No more even/odd distinction.

### Project Config (`.mise.toml`)
```toml
[tools]
node = "24"
python = "3.12"

[env]
DATABASE_URL = "postgresql://dev:dev@localhost:5432/myproject"

[tasks.dev]
run = "pnpm dev"

[tasks.test]
run = "pnpm test"
```

**Why mise over asdf:** Rust binary vs. bash scripts. 10x faster shell startup. No shim overhead. Built-in env vars (replaces direnv). Built-in task runner (replaces make/just).

> **mise v2026.4.9** (April 11): sandbox fields in task templates, deterministic lockfile provenance, cross-device tool install fix. Active development — multiple releases per week.

---

## uv — Python's Package Manager Revolution

Replaces: pip, venv, pyenv, pipx, poetry (for apps)

Written in Rust by Astral (same team behind Ruff linter). 10-100x faster than pip.

### Install
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Usage
```bash
# Create a new Python project
uv init my-project
cd my-project

# Add dependencies (installs in seconds, not minutes)
uv add requests pandas fastapi

# Run scripts (auto-creates venv, installs deps)
uv run main.py

# Sync from lockfile (reproducible)
uv sync

# Install a CLI tool globally
uv tool install ruff
```

### Why uv over pip
- **Speed:** Install a full data science stack in 2-5 seconds vs. 45-60 seconds with pip
- **Lockfile:** `uv.lock` for reproducible installs (pip has no lockfile)
- **Unified:** Replaces pip + venv + pyenv in one binary
- **Global cache:** No duplicate downloads across projects
- **CI impact:** 50-80% reduction in CI pipeline time

**Rule:** Never use `pip install` in 2026. Use `uv add` for project deps, `uv tool install` for global CLI tools.

---

## Bun — The Faster JavaScript Runtime

Replaces: Node.js (for new projects), ts-node, tsx

3x faster HTTP throughput, 4-10x faster startup, native TypeScript execution, built-in test runner and bundler. Current version: **1.3.12** (April 2026 — added `Bun.WebView` headless browser API, `Bun.cron()` scheduler, markdown rendering, 120 bug fixes). 2.0 expected late 2026.

### When to Use Bun vs Node.js

**Use Bun for:**
- New greenfield TypeScript projects
- API servers (3x throughput matters)
- Serverless functions (4x faster cold starts)
- Scripts and CLI tools (native TS, no build step)
- Package installation (`bun install` is 25x faster than `npm install`)

**Keep Node.js for:**
- Existing production codebases (migration cost rarely justified)
- Projects with native addon dependencies
- When debugging ecosystem maturity matters

### Usage
```bash
# Install
curl -fsSL https://bun.sh/install | bash

# Run TypeScript directly (no build step)
bun run server.ts

# Install packages (25x faster than npm)
bun install

# Built-in test runner
bun test

# Built-in bundler
bun build ./src/index.ts --outdir ./dist
```

### Caveat
Debugging tooling is still less mature than Node.js. When something goes wrong in Bun, you're reading GitHub issues. In Node.js, there are 15 years of Stack Overflow answers.

**My approach:** Use Bun for new projects where I'm the sole developer. Use Node.js when working with teams or on projects with complex native dependencies.

---

## pnpm — The Package Manager for Monorepos

Replaces: npm, yarn

```bash
# Install
npm install -g pnpm

# Or via mise
mise use --global pnpm
```

**Why pnpm:**
- 3x faster than npm
- Strict — doesn't allow accessing undeclared dependencies (catches bugs)
- Disk-efficient — global store with hard links (one copy of each package on disk)
- Best monorepo support with workspaces
- Works with Bun and Node.js

---

## The Complete Install Script

```bash
#!/bin/bash
# One script to set up all version/package management

# mise (version manager)
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# Node.js + pnpm via mise
mise use --global node@24
npm install -g pnpm

# Bun
curl -fsSL https://bun.sh/install | bash

# uv (Python)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Ruff (Python linting — same team as uv)
uv tool install ruff

echo "Done. Restart your terminal."
```

---

## Related
- [[The Developer Machine]] — the full machine setup
- [[Docker for Local Dev]] — containerize services
- [[🗺️ Tools MOC]] — where these fit in the stack

---

#foundations #dev-environment #tooling
