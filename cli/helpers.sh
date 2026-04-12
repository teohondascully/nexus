#!/bin/bash
# cli/helpers.sh — shared utilities for nexus commands

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── Resolve vault directory ─────────────────────────────────────
resolve_vault_dir() {
  local source="${BASH_SOURCE[0]}"
  while [ -L "$source" ]; do
    local dir="$(cd "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source"
  done
  echo "$(cd "$(dirname "$source")/.." && pwd)"
}

VAULT_DIR="$(resolve_vault_dir)"
TEMPLATES="$VAULT_DIR/templates"
SCRIPTS="$VAULT_DIR/scripts"

# ── Ecosystem Detection ─────────────────────────────────────────
detect_ecosystem() {
  if [ -f "package.json" ]; then
    echo "node"
  elif [ -f "go.mod" ]; then
    echo "go"
  elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    echo "python"
  elif [ -f "Cargo.toml" ]; then
    echo "rust"
  else
    echo "generic"
  fi
}

# Checks if any existing build system is present
has_build_system() {
  [ -f "Makefile" ] || [ -f "taskfile.yml" ] || [ -f "justfile" ] || \
  [ -f "Rakefile" ] || [ -f "build.gradle" ] || [ -f "pom.xml" ]
}

# ── Prereq Checks ───────────────────────────────────────────────
has_cmd() {
  command -v "$1" &> /dev/null
}

check_git() {
  if ! has_cmd git; then
    echo -e "${RED}git not found.${NC} Run: curl -fsSL https://www.teonnaise.com/install | bash"
    exit 1
  fi
}

check_prereq() {
  local cmd="$1"
  local msg="$2"
  if ! has_cmd "$cmd"; then
    echo -e "  ${YELLOW}!${NC} $cmd not found. $msg"
    return 1
  fi
  return 0
}

# ── Output Helpers ───────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "  ${BOLD}$1${NC}"
  echo ""
}

print_ok() {
  echo -e "  ${GREEN}ok${NC}  $1"
}

print_fail() {
  echo -e "  ${RED}FAIL${NC}  $1"
}

print_warn() {
  echo -e "  ${YELLOW}!${NC}  $1"
}

print_skip() {
  echo -e "  ${DIM}skip${NC}  $1"
}

# ── Pending Installs Tracker ─────────────────────────────────────
PENDING_INSTALLS=""

add_pending_install() {
  PENDING_INSTALLS="${PENDING_INSTALLS}    $1\n"
}

# ── File Conflict Handler ────────────────────────────────────────
drop_file() {
  local src="$1"
  local dest="$2"
  local dest_dir="$(dirname "$dest")"

  mkdir -p "$dest_dir"

  if [ -f "$dest" ]; then
    local basename="$(basename "$dest")"
    echo -e "  ${YELLOW}$basename${NC} already exists. [${BOLD}O${NC}]verwrite / [${BOLD}S${NC}]kip / [${BOLD}D${NC}]iff?"
    while true; do
      printf "  "
      read -n 1 -r choice
      echo ""
      case $choice in
        [oO]) cp "$src" "$dest"; echo -e "  ${GREEN}overwrote${NC} $basename"; return 0 ;;
        [sS]) echo -e "  ${DIM}skipped${NC} $basename"; return 1 ;;
        [dD]) diff --color=always "$dest" "$src" | head -40; echo ""; ;;
        *) echo "  o/s/d?" ;;
      esac
    done
  else
    cp "$src" "$dest"
    echo -e "  ${GREEN}created${NC} $(basename "$dest")"
    return 0
  fi
}

# ── Append with Marker ───────────────────────────────────────────
append_to_file() {
  local file="$1"
  local marker="$2"
  local content="$3"

  if [ -f "$file" ] && grep -q "$marker" "$file" 2>/dev/null; then
    return 1
  fi

  echo "$content" >> "$file"
  return 0
}

# ── File Drop (silent skip if exists) ────────────────────────────
drop_template() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ]; then
    print_skip "$(basename "$dest") (already exists)"
    return 1
  fi

  cp "$src" "$dest"
  echo -e "  ${GREEN}created${NC} $(basename "$dest")"
  return 0
}

# ── CLAUDE.md Section Migration ─────────────────────────────────
# Parses nexus-owned sections from a CLAUDE.md file
# Returns lines of "section_name" for each <!-- nexus:name --> found
parse_nexus_sections() {
  local file="$1"
  grep -o '<!-- nexus:\([a-z-]*\) -->' "$file" 2>/dev/null | grep -v 'nexus:end' | sed 's/<!-- nexus:\(.*\) -->/\1/'
}

# Extracts content between <!-- nexus:name --> and <!-- nexus:end -->
extract_section() {
  local file="$1"
  local name="$2"
  awk -v name="$name" '
    $0 ~ "<!-- nexus:" name " -->" { found=1; next }
    /<!-- nexus:end -->/ { if(found) { found=0; next } }
    found { print }
  ' "$file"
}

# Replaces a nexus-owned section in a file with new content
replace_section() {
  local file="$1"
  local name="$2"
  local new_content="$3"

  # Write content to temp file to avoid awk -v multiline/escape issues
  local tmpfile
  tmpfile=$(mktemp)
  printf '%s\n' "$new_content" > "$tmpfile"

  awk -v name="$name" -v tmpfile="$tmpfile" '
    $0 ~ "<!-- nexus:" name " -->" {
      print
      while ((getline line < tmpfile) > 0) print line
      close(tmpfile)
      skip=1
      next
    }
    /<!-- nexus:end -->/ { if(skip) { print; skip=0; next } }
    !skip { print }
  ' "$file" > "$file.tmp"
  rm -f "$tmpfile"
  mv "$file.tmp" "$file"
}

# Appends a new nexus section to the end of CLAUDE.md
append_section() {
  local file="$1"
  local name="$2"
  local content="$3"

  printf "\n<!-- nexus:%s -->\n%s\n<!-- nexus:end -->\n" "$name" "$content" >> "$file"
}
