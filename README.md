# nexus

One-command dev environment + automated project infrastructure for macOS.

```bash
curl -fsSL https://www.teonnaise.com/install | bash
```

## What this does

Nexus installs and configures a complete terminal-first dev environment:

- **Terminal** &mdash; Ghostty + Starship prompt + JetBrains Mono + Catppuccin theme
- **Modern CLI** &mdash; ripgrep, bat, eza, fd, zoxide, fzf, delta, lazygit (replaces grep, cat, ls, find, cd, diff, git)
- **Advanced tools** &mdash; atuin, httpie, jq, yazi, hyperfine, lazydocker, btop, dust, dive, gh, just, tldr, lefthook
- **Shell** &mdash; zsh-autosuggestions, zsh-syntax-highlighting, aliases for everything
- **Runtimes** &mdash; mise (version manager), Node 24 LTS, pnpm, Bun, Python 3.12, uv, Ruff
- **AI coding** &mdash; Claude Code
- **Configs** &mdash; Ghostty, Starship, mise, git (delta, rebase, rerere), shell aliases

## Transparency

Before installing anything, press `i` at the welcome screen to see the full list of every tool, its source, and whether it auto-installs or asks first. The script is [fully readable](bootstrap.sh).

**Safe to re-run.** Already-installed tools are skipped. Configs only write if the file doesn't exist. Shell config uses a marker to avoid duplication.

## The nexus CLI

After installing, `nexus` is available from any directory. It's a project infrastructure system:

```
nexus                   Runs doctor (default)
nexus init              Zero questions. Drops self-maintaining infrastructure.
nexus doctor            Checks + recommendations
nexus doctor --fix      Auto-fix what it can
nexus doctor --quick    Fast checks (for hooks)
nexus update            Evolves project infrastructure + section-level migration
nexus version           Show version
nexus uninstall         Remove nexus
```

### `nexus init`

Zero questions. Drops self-maintaining infrastructure into your project:

- **CLAUDE.md** with dependency direction, file structure (auto-synced), and conventions
- **justfile** with standard commands (dev, test, build, doctor, etc.)
- **Maintenance scripts** &mdash; env var sync, dependency direction linter, dead export detection, CLAUDE.md file-tree sync, startup validation
- **lefthook** pre-commit hooks (typecheck, lint, env sync, dep direction)
- **Claude Code hooks** (file-tree sync on write, doctor on stop)
- **.gitignore**, **.env.example**, **.mise.toml**, **PR template**

### `nexus doctor`

Runs 7 checks and reports a scorecard with a recommendations tier:

```
  nexus doctor

  ok    CLAUDE.md file structure
  ok    .env.example coverage
  FAIL  Dependency direction (1 violation)
          src/components/OrderList.tsx imports from src/services/orders.ts
  ok    Hallucinated imports
  ok    Dead exports
  ok    Orphaned files
  ok    Nexus v1.1.0

  6/7 passed  1 failed

  Recommendations
   ~  No test runner. Run: pnpm add -D vitest
   ~  TypeScript strict mode is off

  2 recommendations
```

### `nexus update`

Syncs your project's infrastructure against the latest templates. Handles section-level CLAUDE.md migration — only updates sections that have changed, preserving project-specific content.

## How it works

The vault is the brain. Nexus compiles it into machine-enforceable artifacts. AI agents only see artifacts, not the vault.

1. **Vault** — 50+ Obsidian notes encoding architecture patterns, conventions, and stack decisions
2. **Artifacts** — `nexus init` compiles the vault into CLAUDE.md, justfile, scripts, and hook configs
3. **Hooks** — three enforcement layers run continuously during development
4. **Enforcement** — violations surface at commit time, not review time

### Hook system

Three enforcement layers work together:

- **lefthook pre-commit** — typecheck, lint, env var sync, dependency direction on every commit
- **Claude Code hooks** — file-tree sync on write, `nexus doctor --quick` on session stop
- **justfile** — `just doctor` runs the full check suite on demand

### Updating nexus

Re-run the install command. It detects the existing install, compares versions, and offers update-only (pull + re-link) or full reinstall:

```bash
curl -fsSL https://www.teonnaise.com/install | bash
```

Or evolve your project's infrastructure against the latest templates:

```bash
nexus update
```

## The knowledge vault

Nexus is also an [Obsidian](https://obsidian.md) knowledge vault with 50+ interconnected notes covering:

| Section | What's in it |
|---------|-------------|
| **Foundations** | Architecture patterns, harness engineering, stack decisions, design principles |
| **Tools** | AI coding tools, tool comparisons, workflow optimization |
| **Templates** | CLAUDE.md starter, feature slice breakdown, checklists, scaffolds |
| **Signals** | Tracked ecosystem changes with red/yellow/green classification |

To browse the vault, install [Obsidian](https://obsidian.md) (free) and open the `~/.nexus` directory as a vault. Start with `HOME.md`.

The vault separates **foundations** (patterns that don't change) from **tools** (things that rotate). When a tool gets replaced, the foundation pattern it serves stays the same.

## File structure

```
nexus/
├── nexus                     # CLI entry point
├── cli/                      # init, doctor, update, helpers
├── templates/                # files dropped into projects by nexus init
├── scripts/                  # maintenance scripts dropped into projects
├── vault/                    # Obsidian knowledge vault (50+ notes)
│   ├── HOME.md               # vault entry point
│   ├── foundations/          # architecture, design principles
│   ├── tools/                # AI tools, comparisons
│   ├── templates/            # scaffolds and checklists
│   └── signals/              # ecosystem tracking
├── bootstrap.sh              # machine setup
├── install.sh                # curl|bash entry point
├── VERSION
└── CHANGELOG.md
```

## License

MIT
