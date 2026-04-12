#!/bin/bash
# cli/update.sh — nexus update with section-level CLAUDE.md migration

cmd_update() {
  echo ""
  echo -e "  ${BOLD}nexus update${NC}"

  # ── Check vault exists ─────────────────────────────────────────
  if [ ! -d "$HOME/.nexus" ]; then
    echo ""
    echo -e "  ${RED}~/.nexus not found.${NC} Install: curl -fsSL https://www.teonnaise.com/install | bash"
    echo ""
    return 1
  fi

  # ── Pull latest ────────────────────────────────────────────────
  echo ""
  echo -e "  Pulling latest..."
  if [ -d "$HOME/.nexus/.git" ]; then
    git -C "$HOME/.nexus" pull --ff-only --quiet 2>/dev/null || {
      print_warn "Could not pull (not fast-forward or offline)"
    }
  fi

  # ── Compare versions ───────────────────────────────────────────
  local local_ver="unknown"
  local remote_ver="unknown"
  [ -f ".nexus-version" ] && local_ver=$(cat .nexus-version)
  [ -f "$HOME/.nexus/VERSION" ] && remote_ver=$(cat "$HOME/.nexus/VERSION")

  if [ "$local_ver" = "$remote_ver" ]; then
    echo -e "  ${GREEN}Up to date${NC} (v${local_ver})"
    echo ""
    return 0
  fi

  echo -e "  v${local_ver} → v${remote_ver}"
  echo ""

  local updates_available=false

  # ── Script migration ───────────────────────────────────────────
  echo -e "  ${BOLD}Scripts${NC}"
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
    local src="$SCRIPTS/$script"
    local dest="scripts/$script"

    if [ ! -f "$src" ]; then continue; fi

    if [ ! -f "$dest" ]; then
      echo -e "  ${CYAN}new${NC}   $script"
      updates_available=true
    elif is_customized "$dest"; then
      echo -e "  ${DIM}skip${NC}  $script ${DIM}(customized)${NC}"
    elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}up${NC}    $script"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}    $script"
    fi
  done

  # ── Hook migration ─────────────────────────────────────────────
  for hook in lefthook.yml; do
    local src="$TEMPLATES/$hook"
    local dest="$hook"
    if [ ! -f "$src" ] || [ ! -f "$dest" ]; then continue; fi

    if is_customized "$dest"; then
      echo -e "  ${DIM}skip${NC}  $hook ${DIM}(customized)${NC}"
    elif ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}up${NC}    $hook"
      updates_available=true
    else
      echo -e "  ${GREEN}ok${NC}    $hook"
    fi
  done

  # ── CLAUDE.md section migration ────────────────────────────────
  if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
    echo ""
    echo -e "  ${BOLD}CLAUDE.md${NC}"

    local template="$TEMPLATES/CLAUDE.md"

    # Get all nexus sections from template
    local template_sections
    template_sections=$(parse_nexus_sections "$template")

    # Get all nexus sections from project
    local project_sections
    project_sections=$(parse_nexus_sections "CLAUDE.md")

    for section in $template_sections; do
      if echo "$project_sections" | grep -q "^${section}$"; then
        # Section exists — compare content
        local template_content
        template_content=$(extract_section "$template" "$section")
        local project_content
        project_content=$(extract_section "CLAUDE.md" "$section")

        if [ "$template_content" = "$project_content" ]; then
          echo -e "  ${GREEN}ok${NC}    $section"
        else
          echo -e "  ${YELLOW}up${NC}    $section"
          updates_available=true
        fi
      else
        # New section
        echo -e "  ${CYAN}new${NC}   $section"
        updates_available=true
      fi
    done

    # Show user-owned sections as skipped
    # (anything in CLAUDE.md that's NOT between nexus markers)
    grep '^## ' "CLAUDE.md" | while IFS= read -r header; do
      local header_text="${header#\#\# }"
      # Check if this header is inside a nexus section
      local is_nexus=false
      for section in $template_sections; do
        local section_header
        section_header=$(awk -v name="$section" '
          $0 ~ "<!-- nexus:" name " -->" { found=1; next }
          /<!-- nexus:end -->/ { found=0; next }
          found && /^## / { print; exit }
        ' "$template")
        if [ "## $header_text" = "$section_header" ]; then
          is_nexus=true
          break
        fi
      done
      if [ "$is_nexus" = false ]; then
        echo -e "  ${DIM}skip${NC}  $header_text ${DIM}(yours)${NC}"
      fi
    done
  fi

  if ! $updates_available; then
    echo ""
    echo -e "  ${GREEN}Everything up to date.${NC}"
    echo ""
    cp "$HOME/.nexus/VERSION" ".nexus-version" 2>/dev/null || true
    return 0
  fi

  # ── Apply ──────────────────────────────────────────────────────
  echo ""
  printf "  Apply? [Y/n/diff]: "
  read -r apply_choice || true

  case "${apply_choice:-y}" in
    [dD])
      echo ""
      # Show diffs for scripts
      for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
        local src="$SCRIPTS/$script"
        local dest="scripts/$script"
        if [ -f "$src" ] && [ -f "$dest" ] && ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
          echo -e "  ${BOLD}--- $script ---${NC}"
          diff --color=always "$dest" "$src" 2>/dev/null | head -20
          echo ""
        fi
      done
      # Show diffs for CLAUDE.md sections
      if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
        for section in $(parse_nexus_sections "$TEMPLATES/CLAUDE.md"); do
          if echo "$(parse_nexus_sections "CLAUDE.md")" | grep -q "^${section}$"; then
            local t_content
            t_content=$(extract_section "$TEMPLATES/CLAUDE.md" "$section")
            local p_content
            p_content=$(extract_section "CLAUDE.md" "$section")
            if [ "$t_content" != "$p_content" ]; then
              echo -e "  ${BOLD}--- CLAUDE.md:$section ---${NC}"
              diff --color=always <(echo "$p_content") <(echo "$t_content") 2>/dev/null | head -20
              echo ""
            fi
          fi
        done
      fi
      printf "  Apply these? [Y/n]: "
      read -r apply_final || true
      [[ "${apply_final:-y}" =~ ^[nN]$ ]] && return 0
      ;;
    [nN]) return 0 ;;
  esac

  # ── Apply scripts ──────────────────────────────────────────────
  mkdir -p scripts
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
    local src="$SCRIPTS/$script"
    local dest="scripts/$script"
    if [ ! -f "$src" ]; then continue; fi

    if [ ! -f "$dest" ]; then
      cp "$src" "$dest"
      chmod +x "$dest" 2>/dev/null || true
      update_checksum "$dest"
      echo -e "  ${GREEN}added${NC} $script"
    elif ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      cp "$src" "$dest"
      chmod +x "$dest" 2>/dev/null || true
      update_checksum "$dest"
      echo -e "  ${GREEN}updated${NC} $script"
    fi
  done

  # ── Apply hook updates ─────────────────────────────────────────
  for hook in lefthook.yml; do
    local src="$TEMPLATES/$hook"
    local dest="$hook"
    if [ -f "$src" ] && [ -f "$dest" ] && ! is_customized "$dest" && ! diff -q "$src" "$dest" > /dev/null 2>&1; then
      cp "$src" "$dest"
      update_checksum "$dest"
      echo -e "  ${GREEN}updated${NC} $hook"
    fi
  done

  # ── Apply CLAUDE.md section migration ──────────────────────────
  if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
    local template="$TEMPLATES/CLAUDE.md"

    for section in $(parse_nexus_sections "$template"); do
      local new_content
      new_content=$(extract_section "$template" "$section")

      if grep -q "<!-- nexus:${section} -->" "CLAUDE.md" 2>/dev/null; then
        local old_content
        old_content=$(extract_section "CLAUDE.md" "$section")
        if [ "$old_content" != "$new_content" ]; then
          replace_section "CLAUDE.md" "$section" "$new_content"
          echo -e "  ${GREEN}updated${NC} CLAUDE.md:$section"
        fi
      else
        # New section — get full block from template (including header)
        local full_block
        full_block=$(awk -v name="$section" '
          $0 ~ "<!-- nexus:" name " -->" { found=1 }
          found { print }
          /<!-- nexus:end -->/ { if(found) { found=0 } }
        ' "$template")
        printf "\n%s\n" "$full_block" >> "CLAUDE.md"
        echo -e "  ${GREEN}added${NC} CLAUDE.md:$section"
      fi
    done
  fi

  # ── Stamp version ──────────────────────────────────────────────
  cp "$HOME/.nexus/VERSION" ".nexus-version" 2>/dev/null || true

  echo ""
  echo -e "  ${GREEN}Updated to v${remote_ver}.${NC}"
  echo ""
}
