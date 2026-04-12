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
window-decoration = false
window-theme = ghostty
macos-titlebar-style = hidden

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

# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# fzf (fuzzy finder)
source <(fzf --zsh)

# Preview files with bat in fzf
alias preview="fzf --preview 'bat --color=always {}'"
```

### Advanced Tools

| Tool | What It Does | IFYKYK |
|------|-------------|--------|
| **atuin** | Shell history search with sync across machines, SQLite-backed | Replaces ctrl+r with full-text search across all terminals |
| **httpie** | Human-friendly HTTP client (`http GET api.example.com`) | Replaces `curl` for API testing |
| **jq** | Command-line JSON processor | Pipe any JSON through `jq .` for instant pretty-print |
| **yazi** | Terminal file manager with image preview | When you need to browse files visually without leaving terminal |
| **hyperfine** | CLI benchmarking tool | `hyperfine 'command1' 'command2'` for comparing perf |
| **lazydocker** | TUI for Docker (like lazygit but for containers) | View logs, restart, shell into containers without memorizing flags |
| **tldr** | Simplified man pages with examples | `tldr tar` instead of reading 500 lines of `man tar` |
| **btop** | Beautiful system monitor | Replaces `top`/`htop` with a modern UI |
| **dust** | Disk usage analyzer | Replaces `du` with visual, sorted output |
| **dive** | Docker image layer explorer | See exactly what's in each layer of your Docker image |

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
# Set delta as your pager (beautiful diffs)
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.side-by-side true

# Useful defaults
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true  # remember conflict resolutions
```

---

## Dotfiles

Store your config in a git repo so you can reproduce your setup on any machine:

```
~/dotfiles/
├── .zshrc
├── .gitconfig
├── starship.toml
├── ghostty/config
├── mise.toml          # global tool versions
└── install.sh         # symlink everything + brew install
```

Symlink with `ln -s ~/dotfiles/.zshrc ~/.zshrc` etc. Or use a tool like `stow`.

The `install.sh` script should be runnable on a fresh Mac and get you to a working dev environment in under 10 minutes.

---

## Related
- [[Version and Runtime Management]] — mise, uv, Bun
- [[Docker for Local Dev]] — containerize from day 1
- [[The 15 Universal Layers]] — the project-level layers that sit on top of this

---

#foundations #dev-environment #machine-setup
