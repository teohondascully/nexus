# nexus

One-command dev environment + invisible project infrastructure for any language.

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

After installing, `nexus` is available from any directory. It's a language-aware project infrastructure system — detects your ecosystem and drops only what applies. Scripts run from `~/.nexus/`, so your repo stays clean.

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

Auto-detects your ecosystem (Node, Go, Python, Rust, or generic) and drops only what applies. No scripts in your repo — enforcement runs from `~/.nexus/`:

- **CLAUDE.md** with universal conventions (Node projects get additional Node-specific rules)
- **justfile** with doctor commands — no placeholders, no "Configure: replace this"
- **lefthook** pre-commit hooks scoped to your detected ecosystem
- **Claude Code hooks** (session-sync at start/stop via `~/.nexus/scripts/session-sync.sh`)
- **.nexus/context.md** — auto-maintained living context file for fresh AI agents
- **.gitignore**, **.env.example**, **.mise.toml**, **PR template**
- **Git remote hint** when no remote is detected

### `nexus doctor`

Detects your ecosystem and runs only the checks that apply. No "skip" noise for irrelevant tools:

```
  nexus doctor

  Ecosystem: Go

  ok    CLAUDE.md file structure
  ok    .env.example coverage
  ok    Nexus v2.1.0

  3/3 passed

  Recommendations
   ~  No .nexus/context.md found. Run: nexus init

  1 recommendation
```

### `nexus update`

Syncs your project's infrastructure against the latest templates. Handles section-level CLAUDE.md migration — only updates sections that have changed, preserving project-specific content.

## How it works

The vault is the brain. Nexus compiles it into machine-enforceable artifacts. AI agents only see artifacts, not the vault.

1. **Vault** — 50+ Obsidian notes encoding architecture patterns, conventions, and stack decisions
2. **Artifacts** — `nexus init` detects your ecosystem and drops only what applies — no irrelevant hooks, no placeholder scripts
3. **Hooks** — enforcement layers fire at commit time and session boundaries
4. **Enforcement** — violations surface at commit time, not review time

### Hook system

Two enforcement layers work together:

- **lefthook pre-commit** — checks scoped to your ecosystem (Node: typecheck, lint, env sync, dep direction; Go/Rust/Python: subset that applies)
- **Claude Code hooks** — `session-sync.sh` runs at session start and stop, keeping `.nexus/context.md` current so fresh agents immediately know your stack
- **justfile** — `just doctor` runs the full check suite on demand

### What gets dropped per ecosystem

| Ecosystem | CLAUDE.md | lefthook hooks | Extra checks |
|-----------|-----------|----------------|--------------|
| **Node** | Universal + Node conventions | typecheck, lint, env sync, dep direction | hallucinated imports, dead exports |
| **Go** | Universal only | vet, fmt check | — |
| **Python** | Universal only | ruff, uv sync check | — |
| **Rust** | Universal only | clippy, fmt check | — |
| **Generic** | Universal only | — | env coverage |

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

What lives in `~/.nexus/` (the nexus install):

```
~/.nexus/
├── nexus                     # CLI entry point
├── cli/                      # init, doctor, update, helpers
├── templates/                # base templates per ecosystem
├── scripts/                  # maintenance scripts (run from here, not copied)
│   └── session-sync.sh       # syncs .nexus/context.md at session start/stop
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

What `nexus init` drops into your project:

```
your-project/
├── CLAUDE.md                 # conventions for this project (universal + ecosystem-specific)
├── lefthook.yml              # pre-commit hooks scoped to detected ecosystem
├── justfile                  # doctor commands
├── .gitignore
├── .env.example
├── .mise.toml
├── .github/pull_request_template.md
└── .nexus/
    └── context.md            # living context: stack, structure, health (auto-maintained)
```

## License

MIT
