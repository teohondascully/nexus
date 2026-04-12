#!/bin/bash
# ================================================================
# Machine Bootstrap — Interactive Dev Environment Setup
# Last updated: 2026-04-11
# Safe to re-run: skips anything already installed
# Reference: https://github.com/YOUR_USER/dotfiles
# ================================================================
set -e

# ── Colors & Helpers ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color

TOTAL_STEPS=12
CURRENT_STEP=0
INSTALLED=()
SKIPPED=()
FAILED=()

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}[$CURRENT_STEP/$TOTAL_STEPS] $1${NC}"
  echo -e "${DIM}$2${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

installed() {
  echo -e "  ${GREEN}✓${NC} $1 ${DIM}($2)${NC}"
  INSTALLED+=("$1")
}

skipped() {
  echo -e "  ${YELLOW}→${NC} $1 ${DIM}(already installed)${NC}"
  SKIPPED+=("$1")
}

warn() {
  echo -e "  ${YELLOW}!${NC} $1"
}

fail() {
  echo -e "  ${RED}✗${NC} $1"
  FAILED+=("$1")
}

has_cmd() {
  command -v "$1" &> /dev/null
}

has_cask() {
  brew list --cask "$1" &> /dev/null 2>&1
}

has_formula() {
  brew list "$1" &> /dev/null 2>&1
}

brew_install() {
  local name="$1"
  local desc="$2"
  if has_formula "$name"; then
    skipped "$name"
  else
    brew install "$name" > /dev/null 2>&1 && installed "$name" "$desc" || fail "$name"
  fi
}

brew_install_cask() {
  local name="$1"
  local desc="$2"
  if has_cask "$name"; then
    skipped "$name"
  else
    brew install --cask "$name" > /dev/null 2>&1 && installed "$name" "$desc" || fail "$name"
  fi
}

ask() {
  echo ""
  echo -e "${CYAN}?${NC} $1"
  echo -e "  ${DIM}$2${NC}"
  read -p "  Install? [Y/n] " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]
}

