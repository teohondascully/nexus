#!/bin/bash
# cli/add-ci.sh — nexus add ci

cmd_add_ci() {
  print_header "Adding CI"

  mkdir -p .github/workflows

  drop_file "$TEMPLATES/ci/ci.yml"  ".github/workflows/ci.yml"  || true

  # Check for gh CLI
  if check_prereq gh "Install GitHub CLI: https://cli.github.com"; then
    if ! gh auth status &>/dev/null; then
      print_warn "gh is installed but not authenticated. Run: gh auth login"
    else
      print_ok "GitHub CLI authenticated"
    fi
  fi

  print_ok "CI layer ready"
}
