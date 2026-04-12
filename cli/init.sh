#!/bin/bash
# cli/init.sh — nexus init command

cmd_init() {
  local project_name="${1:-}"
  local is_existing=false
  local orig_dir="$PWD"

  check_git

  # ── Detect new vs existing ────────────────────────────────────────
  if [ -n "$project_name" ]; then
    if [ ! -d "$project_name" ]; then
      mkdir -p "$project_name"
      cd "$project_name"
      git init --quiet
      print_ok "Created $project_name and initialized git"
    else
      cd "$project_name"
      is_existing=true
      print_ok "Found existing directory: $project_name"
    fi
  else
    if [ -d ".git" ]; then
      is_existing=true
      print_ok "Detected existing git repo"
    else
      git init --quiet
      print_ok "Initialized git repo in current directory"
    fi
  fi

  print_header "nexus init"

  # ── Project type ──────────────────────────────────────────────────
  echo -e "  What are you building?"
  echo -e "    ${BOLD}1${NC}  Web app (Next.js + Postgres + the works)"
  echo -e "    ${BOLD}2${NC}  Other (just give me the conventions)"
  printf "  [1/2]: "
  read project_type_choice || true
  echo ""

  local project_type
  if [ "${project_type_choice:-}" = "1" ]; then
    project_type="web-app"
  else
    project_type="other"
  fi

  # ── Stack questions (web app only) ────────────────────────────────
  local want_db=true
  local want_auth=true
  local api_choice="1"
  local want_ci=true

  if [ "$project_type" = "web-app" ]; then
    printf "  Database? [Y/n]: "
    read db_ans || true
    [ "${db_ans:-y}" = "n" ] || [ "${db_ans:-y}" = "N" ] && want_db=false

    printf "  Auth? [Y/n]: "
    read auth_ans || true
    [ "${auth_ans:-y}" = "n" ] || [ "${auth_ans:-y}" = "N" ] && want_auth=false

    echo -e "  API style?"
    echo -e "    ${BOLD}1${NC}  tRPC (default)"
    echo -e "    ${BOLD}2${NC}  REST"
    echo -e "    ${BOLD}3${NC}  Skip"
    printf "  [1/2/3]: "
    read api_choice || true
    api_choice="${api_choice:-1}"

    printf "  CI? [Y/n]: "
    read ci_ans || true
    [ "${ci_ans:-y}" = "n" ] || [ "${ci_ans:-y}" = "N" ] && want_ci=false

    echo ""
  fi

  # ── Drop core files ───────────────────────────────────────────────
  print_header "Dropping core files"

  drop_file "$TEMPLATES/core/CLAUDE.md.$project_type"          "CLAUDE.md"          || true
  drop_file "$TEMPLATES/core/justfile.$project_type"           "justfile"           || true
  drop_file "$TEMPLATES/core/gitignore"                        ".gitignore"         || true
  drop_file "$TEMPLATES/core/env.example"                      ".env.example"       || true
  drop_file "$TEMPLATES/core/mise.toml"                        ".mise.toml"         || true
  drop_file "$TEMPLATES/core/pull_request_template.md"         ".github/pull_request_template.md" || true

  # ── Run add commands ──────────────────────────────────────────────
  if [ "$project_type" = "web-app" ]; then
    echo ""
    printf "  Set up everything based on your choices? [Y/n]: "
    read setup_ans || true

    if [ "${setup_ans:-y}" != "n" ] && [ "${setup_ans:-y}" != "N" ]; then
      if [ "$want_db" = true ]; then
        source "$NEXUS_DIR/cli/add-db.sh"
        cmd_add_db
      fi
      if [ "$want_auth" = true ]; then
        source "$NEXUS_DIR/cli/add-auth.sh"
        cmd_add_auth
      fi
      if [ "$api_choice" != "3" ]; then
        source "$NEXUS_DIR/cli/add-api.sh"
        cmd_add_api
      fi
      source "$NEXUS_DIR/cli/add-hooks.sh"
      cmd_add_hooks
      if [ "$want_ci" = true ]; then
        source "$NEXUS_DIR/cli/add-ci.sh"
        cmd_add_ci
      fi
    else
      echo ""
      echo -e "  Available commands:"
      echo -e "    ${GREEN}nexus add db${NC}     — database layer (Drizzle + Postgres)"
      echo -e "    ${GREEN}nexus add auth${NC}   — auth layer (Clerk)"
      echo -e "    ${GREEN}nexus add api${NC}    — API layer (tRPC)"
      echo -e "    ${GREEN}nexus add hooks${NC}  — git hooks + scripts"
      echo -e "    ${GREEN}nexus add ci${NC}     — CI workflow"
    fi
  else
    echo ""
    printf "  Set up hooks? [Y/n]: "
    read hooks_ans || true
    if [ "${hooks_ans:-y}" != "n" ] && [ "${hooks_ans:-y}" != "N" ]; then
      source "$NEXUS_DIR/cli/add-hooks.sh"
      cmd_add_hooks
    fi
  fi

  # ── Pending installs ──────────────────────────────────────────────
  if [ -n "$PENDING_INSTALLS" ]; then
    echo ""
    echo -e "  ${BOLD}Run these to install dependencies:${NC}"
    printf "$PENDING_INSTALLS"
  fi

  # ── Offer commit ──────────────────────────────────────────────────
  echo ""
  printf "  Commit these changes? [Y/n]: "
  read commit_ans || true
  if [ "${commit_ans:-y}" != "n" ] && [ "${commit_ans:-y}" != "N" ]; then
    git add -A && git commit -m "chore: initialize project with nexus conventions" --quiet
    print_ok "Committed"
  fi

  # ── Done ──────────────────────────────────────────────────────────
  echo ""
  echo -e "  ${GREEN}${BOLD}Done.${NC} Run ${CYAN}nexus doctor${NC} anytime to check project health."
  echo ""
}