# ── Audit Table ──────────────────────────────────────────────────
show_audit() {
  echo ""
  echo -e "${BOLD}Full audit of everything this script installs:${NC}"
  echo ""
  echo -e "${BOLD}┌────────────────────┬──────────────────────┬────────────────────────────────────────────┬──────────┐${NC}"
  echo -e "${BOLD}│ Tool               │ Source               │ What it does                               │ Required │${NC}"
  echo -e "${BOLD}├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤${NC}"
  echo -e "│ ${CYAN}xcode-select${NC}      │ Apple                │ git, clang, make — needed by everything    │ yes      │"
  echo -e "│ ${CYAN}homebrew${NC}          │ brew.sh              │ macOS package manager                      │ yes      │"
  echo -e "├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤"
  echo -e "│ ${CYAN}ghostty${NC}           │ ghostty.org          │ GPU-accelerated terminal (Zig)             │ yes      │"
  echo -e "│ ${CYAN}starship${NC}          │ starship.rs          │ Fast shell prompt (Rust)                   │ yes      │"
  echo -e "│ ${CYAN}JetBrains Mono${NC}    │ Nerd Fonts           │ Monospace font with ligatures + icons      │ yes      │"
  echo -e "├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤"
  echo -e "│ ${CYAN}ripgrep${NC}           │ github/BurntSushi    │ grep replacement, 100x faster              │ yes      │"
  echo -e "│ ${CYAN}bat${NC}               │ github/sharkdp       │ cat with syntax highlighting               │ yes      │"
  echo -e "│ ${CYAN}eza${NC}               │ github/eza-community │ ls with icons, git status, tree            │ yes      │"
  echo -e "│ ${CYAN}fd${NC}                │ github/sharkdp       │ find replacement, simpler + faster          │ yes      │"
  echo -e "│ ${CYAN}zoxide${NC}            │ github/ajeetdsouza   │ Smart cd — learns your directories         │ yes      │"
  echo -e "│ ${CYAN}fzf${NC}               │ github/junegunn      │ Fuzzy finder for files, history, branches  │ yes      │"
  echo -e "│ ${CYAN}git-delta${NC}         │ github/dandavison     │ Beautiful syntax-highlighted git diffs      │ yes      │"
  echo -e "│ ${CYAN}lazygit${NC}           │ github/jesseduffield  │ Terminal UI for git                        │ yes      │"
  echo -e "├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤"
  echo -e "│ ${CYAN}atuin${NC}             │ atuin.sh             │ Shell history search, syncs across machines │ yes      │"
  echo -e "│ ${CYAN}httpie${NC}            │ httpie.io            │ Human-friendly HTTP client                 │ yes      │"
  echo -e "│ ${CYAN}jq${NC}               │ jqlang.github.io     │ Command-line JSON processor                │ yes      │"
  echo -e "│ ${CYAN}yazi${NC}              │ github/sxyazi        │ Terminal file manager with preview          │ yes      │"
  echo -e "│ ${CYAN}hyperfine${NC}         │ github/sharkdp       │ CLI benchmarking tool                      │ yes      │"
  echo -e "│ ${CYAN}lazydocker${NC}        │ github/jesseduffield  │ Terminal UI for Docker                     │ yes      │"
  echo -e "│ ${CYAN}tldr${NC}              │ tldr.sh              │ Simplified man pages with examples         │ yes      │"
  echo -e "│ ${CYAN}btop${NC}              │ github/aristocratos   │ System monitor (CPU, mem, disk, network)   │ yes      │"
  echo -e "│ ${CYAN}dust${NC}              │ github/bootandy      │ Disk usage analyzer                        │ yes      │"
  echo -e "│ ${CYAN}dive${NC}              │ github/wagoodman      │ Docker image layer inspector               │ yes      │"
  echo -e "│ ${CYAN}gh${NC}                │ cli.github.com       │ GitHub CLI — PRs, issues, CI from terminal │ yes      │"
  echo -e "│ ${CYAN}just${NC}              │ github/casey          │ Modern command runner (replaces make)       │ yes      │"
  echo -e "│ ${CYAN}raycast${NC}           │ raycast.com          │ App launcher, clipboard, window management  │ ${YELLOW}asks${NC}     │"
  echo -e "├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤"
  echo -e "│ ${CYAN}mise${NC}              │ mise.jdx.dev         │ Version manager (replaces nvm/pyenv/rbenv) │ yes      │"
  echo -e "│ ${CYAN}node 24 LTS${NC}       │ nodejs.org (via mise)│ JavaScript runtime                         │ yes      │"
  echo -e "│ ${CYAN}pnpm${NC}              │ pnpm.io              │ Fast, strict JS package manager             │ yes      │"
  echo -e "│ ${CYAN}bun${NC}               │ bun.sh               │ Fast JS runtime + bundler + test runner     │ ${YELLOW}asks${NC}     │"
  echo -e "│ ${CYAN}python 3.12${NC}       │ python.org (via mise)│ Python runtime                             │ ${YELLOW}asks${NC}     │"
  echo -e "│ ${CYAN}uv${NC}                │ astral.sh            │ Fast Python package manager (Rust)          │ ${YELLOW}asks${NC}     │"
  echo -e "│ ${CYAN}ruff${NC}              │ astral.sh            │ Fast Python linter (Rust)                   │ ${YELLOW}asks${NC}     │"
  echo -e "├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤"
  echo -e "│ ${CYAN}docker${NC}            │ docker.com           │ Containerization platform                  │ ${YELLOW}asks${NC}     │"
  echo -e "│ ${CYAN}claude-code${NC}       │ anthropic (via npm)  │ CLI AI coding agent                        │ yes      │"
  echo -e "├────────────────────┼──────────────────────┼────────────────────────────────────────────┼──────────┤"
  echo -e "│ ${CYAN}nexus CLI${NC}         │ this repo            │ Session launcher — assembles prompts        │ yes      │"
  echo -e "${BOLD}└────────────────────┴──────────────────────┴────────────────────────────────────────────┴──────────┘${NC}"
  echo ""
  echo -e "${BOLD}Configs written${NC} ${DIM}(only if file doesn't already exist)${NC}${BOLD}:${NC}"
  echo ""
  echo -e "  ${CYAN}~/.config/ghostty/config${NC}          Terminal: Catppuccin theme, splits, transparency"
  echo -e "  ${CYAN}~/.config/ghostty/themes/${NC}         Catppuccin Mocha (downloaded from GitHub)"
  echo -e "  ${CYAN}~/.config/starship.toml${NC}           Prompt: minimal, gcloud/aws disabled"
  echo -e "  ${CYAN}~/.config/mise/config.toml${NC}        Versions: node@24, python@3.12, auto_install"
  echo -e "  ${CYAN}~/.gitconfig${NC}                      Git: delta pager, rebase, rerere, side-by-side"
  echo -e "  ${CYAN}~/.zshrc${NC} ${DIM}(appended)${NC}              Aliases, tool integrations, yazi function"
  echo ""
  echo -e "${BOLD}Nothing is installed without your knowledge.${NC}"
  echo -e "Items marked ${YELLOW}asks${NC} will prompt you before installing."
  echo -e "Already-installed tools are skipped automatically."
  echo ""
  echo -e "${DIM}Source code: https://github.com/teo-eb/nexus/blob/main/bootstrap.sh${NC}"
  echo ""
}

