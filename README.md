# nexus

One-command dev environment + project initializer for macOS.

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

After installing, `nexus` is available from any directory. It's a project initializer + maintenance system:

```
nexus init [name]       Create or configure a project
nexus add <layer>       Add a layer: db, auth, api, hooks, ci
nexus doctor            Run all maintenance checks
nexus doctor --quick    Fast checks only (no network/DB)
nexus doctor --fix      Auto-fix what it can
nexus update            Sync project against latest vault templates
nexus version           Show installed version
nexus uninstall         Remove nexus (with optional package cleanup)
```

### `nexus init`

Asks what you're building (web app or other), then drops convention files into your project:

- **CLAUDE.md** with dependency direction, file structure (auto-synced), and conventions
- **justfile** with standard commands (dev, test, build, doctor, db-reset, etc.)
- **Maintenance scripts** &mdash; env var sync, dependency direction linter, dead export detection, CLAUDE.md file-tree sync, startup validation
- **lefthook** pre-commit hooks (typecheck, lint, env sync, dep direction)
- **Claude Code hooks** (file-tree sync on write, doctor on stop)
- **.gitignore**, **.env.example**, **.mise.toml**, **PR template**

For web apps, optionally adds: Postgres + Drizzle, Clerk auth, tRPC + health endpoint, GitHub Actions CI.

### `nexus doctor`

Runs 10 checks and reports a scorecard:

```
  nexus doctor

  ok    CLAUDE.md file structure
  ok    .env.example coverage
  ok    Dependency direction
  FAIL  Dead exports (3 found)
  ok    Startup validation
  ok    Outdated dependencies
  ok    lefthook installed
  ok    Claude Code hooks present
  ok    PR template present
  ok    Nexus version (v1.0.0)

  9/10 passed  1 issue(s) found
```

### Updating nexus

Re-run the install command. It detects the existing install, compares versions, and offers update-only (pull + re-link) or full reinstall:

```bash
curl -fsSL https://www.teonnaise.com/install | bash
```

Or sync your project's nexus files against the latest templates:

```bash
nexus update
```

## The knowledge vault

Nexus is also an [Obsidian](https://obsidian.md) knowledge vault with 50+ interconnected notes covering:

| Section | What's in it |
|---------|-------------|
| **Foundations** | Architecture patterns, harness engineering, stack decisions, design principles |
| **Tools & Meta** | AI coding tools, tool comparisons, workflow optimization |
| **Templates** | CLAUDE.md starter, feature slice breakdown, checklists, scaffolds |
| **Signals** | Tracked ecosystem changes with red/yellow/green classification |

To browse the vault, install [Obsidian](https://obsidian.md) (free) and open the `~/.nexus` directory as a vault. Start with `HOME.md`.

### How the vault works

The vault separates **foundations** (patterns that don't change) from **tools** (things that rotate). When a tool gets replaced, the foundation pattern it serves stays the same.

Notes link to each other via `[[wikilinks]]`. MOC (Map of Content) files in each section serve as entry points.

### Keeping it current

The vault includes an agent-driven update system. Run:

```bash
claude "Read VAULT_UPDATE_PROMPT.md. Run weekly audit."
```

This uses Claude Code to search the web, check for tool updates, and update stale notes. All changes go through `CHANGELOG.md` with human review flags.

## Stack philosophy

The vault documents many tools for **awareness** but only recommends a specific stack for **use**. The Stack Directory in Tools is the source of truth for what we actually build with. Everything else (Cursor, Copilot, Windsurf, etc.) is tracked so you know the landscape, not because you should use all of it.

Changes to the recommended stack require explicit approval. The weekly audit updates version numbers and documents new features but does not swap recommendations.

## File structure

```
nexus/
├── nexus                     # CLI — project initializer + maintenance
├── cli/                      # command implementations (init, add, doctor, update)
├── init-templates/           # template files dropped into projects
│   ├── core/                 # CLAUDE.md, justfile, gitignore, env, mise, PR template
│   ├── scripts/              # maintenance scripts (env sync, dep direction, etc.)
│   ├── hooks/                # lefthook + Claude Code hook configs
│   ├── db/                   # Postgres + Drizzle templates
│   ├── auth/                 # Clerk templates
│   ├── api/                  # tRPC templates
│   └── ci/                   # GitHub Actions workflow
├── bootstrap.sh              # machine setup (idempotent, interactive)
├── install.sh                # curl|bash entry point (smart update detection)
├── VERSION                   # release version tracking
├── HOME.md                   # vault entry point (open in Obsidian)
├── foundations/              # architecture, harness engineering, stack decisions
├── tools/                    # AI tools, comparisons, workflows
├── templates/                # copy-paste scaffolds and checklists
├── projects/                 # project specs and plans
├── signals/                  # ecosystem tracking
├── CHANGELOG.md              # all vault updates with dates
└── VAULT_UPDATE_PROMPT.md    # agent prompt for weekly audits
```

## License

MIT
