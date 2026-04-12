#!/bin/bash
# cli/update.sh — nexus update command

cmd_update() {
  print_header "nexus update"

  # ── 1. Pull latest vault ──────────────────────────────────────────
  if [ -d "$HOME/.nexus/.git" ]; then
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

  # Template source mapping
  declare -A template_map
  template_map["scripts/sync-claude-md.sh"]="$TEMPLATES/scripts/sync-claude-md.sh"
  template_map["scripts/check-env-sync.sh"]="$TEMPLATES/scripts/check-env-sync.sh"
  template_map["scripts/check-deps-direction.ts"]="$TEMPLATES/scripts/check-deps-direction.ts"
  template_map["scripts/check-dead-exports.ts"]="$TEMPLATES/scripts/check-dead-exports.ts"
  template_map["scripts/validate-startup.sh"]="$TEMPLATES/scripts/validate-startup.sh"
  template_map["lefthook.yml"]="$TEMPLATES/hooks/lefthook.yml"
  template_map[".github/pull_request_template.md"]="$TEMPLATES/core/pull_request_template.md"

  local all_files=("${scripts[@]}" "${single_files[@]}")

  # Track what needs updating
  local new_files=()
  local update_files=()

  # ── 3. Compare files ─────────────────────────────────────────────
  for file in "${all_files[@]}"; do
    local tmpl="${template_map[$file]}"

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
      local tmpl="${template_map[$file]}"
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
    local tmpl="${template_map[$file]}"
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
