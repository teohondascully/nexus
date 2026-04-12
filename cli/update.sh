#!/bin/bash
# cli/update.sh — nexus update (simplified — scripts are global)

cmd_update() {
  set +e

  if [ ! -d ".git" ]; then
    echo ""
    echo -e "  ${RED}Not a git repository.${NC} Run nexus update from inside a project."
    echo ""
    return 1
  fi

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

  # ── Scripts (informational — they update globally) ──────────────
  echo -e "  ${BOLD}Scripts${NC} ${DIM}(global — updated via git pull)${NC}"
  echo -e "  ${GREEN}ok${NC}    All scripts updated to v${remote_ver}"
  echo ""

  # ── CLAUDE.md section migration ────────────────────────────────
  if [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md" ]; then
    echo -e "  ${BOLD}CLAUDE.md${NC}"

    local template="$TEMPLATES/CLAUDE.md"
    local template_sections
    template_sections=$(parse_nexus_sections "$template")
    local project_sections
    project_sections=$(parse_nexus_sections "CLAUDE.md")

    for section in $template_sections; do
      if echo "$project_sections" | grep -q "^${section}$"; then
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
        echo -e "  ${CYAN}new${NC}   $section"
        updates_available=true
      fi
    done

    # Check for Node addon sections
    local eco
    eco=$(detect_ecosystem)
    if [ "$eco" = "node" ] && [ -f "$TEMPLATES/CLAUDE.md.node" ]; then
      if ! grep -q "nexus:conventions-node" "CLAUDE.md" 2>/dev/null; then
        echo -e "  ${CYAN}new${NC}   conventions-node"
        updates_available=true
      fi
    fi
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
  printf "  Apply? [Y/n]: "
  read -r apply_choice < /dev/tty || true

  case "${apply_choice:-y}" in
    [nN]) return 0 ;;
  esac

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

    # Add Node addon if applicable
    local eco
    eco=$(detect_ecosystem)
    if [ "$eco" = "node" ] && [ -f "$TEMPLATES/CLAUDE.md.node" ]; then
      if ! grep -q "nexus:conventions-node" "CLAUDE.md" 2>/dev/null; then
        printf "\n" >> "CLAUDE.md"
        cat "$TEMPLATES/CLAUDE.md.node" >> "CLAUDE.md"
        echo -e "  ${GREEN}added${NC} CLAUDE.md:conventions-node"
      fi
    fi
  fi

  # ── Stamp version ──────────────────────────────────────────────
  cp "$HOME/.nexus/VERSION" ".nexus-version" 2>/dev/null || true

  echo ""
  echo -e "  ${GREEN}Updated to v${remote_ver}.${NC}"
  echo ""
}
