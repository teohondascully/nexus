# The Developer Machine

> Layer -1. Everything between opening your laptop and writing your first line of code. This is the layer most guides skip. A solo founder who optimizes this saves 30-60 minutes a day.

---

## The Full Pipeline (in order)

```
Open laptop
  → Terminal (Ghostty or Warp)
    → Shell (Zsh + Starship prompt)
      → CLI tools (modern Rust replacements for everything)
        → Version manager (mise — one tool for all runtimes)
          → Package managers (pnpm for JS, uv for Python)
            → Editor (Cursor / VS Code)
              → Containerization (Docker Compose for local deps)
                → Project scaffold (monorepo, CLAUDE.md, CI)
                  → Agent workflow (Claude Code / Superpowers)
                    → Ship
```

Each layer wraps the previous one. Optimize from the bottom up.

---

## Terminal Emulator

### The Pick: Ghostty (v1.3, March 2026)
- GPU-accelerated, written in Zig by Mitchell Hashimoto (HashiCorp founder)
- Native macOS feel (Metal rendering, AppKit, Mission Control integration)
- **v1.3 added:** scrollback search (cmd+f), native scrollbars, click-to-move-cursor, Unicode 17 support
- Performance: rearchitected renderer, 2-5x lower lock time, available in Ubuntu 26.04 repos
- Zero-config — works perfectly out of the box
- Free, open-source, non-profit stewarded
- Fastest terminal in benchmarks (lower latency than Warp, iTerm2, Alacritty)

**Setup (step by step):**

```bash
# 1. Install Ghostty
brew install --cask ghostty

# 2. Create config directory and themes directory
mkdir -p ~/.config/ghostty/themes

# 3. Download Catppuccin Mocha theme
curl -o ~/.config/ghostty/themes/catppuccin-mocha \
  https://raw.githubusercontent.com/catppuccin/ghostty/main/themes/catppuccin-mocha

# 4. Create the config file
cat > ~/.config/ghostty/config << 'CONF'
font-family = JetBrains Mono
font-size = 14
theme = catppuccin-mocha
window-padding-x = 8
window-padding-y = 8
cursor-style = block
shell-integration = zsh

background-opacity = 0.92
unfocused-split-opacity = 0.85
window-theme = ghostty

font-thicken = true
adjust-cell-height = 2

cursor-style-blink = false
mouse-hide-while-typing = true
copy-on-select = clipboard

keybind = cmd+d=new_split:right
keybind = cmd+shift+d=new_split:down
keybind = cmd+shift+enter=toggle_split_zoom
CONF
```

**What this config does:**
- Semi-transparent background (0.92) with dimmed unfocused splits — keeps context without distraction
- Hidden titlebar (`macos-titlebar-style = hidden`) — maximum screen real estate
- `font-thicken` + `adjust-cell-height = 2` — sharper text on Retina displays
- No cursor blink, hide mouse while typing — less visual noise
- `copy-on-select = clipboard` — select text to copy, no cmd+c needed
- **Splits:** `cmd+d` for vertical, `cmd+shift+d` for horizontal, `cmd+shift+enter` to zoom a split (same muscle memory as iTerm2)

### Runner-up: Warp
- AI-powered command suggestions (good for learning new CLI tools)
- Block-based output (select/copy individual command outputs)
- Modern UI with collaboration features
- **Tradeoff:** Not open-source, telemetry, heavier than Ghostty

### Not recommended in 2026: Oh-My-Zsh
Loads 200+ files on shell startup. Use Starship for your prompt and install plugins manually instead. The performance difference is noticeable.

---

## Shell + Prompt

### Shell: Zsh (default on macOS)
Already installed. Don't overthink this.

### Prompt: Starship
Minimal, blazing-fast, cross-shell prompt written in Rust. Shows only what matters: git branch, language version, cloud context, execution time.

```bash
brew install starship
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

**Config:** `~/.config/starship.toml`
```toml
[character]
success_symbol = "[❯](green)"
error_symbol = "[❯](red)"

# Disable cloud context — shows email, not useful for local dev
[gcloud]
disabled = true

[aws]
disabled = true

[git_branch]
format = "[$branch]($style) "

[nodejs]
format = "[$version](green) "

[python]
format = "[$version](yellow) "

