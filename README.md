# nexus

One-command dev environment for macOS. 30+ tools, all configs, a session launcher CLI.

```bash
curl -fsSL https://raw.githubusercontent.com/teohondascully/nexus/main/install.sh | bash
```

## What this does

Nexus installs and configures a complete terminal-first dev environment:

- **Terminal** &mdash; Ghostty + Starship prompt + JetBrains Mono + Catppuccin theme
- **Modern CLI** &mdash; ripgrep, bat, eza, fd, zoxide, fzf, delta, lazygit (replaces grep, cat, ls, find, cd, diff, git)
- **Advanced tools** &mdash; atuin, httpie, jq, yazi, hyperfine, lazydocker, btop, dust, dive, gh, just, tldr
- **Shell** &mdash; zsh-autosuggestions, zsh-syntax-highlighting, aliases for everything
- **Runtimes** &mdash; mise (version manager), Node 24 LTS, pnpm, Bun, Python 3.12, uv, Ruff
- **AI coding** &mdash; Claude Code + `nexus` session launcher
- **Configs** &mdash; Ghostty, Starship, mise, git (delta, rebase, rerere), shell aliases

## Transparency

Before installing anything, press `i` at the welcome screen to see the full list of every tool, its source, and whether it auto-installs or asks first. The script is [fully readable](bootstrap.sh).

**Safe to re-run.** Already-installed tools are skipped. Configs only write if the file doesn't exist. Shell config uses a marker to avoid duplication.

## The nexus CLI

After installing, run `nexus` from any directory to launch a coding session:

```
nexus              # interactive menu
nexus feature      # build a new feature
nexus bug          # fix a bug
nexus refactor     # refactor code
nexus scaffold     # generate full entity (DB -> API -> tests)
nexus page         # create a new page/route
nexus review       # code review recent commits
nexus audit        # project quality checklist
nexus new-project  # start from scratch
```

Each command asks a few focused questions, assembles a prompt from tested templates, copies it to your clipboard, and offers to launch Claude Code directly.

## The knowledge vault

Nexus is also an [Obsidian](https://obsidian.md) knowledge vault with 50 interconnected notes covering:

| Section | What's in it |
|---------|-------------|
| **Foundations** | Architecture patterns, harness engineering, stack decisions, design principles |
| **Tools & Meta** | AI coding tools, tool comparisons, workflow optimization |
| **Templates** | CLAUDE.md starter, feature slice breakdown, checklists, scaffolds |
| **Signals** | Tracked ecosystem changes with red/yellow/green classification |

To browse the vault, install [Obsidian](https://obsidian.md) (free) and open the `~/.nexus` directory as a vault. Start with `HOME.md`.

### How the vault works

The vault separates **foundations** (patterns that don't change) from **tools** (things that rotate). When a tool gets replaced, the foundation pattern it serves stays the same.

Notes link to each other via `[[wikilinks]]`. MOC (Map of Content) files in each section serve as entry points. The `nexus` CLI reads from the templates section to build your prompts.

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
├── bootstrap.sh              # the install script (idempotent, interactive)
├── install.sh                # curl|bash entry point (clones repo + runs bootstrap)
├── nexus                     # session launcher CLI
├── HOME.md                   # vault entry point (open in Obsidian)
├── foundations/               # architecture, harness engineering, stack decisions
├── tools/                    # AI tools, comparisons, workflows
├── templates/                # copy-paste scaffolds and checklists
├── projects/                 # project specs and plans
├── signals/                  # ecosystem tracking
├── daily/                    # daily logs (optional)
├── CHANGELOG.md              # all vault updates with dates
├── VAULT_UPDATE_PROMPT.md    # agent prompt for weekly audits
└── Vault Maintenance System.md
```

## License

MIT
