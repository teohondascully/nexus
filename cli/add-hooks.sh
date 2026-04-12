#!/bin/bash
# cli/add-hooks.sh — nexus add hooks

cmd_add_hooks() {
  print_header "Adding hooks"

  mkdir -p scripts

  # Drop all scripts
  drop_file "$TEMPLATES/scripts/check-dead-exports.ts"    "scripts/check-dead-exports.ts"    || true
  drop_file "$TEMPLATES/scripts/check-deps-direction.ts"  "scripts/check-deps-direction.ts"  || true
  drop_file "$TEMPLATES/scripts/check-env-sync.sh"        "scripts/check-env-sync.sh"        || true
  drop_file "$TEMPLATES/scripts/sync-claude-md.sh"        "scripts/sync-claude-md.sh"        || true
  drop_file "$TEMPLATES/scripts/validate-startup.sh"      "scripts/validate-startup.sh"      || true

  # Make shell scripts executable
  chmod +x scripts/check-env-sync.sh scripts/sync-claude-md.sh scripts/validate-startup.sh 2>/dev/null || true

  # Drop lefthook config
  drop_file "$TEMPLATES/hooks/lefthook.yml"  "lefthook.yml"  || true

  # Handle lefthook installation
  if ! has_cmd lefthook; then
    echo ""
    printf "  Install lefthook? [Y/n]: "
    read install_lefthook_ans || true
    if [ "${install_lefthook_ans:-y}" != "n" ] && [ "${install_lefthook_ans:-y}" != "N" ]; then
      if has_cmd brew; then
        brew install lefthook
      else
        print_warn "brew not found. Install lefthook manually: https://github.com/evilmartians/lefthook#install"
      fi
    fi
  fi

  if has_cmd lefthook; then
    lefthook install
    print_ok "lefthook installed hooks"
  fi

  # Superpowers prompt
  echo ""
  printf "  Use Superpowers (Claude Code plugin)? [Y/n]: "
  read superpowers_ans || true

  mkdir -p .claude

  if [ "${superpowers_ans:-y}" != "n" ] && [ "${superpowers_ans:-y}" != "N" ]; then
    drop_file "$TEMPLATES/hooks/claude-settings-superpowers.json"  ".claude/settings.json"  || true

    # Append Superpowers workflow section to CLAUDE.md
    append_to_file "CLAUDE.md" "Superpowers" "
## Superpowers Workflow

This project uses the Claude Code Superpowers plugin. After each Write or Edit tool use,
\`scripts/sync-claude-md.sh\` runs automatically to keep the File Structure section of
CLAUDE.md in sync with the actual codebase." || true

    print_ok "Superpowers enabled"
  else
    drop_file "$TEMPLATES/hooks/claude-settings.json"  ".claude/settings.json"  || true
    print_ok "Claude settings configured"
  fi

  # Track checksums file in gitignore
  append_to_file ".gitignore" ".nexus-checksums" "
# nexus
.nexus-checksums" || true

  # Run initial CLAUDE.md sync if both script and CLAUDE.md exist
  if [ -f "scripts/sync-claude-md.sh" ] && [ -f "CLAUDE.md" ]; then
    bash scripts/sync-claude-md.sh 2>/dev/null || true
    print_ok "Initial CLAUDE.md sync complete"
  fi

  print_ok "Hooks layer ready"
}
