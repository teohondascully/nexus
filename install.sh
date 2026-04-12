#!/bin/bash
# ================================================================
# Nexus — Install, update, or uninstall
#
# Usage:
#   curl -fsSL https://www.teonnaise.com/install | bash
#   curl -fsSL https://www.teonnaise.com/install | bash -s -- --uninstall
# ================================================================
set -e

# ── Config ───────────────────────────────────────────────────────
REPO="https://github.com/teohondascully/nexus.git"
INSTALL_DIR="$HOME/.nexus"
BIN_DIR="$HOME/.local/bin"

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Uninstall ────────────────────────────────────────────────────
if [ "${1:-}" = "--uninstall" ]; then
  echo ""
  echo -e "  ${BOLD}nexus uninstall${NC}"
  echo ""

  if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  Nexus is not installed."
    exit 0
  fi

  echo -e "  This will remove:"
  echo -e "    ${DIM}~/.nexus${NC}              (nexus vault + CLI)"
  echo -e "    ${DIM}~/.local/bin/nexus${NC}    (CLI symlink)"
  echo ""
  echo -e "  This will ${BOLD}not${NC} remove:"
  echo -e "    Tools installed by bootstrap (brew packages, mise, etc.)"
  echo -e "    Config files (~/.zshrc, ~/.gitconfig, ~/.config/)"
  echo -e "    Any project files created by nexus init"
  echo ""

  printf "  Remove nexus? [y/N]: "
  read -r confirm < /dev/tty
  if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "  Cancelled."
    exit 0
  fi

  rm -rf "$INSTALL_DIR"
  rm -f "$BIN_DIR/nexus"
  echo -e "  ${GREEN}Removed.${NC}"
  echo ""

  # Offer to uninstall bootstrap packages
  echo -e "  Want to also uninstall packages installed by bootstrap?"
  printf "  [y/N]: "
  read -r uninstall_packages < /dev/tty

  if [[ $uninstall_packages =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "  Select which to uninstall ${DIM}(space-separated numbers, or 'all')${NC}:"
    echo ""

    PACKAGES=(
      "ghostty:brew uninstall --cask ghostty"
      "starship:brew uninstall starship"
      "font-jetbrains-mono-nerd-font:brew uninstall --cask font-jetbrains-mono-nerd-font"
      "zsh-autosuggestions:brew uninstall zsh-autosuggestions"
      "zsh-syntax-highlighting:brew uninstall zsh-syntax-highlighting"
      "ripgrep:brew uninstall ripgrep"
      "bat:brew uninstall bat"
      "eza:brew uninstall eza"
      "fd:brew uninstall fd"
      "zoxide:brew uninstall zoxide"
      "fzf:brew uninstall fzf"
      "git-delta:brew uninstall git-delta"
      "lazygit:brew uninstall lazygit"
      "atuin:brew uninstall atuin"
      "httpie:brew uninstall httpie"
      "jq:brew uninstall jq"
      "yazi:brew uninstall yazi"
      "hyperfine:brew uninstall hyperfine"
      "lazydocker:brew uninstall lazydocker"
      "tldr:brew uninstall tldr"
      "btop:brew uninstall btop"
      "dust:brew uninstall dust"
      "dive:brew uninstall dive"
      "gh:brew uninstall gh"
      "just:brew uninstall just"
      "lefthook:brew uninstall lefthook"
      "mise:brew uninstall mise"
      "claude-code:npm uninstall -g @anthropic-ai/claude-code"
    )

    for i in "${!PACKAGES[@]}"; do
      local_name="${PACKAGES[$i]%%:*}"
      printf "  %2d  %s\n" "$((i + 1))" "$local_name"
    done
    echo ""
    printf "  Choices: "
    read -r choices < /dev/tty

    if [ "$choices" = "all" ]; then
      choices=$(seq 1 ${#PACKAGES[@]} | tr '\n' ' ')
    fi

    echo ""
    for num in $choices; do
      idx=$((num - 1))
      if [ $idx -ge 0 ] && [ $idx -lt ${#PACKAGES[@]} ]; then
        pkg_name="${PACKAGES[$idx]%%:*}"
        pkg_cmd="${PACKAGES[$idx]#*:}"
        printf "  Removing %s... " "$pkg_name"
        if eval "$pkg_cmd" > /dev/null 2>&1; then
          echo -e "${GREEN}done${NC}"
        else
          echo -e "${YELLOW}skipped${NC} (not installed or failed)"
        fi
      fi
    done

    echo ""
    echo -e "  ${DIM}Note: Homebrew itself was not removed. Run 'brew --help' to uninstall it.${NC}"
    echo -e "  ${DIM}Shell config (~/.zshrc additions) was not removed. Edit manually if needed.${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Done.${NC}"
  echo ""
  exit 0
fi

# ── Preflight ────────────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}Error: Nexus currently supports macOS only.${NC}"
  exit 1
fi

if ! command -v git &> /dev/null; then
  echo "Git not found. Installing Xcode CLI tools..."
  xcode-select --install
  echo ""
  printf "Press Enter after Xcode tools finish installing..."
  read -r _ < /dev/tty
fi

# ── Install or Update ────────────────────────────────────────────

if [ -d "$INSTALL_DIR/.git" ]; then
  # Already installed — check for updates
  LOCAL_VERSION=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")

  # Fetch latest without merging
  git -C "$INSTALL_DIR" fetch --quiet origin main 2>/dev/null || true
  REMOTE_VERSION=$(git -C "$INSTALL_DIR" show origin/main:VERSION 2>/dev/null || echo "unknown")

  if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
    echo ""
    echo -e "  ${GREEN}Nexus is up to date${NC} (v${LOCAL_VERSION})."
    echo ""
    exit 0
  fi

  echo ""
  echo -e "  ${BOLD}Nexus update available${NC}"
  echo -e "  ${DIM}v${LOCAL_VERSION}${NC} → ${GREEN}v${REMOTE_VERSION}${NC}"
  echo ""
  echo -e "  ${BOLD}1${NC}  Update nexus only ${DIM}(pull latest, re-link CLI)${NC}"
  echo -e "  ${BOLD}2${NC}  Full reinstall ${DIM}(re-run bootstrap — installs missing packages)${NC}"
  echo -e "  ${BOLD}3${NC}  Cancel"
  echo ""
  printf "  [1/2/3]: "
  read -r update_choice < /dev/tty

  case $update_choice in
    1)
      echo ""
      echo "  Pulling latest..."
      git -C "$INSTALL_DIR" pull --ff-only --quiet 2>/dev/null || {
        echo -e "  ${YELLOW}Pull failed. Trying reset...${NC}"
        git -C "$INSTALL_DIR" reset --hard origin/main --quiet
      }
      # Re-symlink
      mkdir -p "$BIN_DIR"
      ln -sf "$INSTALL_DIR/nexus" "$BIN_DIR/nexus"
      NEW_VERSION=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")
      echo -e "  ${GREEN}Updated to v${NEW_VERSION}.${NC}"
      echo ""
      exit 0
      ;;
    2)
      echo "  Pulling latest..."
      git -C "$INSTALL_DIR" pull --ff-only --quiet 2>/dev/null || {
        git -C "$INSTALL_DIR" reset --hard origin/main --quiet
      }
      # Fall through to bootstrap
      ;;
    *)
      echo "  Cancelled."
      exit 0
      ;;
  esac
else
  # Fresh install
  git clone --quiet "$REPO" "$INSTALL_DIR"
fi

# ── Hand off to bootstrap ───────────────────────────────────────

if [ -f "$INSTALL_DIR/bootstrap.sh" ]; then
  exec bash "$INSTALL_DIR/bootstrap.sh"
else
  echo -e "${RED}Error: bootstrap.sh not found in ${INSTALL_DIR}${NC}"
  exit 1
fi