# ── Welcome ──────────────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║           Machine Bootstrap — Dev Environment            ║${NC}"
echo -e "${BOLD}║              Last approved by Teo: 2026-04-11            ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║${NC}                                                          ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  This script sets up a complete dev environment:          ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}                                                          ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    1.  Xcode CLI Tools     ${DIM}(git, compilers)${NC}              ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    2.  Homebrew             ${DIM}(package manager)${NC}             ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    3.  Ghostty + config     ${DIM}(terminal emulator)${NC}           ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    4.  Modern CLI tools     ${DIM}(ripgrep, bat, eza, etc.)${NC}     ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    5.  Advanced CLI tools   ${DIM}(httpie, yazi, btop, etc.)${NC}    ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    6.  mise                 ${DIM}(version manager)${NC}             ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    7.  Node + pnpm + Bun    ${DIM}(JS runtimes & packages)${NC}     ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    8.  Python + uv + Ruff   ${DIM}(Python toolchain)${NC}           ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}    9.  Docker Desktop       ${DIM}(containerization)${NC}            ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   10.  Claude Code          ${DIM}(CLI AI agent)${NC}                ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   11.  Git config           ${DIM}(delta, rebase, rerere)${NC}       ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   12.  Shell config         ${DIM}(aliases, prompt, tools)${NC}      ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}                                                          ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${GREEN}Safe to re-run — skips anything already installed.${NC}      ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${YELLOW}Optional steps will ask before installing.${NC}              ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}                                                          ${BOLD}║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Press ${BOLD}Enter${NC} to start    ${DIM}│${NC}    Press ${BOLD}i${NC} to inspect everything first"
read -n 1 -r
echo ""

if [[ $REPLY == "i" || $REPLY == "I" ]]; then
  show_audit
  echo -e "  Press ${BOLD}Enter${NC} to continue with install    ${DIM}│${NC}    ${BOLD}Ctrl+C${NC} to cancel"
  read -r
fi

# ═════════════════════════════════════════════════════════════════
# STEP 1: Xcode Command Line Tools
# ═════════════════════════════════════════════════════════════════
step "Xcode Command Line Tools" "Provides git, clang, make, and other compilers. Required by almost everything else."

if xcode-select -p &> /dev/null; then
  skipped "xcode-select"
else
  echo "  Installing Xcode CLI tools (this opens a system dialog)..."
  xcode-select --install
  echo ""
  read -p "  Press Enter after the Xcode installer finishes..."
  installed "xcode-select" "compilers, git, make"
fi

# ═════════════════════════════════════════════════════════════════
# STEP 2: Homebrew
# ═════════════════════════════════════════════════════════════════
step "Homebrew" "macOS package manager. Installs everything else. https://brew.sh"

if has_cmd brew; then
  skipped "homebrew"
  echo "  Updating brew..."
  brew update > /dev/null 2>&1
else
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to PATH for this session
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Persist for future sessions (only if not already there)
  if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
  installed "homebrew" "package manager"
fi

# ═════════════════════════════════════════════════════════════════
# STEP 3: Terminal + Prompt + Font
# ═════════════════════════════════════════════════════════════════
step "Terminal: Ghostty + Starship + Font" "GPU-accelerated terminal (Zig), fast prompt (Rust), icon font for the shell."

brew_install_cask "ghostty" "GPU-accelerated terminal by Mitchell Hashimoto"
brew_install "starship" "cross-shell prompt — shows git, node, python versions"
brew_install_cask "font-jetbrains-mono-nerd-font" "monospace font with ligatures + icons"

# Ghostty config (only write if no config exists yet)
if [ ! -f ~/.config/ghostty/config ]; then
  echo "  Writing Ghostty config + Catppuccin theme..."
  mkdir -p ~/.config/ghostty/themes
  curl -so ~/.config/ghostty/themes/catppuccin-mocha \
    https://raw.githubusercontent.com/catppuccin/ghostty/main/themes/catppuccin-mocha
  cat > ~/.config/ghostty/config << 'GHOSTTY'
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
GHOSTTY
  installed "ghostty config" "catppuccin-mocha, splits, transparency"