[cmd_duration]
min_time = 2_000  # only show if > 2s
```

---

## CLI Tools (The Modern Unix Stack)

Every one of these is a Rust or Go binary that replaces a slow, outdated Unix default. Install all at once:

```bash
brew install fzf ripgrep bat eza zoxide git-delta lazygit fd httpie jq starship atuin
```

### The Essentials (install these first)

| Classic | Modern Replacement | Why |
|---------|-------------------|-----|
| `grep` | **ripgrep** (`rg`) | 10-100x faster, respects .gitignore, colored output |
| `cat` | **bat** | Syntax highlighting, line numbers, git integration |
| `ls` | **eza** | Icons, colors, git status per file, tree view built in |
| `find` | **fd** | Simpler syntax, faster, respects .gitignore |
| `cd` | **zoxide** (`z`) | Learns your dirs, jump with partial names: `z proj` |
| `ctrl+r` | **fzf** | Fuzzy search everything: history, files, git branches |
| `git diff` | **delta** | Syntax-highlighted diffs, line numbers, side-by-side |
| `git` (TUI) | **lazygit** | Visual git interface: stage hunks, rebase, resolve conflicts |

### Shell Aliases (add to `~/.zshrc`)

```bash
# Modern replacements
alias cat="bat"
alias ls="eza --icons"
alias ll="eza -l --git --icons"
alias la="eza -la --git --icons"
alias tree="eza --tree --icons --level=3"
alias grep="rg"
alias find="fd"
alias lg="lazygit"

# Zoxide (smart cd — works as normal cd too)
eval "$(zoxide init zsh --cmd cd)"

# fzf (fuzzy finder)
source <(fzf --zsh)

# Preview files with bat in fzf
alias preview="fzf --preview 'bat --color=always {}'"
```

### Advanced Tools

Install everything at once:

```bash
brew install atuin httpie jq yazi hyperfine lazydocker tldr btop dust dive
```

Add these aliases to `~/.zshrc`:

```bash
# atuin (shell history)
eval "$(atuin init zsh)"

# Shortcuts
alias lzd="lazydocker"
alias top="btop"
alias du="dust"
alias http="httpie"

# httpie shortcuts for local dev
alias api="http localhost:3000/api"
alias apih="http localhost:3000/api/health"

# jq shortcuts
alias json="jq ."                          # pretty-print JSON
alias jsonkeys="jq 'keys'"                 # list top-level keys
alias jsonflat="jq '[paths(scalars)]'"     # flatten nested structure

# yazi — cd into the directory you were browsing when you quit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
```

---

#### atuin — Shell History on Steroids
Replaces `ctrl+r` with full-text search across all terminals, SQLite-backed, optional sync across machines.

```bash
brew install atuin
eval "$(atuin init zsh)"   # add to ~/.zshrc
```

**Key commands:**
```bash
atuin search "docker"      # search all history for "docker"
# ctrl+r                   # interactive fuzzy search (replaces default)
atuin stats                # see your most-used commands
atuin sync                 # sync history across machines (opt-in)
```

**When to use:**
- "What was that `curl` command I ran last Tuesday?" — `atuin search curl`
- "What flags did I use for that `docker build`?" — `atuin search docker build`
- Recovering a complex one-liner you ran in a different terminal session

---

#### httpie — Human-Friendly HTTP Client
Replaces `curl` for API testing. Syntax coloring, JSON by default, sensible flags.

```bash
brew install httpie
```

**Key commands:**
```bash
# GET request (JSON output by default)
http GET localhost:3000/api/orders

# POST with JSON body
http POST localhost:3000/api/orders productId=abc quantity:=5

# With auth header
http GET localhost:3000/api/me Authorization:"Bearer tok_123"

# Upload a file
http --form POST localhost:3000/api/upload file@./photo.jpg

# Follow redirects, show headers
http --follow --headers GET example.com
```

**When to use:**
- Testing API endpoints during development — see [[API Design Patterns]] and [[Template — API Route Checklist]]
- Verifying webhook payloads before going live — see [[Template — Launch Checklist]]
- Debugging auth flows — quicker than Postman for one-off requests
- Smoke testing after deploy: `http GET yourapp.com/api/health`

---

#### jq — Command-Line JSON Processor
Pipe any JSON through `jq` to filter, transform, and extract data.

```bash
brew install jq
```

**Key commands:**
```bash
# Pretty-print JSON
echo '{"name":"teo","role":"founder"}' | jq .

# Extract a field
cat package.json | jq '.dependencies'

# Get all keys
cat package.json | jq 'keys'

# Filter an array
cat data.json | jq '.users[] | select(.role == "admin")'

# Count items in an array
cat data.json | jq '.items | length'

# Combine with httpie — fetch + extract
http GET localhost:3000/api/orders | jq '.data[] | {id, status}'

