# Template — Machine Bootstrap

> One script. Fresh Mac to fully operational dev environment in under 15 minutes. Run this on day 1.

---

## The Script

Save as `~/bootstrap.sh` and run with `bash bootstrap.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Setting up dev machine..."

# ============================================
# 1. Xcode Command Line Tools (git, make, etc)
# ============================================
if ! xcode-select -p &> /dev/null; then
  echo "Installing Xcode CLI tools..."
  xcode-select --install
  read -p "Press enter after Xcode tools finish installing..."
fi

# ============================================
# 2. Homebrew
# ============================================
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ============================================
# 3. Terminal + Shell Tools
# ============================================
echo "Installing terminal and shell tools..."
brew install --cask ghostty           # Terminal emulator
brew install starship                  # Shell prompt
brew install --cask font-jetbrains-mono-nerd-font  # Font with icons

# Ghostty config + Catppuccin theme
mkdir -p ~/.config/ghostty/themes
curl -o ~/.config/ghostty/themes/catppuccin-mocha \
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

# ============================================
# 4. Modern CLI Replacements
# ============================================
echo "Installing modern CLI tools..."
brew install \
  fzf \
  ripgrep \
  bat \
  eza \
  zoxide \
  git-delta \
  lazygit \
  fd \
  httpie \
  jq \
  atuin \
  lazydocker \
  tldr \
  btop \
  yazi \
  hyperfine \
  dust \
  dive

# ============================================
# 5. Version Manager (mise)
# ============================================
echo "Installing mise..."
brew install mise

# ============================================
# 6. Runtime + Package Managers
# ============================================
echo "Installing runtimes..."
eval "$(mise activate zsh)"
mise use --global node@24
mise use --global python@3.12

# pnpm (JS package manager)
npm install -g pnpm

# Bun (fast JS runtime)
curl -fsSL https://bun.sh/install | bash

# uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Ruff (Python linter — same team as uv)
uv tool install ruff

# ============================================
# 7. Docker
# ============================================
echo "Installing Docker..."
brew install --cask docker
# Note: Docker Desktop needs to be opened manually the first time

# ============================================
# 8. Editor
# ============================================
echo "Installing editors..."
brew install --cask cursor            # AI-native IDE
# brew install --cask visual-studio-code  # Uncomment if preferred

# ============================================
# 9. Claude Code
# ============================================
echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

# ============================================
# 10. Git Config
# ============================================
echo "Configuring git..."
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true

# Prompt for identity if not set
if [ -z "$(git config --global user.name)" ]; then
  read -p "Git name: " git_name
  git config --global user.name "$git_name"
fi
if [ -z "$(git config --global user.email)" ]; then
  read -p "Git email: " git_email
  git config --global user.email "$git_email"
fi

# ============================================
# 11. Shell Config
# ============================================
echo "Configuring shell..."
cat >> ~/.zshrc << 'ZSHRC'

# === Builder's Brain Shell Config ===

# Starship prompt
eval "$(starship init zsh)"

# mise (version manager)
eval "$(mise activate zsh)"

# zoxide (smart cd)
eval "$(zoxide init zsh)"

# fzf (fuzzy finder)
source <(fzf --zsh)

# atuin (shell history)
eval "$(atuin init zsh)"

# Modern aliases — essentials
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

# fzf preview
alias preview="fzf --preview 'bat --color=always {}'"

# httpie shortcuts for local dev
alias api="http localhost:3000/api"
alias apih="http localhost:3000/api/health"

# jq shortcuts
alias json="jq ."
alias jsonkeys="jq 'keys'"

# yazi — cd into the directory you were browsing when you quit
function y() {
  local tmp="\$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "\$@" --cwd-file="\$tmp"
  if cwd="\$(command cat -- "\$tmp")" && [ -n "\$cwd" ] && [ "\$cwd" != "\$PWD" ]; then
    builtin cd -- "\$cwd"
  fi
  rm -f -- "\$tmp"
}

# Quick project navigation
alias dev="cd ~/dev"
ZSHRC

# ============================================
# 12. Starship Config
# ============================================
mkdir -p ~/.config
cat > ~/.config/starship.toml << 'STARSHIP'
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
min_time = 2_000
format = "[$duration]($style) "
STARSHIP

# ============================================
# 13. Create dev directory
# ============================================
mkdir -p ~/dev

# ============================================
# Done
# ============================================
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Open Docker Desktop (first launch requires manual start)"
echo "  3. Open Ghostty — config and theme are already set up"
echo "  4. Run 'claude' to set up Claude Code API key"
echo "  5. Start building: cd ~/dev && mkdir my-project && cd my-project"
echo ""
echo "Your tools:"
echo "  Terminal:  ghostty"
echo "  Editor:    cursor"
echo "  Git TUI:   lg (lazygit)"
echo "  Docker:    lzd (lazydocker)"
echo "  AI Agent:  claude (Claude Code)"
echo "  Search:    rg (ripgrep)"
echo "  Navigate:  z (zoxide)"
echo "  Find:      fzf, fd"
echo ""
```

---

## After Bootstrap

1. **Verify everything works:** `node --version && python --version && bun --version && uv --version && docker --version`
2. **Clone your dotfiles** if you have them, overwrite the defaults above
3. **Open Docker Desktop** — it needs a one-time manual launch to finish setup
4. **Set up Claude Code:** run `claude` and follow the API key setup
5. **Start your first project** using [[Template — Monorepo Scaffold]]

## Maintaining Your Setup

- **Store this script in a git repo** along with your dotfiles
- **Update quarterly** during your [[Template — Weekly Tools Review|weekly tools review]]
- **Test on a fresh account** occasionally (macOS guest user) to make sure it still works

---

## Related
- [[The Developer Machine]] — rationale behind each tool choice
- [[Version and Runtime Management]] — deep dive on mise, uv, Bun
- [[Template — Monorepo Scaffold]] — next step after machine setup

---

#templates #machine-setup #bootstrap