else
  skipped "ghostty config"
fi

# ═════════════════════════════════════════════════════════════════
# STEP 4: Essential CLI Tools
# ═════════════════════════════════════════════════════════════════
step "Essential CLI Tools" "Modern Rust/Go replacements for grep, cat, ls, find, cd, git. 10-100x faster."

brew_install "fzf"       "fuzzy finder — search files, history, branches"
brew_install "ripgrep"   "rg — grep but 100x faster, respects .gitignore"
brew_install "bat"       "cat with syntax highlighting + line numbers"
brew_install "eza"       "ls with icons, colors, git status, tree view"
brew_install "zoxide"    "smart cd — learns your directories, jump with partial names"
brew_install "git-delta" "beautiful syntax-highlighted git diffs"
brew_install "lazygit"   "terminal UI for git — stage, rebase, resolve conflicts visually"
brew_install "fd"        "find but simpler + faster, respects .gitignore"

# ═════════════════════════════════════════════════════════════════
# STEP 5: Advanced CLI Tools
# ═════════════════════════════════════════════════════════════════
step "Advanced CLI Tools" "Power tools for API testing, monitoring, Docker, benchmarks, file management."

brew_install "atuin"       "shell history search — full-text, syncs across machines"
brew_install "httpie"      "human-friendly HTTP client — replaces curl for API testing"
brew_install "jq"          "command-line JSON processor — filter, transform, extract"
brew_install "yazi"        "terminal file manager — preview images, bulk rename"
brew_install "hyperfine"   "CLI benchmarking — compare command performance"
brew_install "lazydocker"  "terminal UI for Docker — logs, restart, shell into containers"
brew_install "tldr"        "simplified man pages with practical examples"
brew_install "btop"        "beautiful system monitor — CPU, memory, disk, network"
brew_install "dust"        "disk usage analyzer — visual, sorted, fast"
brew_install "dive"        "Docker image layer inspector — find bloat"
brew_install "gh"          "GitHub CLI — create PRs, check CI, manage issues from terminal"
brew_install "just"        "modern command runner — replaces Makefiles with simpler syntax"

# Raycast (optional — replaces Spotlight, Rectangle, clipboard managers)
if ! has_cask raycast; then
  if ask "Raycast (macOS app launcher)" "Spotlight replacement with clipboard history, window management, snippets. Free tier is generous."; then
    brew_install_cask "raycast" "Spotlight replacement with superpowers"
  fi
fi

# ═════════════════════════════════════════════════════════════════
# STEP 6: Version Manager (mise)
# ═════════════════════════════════════════════════════════════════
step "mise — Version Manager" "One tool for all runtimes (Node, Python, Go, etc). Replaces nvm + pyenv + rbenv."

brew_install "mise" "polyglot version manager — manages runtimes, env vars, tasks"

# Write a global mise config if one doesn't exist
if [ ! -f ~/.config/mise/config.toml ]; then
  mkdir -p ~/.config/mise
  cat > ~/.config/mise/config.toml << 'MISE'
# Global mise config — tool versions used when no project .mise.toml exists
# Override per-project by creating .mise.toml in the project root.

[tools]
node = "24"
python = "3.12"

[settings]
# Automatically install missing tools when cd'ing into a project
auto_install = true
MISE
  installed "mise global config" "node@24, python@3.12, auto_install"
else
  skipped "mise global config"
fi

# ═════════════════════════════════════════════════════════════════
# STEP 7: JavaScript Runtimes + Packages
# ═════════════════════════════════════════════════════════════════
step "JavaScript: Node + pnpm + Bun" "Node 24 LTS via mise, pnpm for monorepos, Bun for speed."

# Activate mise for this session
if has_cmd mise; then
  eval "$(mise activate bash)"

  # Node.js
  if mise ls node 2>/dev/null | grep -q "24"; then
    skipped "node@24"
  else
    echo "  Installing Node.js 24 LTS via mise..."
    mise use --global node@24 > /dev/null 2>&1 && installed "node@24" "LTS — also 22 LTS available" || fail "node@24"
  fi

  # pnpm
  if has_cmd pnpm; then
    skipped "pnpm"
  else
    echo "  Installing pnpm..."
    npm install -g pnpm > /dev/null 2>&1 && installed "pnpm" "fast, strict, disk-efficient package manager" || fail "pnpm"
  fi