# Combine with curl for quick API checks
curl -s https://api.github.com/repos/vercel/next.js | jq '{stars: .stargazers_count, forks: .forks_count}'
```

**When to use:**
- Inspecting API responses without opening a browser
- Extracting data from JSON config files, `package.json`, `tsconfig.json`
- Piping httpie or curl output to extract exactly what you need
- Debugging Stripe webhook payloads, Sentry events, PostHog event data

---

#### yazi — Terminal File Manager
Browse, preview, and manage files without leaving the terminal. Image preview, syntax-highlighted code preview, bulk rename.

```bash
brew install yazi
```

**Key commands:**
```bash
yazi                # open in current directory
yazi ~/dev/project  # open in specific directory
# Use the y() function alias above to cd into browsed dir on quit
```

**Navigation:** Arrow keys or vim bindings (`h/j/k/l`). `Enter` to open. `q` to quit. `Space` to select multiple files. `d` to delete. `r` to rename. `p` to paste. `/` to search.

**When to use:**
- Exploring an unfamiliar codebase you just cloned
- Bulk renaming files (select with `Space`, then rename)
- Previewing images, PDFs, or code files without opening an editor
- Navigating deep directory structures faster than `cd`/`ls`

---

#### hyperfine — CLI Benchmarking
Compare the performance of commands. Runs each command multiple times, shows mean/min/max with statistical analysis.

```bash
brew install hyperfine
```

**Key commands:**
```bash
# Compare two commands
hyperfine 'pnpm build' 'bun build'

# Compare with warmup runs
hyperfine --warmup 3 'node server.js' 'bun server.ts'

# Compare shell startup time (is your .zshrc slow?)
hyperfine 'zsh -ic exit'

# Export results as markdown
hyperfine --export-markdown bench.md 'command1' 'command2'
```

**When to use:**
- Deciding between Bun and Node for a specific task — see [[Version and Runtime Management]]
- Measuring the impact of a build config change
- Checking if your shell startup time is bloated (should be < 200ms)
- Benchmarking database query alternatives

---

#### lazydocker — Docker TUI
The `lazygit` of Docker. Manage containers, view logs, restart services, shell in — all keyboard-driven.

```bash
brew install lazydocker
lazydocker   # or: lzd
```

**Navigation:** Tab between panels (containers, images, volumes). `Enter` to drill in. `d` to remove. `r` to restart. `l` to view logs. `e` to exec shell.

**When to use:**
- Managing your [[Docker for Local Dev]] services (Postgres, Redis, Mailpit, MinIO)
- Tailing logs from a specific container without `docker compose logs -f postgres`
- Restarting a crashed service during development
- Inspecting container resource usage (CPU, memory)

---

#### tldr — Simplified Man Pages
Community-maintained examples for common commands. Answers "how do I use this?" in 5 seconds.

```bash
brew install tldr
```

**Key commands:**
```bash
tldr tar           # "how do I extract a .tar.gz again?"
tldr git rebase    # interactive rebase examples
tldr docker compose
tldr ssh-keygen
tldr ffmpeg        # the tool nobody remembers flags for
```

**When to use:**
- Before reaching for Stack Overflow for basic CLI usage
- Learning a new tool — `tldr mise`, `tldr pnpm`
- Refreshing your memory on flags you use rarely

---

#### btop — System Monitor
Beautiful, feature-rich system monitor. CPU, memory, disk, network, per-process usage.

```bash
brew install btop
btop    # or: top (if you added the alias)
```

**When to use:**
- Diagnosing a slow machine during development — which process is eating CPU?
- Monitoring resource usage while running builds, Docker containers, or test suites
- Checking if Docker is hogging memory (common issue with Docker Desktop)
- Part of the [[Template — Launch Checklist]] — verify production server resource usage
- Debugging "my fan is going crazy" — find the runaway process

---

#### dust — Disk Usage Analyzer
Replaces `du` with a visual, sorted tree of what's eating your disk space.

```bash
brew install dust
dust    # or: du (if you added the alias)
```

**Key commands:**
```bash
dust                    # current directory
dust ~/dev              # specific directory
dust -r                 # reverse sort (smallest first)
dust -n 20              # show top 20 entries
dust node_modules       # "why is node_modules 2GB?"
```

**When to use:**
- Figuring out why your disk is full — `dust ~`
- Finding bloated `node_modules` or build artifacts across projects
- Cleaning up before committing — make sure no large binaries snuck in
- Checking Docker volume sizes when containers feel heavy

---

#### dive — Docker Image Layer Explorer
Inspect each layer of a Docker image to find bloat, unnecessary files, and optimization opportunities.

```bash
brew install dive
```

**Key commands:**
```bash
dive myapp:latest              # inspect a built image
dive --ci myapp:latest         # CI mode — fails if image is too wasteful
```

**Navigation:** Tab between layers and file tree. Layers panel shows size of each build step. File tree shows exactly what files were added/modified/removed.

**When to use:**
- Optimizing your [[Docker for Local Dev#Production Dockerfile (Multi-Stage)|production Dockerfile]] — find what's making the image large
- Verifying multi-stage builds actually pruned dev dependencies
- Before pushing to a container registry — make sure no secrets or unnecessary files leaked into the image
- CI integration: `dive --ci` can fail a pipeline if the image efficiency score is too low

---

### Quick Reference: Which Tool for Which Job?

| Situation | Reach for | Example |
|-----------|-----------|---------|
| "What command did I run last week?" | **atuin** | `atuin search "drizzle"` |
| "Test this API endpoint" | **httpie** + **jq** | `http GET :3000/api/orders \| jq '.data[0]'` |
| "Explore this repo I just cloned" | **yazi** | `y ~/dev/new-project` |
| "Is Bun actually faster here?" | **hyperfine** | `hyperfine 'bun test' 'pnpm test'` |
| "Restart the Postgres container" | **lazydocker** | `lzd` → navigate → `r` |
| "How do I use this CLI tool?" | **tldr** | `tldr git stash` |
| "Why is my machine slow?" | **btop** | `btop` → sort by CPU |
| "Where did my disk space go?" | **dust** | `dust ~/dev` |
| "Why is this Docker image 2GB?" | **dive** | `dive myapp:latest` |
| "Pretty-print this JSON file" | **jq** | `jq . config.json` |

---

## Font

**JetBrains Mono Nerd Font** — monospace, ligatures, and includes icons that eza/starship use.

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Set it in Ghostty config, VS Code settings, and Cursor settings.

---

## Git Config

```bash
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.side-by-side true

