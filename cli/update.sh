#!/bin/bash
# cli/update.sh — nexus update command

cmd_update() {
  print_header "nexus update"

  # ── 0. Check vault exists ─────────────────────────────────────────
  if [ ! -d "$HOME/.nexus" ]; then
    echo -e "  ${RED}~/.nexus not found.${NC} Install first:"
    echo -e "  curl -fsSL https://www.teonnaise.com/install | bash"
    echo ""
    return 1
  fi

  # ── 1. Pull latest vault ──────────────────────────────────────────
  if [ -d "$HOME/.nexus/.git" ]; then
    echo -e "  Pulling latest..."
    if ! git -C "$HOME/.nexus" pull --ff-only --quiet 2>/dev/null; then
      print_warn "Could not pull latest vault (not fast-forward or no network)"
    fi
  fi

  # ── 2. Files to check ────────────────────────────────────────────
  # scripts/ files
  local scripts=(
    "scripts/sync-claude-md.sh"
    "scripts/check-env-sync.sh"
    "scripts/check-deps-direction.ts"
    "scripts/check-dead-exports.ts"
    "scripts/validate-startup.sh"
  )

  # Determine CLAUDE.md template (by convention — always skip)
  # and other single files
  local single_files=(
    "lefthook.yml"
    ".github/pull_request_template.md"
  )

  # Template source lookup (bash 3.2 compatible — no associative arrays)
  get_template() {
    case "$1" in
      "scripts/sync-claude-md.sh")         echo "$TEMPLATES/scripts/sync-claude-md.sh" ;;
      "scripts/check-env-sync.sh")         echo "$TEMPLATES/scripts/check-env-sync.sh" ;;
      "scripts/check-deps-direction.ts")   echo "$TEMPLATES/scripts/check-deps-direction.ts" ;;
      "scripts/check-dead-exports.ts")     echo "$TEMPLATES/scripts/check-dead-exports.ts" ;;
      "scripts/validate-startup.sh")       echo "$TEMPLATES/scripts/validate-startup.sh" ;;
      "lefthook.yml")                      echo "$TEMPLATES/hooks/lefthook.yml" ;;
      ".github/pull_request_template.md")  echo "$TEMPLATES/core/pull_request_template.md" ;;
      *) echo "" ;;
    esac
  }

  local all_files=("${scripts[@]}" "${single_files[@]}")

  # Track what needs updating
  local new_files=()
  local update_files=()

  # ── 3. Compare files ─────────────────────────────────────────────
  for file in "${all_files[@]}"; do
    local tmpl
    tmpl="$(get_template "$file")"

    # Skip if template doesn't exist
    if [ ! -f "$tmpl" ]; then
      continue
    fi

    if [ ! -f "$file" ]; then
      echo -e "  ${CYAN}+${NC}  ${file} ${DIM}(new)${NC}"
      new_files+=("$file")
    elif is_customized "$file"; then
      echo -e "  ${DIM}skip  ${file} (customized)${NC}"
    elif ! diff -q "$file" "$tmpl" &>/dev/null; then
      echo -e "  ${YELLOW}↑${NC}  ${file} ${DIM}(update available)${NC}"
      update_files+=("$file")
    else
      print_ok "$file"
    fi
  done

  # Always note CLAUDE.md and justfile are skipped
  echo -e "  ${DIM}skip  CLAUDE.md (always customized)${NC}"
  echo -e "  ${DIM}skip  justfile (always customized)${NC}"

  echo ""

  # ── 4. Apply ─────────────────────────────────────────────────────
  local actionable=("${new_files[@]}" "${update_files[@]}")

  if [ ${#actionable[@]} -eq 0 ]; then
    echo -e "  ${GREEN}Everything up to date.${NC}"
    echo ""
    return 0
  fi

  local answer
  printf "  Apply updates? [Y/n/diff] "
  read -r answer
  answer="${answer:-Y}"

  # Handle diff option
  if [[ "$answer" =~ ^[dD]$ ]]; then
    echo ""
    for file in "${actionable[@]}"; do
      local tmpl
      tmpl="$(get_template "$file")"
      echo -e "  ${BOLD}--- ${file}${NC}"
      if [ ! -f "$file" ]; then
        echo -e "  ${CYAN}(new file)${NC}"
        head -30 "$tmpl" | while IFS= read -r line; do
          echo -e "  ${CYAN}+ ${line}${NC}"
        done
      else
        diff --color=always "$file" "$tmpl" | head -30 || true
      fi
      echo ""
    done

    printf "  Apply? [Y/n] "
    read -r answer
    answer="${answer:-Y}"
  fi

  if [[ "$answer" =~ ^[nN]$ ]]; then
    echo ""
    return 0
  fi

  # Apply updates
  for file in "${actionable[@]}"; do
    local tmpl
    tmpl="$(get_template "$file")"
    local dir
    dir="$(dirname "$file")"
    mkdir -p "$dir"
    cp "$tmpl" "$file"
    update_checksum "$file"
    # chmod +x for shell scripts and TypeScript scripts used via bun
    case "$file" in
      scripts/*.sh) chmod +x "$file" ;;
    esac
  done

  echo ""
  echo -e "  ${GREEN}Updates applied.${NC}"
  echo ""
}