else
  warn "mise not found — skipping Node/pnpm install. Install mise first."
fi

# Bun
if has_cmd bun; then
  skipped "bun"
else
  if ask "Bun (JavaScript runtime)" "3x faster HTTP, native TypeScript, 25x faster installs. Best for new greenfield projects."; then
    curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1 && installed "bun" "fast JS runtime + bundler + test runner" || fail "bun"
  fi
fi

# ═════════════════════════════════════════════════════════════════
# STEP 8: Python Toolchain
# ═════════════════════════════════════════════════════════════════
step "Python: uv + Ruff" "uv replaces pip/venv/pyenv (10-100x faster). Ruff replaces pylint/flake8 (100x faster)."

# Python via mise
if has_cmd mise; then
  if mise ls python 2>/dev/null | grep -q "3.12"; then
    skipped "python@3.12"
  else
    if ask "Python 3.12 (via mise)" "Managed by mise — no system Python conflicts."; then
      mise use --global python@3.12 > /dev/null 2>&1 && installed "python@3.12" "via mise" || fail "python@3.12"
    fi
  fi
fi

# uv
if has_cmd uv; then
  skipped "uv"
else
  if ask "uv (Python package manager by Astral)" "10-100x faster than pip. Also replaces venv and pyenv."; then
    curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1 && installed "uv" "fast Python package/project manager" || fail "uv"
  fi
fi

# Ruff
if has_cmd ruff; then
  skipped "ruff"
else
  if has_cmd uv; then
    if ask "Ruff (Python linter by Astral)" "100x faster than pylint. Same team as uv."; then
      uv tool install ruff > /dev/null 2>&1 && installed "ruff" "fast Python linter + formatter" || fail "ruff"
    fi
  fi
fi

# ═════════════════════════════════════════════════════════════════
# STEP 9: Docker
# ═════════════════════════════════════════════════════════════════
step "Docker Desktop" "Run Postgres, Redis, and other services in containers. Your app runs locally, infra runs in Docker."

if has_cask docker || has_cmd docker; then
  skipped "docker"
else
  if ask "Docker Desktop" "Required for local databases (Postgres, Redis). You'll manage containers with lazydocker."; then
    brew_install_cask "docker" "containerization platform"
    warn "Docker Desktop needs to be opened manually the first time to finish setup."
  fi
fi

# ═════════════════════════════════════════════════════════════════
# STEP 10: Claude Code
# ═════════════════════════════════════════════════════════════════
step "Claude Code" "Anthropic's CLI agent. Terminal-first, hooks for verification, 1M context, MCP servers."

if has_cmd claude; then
  skipped "claude-code"
else
  if has_cmd npm; then
    echo "  Installing Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code > /dev/null 2>&1 && installed "claude-code" "CLI AI agent by Anthropic" || fail "claude-code"
  else
    warn "npm not found — install Node.js first, then run: npm install -g @anthropic-ai/claude-code"
  fi
fi

# ═════════════════════════════════════════════════════════════════
# STEP 11: Git Config
# ═════════════════════════════════════════════════════════════════
step "Git Config" "delta for beautiful diffs, rebase on pull, auto-setup remote, rerere for conflict memory."

# These are safe to set even if already set (idempotent)
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true
installed "git config" "delta pager, rebase, rerere"

# Only prompt for identity if not already set
if [ -z "$(git config --global user.name)" ]; then
  echo ""
  read -p "  Git name (for commits): " git_name
  git config --global user.name "$git_name"
fi
if [ -z "$(git config --global user.email)" ]; then
  read -p "  Git email (for commits): " git_email
  git config --global user.email "$git_email"
fi

# ═════════════════════════════════════════════════════════════════
# STEP 12: Shell Config
# ═════════════════════════════════════════════════════════════════
step "Shell Config" "Aliases, tool integrations, prompt. Appended to ~/.zshrc."

# Only append if we haven't already (check for our marker comment)
if grep -q "# === Nexus Shell Config ===" ~/.zshrc 2>/dev/null; then
  skipped "shell config (already in ~/.zshrc)"
else
  echo "  Appending shell config to ~/.zshrc..."
  cat >> ~/.zshrc << 'ZSHRC'

# === Nexus Shell Config ===
# Generated by bootstrap.sh — edit freely, but keep the marker above
# so re-running bootstrap doesn't duplicate this block.

