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

# ── Clone or Update (silent) ────────────────────────────────────

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only > /dev/null 2>&1 || true
else
  git clone --quiet "$REPO" "$INSTALL_DIR"
fi

# ── Hand off to bootstrap ───────────────────────────────────────

if [ -f "$INSTALL_DIR/bootstrap.sh" ]; then
  exec bash "$INSTALL_DIR/bootstrap.sh"
else
  echo -e "${RED}Error: bootstrap.sh not found in ${INSTALL_DIR}${NC}"
  exit 1
fi
