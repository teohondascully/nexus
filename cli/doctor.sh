#!/bin/bash
# cli/doctor.sh — nexus doctor command

cmd_doctor() {
  local quick=false
  local fix=false

  for arg in "$@"; do
    case "$arg" in
      --quick) quick=true ;;
      --fix)   fix=true ;;
    esac
  done

  local passed=0
  local failed=0
  local skipped=0

  if [ ! -d ".git" ]; then
    echo ""
    echo -e "  ${RED}Not a git repository.${NC} Run nexus doctor from inside a project."
    echo ""
    return 1
  fi

  print_header "nexus doctor"

  # ── 1. CLAUDE.md file structure sync ────────────────────────────
  if [ -f "CLAUDE.md" ] && grep -q "FILE_STRUCTURE_START" "CLAUDE.md" 2>/dev/null && [ -f "scripts/sync-claude-md.sh" ]; then
    local backup="CLAUDE.md.doctor-backup"
    cp "CLAUDE.md" "$backup"
    if bash scripts/sync-claude-md.sh "CLAUDE.md" 2>/dev/null; then
      if diff -q "$backup" "CLAUDE.md" &>/dev/null; then
        print_ok "CLAUDE.md file structure sync"
        ((passed++))
      else
        if $fix; then
          print_ok "CLAUDE.md file structure sync (fixed)"
          ((passed++))
        else
          cp "$backup" "CLAUDE.md"
          print_fail "CLAUDE.md file structure is out of sync (run with --fix)"
          ((failed++))
        fi
      fi
    else
      cp "$backup" "CLAUDE.md"
      print_fail "CLAUDE.md sync script failed"
      ((failed++))
    fi
    rm -f "$backup"
  else
    print_skip "CLAUDE.md file structure sync (no markers or script)"
    ((skipped++))
  fi

  # ── 2. .env.example coverage ─────────────────────────────────────
  if [ -f "scripts/check-env-sync.sh" ]; then
    local env_output
    env_output=$(bash scripts/check-env-sync.sh 2>&1)
    local env_exit=$?
    if [ $env_exit -eq 0 ]; then
      print_ok ".env.example coverage"
      ((passed++))
    else
      if $fix && [ -f ".env.example" ]; then
        local missing_vars
        missing_vars=$(echo "$env_output" | grep -oE '^[A-Z_][A-Z0-9_]+' 2>/dev/null || true)
        if [ -n "$missing_vars" ]; then
          while IFS= read -r varname; do
            [ -n "$varname" ] && echo "${varname}= # TODO: set value" >> ".env.example"
          done <<< "$missing_vars"
        fi
        print_ok ".env.example coverage (fixed)"
        ((passed++))
      else
        print_fail ".env.example coverage"
        echo "$env_output" | head -5 | while IFS= read -r line; do
          echo -e "        ${DIM}${line}${NC}"
        done
        ((failed++))
      fi
    fi
  else
    print_skip ".env.example coverage (no check-env-sync.sh)"
    ((skipped++))
  fi

  # ── 3. Dependency direction ───────────────────────────────────────
  if has_cmd bun && [ -f "scripts/check-deps-direction.ts" ]; then
    local deps_output
    deps_output=$(bun scripts/check-deps-direction.ts 2>&1)
    local deps_exit=$?
    if [ $deps_exit -eq 0 ]; then
      print_ok "Dependency direction"
      ((passed++))
    else
      print_fail "Dependency direction"
      echo "$deps_output" | head -5 | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    print_skip "Dependency direction (bun or script not found)"
    ((skipped++))
  fi

  # ── 4. Dead exports ───────────────────────────────────────────────
  if has_cmd bun && [ -f "scripts/check-dead-exports.ts" ]; then
    local dead_output
    dead_output=$(bun scripts/check-dead-exports.ts 2>&1)
    local dead_exit=$?
    if [ $dead_exit -eq 0 ]; then
      print_ok "Dead exports"
      ((passed++))
    else
      local dead_count
      dead_count=$(echo "$dead_output" | wc -l | tr -d ' ')
      print_fail "Dead exports (${dead_count} found)"
      echo "$dead_output" | head -5 | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    print_skip "Dead exports (bun or script not found)"
    ((skipped++))
  fi

  # ── 5. Startup validation (skip if --quick) ───────────────────────
  if $quick; then
    print_skip "Startup validation (--quick)"
    ((skipped++))
  elif [ -f "scripts/validate-startup.sh" ]; then
    local startup_output
    startup_output=$(bash scripts/validate-startup.sh 2>&1)
    local startup_exit=$?
    if [ $startup_exit -eq 0 ]; then
      print_ok "Startup validation"
      ((passed++))
    else
      print_fail "Startup validation"
      echo "$startup_output" | while IFS= read -r line; do
        echo -e "        ${DIM}${line}${NC}"
      done
      ((failed++))
    fi
  else
    print_skip "Startup validation (no validate-startup.sh)"
    ((skipped++))
  fi

  # ── 6. Outdated dependencies (skip if --quick) ────────────────────
  if $quick; then
    print_skip "Outdated dependencies (--quick)"
    ((skipped++))
  elif ! has_cmd pnpm || [ ! -f "package.json" ]; then
    print_skip "Outdated dependencies (pnpm or package.json not found)"
    ((skipped++))
  else
    local outdated_output
    outdated_output=$(pnpm outdated 2>&1)
    local outdated_exit=$?
    if [ $outdated_exit -eq 0 ]; then
      print_ok "Outdated dependencies"
      ((passed++))
    else
      local outdated_count
      outdated_count=$(echo "$outdated_output" | grep -c '^' || true)
      print_fail "Outdated dependencies (${outdated_count} package(s))"
      ((failed++))
    fi
  fi

  # ── 7. lefthook installed ─────────────────────────────────────────
  if [ -f "lefthook.yml" ] && has_cmd lefthook && [ -f ".git/hooks/pre-commit" ]; then
    print_ok "lefthook installed"
    ((passed++))
  else
    local lh_msg="lefthook not fully configured"
    if [ ! -f "lefthook.yml" ]; then
      lh_msg="${lh_msg} (missing lefthook.yml)"
    fi
    if ! has_cmd lefthook; then
      lh_msg="${lh_msg} (lefthook not in PATH — run: brew install lefthook)"
    fi
    if [ ! -f ".git/hooks/pre-commit" ]; then
      lh_msg="${lh_msg} (hooks not installed — run: lefthook install)"
    fi
    print_fail "$lh_msg"
    ((failed++))
  fi

  # ── 8. Claude Code hooks present ──────────────────────────────────
  if [ -f ".claude/settings.json" ]; then
    print_ok "Claude Code hooks present"
    ((passed++))
  else
    print_fail "Claude Code hooks present (.claude/settings.json missing)"
    ((failed++))
  fi

  # ── 9. PR template present ────────────────────────────────────────
  if [ -f ".github/pull_request_template.md" ]; then
    print_ok "PR template present"
    ((passed++))
  else
    print_fail "PR template present (.github/pull_request_template.md missing)"
    ((failed++))
  fi

  # ── 10. Nexus version (skip if --quick) ────────────────────────────
  if $quick; then
    print_skip "Nexus version (--quick)"
    ((skipped++))
  elif [ -d "$HOME/.nexus/.git" ] && [ -f "$HOME/.nexus/VERSION" ]; then
    local local_ver
    local_ver=$(cat "$HOME/.nexus/VERSION" 2>/dev/null || echo "unknown")
    local remote_ver
    remote_ver=$(git -C "$HOME/.nexus" show origin/main:VERSION 2>/dev/null || echo "")
    if [ -z "$remote_ver" ]; then
      # Try fetching first
      git -C "$HOME/.nexus" fetch --quiet origin main 2>/dev/null || true
      remote_ver=$(git -C "$HOME/.nexus" show origin/main:VERSION 2>/dev/null || echo "")
    fi
    if [ -z "$remote_ver" ] || [ "$local_ver" = "$remote_ver" ]; then
      print_ok "Nexus version (v${local_ver})"
      ((passed++))
    else
      print_fail "Nexus outdated (v${local_ver} → v${remote_ver})"
      echo -e "        ${DIM}Run: curl -fsSL https://www.teonnaise.com/install | bash${NC}"
      ((failed++))
    fi
  else
    print_skip "Nexus version (~/.nexus not found)"
    ((skipped++))
  fi

  # ── Summary ───────────────────────────────────────────────────────
  local total=$(( passed + failed ))
  echo ""
  if [ $failed -eq 0 ]; then
    echo -e "  ${GREEN}${passed}/${total} passed${NC}  ${DIM}${skipped} skipped${NC}"
  else
    echo -e "  ${GREEN}${passed}/${total} passed${NC}  ${RED}${failed} issue(s) found${NC}  ${DIM}${skipped} skipped${NC}"
  fi
  echo ""

  return $failed
}