git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true 
```

---

## The One-Command Setup

**You don't need to do any of the above manually.** The [[Template — Machine Bootstrap]] script installs and configures everything on this page — Ghostty, Starship, all CLI tools, mise, pnpm, Bun, uv, Docker, Claude Code, git config, shell aliases, and the Ghostty theme.

```bash
# On a fresh Mac:
curl -fsSL https://www.teonnaise.com/install | bash
# Restart terminal. Done.
```

This silently clones the nexus repo to `~/.nexus`, then launches the interactive bootstrap — nothing installs until you press Enter. See the template for the full script.

---

## Dotfiles (Optional — For Reproducibility)

Once your machine is set up and working, you can snapshot your config into a git repo. This is optional but useful if you ever need to set up a second machine or recover from a wipe.

```bash
# 1. Create the repo
mkdir -p ~/dotfiles && cd ~/dotfiles && git init

# 2. Copy your config files in
cp ~/.zshrc ~/dotfiles/.zshrc
cp ~/.gitconfig ~/dotfiles/.gitconfig
cp ~/.config/starship.toml ~/dotfiles/starship.toml
cp -r ~/.config/ghostty ~/dotfiles/ghostty
cp ~/.config/mise/config.toml ~/dotfiles/mise.toml 2>/dev/null

# 3. Create symlinks pointing back (so edits go to the repo)
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/ghostty/config ~/.config/ghostty/config

# 4. Commit and push
cd ~/dotfiles && git add -A && git commit -m "Initial dotfiles"
# git remote add origin <your-repo> && git push
```

**Structure:**
```
~/dotfiles/
├── .zshrc                 # shell config + aliases
├── .gitconfig             # delta, rebase, rerere
├── starship.toml          # prompt config
├── ghostty/
│   ├── config             # terminal config
│   └── themes/
│       └── catppuccin-mocha
├── mise.toml              # global tool versions
└── bootstrap.sh           # the full install script from Template — Machine Bootstrap
```

**On a new machine:** clone the repo, run `bootstrap.sh`, then symlink your dotfiles. Total time: ~15 minutes.

---

## Related
- [[Template — Machine Bootstrap]] — **the install script that automates everything on this page**
- [[Version and Runtime Management]] — mise, uv, Bun
- [[Docker for Local Dev]] — containerize from day 1
- [[The 15 Universal Layers]] — the project-level layers that sit on top of this

---

#foundations #dev-environment #machine-setup