# ── Tool Integrations ────────────────────────────────────────
eval "$(starship init zsh)"      # prompt
eval "$(mise activate zsh)"      # version manager
eval "$(zoxide init zsh --cmd cd)"  # smart cd (works as normal cd too)
source <(fzf --zsh)              # fuzzy finder
eval "$(atuin init zsh)"         # shell history

# ── Aliases: Essentials ──────────────────────────────────────
alias cat="bat"
alias ls="eza --icons"
alias ll="eza -l --git --icons"
alias la="eza -la --git --icons"
alias tree="eza --tree --icons --level=3"
alias grep="rg"
alias find="fd"
alias lg="lazygit"
alias lzd="lazydocker"
alias top="btop"
alias du="dust"

# ── Aliases: Dev Shortcuts ───────────────────────────────────
alias preview="fzf --preview 'bat --color=always {}'"
alias api="http localhost:3000/api"
alias apih="http localhost:3000/api/health"
alias json="jq ."
alias jsonkeys="jq 'keys'"
alias jsonflat="jq '[paths(scalars)]'"
alias dev="cd ~/dev"

# ── Functions ────────────────────────────────────────────────
# yazi: cd into the directory you were browsing when you quit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# === End Nexus Shell Config ===
ZSHRC
  installed "shell config" "aliases, integrations, yazi function"
fi

# Starship config (only write if no config exists)
if [ ! -f ~/.config/starship.toml ]; then
  mkdir -p ~/.config
  cat > ~/.config/starship.toml << 'STARSHIP'
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
min_time = 2_000
format = "[$duration]($style) "
STARSHIP
  installed "starship config" "minimal prompt"
else
  skipped "starship config"
fi

# Dev directory
mkdir -p ~/dev

# nexus CLI — symlink into PATH
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/nexus" ]; then
  mkdir -p ~/.local/bin
  ln -sf "$SCRIPT_DIR/nexus" ~/.local/bin/nexus
  installed "nexus" "session launcher CLI — run 'nexus' from anywhere"
fi

# ═════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    Setup Complete                     ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ${#INSTALLED[@]} -gt 0 ]; then
  echo -e "${GREEN}Installed (${#INSTALLED[@]}):${NC}"
  for item in "${INSTALLED[@]}"; do
    echo -e "  ${GREEN}✓${NC} $item"
  done
  echo ""
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo -e "${YELLOW}Already installed (${#SKIPPED[@]}):${NC}"
  for item in "${SKIPPED[@]}"; do
    echo -e "  ${YELLOW}→${NC} $item"
  done
  echo ""
fi

if [ ${#FAILED[@]} -gt 0 ]; then
  echo -e "${RED}Failed (${#FAILED[@]}):${NC}"
  for item in "${FAILED[@]}"; do
    echo -e "  ${RED}✗${NC} $item"
  done
  echo ""
fi

echo -e "${BOLD}Next steps:${NC}"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
if has_cask docker 2>/dev/null; then
  echo "  2. Open Docker Desktop (first launch needs manual start)"
fi
if has_cmd claude; then
  echo "  3. Run 'claude' to set up your Anthropic API key"
fi
echo ""
echo -e "${BOLD}Your toolkit:${NC}"
echo -e "  ${CYAN}Terminal${NC}    ghostty          ${CYAN}Git TUI${NC}     lg (lazygit)"
echo -e "  ${CYAN}AI Agent${NC}   claude           ${CYAN}Docker TUI${NC}  lzd (lazydocker)"
echo -e "  ${CYAN}Search${NC}     rg (ripgrep)     ${CYAN}Monitor${NC}     btop (or: top)"
echo -e "  ${CYAN}Navigate${NC}   cd (zoxide)      ${CYAN}Disk${NC}        dust (or: du)"
echo -e "  ${CYAN}Find${NC}       fd + fzf         ${CYAN}Files${NC}       y (yazi)"
echo -e "  ${CYAN}API Test${NC}   http (httpie)    ${CYAN}GitHub${NC}      gh"
echo -e "  ${CYAN}JSON${NC}       jq               ${CYAN}History${NC}     atuin (ctrl+r)"
echo -e "  ${CYAN}Benchmark${NC}  hyperfine        ${CYAN}Man Pages${NC}   tldr"
echo -e "  ${CYAN}Launcher${NC}   nexus            ${CYAN}Tasks${NC}       just"
echo ""
echo -e "${DIM}Last approved by Teo: 2026-04-11 | Reference: The Developer Machine note${NC}"
echo ""
