#!/bin/bash
# ================================================================
# Nexus — One-command dev environment setup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/teohondascully/nexus/main/install.sh | bash
#
# What this does:
#   1. Clones the Nexus vault to ~/.nexus
#   2. Runs the bootstrap script (installs tools + configs)
#   3. Symlinks the nexus CLI into your PATH
#
# Safe to re-run: pulls latest if already cloned, bootstrap skips
# anything already installed.
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

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║         Nexus — Dev Environment          ║${NC}"
echo -e "${BOLD}║        https://github.com/teohondascully/nexus   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "This will install Nexus to ${BOLD}~/.nexus${NC} and run bootstrap."
echo ""
if [ -t 0 ]; then
  read -p "Press Enter to continue (or Ctrl-C to cancel)..."
else
  printf "Press Enter to continue (or Ctrl-C to cancel)..."
  read -r _ < /dev/tty
fi

echo ""

# ── Preflight ────────────────────────────────────────────────────

# macOS only (for now)
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}Error: Nexus currently supports macOS only.${NC}"
  exit 1
fi

# Need git
if ! command -v git &> /dev/null; then
  echo -e "${YELLOW}Git not found. Installing Xcode CLI tools...${NC}"
  xcode-select --install
  echo ""
  read -p "Press Enter after Xcode tools finish installing..."
fi

# ── Clone or Update ──────────────────────────────────────────────

if [ -d "$INSTALL_DIR/.git" ]; then
  echo -e "${GREEN}Nexus already installed at ${INSTALL_DIR}${NC}"
  echo "  Pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only > /dev/null 2>&1 || {
    echo -e "${YELLOW}  Pull failed (local changes?). Continuing with existing version.${NC}"
  }
else
  echo "Cloning Nexus to ${INSTALL_DIR}..."
  git clone "$REPO" "$INSTALL_DIR"
fi

echo ""

# ── Run Bootstrap ────────────────────────────────────────────────

if [ -f "$INSTALL_DIR/bootstrap.sh" ]; then
  echo -e "${BOLD}Running bootstrap...${NC}"
  echo ""
  bash "$INSTALL_DIR/bootstrap.sh"
else
  echo -e "${RED}Error: bootstrap.sh not found in ${INSTALL_DIR}${NC}"
  exit 1
fi

# ── Symlink nexus CLI ────────────────────────────────────────────

mkdir -p "$BIN_DIR"
if [ -f "$INSTALL_DIR/nexus" ]; then
  ln -sf "$INSTALL_DIR/nexus" "$BIN_DIR/nexus"
  echo ""
  echo -e "${GREEN}nexus CLI installed.${NC} Run ${BOLD}nexus${NC} from anywhere to get started."
fi

# ── Ensure ~/.local/bin is on PATH ───────────────────────────────

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo ""
  echo -e "${YELLOW}Note: ~/.local/bin is not on your PATH yet.${NC}"
  echo -e "Add this to your ~/.zshrc if it's not already there:"
  echo ""
  echo -e "  ${DIM}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
  echo ""
fi

echo ""
echo -e "${BOLD}Done.${NC} Restart your terminal, then run ${BOLD}nexus${NC} to start a session."
echo ""
